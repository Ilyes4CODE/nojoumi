"""Article 7.3's idempotency, on an engine with no partial indexes.

## What went wrong

The rule is a conditional unique constraint: `event_id` is unique **only across
signature-verified rows**, so a forged delivery can be recorded for the audit
trail without reserving the id a genuine one will need (D-42).

PostgreSQL implements that directly. **MariaDB has no partial indexes**, and on
the production deployment of 2026-09-09 Django said so and carried on:

    models.W036 MariaDB does not support unique constraints with conditions.
    HINT: A constraint won't be created.

The migration reported OK. The table existed. And the constraint that the view's
`except IntegrityError` waits for did not — so a gateway retry of an already
processed payment would have been processed again and issued a second activation
code for one payment.

## What these tests pin

`verified_event_id` carries the guarantee as a **plain unique nullable column**,
which MySQL, MariaDB and PostgreSQL all implement identically: many NULLs are
allowed in a unique index, so refused deliveries do not participate.

They are written against *that column* rather than against the constraint. On
SQLite — where the partial index does work — a test that only tried a duplicate
insert would pass for the wrong reason and say nothing about the engine actually
deployed to.
"""

from __future__ import annotations

from django.db import IntegrityError, transaction
from django.test import TestCase

from apps.payments.models import WebhookEvent


def make(event_id: str, *, verified: bool) -> WebhookEvent:
    return WebhookEvent.objects.create(
        event_id=event_id,
        payload_sha256="0" * 64,
        signature_valid=verified,
        outcome=(
            WebhookEvent.Outcome.PROCESSED
            if verified
            else WebhookEvent.Outcome.BAD_SIGNATURE
        ),
    )


class TheKeyFollowsTheSignature(TestCase):
    def test_a_verified_event_carries_its_key(self):
        self.assertEqual(make("evt_1", verified=True).verified_event_id, "evt_1")

    def test_a_refused_event_carries_none(self):
        self.assertIsNone(
            make("evt_1", verified=False).verified_event_id,
            "a refused delivery is an audit row and must reserve nothing",
        )

    def test_it_follows_a_later_change(self):
        # Maintained in save(), so nothing can set one without the other — which
        # is why it is there rather than at the three call sites.
        event = make("evt_1", verified=False)
        event.signature_valid = True
        event.save()
        event.refresh_from_db()
        self.assertEqual(event.verified_event_id, "evt_1")


class TheGuaranteeHoldsWithoutAPartialIndex(TestCase):
    def test_the_same_verified_event_cannot_arrive_twice(self):
        # The gateway retries. Without this the retry is processed as new and a
        # second activation code is issued for one payment.
        make("evt_1", verified=True)
        with self.assertRaises(IntegrityError), transaction.atomic():
            make("evt_1", verified=True)

    def test_D42_a_forgery_cannot_lock_out_the_genuine_delivery(self):
        # The defect this whole design exists for. An unsigned request carrying
        # a guessed event id must be recorded and must reserve nothing, so the
        # real delivery of that id still gets through.
        make("evt_1", verified=False)
        make("evt_1", verified=False)

        genuine = make("evt_1", verified=True)

        self.assertEqual(genuine.outcome, WebhookEvent.Outcome.PROCESSED)
        self.assertEqual(
            WebhookEvent.objects.filter(event_id="evt_1").count(),
            3,
            "two refusals kept for the audit trail, and the real one processed",
        )

    def test_many_refusals_of_the_same_id_are_all_recorded(self):
        # "When the client asks why a payment did not activate, the answer must
        # be a row, not a theory."
        for _ in range(5):
            make("evt_flood", verified=False)

        self.assertEqual(WebhookEvent.objects.filter(event_id="evt_flood").count(), 5)
        self.assertEqual(
            WebhookEvent.objects.filter(verified_event_id="evt_flood").count(),
            0,
            "none of them may hold the key",
        )

    def test_different_events_are_independent(self):
        make("evt_1", verified=True)
        make("evt_2", verified=True)
        self.assertEqual(WebhookEvent.objects.exclude(verified_event_id=None).count(), 2)
