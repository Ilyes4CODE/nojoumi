"""A forged webhook must not be able to lock a real payment out.

Found on 2026-08-28 while running the first end-to-end payment test: replaying a
deliberately bad signature and then the genuine event produced
`{"detail": "duplicate ignored"}` on the **genuine** one, and no activation code.

The mechanism: every inbound webhook is recorded, refusals included, and
`event_id` carried a plain `unique=True`. So the rejected request consumed the
idempotency key, and Chargily's real delivery of that same event collided with it
and was discarded.

What that costs, in the contract's terms: the parent pays 1.000 DZD, Article 7.3
step 4 never issues a code, and the audit trail says "duplicate" — the one word
that sends whoever investigates to the wrong conclusion. It needs no access and no
secret: the webhook URL is public by construction and the event id is guessable
from a checkout id.
"""

import hashlib
import hmac
import json

from django.test import TestCase, override_settings
from django.urls import reverse

from apps.payments.models import Transaction, TransactionStatus, WebhookEvent
from apps.subscriptions.models import ActivationCode

SECRET = "test_sk_for_tests_only"


def envelope(checkout_id: str = "chk_1", status: str = "paid") -> bytes:
    return json.dumps(
        {
            "id": f"evt_{checkout_id}",
            "entity": "event",
            "livemode": False,
            "type": "checkout.paid",
            "data": {
                "id": checkout_id,
                "entity": "checkout",
                "amount": 1000,
                "currency": "dzd",
                "status": status,
                "metadata": [{"plan": "monthly"}],
            },
        }
    ).encode("utf-8")


def sign(body: bytes) -> str:
    return hmac.new(SECRET.encode("utf-8"), body, hashlib.sha256).hexdigest()


@override_settings(CHARGILY_SECRET_KEY=SECRET, CHARGILY_LIVE_MODE=False)
class ForgedWebhookDoesNotLockOutTheRealOne(TestCase):
    def setUp(self):
        self.url = reverse("payments:chargily-webhook")

    def test_a_refused_delivery_does_not_consume_the_event_id(self):
        body = envelope()

        forged = self.client.post(
            self.url,
            data=body,
            content_type="application/json",
            headers={"signature": "0" * 64},
        )
        self.assertEqual(forged.status_code, 400)

        genuine = self.client.post(
            self.url,
            data=body,
            content_type="application/json",
            headers={"signature": sign(body)},
        )

        self.assertEqual(genuine.status_code, 200)
        self.assertNotIn("duplicate", genuine.json().get("detail", ""))

        # The money reached us and the parent must be able to use it.
        self.assertEqual(
            Transaction.objects.filter(status=TransactionStatus.PAID).count(), 1
        )
        self.assertEqual(ActivationCode.objects.count(), 1)

    def test_the_refusal_is_still_recorded(self):
        # The audit row is the point of recording refusals at all (Art. 7.3), and
        # the fix must not have bought correctness by dropping it.
        body = envelope()
        self.client.post(
            self.url,
            data=body,
            content_type="application/json",
            headers={"signature": "0" * 64},
        )
        self.assertEqual(
            WebhookEvent.objects.filter(
                outcome=WebhookEvent.Outcome.BAD_SIGNATURE
            ).count(),
            1,
        )

    def test_a_genuine_replay_is_still_ignored(self):
        # The property the constraint existed for in the first place. Chargily
        # retries, and a retry must never issue a second activation code.
        body = envelope()
        headers = {"signature": sign(body)}

        first = self.client.post(
            self.url, data=body, content_type="application/json", headers=headers
        )
        second = self.client.post(
            self.url, data=body, content_type="application/json", headers=headers
        )

        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.status_code, 200)
        self.assertIn("duplicate", second.json()["detail"])
        self.assertEqual(ActivationCode.objects.count(), 1)

    def test_many_forgeries_still_leave_the_real_one_free(self):
        body = envelope()
        for _ in range(5):
            self.client.post(
                self.url,
                data=body,
                content_type="application/json",
                headers={"signature": "1" * 64},
            )

        genuine = self.client.post(
            self.url,
            data=body,
            content_type="application/json",
            headers={"signature": sign(body)},
        )
        self.assertEqual(genuine.status_code, 200)
        self.assertEqual(ActivationCode.objects.count(), 1)
