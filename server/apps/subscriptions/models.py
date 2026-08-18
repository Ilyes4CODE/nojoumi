"""Subscriptions and activation codes.

Article 7.6 makes this app the **single source of truth**: "المرجع الأساسي لحالة
الاشتراك هو الخادم، وليس الجهاز، منعاً للتلاعب." The device gets a signed copy and
may downgrade it as time passes, never upgrade it.

Note what is absent: no card fields, no payment instrument of any kind. Article
7.7 is absolute, and `apps/lessons/tests/test_privacy.py` scans every model in the
project to enforce it.
"""

from __future__ import annotations

import secrets
from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone

from .plans import GRACE_DAYS, PLAN_DAYS, PlanCode, SubscriptionState

# Unambiguous alphabet: no 0/O, no 1/I/L. A parent types this by hand off a web
# page (Art. 7.3), often from a phone screen, sometimes read aloud.
_CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
_CODE_LENGTH = 10


def generate_code() -> str:
    raw = "".join(secrets.choice(_CODE_ALPHABET) for _ in range(_CODE_LENGTH))
    return f"{raw[:5]}-{raw[5:]}"


class Subscription(models.Model):
    """One paid or trial period for one parent."""

    parent = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="subscriptions",
    )
    plan = models.CharField(max_length=16, choices=PlanCode.choices)

    # The server's own record of state. `effective_state()` is what callers want:
    # this field only distinguishes "the client refunded it" from "time passed".
    state = models.CharField(
        max_length=16,
        choices=SubscriptionState.choices,
        default=SubscriptionState.ACTIVE,
    )

    started_at = models.DateTimeField()
    ends_at = models.DateTimeField()

    # Art. 7.5 — the client marks a refund in the admin dashboard and it stops
    # immediately on the parent's device.
    refunded_at = models.DateTimeField(null=True, blank=True)

    created_from_transaction = models.ForeignKey(
        "payments.Transaction",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="subscriptions",
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-ends_at",)
        indexes = [
            models.Index(fields=["parent", "-ends_at"]),
            models.Index(fields=["state"]),
        ]

    def __str__(self) -> str:
        return f"{self.parent_id} {self.plan} until {self.ends_at:%Y-%m-%d}"

    @property
    def grace_ends_at(self):
        return self.ends_at + timedelta(days=GRACE_DAYS)

    def effective_state(self, now=None) -> str:
        """State right now, deriving grace and expiry from the clock.

        Mirrors `SubscriptionMachine.effectiveState` in
        `packages/nojoumi_subscription` deliberately: the app derives the same
        thing offline from the signed snapshot, and the two must never disagree.
        """
        now = now or timezone.now()
        if self.refunded_at or self.state == SubscriptionState.REFUNDED:
            return SubscriptionState.REFUNDED
        if now < self.ends_at:
            return (
                SubscriptionState.TRIAL
                if self.plan == PlanCode.TRIAL
                else SubscriptionState.ACTIVE
            )
        if now < self.grace_ends_at:
            return SubscriptionState.GRACE
        return SubscriptionState.EXPIRED

    def extend(self, plan: str, now=None) -> None:
        """Art. 7.4 — "التجديد قبل انتهاء المدة يضيف المدة الجديدة إلى ما تبقّى".

        Renewing early must not forfeit days already paid for; renewing late must
        not back-date the new period.
        """
        now = now or timezone.now()
        base = self.ends_at if self.ends_at > now else now
        self.ends_at = base + timedelta(days=PLAN_DAYS[plan])
        self.plan = plan
        self.state = SubscriptionState.ACTIVE
        self.save(update_fields=["ends_at", "plan", "state", "updated_at"])


class ActivationCode(models.Model):
    """The code the parent types once, from the external web page (Art. 7.3).

    Single use, enforced in the database by `consumed_at` plus a locked update in
    `services.activate`. Two devices racing on the same code must not both win.
    """

    code = models.CharField(max_length=16, unique=True, default=generate_code)
    plan = models.CharField(max_length=16, choices=PlanCode.choices)

    transaction = models.ForeignKey(
        "payments.Transaction",
        on_delete=models.CASCADE,
        related_name="activation_codes",
    )

    issued_at = models.DateTimeField(auto_now_add=True)
    consumed_at = models.DateTimeField(null=True, blank=True)
    consumed_by_parent = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="activation_codes",
    )
    consumed_by_install = models.ForeignKey(
        "devices.Install",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="activation_codes",
    )

    class Meta:
        indexes = [models.Index(fields=["consumed_at"])]

    def __str__(self) -> str:
        return f"{self.code} ({self.plan})"

    @property
    def is_consumed(self) -> bool:
        return self.consumed_at is not None
