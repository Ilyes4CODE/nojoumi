"""The three plans and the five states of Article 7.

Held as code, not as database rows, on purpose. They are contract-fixed: Art. 7.1
names three plans with exact durations and prices, and Art. 7.6 names exactly
five states. A table would let them drift out of step with the Dart enums in
`packages/lunio_subscription`, and a drift between server and app in *this*
particular area is a billing dispute.

Art. 7.2 also means the prices are never shown by the Android app — they exist
here only to stamp a transaction record.
"""

from __future__ import annotations

from django.db import models


class PlanCode(models.TextChoices):
    TRIAL = "trial", "تجريبية"
    MONTHLY = "monthly", "شهرية"
    ANNUAL = "annual", "سنوية"


class SubscriptionState(models.TextChoices):
    """Art. 7.6 — "تجريبي، فعّال، مهلة سماح، منتهٍ، مسترجع"."""

    TRIAL = "trial", "تجريبي"
    ACTIVE = "active", "فعّال"
    GRACE = "grace", "مهلة سماح"
    EXPIRED = "expired", "منتهٍ"
    REFUNDED = "refunded", "مسترجع"


# Duration in days, exactly as Art. 7.1 states them.
PLAN_DAYS: dict[str, int] = {
    PlanCode.TRIAL: 7,
    PlanCode.MONTHLY: 30,
    PlanCode.ANNUAL: 365,
}

# Price in DZD.
#
# **These are not the contract's numbers.** Article 7.1 sets 1000 and 10000; the
# client halved both on 2026-09-20 (D-94). Recorded here rather than only in the
# decision log, because the next person to read this file will otherwise check it
# against the contract and think it is a bug.
#
# One constant, read by the checkout endpoint, the payment page and the
# transaction record alike. The amount is never taken from a request — an amount
# that arrives over the wire is an amount somebody can edit.
PLAN_PRICE_DZD: dict[str, int] = {
    PlanCode.TRIAL: 0,
    PlanCode.MONTHLY: 500,
    PlanCode.ANNUAL: 5000,
}

# Art. 7.4 — "مهلة سماح ثلاثة أيام".
GRACE_DAYS = 3

# Art. 7.6 — the offline window the signed local copy is good for.
OFFLINE_WINDOW_DAYS = 7

# Art. 7.4 — "قبل 7 أيام ثم قبل يومين".
REMINDER_DAYS_BEFORE = (7, 2)
