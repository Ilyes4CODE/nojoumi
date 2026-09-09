"""Payment records and webhook events.

Article 7.7, quoted because it admits no interpretation:

    "لا يجمع التطبيق ولا الخادم أي بيانات بطاقة بنكية إطلاقاً — لا رقم بطاقة، ولا
     تاريخ صلاحية، ولا رمز تحقّق. تُدخل هذه البيانات حصرياً على صفحة Chargily
     الآمنة. ما يُخزَّن على الخادم هو فقط: معرّف العملية، والمبلغ، وحالتها،
     وتاريخها."

Four fields. That is the entire permitted schema, and `Transaction` holds exactly
those plus the plan it was for. A pull request that adds a fifth field of card
shape is a contract breach, not a review comment — and the structural test in
`apps/lessons/tests/test_privacy.py` fails the build if one appears.
"""

from __future__ import annotations

from django.conf import settings
from django.db import models

from apps.subscriptions.plans import PlanCode


class TransactionStatus(models.TextChoices):
    """Our own vocabulary, mapped from the gateway's.

    Chargily's exact status strings are **not** written here from memory — that
    mapping lives in `chargily.py` and is filled in from the current
    documentation once the client supplies it (Art. 7.8).
    """

    PENDING = "pending", "قيد الانتظار"
    PAID = "paid", "مدفوعة"
    FAILED = "failed", "فاشلة"
    CANCELED = "canceled", "ملغاة"
    REFUNDED = "refunded", "مسترجعة"


class Transaction(models.Model):
    """One payment attempt. Art. 7.6 also requires a downloadable receipt per one."""

    # "معرّف العملية" — the gateway's identifier, and our idempotency anchor.
    gateway = models.CharField(max_length=32, default="chargily")
    gateway_checkout_id = models.CharField(max_length=128, blank=True, db_index=True)
    gateway_payment_id = models.CharField(
        max_length=128, blank=True, null=True, unique=True
    )

    # "المبلغ" — integer dinars. No fractional currency in DZD retail pricing, and
    # an integer cannot drift.
    amount_dzd = models.PositiveIntegerField()
    currency = models.CharField(max_length=8, default="dzd")

    # "حالتها"
    status = models.CharField(
        max_length=16,
        choices=TransactionStatus.choices,
        default=TransactionStatus.PENDING,
    )

    plan = models.CharField(max_length=16, choices=PlanCode.choices)

    # Nullable: a payment starts on an external web page (Art. 7.2) and may be
    # made before the parent has an account, or by someone paying on their behalf.
    parent = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="transactions",
    )

    # "وتاريخها"
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    paid_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ("-created_at",)
        indexes = [models.Index(fields=["status", "-created_at"])]

    def __str__(self) -> str:
        return f"{self.gateway}:{self.gateway_payment_id or self.gateway_checkout_id}"


class WebhookEvent(models.Model):
    """Every inbound webhook, verified once and never processed twice.

    Article 7.3: "يتحقّق الخادم من صحة توقيع الإشعار ويرفض أي إشعار غير موقّع أو
    مكرّر (idempotency)."

    Storing rejected events too is deliberate: when the client asks why a payment
    did not activate, the answer must be a row, not a theory.
    """

    class Outcome(models.TextChoices):
        PROCESSED = "processed", "تمت المعالجة"
        DUPLICATE = "duplicate", "مكرّر"
        BAD_SIGNATURE = "bad_signature", "توقيع غير صحيح"
        UNKNOWN_EVENT = "unknown_event", "حدث غير معروف"
        ERROR = "error", "خطأ"

    gateway = models.CharField(max_length=32, default="chargily")

    # The gateway's own event id. Unique **only across signature-verified rows**,
    # which is what makes replay impossible without letting a forged request lock
    # a real payment out.
    #
    # A plain `unique=True` was wrong, and wrong in a way that cost money. Every
    # inbound webhook is recorded including the refused ones, so an unsigned
    # request carrying a guessed event id consumed the idempotency key; the
    # genuine delivery of that same event then hit the constraint and was
    # discarded as a duplicate. The parent had paid, no activation code was ever
    # issued, and the audit trail said "duplicate" — the one word that would have
    # sent us looking in the wrong place. Found 2026-08-28 by replaying a forged
    # signature immediately before a valid one.
    #
    # The condition is the whole fix: an unverified request can still be recorded
    # for the audit trail, and can no longer reserve anything.
    event_id = models.CharField(max_length=160, db_index=True)

    # The same id again, but **only for verified rows**, and NULL otherwise.
    #
    # ### Why a second column instead of the conditional constraint below
    #
    # The `UniqueConstraint(condition=...)` in `Meta` is a partial index, and
    # **MariaDB does not have those**. Django says so and carries on:
    #
    #     models.W036 MariaDB does not support unique constraints with
    #     conditions. HINT: A constraint won't be created.
    #
    # Seen on the production deployment, 2026-09-09. The migration reported OK,
    # the table was created, and Article 7.3's idempotency had no enforcement at
    # all — while the view's `except IntegrityError` sat there waiting for a
    # violation that could no longer happen. A gateway retry of an already
    # processed payment would have been processed a second time and issued a
    # second activation code.
    #
    # A plain unique index on a nullable column does the same work on every
    # engine we might run on: MySQL, MariaDB and PostgreSQL all allow many NULLs
    # in a unique index, so refused deliveries — which are audit rows and must
    # never reserve anything — simply do not participate.
    #
    # Kept in step in `save`, so no caller has to remember it.
    verified_event_id = models.CharField(
        max_length=160, null=True, blank=True, unique=True, editable=False
    )

    signature_valid = models.BooleanField(default=False)
    outcome = models.CharField(max_length=16, choices=Outcome.choices)

    # A hash, never the body: a webhook body carries payment metadata we have no
    # reason to retain, and possibly fields we are forbidden to (Art. 7.7).
    payload_sha256 = models.CharField(max_length=64)

    transaction = models.ForeignKey(
        Transaction,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="webhook_events",
    )

    received_at = models.DateTimeField(auto_now_add=True)
    note = models.CharField(max_length=200, blank=True)

    class Meta:
        ordering = ("-received_at",)
        indexes = [models.Index(fields=["outcome", "-received_at"])]
        constraints = [
            # Article 7.3's idempotency, scoped to events we actually
            # authenticated. Refused deliveries are audit rows and nothing more.
            #
            # **This one only exists on PostgreSQL.** MariaDB and MySQL have no
            # partial indexes and skip it with a warning, which is precisely why
            # `verified_event_id` carries the same guarantee as a plain unique
            # column. Kept rather than deleted: on PostgreSQL it is the more
            # direct statement of the rule, and having both costs one index.
            models.UniqueConstraint(
                fields=["event_id"],
                condition=models.Q(signature_valid=True),
                name="unique_verified_webhook_event",
            )
        ]

    def save(self, *args, **kwargs):
        """Keep `verified_event_id` in step with `signature_valid`.

        Here rather than at the call sites: there are three of them today, and
        the fourth is the one that would forget.
        """
        self.verified_event_id = self.event_id if self.signature_valid else None
        return super().save(*args, **kwargs)

    def __str__(self) -> str:
        return f"{self.event_id} -> {self.outcome}"
