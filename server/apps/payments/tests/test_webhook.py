"""Article 7.3 and 7.7 on the payment surface.

Two obligations are tested here, and both are the kind that only show up when
abused:

    7.3 — "يتحقّق الخادم من صحة توقيع الإشعار ويرفض أي إشعار غير موقّع أو مكرّر
           (idempotency)."
    7.7 — the server stores only transaction id, amount, status, timestamps.

**These tests sign for real.** `verify_signature` is no longer mocked: each
request carries an HMAC-SHA256 of its own raw body, computed exactly as the
Chargily documentation specifies (verified 2026-08-18, see decisions.md D-35).
That matters, because a mocked signature check proves the plumbing and nothing
about the one line that stands between this endpoint and a free subscription.

The payload shape is the documented envelope —
`{id, entity, livemode, type, data, created_at, updated_at}` — with the checkout
in `data`. An earlier draft read the status from the root and would have found
nothing.
"""

from __future__ import annotations

import hashlib
import hmac
import json

from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.payments import chargily
from apps.payments.models import Transaction, TransactionStatus, WebhookEvent
from apps.subscriptions.models import ActivationCode
from apps.subscriptions.plans import PlanCode

URL = "/api/payments/webhook/chargily/"

# Never a real key, and deliberately not the one in .env: a test that depends on
# deployment configuration fails on someone else's machine for the wrong reason.
TEST_SECRET = "test_sk_unit_tests_only_not_a_real_key"


def envelope(
    *,
    event_id: str = "evt_01hjjjzf7wbc454te45mwx35fe",
    checkout_id: str = "chk_01hjjjzf7wbc454te45mwx35fe",
    plan: str = PlanCode.MONTHLY,
    status: str = "paid",
    event_type: str | None = None,
    amount: int = 1000,
) -> bytes:
    """One webhook body in the documented shape."""
    return json.dumps(
        {
            "id": event_id,
            "entity": "event",
            "livemode": False,
            "type": event_type or f"checkout.{status}",
            "data": {
                "id": checkout_id,
                "entity": "checkout",
                "amount": amount,
                "currency": "dzd",
                "status": status,
                "metadata": {"plan": plan},
            },
            "created_at": 1773133200,
            "updated_at": 1773133200,
        }
    ).encode("utf-8")


def sign(raw_body: bytes, secret: str = TEST_SECRET) -> str:
    """The signature exactly as Chargily documents it: HMAC-SHA256, hex."""
    return hmac.new(secret.encode("utf-8"), raw_body, hashlib.sha256).hexdigest()


@override_settings(CHARGILY_SECRET_KEY=TEST_SECRET)
class SignatureTests(TestCase):
    """The signature is the authentication. Every one of these is an open door."""

    def setUp(self):
        self.client = APIClient()

    def post(self, body: bytes, signature: str | None = None):
        headers = {} if signature is None else {"HTTP_SIGNATURE": signature}
        return self.client.post(
            URL, data=body, content_type="application/json", **headers
        )

    def test_a_correctly_signed_webhook_is_accepted(self):
        body = envelope()
        response = self.post(body, sign(body))

        self.assertEqual(response.status_code, 200)
        self.assertTrue(WebhookEvent.objects.get().signature_valid)

    def test_a_webhook_with_no_signature_header_is_rejected(self):
        response = self.post(envelope())

        self.assertEqual(response.status_code, 400)
        self.assertEqual(Transaction.objects.count(), 0)
        self.assertEqual(ActivationCode.objects.count(), 0)

    def test_a_wrong_signature_is_rejected(self):
        response = self.post(envelope(), "0" * 64)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(ActivationCode.objects.count(), 0)

    def test_a_signature_from_a_different_secret_is_rejected(self):
        body = envelope()
        response = self.post(body, sign(body, "someone_elses_secret"))

        self.assertEqual(response.status_code, 400)

    def test_tampering_with_the_body_invalidates_the_signature(self):
        """The point of signing the body rather than an id."""
        original = envelope(amount=1000)
        signature = sign(original)
        tampered = envelope(amount=1)

        response = self.post(tampered, signature)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(Transaction.objects.count(), 0)

    def test_with_no_secret_configured_everything_is_refused(self):
        """A deployment that forgot the key must reject, never accept."""
        body = envelope()
        with override_settings(CHARGILY_SECRET_KEY=""):
            response = self.post(body, sign(body))

        self.assertEqual(response.status_code, 400)

    def test_the_refusal_is_recorded_so_it_can_be_explained_later(self):
        self.post(envelope())

        event = WebhookEvent.objects.get()
        self.assertFalse(event.signature_valid)
        self.assertEqual(event.outcome, WebhookEvent.Outcome.BAD_SIGNATURE)
        self.assertEqual(len(event.payload_sha256), 64)

    def test_the_raw_body_is_never_stored_only_its_hash(self):
        """Art. 7.7 — a webhook body carries data we have no reason to keep."""
        self.post(envelope())
        event = WebhookEvent.objects.get()

        for field in event._meta.get_fields():
            value = getattr(event, getattr(field, "name", ""), None)
            if isinstance(value, str):
                self.assertNotIn("chk_01hjjjzf", value)
                self.assertNotIn("metadata", value)


