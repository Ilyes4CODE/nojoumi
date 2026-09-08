"""Request and response shapes for starting a payment.

Article 7.2 decides who these are for: **the independent web page, never the
Android app.** The app shows no price, no buy button and no payment link, which
is what keeps it clear of Google Play's billing policy. Nothing in `app/` may
call the endpoint these serve.
"""

from __future__ import annotations

from rest_framework import serializers

from apps.subscriptions.plans import PLAN_PRICE_DZD, PlanCode


class CheckoutRequestSerializer(serializers.Serializer):
    """Everything the payment page may choose. Which is: the plan, and nothing else.

    The amount is **not** accepted from the client. It is looked up from
    `PLAN_PRICE_DZD`, because an amount that arrives over the wire is an amount
    somebody can change, and Article 7.1 fixes the two prices.
    """

    plan = serializers.ChoiceField(
        choices=[PlanCode.MONTHLY, PlanCode.ANNUAL],
        help_text="Paid plans only — the trial is granted by the app, not bought.",
    )

    def validate_plan(self, value: str) -> str:
        if PLAN_PRICE_DZD.get(value, 0) <= 0:
            raise serializers.ValidationError("this plan has no price")
        return value


class CheckoutResponseSerializer(serializers.Serializer):
    """What the page needs to send the parent to Chargily.

    Deliberately three fields. The gateway returns far more, and none of the rest
    is ours to keep (Art. 7.7).
    """

    checkout_url = serializers.URLField()
    checkout_id = serializers.CharField()
    amount_dzd = serializers.IntegerField()
