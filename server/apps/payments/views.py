"""The payment webhook.

Article 7.3, the whole sequence:

  1. Chargily posts a signed notification to the server.
  2. The server verifies the signature and **rejects any unsigned or duplicated
     notification (idempotency)**.
  3. A subscription is created with state "active" and computed dates.
  4. An activation code is generated, shown to the parent on the page and sent.
  5. The parent enters the code once in the app and the account unlocks.

Steps 2, 3 and 4 happen here. Step 5 is `apps/subscriptions/views.ActivateView`.

The ordering below is the security argument: **verify, then deduplicate, then
act.** Every branch writes a `WebhookEvent` row, including the refusals, so the
question "why did this payment not activate?" is answered by a query.
"""

from __future__ import annotations

import json
import logging

from django.db import IntegrityError, transaction
from django.utils import timezone
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.subscriptions.models import ActivationCode
from apps.subscriptions.plans import PLAN_PRICE_DZD, PlanCode

from . import chargily
from .models import Transaction, TransactionStatus, WebhookEvent

log = logging.getLogger("nojoumi.payments")


class ChargilyWebhookView(APIView):
    """Unauthenticated by necessity — the gateway has no JWT.

    The signature *is* the authentication. This is why `verify_signature`
    returning False by default is the right default: an endpoint that trusts
    unverified input would be an open door to granting subscriptions.
    """

    permission_classes = [AllowAny]
    authentication_classes: list = []

    @extend_schema(
        request=OpenApiTypes.OBJECT,
        responses={
            200: OpenApiTypes.OBJECT,
            400: OpenApiTypes.OBJECT,
            501: OpenApiTypes.OBJECT,
        },
        summary="Chargily payment webhook",
        description=(
            "Called by the gateway, not by the app. The **signature is the "
            "authentication** — there is no JWT.\n\n"
            "Order of operations is the security argument: verify the signature, "
            "then reject duplicates by unique event id, then act (Art. 7.3). "
            "Every outcome, including every refusal, is recorded as a "
            "`WebhookEvent` row so that 'why did this payment not activate?' is "
            "answered by a query rather than a theory.\n\n"
            "Returns 501 while Chargily's signature algorithm and status "
            "vocabulary remain undocumented (Art. 7.8, client obligation). "
            "Refusing is the correct failure mode: an unverified webhook must "
            "never activate a subscription."
        ),
    )
    def post(self, request):
        raw_body: bytes = request.body
        digest = chargily.body_digest(raw_body)
        event_id = chargily.extract_event_id(raw_body, request.headers)

        # --- step 2a: signature ------------------------------------------------
        if not chargily.verify_signature(raw_body, request.headers):
            self._record(
                event_id=event_id,
                digest=digest,
                signature_valid=False,
                outcome=WebhookEvent.Outcome.BAD_SIGNATURE,
                note="signature rejected or verification not yet configured",
            )
            log.warning("webhook rejected: bad or unverifiable signature")
            return Response(
                {"detail": "signature verification failed"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # --- step 2b: idempotency ---------------------------------------------
        # The unique constraint on event_id is the actual guard. Checking first
        # would race; letting the insert fail cannot.
        try:
            with transaction.atomic():
                event = WebhookEvent.objects.create(
                    event_id=event_id,
                    payload_sha256=digest,
                    signature_valid=True,
                    outcome=WebhookEvent.Outcome.PROCESSED,
                )
        except IntegrityError:
            WebhookEvent.objects.filter(event_id=event_id).update(
                outcome=WebhookEvent.Outcome.DUPLICATE
            )
            log.info("webhook ignored: duplicate event")
            # 200, not an error: a gateway retry is normal and must not be
            # retried forever.
            return Response({"detail": "duplicate ignored"}, status=status.HTTP_200_OK)

        # --- steps 3 and 4 -----------------------------------------------------
        try:
            payload = json.loads(raw_body.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            event.outcome = WebhookEvent.Outcome.ERROR
            event.note = "body was not JSON"
            event.save(update_fields=["outcome", "note"])
            return Response(
                {"detail": "invalid body"}, status=status.HTTP_400_BAD_REQUEST
            )

        try:
            transaction_row, code = self._apply(payload)
        except chargily.ChargilyNotConfigured as exc:
            event.outcome = WebhookEvent.Outcome.ERROR
            event.note = str(exc)[:200]
            event.save(update_fields=["outcome", "note"])
            log.error("webhook could not be applied: %s", exc)
            return Response(
                {"detail": "gateway mapping not configured"},
                status=status.HTTP_501_NOT_IMPLEMENTED,
            )

        event.transaction = transaction_row
        event.save(update_fields=["transaction"])
        log.info(
            "webhook processed: transaction=%s status=%s code_issued=%s",
            transaction_row.pk,
            transaction_row.status,
            bool(code),
        )
        return Response({"detail": "ok"}, status=status.HTTP_200_OK)

    @staticmethod
    def _record(*, event_id: str, digest: str, signature_valid: bool, outcome: str,
                note: str = "") -> None:
        """Record a refusal. Uses get_or_create so a replayed bad event is not an
        integrity error on top of an already-refused one."""
        WebhookEvent.objects.get_or_create(
            event_id=event_id,
            defaults={
                "payload_sha256": digest,
                "signature_valid": signature_valid,
                "outcome": outcome,
                "note": note[:200],
            },
        )

    @transaction.atomic
    def _apply(self, payload: dict) -> tuple[Transaction, ActivationCode | None]:
        """Record the transaction and, if paid, issue an activation code.

        Field names come from the payload and are therefore Chargily-specific;
        they are read defensively so that a missing field fails loudly rather than
        producing a half-built transaction.
        """
        gateway_status = str(payload.get("status", ""))
        our_status = chargily.map_status(gateway_status)

        plan = str(payload.get("metadata", {}).get("plan", ""))
        if plan not in PlanCode.values or plan == PlanCode.TRIAL:
            raise chargily.ChargilyNotConfigured(
                f"webhook carried plan {plan!r}; the checkout must set a paid plan "
                "in its metadata"
            )

        row, _ = Transaction.objects.update_or_create(
            gateway_payment_id=str(payload.get("id") or "") or None,
            defaults={
                "gateway": "chargily",
                "gateway_checkout_id": str(payload.get("checkout_id", "")),
                "amount_dzd": int(payload.get("amount") or PLAN_PRICE_DZD[plan]),
                "status": our_status,
                "plan": plan,
            },
        )

        if our_status != TransactionStatus.PAID:
            return row, None

        if row.paid_at is None:
            row.paid_at = timezone.now()
            row.save(update_fields=["paid_at"])

        # Art. 7.3 step 4 — one code per paid transaction, and only one.
        code = row.activation_codes.first()
        if code is None:
            code = ActivationCode.objects.create(transaction=row, plan=plan)
        return row, code
