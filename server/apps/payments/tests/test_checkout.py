"""Creating a payment — Article 7.1, 7.2 and 7.7.

The gateway is never called for real here. What is asserted is the shape of the
request we would send and the boundary we refuse to cross:

  * the **amount comes from the plan**, never from the caller (Art. 7.1 fixes
    1.000 DZD monthly and 10.000 DZD annually);
  * **no card field exists anywhere** in the request, the response or the stored
    row (Art. 7.7);
  * a gateway failure produces a refusal, never a half-made subscription.
"""

from __future__ import annotations

from unittest import mock

from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.payments import chargily
from apps.payments.models import Transaction, TransactionStatus
from apps.subscriptions.plans import PLAN_PRICE_DZD, PlanCode

URL = "/api/payments/checkout/"

CARD_SHAPED = (
    "card", "card_number", "pan", "cvv", "cvc", "expiry", "exp_month",
    "exp_year", "cardholder", "credit", "iban",
)


def gateway_response(checkout_id="chk_1", url="https://pay.chargily.net/x"):
    return {
        "id": checkout_id,
        "entity": "checkout",
        "status": "pending",
        "amount": 1000,
        "currency": "dzd",
        "checkout_url": url,
    }


@override_settings(
    CHARGILY_SECRET_KEY="test_sk_unit_tests_only",
    CHARGILY_SUCCESS_URL="https://example.test/ok",
    CHARGILY_FAILURE_URL="https://example.test/no",
    CHARGILY_WEBHOOK_URL="https://example.test/hook",
)
class CreateCheckoutTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def post(self, **data):
        return self.client.post(URL, data=data, format="json")

    @mock.patch("apps.payments.chargily.create_checkout")
    def test_a_monthly_checkout_uses_the_contract_price(self, create):
        create.return_value = gateway_response()
        response = self.post(plan=PlanCode.MONTHLY)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(create.call_args.kwargs["amount_dzd"], 1000)
        self.assertEqual(response.json()["amount_dzd"], 1000)

    @mock.patch("apps.payments.chargily.create_checkout")
    def test_an_annual_checkout_uses_the_contract_price(self, create):
        create.return_value = gateway_response()
        response = self.post(plan=PlanCode.ANNUAL)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(create.call_args.kwargs["amount_dzd"], 10000)

    @mock.patch("apps.payments.chargily.create_checkout")
    def test_an_amount_supplied_by_the_caller_is_ignored(self, create):
        """An amount that arrives over the wire is an amount somebody can edit."""
        create.return_value = gateway_response()
        response = self.client.post(
            URL, data={"plan": PlanCode.ANNUAL, "amount_dzd": 1}, format="json"
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(create.call_args.kwargs["amount_dzd"], PLAN_PRICE_DZD[PlanCode.ANNUAL])

    def test_the_trial_cannot_be_bought(self):
        """Art. 7.1 — the trial is granted once per device by the app."""
        response = self.post(plan=PlanCode.TRIAL)
        self.assertEqual(response.status_code, 400)

    def test_an_unknown_plan_is_refused(self):
        self.assertEqual(self.post(plan="lifetime").status_code, 400)

    @mock.patch("apps.payments.chargily.create_checkout")
    def test_the_plan_is_stamped_on_the_checkout(self, create):
        """The webhook is all that comes back, so it must carry the plan."""
        create.return_value = gateway_response()
        self.post(plan=PlanCode.MONTHLY)

        self.assertEqual(create.call_args.kwargs["plan"], PlanCode.MONTHLY)

    @mock.patch("apps.payments.chargily.create_checkout")
    def test_a_pending_transaction_is_recorded_immediately(self, create):
        """A payment that starts and never returns must still leave a trace."""
        create.return_value = gateway_response(checkout_id="chk_abc")
        self.post(plan=PlanCode.MONTHLY)

        txn = Transaction.objects.get()
        self.assertEqual(txn.status, TransactionStatus.PENDING)
        self.assertEqual(txn.gateway_checkout_id, "chk_abc")
        self.assertIsNone(txn.paid_at)

    @mock.patch("apps.payments.chargily.create_checkout")
    def test_Article_7_7_no_card_field_reaches_the_gateway(self, create):
        create.return_value = gateway_response()
        self.post(plan=PlanCode.MONTHLY)

        sent = " ".join(f"{k}={v}" for k, v in create.call_args.kwargs.items()).lower()
        for forbidden in CARD_SHAPED:
            self.assertNotIn(
                forbidden,
                sent,
                "Art. 7.7 — the app and the server never touch card data, in any "
                f"form; found {forbidden!r} in the outbound request",
            )

    @mock.patch("apps.payments.chargily.create_checkout")
    def test_Article_7_7_the_response_carries_only_three_fields(self, create):
        create.return_value = gateway_response()
        response = self.post(plan=PlanCode.MONTHLY)

        self.assertEqual(
            set(response.json()),
            {"checkout_url", "checkout_id", "amount_dzd"},
            "the gateway returns far more, and none of the rest is ours to keep",
        )

    @mock.patch("apps.payments.chargily.create_checkout")
    def test_a_gateway_failure_is_a_refusal_not_a_half_made_payment(self, create):
        create.side_effect = chargily.ChargilyError("gateway down")
        response = self.post(plan=PlanCode.MONTHLY)

        self.assertEqual(response.status_code, 502)
        self.assertEqual(Transaction.objects.count(), 0)

    @mock.patch("apps.payments.chargily.create_checkout")
    def test_a_missing_secret_key_is_a_refusal(self, create):
        create.side_effect = chargily.ChargilyNotConfigured("no key")
        response = self.post(plan=PlanCode.MONTHLY)

        self.assertEqual(response.status_code, 502)
        self.assertEqual(Transaction.objects.count(), 0)


class CheckoutRequestShapeTests(TestCase):
    """What `create_checkout` actually sends, without touching the network."""

    @override_settings(
        CHARGILY_SECRET_KEY="test_sk_unit_tests_only",
        CHARGILY_BASE_URL="",
        CHARGILY_LIVE_MODE=False,
        CHARGILY_TIMEOUT_SECONDS=20,
    )
    @mock.patch("apps.payments.chargily.requests.post")
    def test_the_request_matches_the_documented_contract(self, post):
        post.return_value = mock.Mock(
            status_code=200,
            json=mock.Mock(return_value=gateway_response()),
        )

        chargily.create_checkout(
            amount_dzd=1000,
            plan=PlanCode.MONTHLY,
            success_url="https://example.test/ok",
            failure_url="https://example.test/no",
            webhook_endpoint="https://example.test/hook",
        )

        url = post.call_args.args[0]
        headers = post.call_args.kwargs["headers"]
        body = post.call_args.kwargs["json"]

        # Verified 2026-08-18 against dev.chargily.com.
        self.assertEqual(url, f"{chargily.TEST_BASE_URL}/checkouts")
        self.assertEqual(headers["Authorization"], "Bearer test_sk_unit_tests_only")
        self.assertEqual(body["currency"], "dzd")
        self.assertEqual(body["amount"], 1000)
        self.assertEqual(body["metadata"], {"plan": PlanCode.MONTHLY})
        self.assertEqual(body["success_url"], "https://example.test/ok")

    @override_settings(CHARGILY_SECRET_KEY="k", CHARGILY_TIMEOUT_SECONDS=20)
    @mock.patch("apps.payments.chargily.requests.post")
    def test_a_response_without_a_checkout_url_is_an_error(self, post):
        """Handing the parent a broken payment link is worse than failing."""
        post.return_value = mock.Mock(
            status_code=200,
            json=mock.Mock(return_value={"id": "chk_1", "status": "pending"}),
        )

        with self.assertRaises(chargily.ChargilyError):
            chargily.create_checkout(
                amount_dzd=1000, plan=PlanCode.MONTHLY, success_url="https://x.test/ok"
            )

    @override_settings(CHARGILY_SECRET_KEY="", CHARGILY_TIMEOUT_SECONDS=20)
    def test_no_secret_key_refuses_before_any_network_call(self):
        with self.assertRaises(chargily.ChargilyNotConfigured):
            chargily.create_checkout(
                amount_dzd=1000, plan=PlanCode.MONTHLY, success_url="https://x.test/ok"
            )
