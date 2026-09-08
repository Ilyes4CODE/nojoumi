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
from django.conf import settings
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.subscriptions.models import ActivationCode
from apps.subscriptions.plans import PLAN_PRICE_DZD, PlanCode

from . import chargily
from .models import Transaction, TransactionStatus, WebhookEvent
from .serializers import CheckoutRequestSerializer, CheckoutResponseSerializer

log = logging.getLogger("lunio.payments")


class ChargilyWebhookView(APIView):
    """Unauthenticated by necessity — the gateway has no JWT.

    The signature *is* the authentication, so `verify_signature` failing closed
    on a missing header, a missing secret or a mismatch is not defensive
    programming — it is the only thing standing between this endpoint and a free
    subscription for anyone who can POST JSON.
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
            "The signature is HMAC-SHA256 of the raw body, hex-encoded, in "
            "the `signature` header (verified against the current Chargily "
            "documentation on 2026-08-18; see decisions.md D-35).\n\n"
            "Returns 501 when the gateway sends a status outside the documented "
            "set, rather than guessing at it: mapping an unknown status to "
            "`paid` would activate a subscription that was never paid."
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

        The payload shape is the documented envelope — `{id, entity, livemode,
        type, data, created_at, updated_at}` — so the checkout lives in `data`
        and the root `id` is the *event* id, not the payment's. Reading the
        status from the root, as an earlier draft of this file did, would have
        found nothing and mapped an empty string.
        """
        if not chargily.is_checkout_event(payload):
            raise chargily.ChargilyNotConfigured(
                f"event type {payload.get('type')!r} does not concern a checkout"
            )

        checkout = chargily.checkout_of(payload)

        # The decision comes from `data.status`, whose values are documented
        # exhaustively, rather than from the event type, whose list is not.
        our_status = chargily.map_status(str(checkout.get("status", "")))

        plan = chargily.plan_from_metadata(checkout)
        if plan not in PlanCode.values or plan == PlanCode.TRIAL:
            raise chargily.ChargilyNotConfigured(
                f"webhook carried plan {plan!r}; the checkout must set a paid plan "
                "in its metadata"
            )

        row, _ = Transaction.objects.update_or_create(
            gateway_payment_id=str(checkout.get("id") or "") or None,
            defaults={
                "gateway": "chargily",
                "gateway_checkout_id": str(checkout.get("id", "")),
                "amount_dzd": int(checkout.get("amount") or PLAN_PRICE_DZD[plan]),
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


class CreateCheckoutView(APIView):
    """Start a payment. **Called by the web page of Article 7.2, not by the app.**

    This is the boundary Article 7.7 draws: the parent's card details are entered
    exclusively on the `checkout_url` this returns, on Chargily's own page. The
    server never sees a card number, an expiry or a CVV, and there is no field
    anywhere in this codebase that could hold one.

    Unauthenticated, deliberately. A payment may be made before the parent has an
    account, or by a relative paying on their behalf — Article 7.3 links the money
    to the person afterwards, through an activation code the parent types into the
    app once. Requiring a login here would break the flow the contract describes.

    The amount is never taken from the request. It comes from `PLAN_PRICE_DZD`,
    because Article 7.1 fixes the two prices and an amount that arrives over the
    wire is an amount somebody can edit.
    """

    permission_classes = [AllowAny]
    authentication_classes: list = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "checkout"

    @extend_schema(
        request=CheckoutRequestSerializer,
        responses={200: CheckoutResponseSerializer, 502: OpenApiTypes.OBJECT},
        summary="Create a Chargily checkout",
        description=(
            "Returns a hosted `checkout_url` to redirect the parent to. "
            "**The Android app must never call this** (Art. 7.2: no price, no buy "
            "button and no payment link inside the app). It exists for the "
            "independent payment page. "
            "The amount is looked up from the plan, never accepted from the "
            "caller (Art. 7.1 fixes both prices)."
        ),
    )
    def post(self, request):
        serializer = CheckoutRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        plan = serializer.validated_data["plan"]
        amount = PLAN_PRICE_DZD[plan]

        try:
            checkout = chargily.create_checkout(
                amount_dzd=amount,
                plan=plan,
                success_url=settings.CHARGILY_SUCCESS_URL,
                failure_url=settings.CHARGILY_FAILURE_URL,
                webhook_endpoint=settings.CHARGILY_WEBHOOK_URL,
                description=f"Lunio {plan}",
            )
        except (chargily.ChargilyError, chargily.ChargilyNotConfigured) as exc:
            log.error("checkout creation failed: %s", exc)
            return Response(
                {"detail": "could not start the payment"},
                status=status.HTTP_502_BAD_GATEWAY,
            )

        # Recorded immediately, as pending. If the webhook never arrives we still
        # have a row saying a payment was started, which is the difference between
        # investigating a complaint and guessing at it.
        Transaction.objects.update_or_create(
            gateway_payment_id=str(checkout.get("id") or "") or None,
            defaults={
                "gateway": "chargily",
                "gateway_checkout_id": str(checkout.get("id", "")),
                "amount_dzd": amount,
                "status": TransactionStatus.PENDING,
                "plan": plan,
            },
        )
        log.info("checkout created: plan=%s amount=%s", plan, amount)

        return Response(
            CheckoutResponseSerializer(
                {
                    "checkout_url": checkout["checkout_url"],
                    "checkout_id": str(checkout.get("id", "")),
                    "amount_dzd": amount,
                }
            ).data,
            status=status.HTTP_200_OK,
        )