@override_settings(CHARGILY_SECRET_KEY=TEST_SECRET)
class VerifiedWebhookTests(TestCase):
    """With a valid signature, the rest of Article 7.3 must hold."""

    def setUp(self):
        self.client = APIClient()

    def post(self, body: bytes):
        return self.client.post(
            URL,
            data=body,
            content_type="application/json",
            HTTP_SIGNATURE=sign(body),
        )

    def test_a_paid_webhook_creates_a_transaction_and_one_activation_code(self):
        response = self.post(envelope())

        self.assertEqual(response.status_code, 200)
        txn = Transaction.objects.get()
        self.assertEqual(txn.status, TransactionStatus.PAID)
        self.assertEqual(txn.amount_dzd, 1000)
        self.assertEqual(txn.plan, PlanCode.MONTHLY)
        self.assertIsNotNone(txn.paid_at)
        self.assertEqual(txn.activation_codes.count(), 1)

    def test_a_replayed_webhook_is_rejected_and_issues_no_second_code(self):
        """The core idempotency assertion of Art. 7.3."""
        body = envelope()
        first = self.post(body)
        second = self.post(body)

        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.status_code, 200, "a gateway retry is not an error")
        self.assertIn("duplicate", second.json()["detail"])

        self.assertEqual(Transaction.objects.count(), 1)
        self.assertEqual(
            ActivationCode.objects.count(), 1, "a replay must not mint a second code"
        )
        self.assertEqual(
            WebhookEvent.objects.get().outcome, WebhookEvent.Outcome.DUPLICATE
        )

    def test_replaying_ten_times_still_yields_one_code(self):
        body = envelope()
        for _i in range(10):
            self.post(body)

        self.assertEqual(Transaction.objects.count(), 1)
        self.assertEqual(ActivationCode.objects.count(), 1)

    def test_idempotency_keys_on_the_event_id_not_the_checkout(self):
        """A checkout can legitimately produce more than one event.

        `checkout.pending` then `checkout.paid` are two different events about
        the same checkout, and the second must be applied. Deduplicating on the
        checkout id would silently drop the payment.
        """
        self.post(envelope(event_id="evt_1", status="pending"))
        self.post(envelope(event_id="evt_2", status="paid"))

        self.assertEqual(Transaction.objects.count(), 1, "one checkout, one row")
        self.assertEqual(Transaction.objects.get().status, TransactionStatus.PAID)
        self.assertEqual(ActivationCode.objects.count(), 1)

    def test_a_failed_payment_creates_no_activation_code(self):
        response = self.post(envelope(status="failed"))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(Transaction.objects.get().status, TransactionStatus.FAILED)
        self.assertEqual(ActivationCode.objects.count(), 0)

    def test_a_canceled_payment_creates_no_activation_code(self):
        response = self.post(envelope(status="canceled"))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(Transaction.objects.get().status, TransactionStatus.CANCELED)
        self.assertEqual(ActivationCode.objects.count(), 0)

    def test_processing_is_treated_as_pending_not_as_paid(self):
        """Money in flight is not money received."""
        response = self.post(envelope(status="processing"))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(Transaction.objects.get().status, TransactionStatus.PENDING)
        self.assertEqual(
            ActivationCode.objects.count(),
            0,
            "a subscription must not activate on a payment that may still fail",
        )

    def test_an_unmapped_status_refuses_rather_than_guessing(self):
        """Mapping an unknown status to PAID would grant an unpaid subscription."""
        response = self.post(envelope(status="something_new"))

        self.assertEqual(response.status_code, 501)
        self.assertEqual(ActivationCode.objects.count(), 0)
        self.assertEqual(WebhookEvent.objects.get().outcome, WebhookEvent.Outcome.ERROR)

    def test_an_event_that_is_not_about_a_checkout_is_refused(self):
        """The documented event list is not claimed to be exhaustive."""
        response = self.post(envelope(event_type="customer.created"))

        self.assertEqual(response.status_code, 501)
        self.assertEqual(Transaction.objects.count(), 0)

    def test_a_payload_without_the_data_envelope_is_refused(self):
        body = json.dumps({"id": "evt_x", "type": "checkout.paid"}).encode("utf-8")
        response = self.client.post(
            URL, data=body, content_type="application/json", HTTP_SIGNATURE=sign(body)
        )

        self.assertEqual(response.status_code, 501)
        self.assertEqual(Transaction.objects.count(), 0)

    def test_a_trial_plan_in_a_webhook_is_refused(self):
        """The trial is granted by the device flow, never bought."""
        response = self.post(envelope(plan=PlanCode.TRIAL))

        self.assertEqual(response.status_code, 501)
        self.assertEqual(ActivationCode.objects.count(), 0)

    def test_a_webhook_with_no_plan_metadata_is_refused(self):
        body = json.dumps(
            {
                "id": "evt_no_plan",
                "type": "checkout.paid",
                "data": {"id": "chk_1", "amount": 1000, "status": "paid"},
            }
        ).encode("utf-8")
        response = self.client.post(
            URL, data=body, content_type="application/json", HTTP_SIGNATURE=sign(body)
        )

        self.assertEqual(response.status_code, 501)
        self.assertEqual(ActivationCode.objects.count(), 0)

    def test_metadata_as_a_list_is_also_accepted(self):
        """The API reference calls `metadata` an array; examples show an object."""
        body = json.dumps(
            {
                "id": "evt_list_meta",
                "type": "checkout.paid",
                "data": {
                    "id": "chk_list",
                    "amount": 1000,
                    "status": "paid",
                    "metadata": [{"plan": PlanCode.ANNUAL}],
                },
            }
        ).encode("utf-8")
        response = self.client.post(
            URL, data=body, content_type="application/json", HTTP_SIGNATURE=sign(body)
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(Transaction.objects.get().plan, PlanCode.ANNUAL)

    def test_a_non_json_body_is_refused_after_the_event_is_recorded(self):
        body = b"not json at all"
        response = self.client.post(
            URL, data=body, content_type="application/json", HTTP_SIGNATURE=sign(body)
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(WebhookEvent.objects.get().outcome, WebhookEvent.Outcome.ERROR)

    def test_two_distinct_payments_both_go_through(self):
        self.post(envelope(event_id="evt_1", checkout_id="chk_1"))
        self.post(envelope(event_id="evt_2", checkout_id="chk_2"))

        self.assertEqual(Transaction.objects.count(), 2)
        self.assertEqual(ActivationCode.objects.count(), 2)


class StatusMapTests(TestCase):
    """The mapping is the place a wrong guess costs money."""

    def test_the_map_covers_exactly_the_documented_statuses(self):
        self.assertEqual(
            set(chargily.STATUS_MAP),
            {"pending", "processing", "paid", "failed", "canceled"},
            "verified 2026-08-18 from the checkout-object reference; adding to "
            "this set requires re-reading the documentation, not guessing",
        )

    def test_only_paid_maps_to_paid(self):
        paid = [k for k, v in chargily.STATUS_MAP.items() if v == TransactionStatus.PAID]
        self.assertEqual(paid, ["paid"])

    def test_an_unknown_status_raises_rather_than_defaulting(self):
        with self.assertRaises(chargily.ChargilyNotConfigured):
            chargily.map_status("refunded_by_bank_next_year")


class BaseUrlTests(TestCase):
    """Test and live must never be inferred from a key prefix."""

    @override_settings(CHARGILY_BASE_URL="", CHARGILY_LIVE_MODE=False)
    def test_test_mode_uses_the_test_endpoint(self):
        self.assertEqual(chargily.base_url(), chargily.TEST_BASE_URL)
        self.assertIn("/test/", chargily.base_url())

    @override_settings(CHARGILY_BASE_URL="", CHARGILY_LIVE_MODE=True)
    def test_live_mode_uses_the_live_endpoint(self):
        self.assertEqual(chargily.base_url(), chargily.LIVE_BASE_URL)
        self.assertNotIn("/test/", chargily.base_url())

    @override_settings(CHARGILY_BASE_URL="https://example.test/api/v2/")
    def test_an_explicit_override_wins_and_loses_its_trailing_slash(self):
        self.assertEqual(chargily.base_url(), "https://example.test/api/v2")


class TransactionShapeTests(TestCase):
    """Art. 7.7 — four kinds of field, and no more."""

    def test_the_transaction_model_holds_only_what_the_contract_permits(self):
        permitted = {
            # "معرّف العملية"
            "id", "gateway", "gateway_checkout_id", "gateway_payment_id",
            # "المبلغ"
            "amount_dzd", "currency",
            # "حالتها"
            "status",
            # "وتاريخها"
            "created_at", "updated_at", "paid_at",
            # the plan it was for, and who it belongs to
            "plan", "parent",
            # reverse relations
            "subscriptions", "activation_codes", "webhook_events",
        }
        actual = {f.name for f in Transaction._meta.get_fields()}

        self.assertEqual(
            actual - permitted,
            set(),
            "Article 7.7 permits only transaction id, amount, status and "
            "timestamps. New fields here need a contract reading, not a review.",
        )
