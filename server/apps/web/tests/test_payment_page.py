"""The payment page, and the boundary it exists to keep.

Article 7.2 puts every price, buy button and payment link **outside** the Android
app, and the contract says why: it is what keeps Lunio clear of Google Play's
billing policy. This file guards the web half of that line. The app half is
guarded in `app/test/article_7_2_test.dart`.
"""

from __future__ import annotations

import re
from pathlib import Path

from django.test import TestCase
from django.urls import reverse

from apps.subscriptions.plans import PLAN_PRICE_DZD, PlanCode

TEMPLATES = Path(__file__).resolve().parents[1] / "templates" / "web"


class ThePageShowsWhatTheAppMayNot(TestCase):
    def test_the_plans_page_renders(self):
        response = self.client.get(reverse("web:plans"))
        self.assertEqual(response.status_code, 200)

    def test_both_contract_prices_appear(self):
        # This is the one surface in the whole product allowed to show a price,
        # so it had better show the right ones.
        html = self.client.get(reverse("web:plans")).content.decode()
        self.assertIn(str(PLAN_PRICE_DZD[PlanCode.MONTHLY]), html)
        self.assertIn(str(PLAN_PRICE_DZD[PlanCode.ANNUAL]), html)

    def test_the_price_is_never_taken_from_the_request(self):
        # Article 7.1 fixes both prices. An amount that arrives over the wire is
        # an amount somebody can edit, so the form posts a plan code and nothing
        # else; the page must carry no amount field at all.
        html = self.client.get(reverse("web:plans")).content.decode()
        self.assertNotRegex(html, r'name=["\']amount["\']')

    def test_an_unknown_plan_is_refused(self):
        response = self.client.post(reverse("web:checkout"), {"plan": "free-forever"})
        self.assertEqual(response.status_code, 404)


class NoCardDataAnywhere(TestCase):
    """Article 7.7, checked against the markup rather than against intent.

    Card details are entered on Chargily's hosted page and nowhere else. A field
    on our page that could hold one is a contract breach, not a code-review
    comment — so the templates are read and searched.
    """

    FORBIDDEN = re.compile(
        r"card[_-]?number|cardnumber|\bcvv\b|\bcvc\b|expiry|exp[_-]?month|"
        r"exp[_-]?year|autocomplete=[\"']cc-",
        re.IGNORECASE,
    )

    def test_no_template_contains_a_card_shaped_field(self):
        for template in TEMPLATES.glob("*.html"):
            text = template.read_text(encoding="utf-8")
            self.assertIsNone(
                self.FORBIDDEN.search(text),
                msg=f"{template.name} contains a card-shaped field (Art. 7.7)",
            )

    def test_the_rendered_pages_contain_no_password_or_card_inputs(self):
        for url in (reverse("web:plans"), reverse("web:failed")):
            html = self.client.get(url).content.decode()
            self.assertNotIn('type="password"', html)
            self.assertIsNone(self.FORBIDDEN.search(html))


class TheCodeOnlyAppearsAfterASignedWebhook(TestCase):
    """The return redirect is not proof of payment.

    A parent lands on `/pay/done/` because Chargily sent them there — but a query
    string is something anybody can type. Only the signed webhook moves a
    transaction to paid (Art. 7.3), so the status endpoint must refuse to produce
    a code on the strength of the redirect alone.
    """

    def test_an_unknown_checkout_yields_no_code(self):
        response = self.client.get(
            reverse("web:code-status"), {"checkout_id": "not-a-real-id"}
        )
        self.assertEqual(response.json(), {"state": "unknown"})

    def test_a_pending_transaction_yields_no_code(self):
        from apps.payments.models import Transaction, TransactionStatus

        Transaction.objects.create(
            gateway="chargily",
            gateway_checkout_id="chk_pending",
            gateway_payment_id="chk_pending",
            amount_dzd=PLAN_PRICE_DZD[PlanCode.MONTHLY],
            status=TransactionStatus.PENDING,
            plan=PlanCode.MONTHLY,
        )
        response = self.client.get(
            reverse("web:code-status"), {"checkout_id": "chk_pending"}
        )
        self.assertNotIn("code", response.json())


class NothingLeaksIntoThePage(TestCase):
    """Developer prose must not reach the parent.

    On 2026-08-29 the whole header comment of `base.html` rendered as visible
    text at the top of the payment page — a paragraph of English explaining why
    the page must not look like a scam, sitting above the prices, on the one page
    in the product that has to look trustworthy.

    The cause is a Django detail worth knowing: **`{# … #}` is single-line only.**
    It stops at the first newline, so every line after it was ordinary markup. The
    multi-line form is `{% comment %}`, which is also stripped from the response
    rather than shipped as an HTML comment.

    Nothing about it was visible in the template source, in `manage.py check`, or
    in the eight tests that already covered this page — all of which asserted on
    what the page *contains*, never on what it should not.
    """

    URLS = ("web:plans", "web:failed")

    def test_no_template_syntax_survives_into_the_response(self):
        for name in self.URLS:
            html = self.client.get(reverse(name)).content.decode()
            for token in ("{#", "#}", "{%", "%}", "{{", "}}"):
                self.assertNotIn(
                    token,
                    html,
                    msg=f"{name} leaked the template token {token!r}",
                )

    def test_no_developer_prose_reaches_the_parent(self):
        # Phrases from the comments in these templates. If any of them is on
        # screen, a comment is being rendered rather than stripped.
        leaked = (
            "Article 7.2",
            "shape of a scam",
            "payment form",
            "right-to-left, and no framework",
        )
        for name in self.URLS:
            html = self.client.get(reverse(name)).content.decode()
            for phrase in leaked:
                self.assertNotIn(
                    phrase, html, msg=f"{name} is showing a developer comment"
                )

    def test_the_page_opens_with_its_heading(self):
        # The positive half: not merely "no comment", but that the first thing a
        # parent reads is the thing the page is about.
        html = self.client.get(reverse("web:plans")).content.decode()
        body = html.split("<body>", 1)[1]
        heading = body.index("<h1>")
        # Only the logo image may come before it.
        self.assertLess(body.index("<header>"), heading)
        self.assertNotIn("Lunio rather than", body[:heading])
