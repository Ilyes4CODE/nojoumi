"""A checkout is never created without a webhook Chargily can reach.

## The first bug, 2026-08-29

Reported as «الدفع لا يعمل». `.env` still held the previous day's cloudflared
address; Chargily **resolves** `webhook_endpoint` and refuses the entire checkout
when the host no longer answers:

    HTTP 422 {"message":"The webhook endpoint field must be a valid URL."}

So a tunnel that closed overnight stopped the parent from paying at all, with an
error naming a field they have never heard of.

## The fix for it was worse, and this file exists to keep it from coming back

The answer then was to retry without the field, on the reasoning that Chargily
would fall back to the endpoint set in its own dashboard, and that a checkout was
better than an error.

On **2026-08-30** that produced five checkouts with no reachable webhook at all —
the dashboard endpoint pointed at the same dead tunnel — every one of them stuck
at «في انتظار تأكيد Chargily» for ever. The transactions table showed five rows
of `pending` and nothing in the logs but one ERROR nobody was watching.

**The two failures are not comparable.** A payment that never starts costs the
parent ten seconds: they see it fail and try again. A payment that starts and can
never be confirmed cannot be recovered by the parent at all, and from where they
are sitting the two look identical. So the refusal is now taken at face value and
raised, **before** a payment exists.

In production `CHARGILY_WEBHOOK_URL` is a real domain and none of this runs. It
exists so that a development mistake cannot look like a working payment.
"""

from __future__ import annotations

from unittest import mock

from django.test import TestCase, override_settings

from apps.payments import chargily


class _Response:
    def __init__(self, status_code, payload=None, text=""):
        self.status_code = status_code
        self._payload = payload or {}
        self.text = text

    def json(self):
        return self._payload


GOOD = {"id": "chk_1", "checkout_url": "https://pay.chargily.net/test/x"}
WEBHOOK_422 = (
    '{"message":"The webhook endpoint field must be a valid URL.",'
    '"errors":{"webhook_endpoint":["The webhook endpoint field must be a valid URL."]}}'
)


@override_settings(CHARGILY_SECRET_KEY="test_sk_x", CHARGILY_LIVE_MODE=False)
class AnUnreachableWebhookStopsTheCheckout(TestCase):
    def _create(self, webhook):
        return chargily.create_checkout(
            amount_dzd=1000,
            plan="monthly",
            success_url="https://example.dz/pay/done/",
            webhook_endpoint=webhook,
        )

    def test_a_rejected_webhook_creates_nothing(self):
        calls = []

        def post(url, **kwargs):
            # A copy: the payload is a live dict, and recording the reference
            # would show the entry in whatever state the call left it.
            calls.append(dict(kwargs["json"]))
            return _Response(422, text=WEBHOOK_422)

        with mock.patch("apps.payments.chargily.requests.post", side_effect=post):
            with self.assertRaises(chargily.ChargilyError):
                self._create("https://dead-tunnel.example/hook/")

        self.assertEqual(
            len(calls),
            1,
            "there must be no second attempt — a checkout without a reachable "
            "webhook can never be confirmed, and creating one strands the "
            "parent's payment with no way back",
        )

    def test_the_parent_is_told_something_they_can_act_on(self):
        # Not «webhook_endpoint field must be a valid URL». The parent has never
        # heard of a webhook, and an error they cannot act on reads as the app
        # being broken rather than as something to try again.
        def post(url, **kwargs):
            return _Response(422, text=WEBHOOK_422)

        with mock.patch("apps.payments.chargily.requests.post", side_effect=post):
            with self.assertRaises(chargily.ChargilyError) as caught:
                self._create("https://dead-tunnel.example/hook/")

        message = str(caught.exception)
        self.assertIn("no payment was started", message)
        self.assertNotIn("webhook_endpoint", message)

    def test_a_good_webhook_is_sent_and_kept(self):
        calls = []

        def post(url, **kwargs):
            calls.append(dict(kwargs["json"]))
            return _Response(200, GOOD)

        with mock.patch("apps.payments.chargily.requests.post", side_effect=post):
            result = self._create("https://live.example.dz/hook/")

        self.assertEqual(result["checkout_url"], GOOD["checkout_url"])
        self.assertEqual(len(calls), 1, "a working webhook must not be retried away")
        self.assertEqual(calls[0]["webhook_endpoint"], "https://live.example.dz/hook/")

    def test_other_refusals_are_unchanged(self):
        # A bad amount, a bad key, a bad currency. These were never retried and
        # must keep surfacing their own message rather than the webhook one.
        calls = []

        def post(url, **kwargs):
            calls.append(dict(kwargs["json"]))
            return _Response(422, text='{"message":"The amount field is required."}')

        with mock.patch("apps.payments.chargily.requests.post", side_effect=post):
            with self.assertRaises(chargily.ChargilyError):
                self._create("https://live.example.dz/hook/")

        self.assertEqual(len(calls), 1)
