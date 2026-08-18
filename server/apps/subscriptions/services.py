"""Subscription operations. All of Article 7's behaviour lives here.

Kept out of the views so the rules are testable without HTTP, and so the same
functions can be driven by the webhook, by the admin, and by a management command.
"""

from __future__ import annotations

from datetime import timedelta

from django.db import transaction
from django.utils import timezone

from apps.common.signing import public_key_hex, sign_payload
from apps.devices.models import Install

from .models import ActivationCode, Subscription
from .plans import (
    GRACE_DAYS,
    OFFLINE_WINDOW_DAYS,
    PLAN_DAYS,
    REMINDER_DAYS_BEFORE,
    PlanCode,
    SubscriptionState,
)

# Payload format version. Bump this rather than editing `canonical_bytes`, so
# already-installed apps keep verifying the format they were built against.
SNAPSHOT_VERSION = 1


class SubscriptionError(Exception):
    """A refusal the caller may show to the parent verbatim."""


class TrialAlreadyUsed(SubscriptionError):
    pass


class CodeInvalid(SubscriptionError):
    pass


class CodeAlreadyUsed(SubscriptionError):
    pass


def _ms(dt) -> int:
    return int(dt.timestamp() * 1000)


def current_subscription(parent) -> Subscription | None:
    """The subscription that decides this parent's state.

    The one with the furthest `ends_at`, because a renewal extends rather than
    replaces (Art. 7.4) and a refund must not be hidden by an older row.
    """
    refunded = parent.subscriptions.filter(refunded_at__isnull=False).first()
    if refunded:
        return refunded
    return parent.subscriptions.order_by("-ends_at").first()


@transaction.atomic
def start_trial(*, parent, install: Install, now=None) -> Subscription:
    """Art. 7.1 — 7 days, all features, **once per device**.

    The lock matters: two launches racing at first start must not both be granted
    a trial. The check is on the *device*, not the account, which is what the
    contract says — otherwise a new email address resets the trial.
    """
    now = now or timezone.now()

    locked = Install.objects.select_for_update().get(pk=install.pk)
    if locked.trial_consumed_at is not None:
        raise TrialAlreadyUsed(
            "التجربة المجانية استُعملت مرة واحدة على هذا الجهاز."
        )

    subscription = Subscription.objects.create(
        parent=parent,
        plan=PlanCode.TRIAL,
        state=SubscriptionState.TRIAL,
        started_at=now,
        ends_at=now + timedelta(days=PLAN_DAYS[PlanCode.TRIAL]),
    )

    locked.trial_consumed_at = now
    if locked.parent_id is None:
        locked.parent = parent
    locked.save(update_fields=["trial_consumed_at", "parent", "last_seen_at"])

    return subscription


@transaction.atomic
def activate(*, code: str, parent, install: Install | None = None, now=None) -> Subscription:
    """Art. 7.3 step 5 — the parent enters the code once and the account unlocks.

    Single use is enforced with a row lock, not with a read-then-write: two
    devices submitting the same code simultaneously must produce one activation
    and one clear refusal.
    """
    now = now or timezone.now()
    normalised = (code or "").strip().upper()
    if not normalised:
        raise CodeInvalid("أدخل رمز التفعيل.")

    try:
        row = ActivationCode.objects.select_for_update().get(code=normalised)
    except ActivationCode.DoesNotExist as exc:
        raise CodeInvalid("رمز التفعيل غير صحيح.") from exc

    if row.consumed_at is not None:
        raise CodeAlreadyUsed("هذا الرمز مستعمل من قبل.")

    existing = parent.subscriptions.order_by("-ends_at").first()
    if existing and existing.refunded_at is None and existing.ends_at > now:
        # Art. 7.4 — renewal adds to the remainder.
        existing.extend(row.plan, now=now)
        subscription = existing
    else:
        subscription = Subscription.objects.create(
            parent=parent,
            plan=row.plan,
            state=SubscriptionState.ACTIVE,
            started_at=now,
            ends_at=now + timedelta(days=PLAN_DAYS[row.plan]),
            created_from_transaction=row.transaction,
        )

    row.consumed_at = now
    row.consumed_by_parent = parent
    row.consumed_by_install = install
    row.save(
        update_fields=["consumed_at", "consumed_by_parent", "consumed_by_install"]
    )
    return subscription


def mark_refunded(subscription: Subscription, now=None) -> Subscription:
    """Art. 7.5 — the client marks it and it stops immediately on the device."""
    now = now or timezone.now()
    subscription.refunded_at = now
    subscription.state = SubscriptionState.REFUNDED
    subscription.save(update_fields=["refunded_at", "state", "updated_at"])
    return subscription


def days_until(dt, now) -> int:
    return (dt - now).days


def due_reminder(subscription: Subscription, now=None) -> int | None:
    """Art. 7.4 — 7 days then 2 days before expiry. Returns which one is due."""
    now = now or timezone.now()
    if subscription.refunded_at or now >= subscription.ends_at:
        return None
    left = subscription.ends_at - now
    for days in sorted(REMINDER_DAYS_BEFORE):
        if left <= timedelta(days=days):
            return days
    return None


def build_snapshot(*, parent, now=None) -> dict:
    """The signed payload the device caches for up to 7 days (Art. 7.6).

    `parent_id` is included so a snapshot cannot be lifted from one account's
    device and replayed on another's. The app checks it against the account it is
    logged in as.
    """
    now = now or timezone.now()
    subscription = current_subscription(parent)

    if subscription is None:
        payload = {
            "version": SNAPSHOT_VERSION,
            "parent_id": parent.id,
            "state": SubscriptionState.EXPIRED,
            "plan": "",
            "started_at_ms": 0,
            "ends_at_ms": 0,
            "grace_ends_at_ms": 0,
            "issued_at_ms": _ms(now),
        }
    else:
        payload = {
            "version": SNAPSHOT_VERSION,
            "parent_id": parent.id,
            "state": subscription.effective_state(now),
            "plan": subscription.plan,
            "started_at_ms": _ms(subscription.started_at),
            "ends_at_ms": _ms(subscription.ends_at),
            "grace_ends_at_ms": _ms(subscription.grace_ends_at),
            "issued_at_ms": _ms(now),
        }

    return {
        "payload": payload,
        "signature": sign_payload(payload),
        "public_key": public_key_hex(),
        "offline_window_days": OFFLINE_WINDOW_DAYS,
        "grace_days": GRACE_DAYS,
        "revalidate_after_hours": 24,
        # Art. 7.1 — spelled out in the response so the app never has to infer it.
        "capabilities": {
            "can_generate_new_lessons": (
                payload["state"]
                in (
                    SubscriptionState.TRIAL,
                    SubscriptionState.ACTIVE,
                    SubscriptionState.GRACE,
                )
            ),
            "blocking_active": True,
            "stars_active": True,
            "saved_lessons_accessible": True,
        },
    }
