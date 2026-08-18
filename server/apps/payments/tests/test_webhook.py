"""Article 7.3 and 7.7 on the payment surface.

Two obligations are tested here, and both are the kind that only show up when
abused:

    7.3 — "يتحقّق الخادم من صحة توقيع الإشعار ويرفض أي إشعار غير موقّع أو مكرّر
           (idempotency)."
    7.7 — the server stores only transaction id, amount, status, timestamps.

Chargily's own specifics are not yet documented (Art. 7.8, client obligation), so
`verify_signature` currently refuses everything. That makes the *refusal* path
fully testable today, and it is the path that matters: an unverified webhook must
never activate a subscription.
"""

from __future__ import annotations

import json
from unittest import mock

from django.test import TestCase
from rest_framework.test import APIClient

from apps.payments import chargily
from apps.payments.models import Transaction, TransactionStatus, WebhookEvent
from apps.subscriptions.models import ActivationCode
from apps.subscriptions.plans import PlanCode

URL = "/api/payments/webhook/chargily/"


def paid_body(payment_id="pay_123", plan=PlanCode.MONTHLY, status="paid") -> bytes:
    return json.dumps(
        {
            "id": payment_id,
            "checkout_id": "chk_123",
            "amount": 1000,
            "status": status,
            "metadata": {"plan": plan},
        }
    ).encode("utf-8")


class SignatureRefusalTests(TestCase):
    """The default posture: reject."""

    def setUp(self):
        self.client = APIClient()

    def test_an_unverified_webhook_is_rejected(self):
        response = self.client.post(URL, data=paid_body(), content_type="application/json")

        self.assertEqual(response.status_code, 400)
        self.assertEqual(Transaction.objects.count(), 0)
        self.assertEqual(ActivationCode.objects.count(), 0)

    def test_the_refusal_is_recorded_so_it_can_be_explained_later(self):
        self.client.post(URL, data=paid_body(), content_type="application/json")

        event = WebhookEvent.objects.get()
        self.assertFalse(event.signature_valid)
        self.assertEqual(event.outcome, WebhookEvent.Outcome.BAD_SIGNATURE)
        self.assertEqual(len(event.payload_sha256), 64)

    def test_the_raw_body_is_never_stored_only_its_hash(self):
        """Art. 7.7 — a webhook body carries payment metadata we must not keep."""
        self.client.post(URL, data=paid_body(), content_type="application/json")
        event = WebhookEvent.objects.get()

        for field in event._meta.get_fields():
            value = getattr(event, getattr(field, "name", ""), None)
            if isinstance(value, str):
                self.assertNotIn("chk_123", value)
                self.assertNotIn("pay_123", value)

    def test_verify_signature_defaults_to_false_and_that_is_deliberate(self):
        self.assertFalse(chargily.verify_signature(b"{}", {}))


@mock.patch("apps.payments.chargily.verify_signature", return_value=True)
class VerifiedWebhookTests(TestCase):
    """With the signature accepted, the rest of Article 7.3 must hold."""

    def setUp(self):
        self.client = APIClient()
        self.status_patch = mock.patch.dict(
            chargily.STATUS_MAP,
            {
                "paid": TransactionStatus.PAID,
                "failed": TransactionStatus.FAILED,
            },
            clear=True,
        )
        self.status_patch.start()
        self.addCleanup(self.status_patch.stop)

    def post(self, body: bytes):
        return self.client.post(URL, data=body, content_type="application/json")

    def test_a_paid_webhook_creates_a_transaction_and_one_activation_code(self, _):
        response = self.post(paid_body())

        self.assertEqual(response.status_code, 200)
        txn = Transaction.objects.get()
        self.assertEqual(txn.status, TransactionStatus.PAID)
        self.assertEqual(txn.amount_dzd, 1000)
        self.assertEqual(txn.plan, PlanCode.MONTHLY)
        self.assertIsNotNone(txn.paid_at)
        self.assertEqual(txn.activation_codes.count(), 1)

    def test_a_replayed_webhook_is_rejected_and_issues_no_second_code(self, _):
        """The core idempotency assertion of Art. 7.3."""
        body = paid_body()
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

    def test_replaying_ten_times_still_yields_one_code(self, _):
        body = paid_body()
        for _i in range(10):
            self.post(body)

        self.assertEqual(Transaction.objects.count(), 1)
        self.assertEqual(ActivationCode.objects.count(), 1)

    def test_a_failed_payment_creates_no_activation_code(self, _):
        response = self.post(paid_body(status="failed"))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            Transaction.objects.get().status, TransactionStatus.FAILED
        )
        self.assertEqual(ActivationCode.objects.count(), 0)

    def test_an_unmapped_status_refuses_rather_than_guessing(self, _):
        """Mapping an unknown status to PAID would grant an unpaid subscription."""
        response = self.post(paid_body(status="something_new"))

        self.assertEqual(response.status_code, 501)
        self.assertEqual(ActivationCode.objects.count(), 0)
        self.assertEqual(
            WebhookEvent.objects.get().outcome, WebhookEvent.Outcome.ERROR
        )

    def test_a_trial_plan_in_a_webhook_is_refused(self, _):
        """The trial is granted by the device flow, never bought."""
        response = self.post(paid_body(plan=PlanCode.TRIAL))

        self.assertEqual(response.status_code, 501)
        self.assertEqual(ActivationCode.objects.count(), 0)

    def test_a_non_json_body_is_refused_after_the_event_is_recorded(self, _):
        response = self.client.post(
            URL, data=b"not json at all", content_type="application/json"
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            WebhookEvent.objects.get().outcome, WebhookEvent.Outcome.ERROR
        )

    def test_two_distinct_payments_both_go_through(self, _):
        self.post(paid_body(payment_id="pay_1"))
        self.post(paid_body(payment_id="pay_2"))

        self.assertEqual(Transaction.objects.count(), 2)
        self.assertEqual(ActivationCode.objects.count(), 2)


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
