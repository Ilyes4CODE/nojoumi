"""Three accounts on one phone, and one subscription between them.

The client's rule of 2026-08-28 was one account per phone. On 2026-09-25 they
raised it to three, "but the subscription stays on the device" — so the two
halves of this file are the two halves of that sentence, and the second is the
one with teeth: a household that paid for a year must not be asked to pay again
because the other parent signed in.
"""

from __future__ import annotations

import uuid
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone

from apps.accounts import install_binding
from apps.accounts.install_binding import MAX_ACCOUNTS_PER_INSTALL
from apps.devices.models import Install, InstallAccount
from apps.subscriptions import services
from apps.subscriptions.models import Subscription
from apps.subscriptions.plans import PlanCode, SubscriptionState

ParentUser = get_user_model()


def a_parent(n: int):
    return ParentUser.objects.create_user(
        email=f"wali{n}@bayt.dz", password="n7-Sabah-Khayr-2026"
    )


class HowManyAccountsFitOnAPhone(TestCase):
    def setUp(self):
        self.install_id = uuid.uuid4()

    def bind(self, parent):
        return install_binding.bind(install_id=self.install_id, parent=parent)

    def test_three_accounts_are_allowed(self):
        for n in range(MAX_ACCOUNTS_PER_INSTALL):
            self.bind(a_parent(n))

        install = Install.objects.get(pk=self.install_id)
        self.assertEqual(install.accounts.count(), 3)

    def test_the_fourth_is_refused_with_something_a_parent_can_act_on(self):
        for n in range(MAX_ACCOUNTS_PER_INSTALL):
            self.bind(a_parent(n))

        with self.assertRaises(install_binding.InstallAlreadyClaimed) as refused:
            self.bind(a_parent(99))

        said = str(refused.exception)
        self.assertIn("احذف بيانات التطبيق", said)
        # And the refusal leaves nothing behind: the row is inserted and then
        # undone, so a failed attempt must not occupy one of the three seats.
        self.assertEqual(Install.objects.get(pk=self.install_id).accounts.count(), 3)

    def test_signing_in_again_is_not_a_new_seat(self):
        # The app sends its install id on every sign-in. A parent signing in on
        # their own phone twice a day is the ordinary case, not a violation.
        parent = a_parent(0)
        for _ in range(5):
            self.bind(parent)

        self.assertEqual(Install.objects.get(pk=self.install_id).accounts.count(), 1)

    def test_the_first_account_stays_the_install_owner(self):
        # `Install.parent` is read by the trial, by the activation code and by
        # every query written before the join table existed. The second and third
        # bindings must not move it.
        first, second = a_parent(0), a_parent(1)
        self.bind(first)
        self.bind(second)

        self.assertEqual(Install.objects.get(pk=self.install_id).parent_id, first.pk)


class TheSubscriptionBelongsToThePhone(TestCase):
    """The half of the request that actually costs the client money if wrong."""

    def setUp(self):
        self.install = Install.objects.create(id=uuid.uuid4())
        self.payer = a_parent(0)
        self.other = a_parent(1)
        for parent in (self.payer, self.other):
            install_binding.bind(install_id=self.install.id, parent=parent)

        self.now = timezone.now()
        self.paid = Subscription.objects.create(
            parent=self.payer,
            plan=PlanCode.ANNUAL,
            state=SubscriptionState.ACTIVE,
            started_at=self.now,
            ends_at=self.now + timedelta(days=365),
        )

    def test_the_other_parent_on_the_phone_sees_what_was_paid_for(self):
        found = services.current_subscription(self.other, self.install)
        self.assertEqual(found, self.paid)

    def test_without_the_install_it_is_still_account_scoped(self):
        # An older build does not send the install id, and must not start seeing
        # somebody else's subscription by accident.
        self.assertIsNone(services.current_subscription(self.other))

    def test_a_parent_on_a_different_phone_sees_nothing(self):
        # The widening follows the device. It must not leak across devices, or
        # one purchase would unlock every account that ever touched the payer.
        elsewhere = Install.objects.create(id=uuid.uuid4())
        install_binding.bind(install_id=elsewhere.id, parent=self.other)

        self.assertIsNone(services.current_subscription(self.other, elsewhere))

    def test_a_refund_on_any_account_still_wins(self):
        # Otherwise a household could refund the purchase and keep the app by
        # signing in as the other parent.
        self.paid.refunded_at = self.now
        self.paid.state = SubscriptionState.REFUNDED
        self.paid.save()

        found = services.current_subscription(self.other, self.install)
        self.assertEqual(found, self.paid)
        self.assertIsNotNone(found.refunded_at)

    def test_the_snapshot_still_names_the_parent_reading_it(self):
        # What the device may *show* has widened. What the snapshot may be
        # *used by* has not — it is still bound to one account, so it cannot be
        # lifted onto another parent's phone.
        snapshot = services.build_snapshot(parent=self.other, install=self.install)
        self.assertEqual(snapshot["payload"]["parent_id"], self.other.id)
        self.assertEqual(snapshot["payload"]["state"], SubscriptionState.ACTIVE)

    def test_a_device_bound_before_the_join_table_existed_still_resolves(self):
        # Rows written under the old one-account rule have `Install.parent` and,
        # until the backfill or the next sign-in, no `InstallAccount` row.
        legacy = Install.objects.create(id=uuid.uuid4(), parent=self.payer)
        InstallAccount.objects.filter(install=legacy).delete()

        self.assertEqual(
            services.current_subscription(self.payer, legacy), self.paid
        )
