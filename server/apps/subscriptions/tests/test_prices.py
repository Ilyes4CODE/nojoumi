"""The two prices, pinned as literals in exactly one place.

**Why this file exists.** Every other test reads `PLAN_PRICE_DZD` rather than a
number, which is right — their claim is "the checkout uses the constant", not
"the checkout charges one thousand" — but it leaves the constant itself
unguarded. A stray edit to `plans.py` would then pass the whole suite and start
charging parents a different amount, and the first person to notice would be a
customer or the client's accountant.

So the literals live here, once, where changing them is obviously a decision.
If this test fails, either somebody mistyped a price or the price genuinely
changed; in the second case update the numbers **and** the decision log, because
a price is a term of the contract rather than a configuration value.
"""

from __future__ import annotations

from django.test import SimpleTestCase

from apps.subscriptions.plans import PLAN_DAYS, PLAN_PRICE_DZD, PlanCode


class ThePricesAreWhatWeAgreed(SimpleTestCase):
    def test_the_monthly_plan_costs_five_hundred_dinars(self):
        # Article 7.1 says 1000. The client halved it on 2026-09-20 — D-94.
        self.assertEqual(PLAN_PRICE_DZD[PlanCode.MONTHLY], 500)

    def test_the_annual_plan_costs_five_thousand_dinars(self):
        # Article 7.1 says 10000. Halved with the monthly one — D-94.
        self.assertEqual(PLAN_PRICE_DZD[PlanCode.ANNUAL], 5000)

    def test_the_trial_is_free(self):
        # Not a price the client can change: Article 7.1 makes the trial free,
        # and a trial that costs anything is a different product.
        self.assertEqual(PLAN_PRICE_DZD[PlanCode.TRIAL], 0)

    def test_the_annual_plan_is_worth_buying(self):
        # Ten months for twelve. If an edit ever made the year cost more than
        # twelve months of the monthly plan, the page would be offering a
        # discount that is not one.
        self.assertLess(
            PLAN_PRICE_DZD[PlanCode.ANNUAL],
            PLAN_PRICE_DZD[PlanCode.MONTHLY] * 12,
        )

    def test_the_durations_are_still_the_contract_durations(self):
        # These the client has not touched, and they are what the price buys.
        self.assertEqual(PLAN_DAYS[PlanCode.TRIAL], 7)
        self.assertEqual(PLAN_DAYS[PlanCode.MONTHLY], 30)
        self.assertEqual(PLAN_DAYS[PlanCode.ANNUAL], 365)
