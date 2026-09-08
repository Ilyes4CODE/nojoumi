"""Article 7 on the server side.

`packages/lunio_subscription` already proves the *device's* reading of Article 7
with 42 tests. This file proves the *server's* — and Art. 7.6 makes the server the
authority, so the two must agree. Where a rule appears in both, the test name says
so, and a divergence between them is a bug in whichever one changed last.
"""

from __future__ import annotations

from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIClient

from apps.common.signing import verify_payload
from apps.devices.models import Install
from apps.payments.models import Transaction, TransactionStatus
from apps.subscriptions import services
from apps.subscriptions.models import ActivationCode, Subscription, generate_code
from apps.subscriptions.plans import PlanCode, SubscriptionState

# A fixed test key so signature assertions are deterministic.
TEST_SIGNING_KEY = "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60"

ParentUser = get_user_model()


def make_parent(email="parent@example.com") -> ParentUser:
    return ParentUser.objects.create_user(email, password="Str0ng-Passw0rd!")


def make_install() -> Install:
    return Install.objects.create()


def make_code(plan=PlanCode.MONTHLY) -> ActivationCode:
    txn = Transaction.objects.create(
        gateway_payment_id=generate_code(),
        amount_dzd=1000,
        status=TransactionStatus.PAID,
        plan=plan,
    )
    return ActivationCode.objects.create(transaction=txn, plan=plan)


class TrialTests(TestCase):
    """Art. 7.1 — 7 days, all features, once per device."""

    def test_a_trial_lasts_seven_days(self):
        parent, install = make_parent(), make_install()
        sub = services.start_trial(parent=parent, install=install)

        self.assertEqual(sub.plan, PlanCode.TRIAL)
        self.assertEqual((sub.ends_at - sub.started_at).days, 7)
        self.assertEqual(sub.effective_state(), SubscriptionState.TRIAL)

    def test_the_trial_is_once_per_DEVICE_not_once_per_account(self):
        """The contract says "مرة واحدة لكل جهاز" — a new email must not reset it."""
        install = make_install()
        services.start_trial(parent=make_parent("a@example.com"), install=install)

        with self.assertRaises(services.TrialAlreadyUsed):
            services.start_trial(
                parent=make_parent("b@example.com"), install=install
            )

    def test_a_different_device_gets_its_own_trial(self):
        parent = make_parent()
        services.start_trial(parent=parent, install=make_install())
        second = services.start_trial(parent=parent, install=make_install())
        self.assertEqual(second.plan, PlanCode.TRIAL)

    def test_consuming_the_trial_is_recorded_on_the_install_and_never_cleared(self):
        install = make_install()
        self.assertTrue(install.trial_available)

        services.start_trial(parent=make_parent(), install=install)
        install.refresh_from_db()

        self.assertFalse(install.trial_available)
        self.assertIsNotNone(install.trial_consumed_at)

    def test_an_expired_trial_gets_grace_then_free_mode(self):
        parent, install = make_parent(), make_install()
        sub = services.start_trial(parent=parent, install=install)
        now = sub.ends_at

        self.assertEqual(
            sub.effective_state(now + timedelta(days=1)), SubscriptionState.GRACE
        )
        self.assertEqual(
            sub.effective_state(now + timedelta(days=4)), SubscriptionState.EXPIRED
        )


class ActivationTests(TestCase):
    """Art. 7.3 step 5 — the parent enters the code once."""

    def test_a_valid_code_creates_an_active_subscription(self):
        parent = make_parent()
        code = make_code(PlanCode.MONTHLY)

        sub = services.activate(code=code.code, parent=parent, install=make_install())

        self.assertEqual(sub.plan, PlanCode.MONTHLY)
        self.assertEqual(sub.effective_state(), SubscriptionState.ACTIVE)
        self.assertEqual((sub.ends_at - sub.started_at).days, 30)

    def test_an_annual_code_gives_365_days(self):
        sub = services.activate(
            code=make_code(PlanCode.ANNUAL).code, parent=make_parent()
        )
        self.assertEqual((sub.ends_at - sub.started_at).days, 365)

    def test_a_code_works_exactly_once(self):
        code = make_code()
        services.activate(code=code.code, parent=make_parent("a@example.com"))

        with self.assertRaises(services.CodeAlreadyUsed):
            services.activate(code=code.code, parent=make_parent("b@example.com"))

    def test_an_unknown_code_is_refused(self):
        with self.assertRaises(services.CodeInvalid):
            services.activate(code="ZZZZZ-ZZZZZ", parent=make_parent())

    def test_an_empty_code_is_refused_without_a_database_lookup(self):
        with self.assertRaises(services.CodeInvalid):
            services.activate(code="   ", parent=make_parent())

    def test_codes_are_case_insensitive_and_trimmed(self):
        """A parent types this by hand off a web page (Art. 7.3)."""
        code = make_code()
        sub = services.activate(code=f"  {code.code.lower()}  ", parent=make_parent())
        self.assertEqual(sub.effective_state(), SubscriptionState.ACTIVE)

    def test_the_generated_code_avoids_ambiguous_characters(self):
        for _ in range(200):
            code = generate_code()
            self.assertNotRegex(code, r"[01OIL]")
            self.assertRegex(code, r"^[A-Z2-9]{5}-[A-Z2-9]{5}$")

    def test_consumption_records_who_used_it_and_on_which_device(self):
        parent, install = make_parent(), make_install()
        code = make_code()
        services.activate(code=code.code, parent=parent, install=install)
        code.refresh_from_db()

        self.assertTrue(code.is_consumed)
        self.assertEqual(code.consumed_by_parent, parent)
        self.assertEqual(code.consumed_by_install, install)


class RenewalTests(TestCase):
    """Art. 7.4 — no auto-debit, and renewal ADDS to the remainder."""

    def test_renewing_early_adds_to_what_remains(self):
        parent = make_parent()
        services.activate(code=make_code(PlanCode.MONTHLY).code, parent=parent)
        first = services.current_subscription(parent)
        remaining = first.ends_at

        services.activate(code=make_code(PlanCode.MONTHLY).code, parent=parent)
        second = services.current_subscription(parent)

        self.assertEqual(second.pk, first.pk, "renewal extends, it does not replace")
        self.assertEqual((second.ends_at - remaining).days, 30)

    def test_renewing_late_starts_from_now_and_is_not_back_dated(self):
        parent = make_parent()
        now = timezone.now()
        Subscription.objects.create(
            parent=parent,
            plan=PlanCode.MONTHLY,
            started_at=now - timedelta(days=40),
            ends_at=now - timedelta(days=10),
        )

        services.activate(code=make_code(PlanCode.MONTHLY).code, parent=parent)
        sub = services.current_subscription(parent)

        self.assertGreater(sub.ends_at, now + timedelta(days=29))

    def test_an_annual_renewal_stacks_on_a_running_monthly(self):
        parent = make_parent()
        services.activate(code=make_code(PlanCode.MONTHLY).code, parent=parent)
        before = services.current_subscription(parent).ends_at

        services.activate(code=make_code(PlanCode.ANNUAL).code, parent=parent)
        after = services.current_subscription(parent)

        self.assertEqual((after.ends_at - before).days, 365)
        self.assertEqual(after.plan, PlanCode.ANNUAL)

    def test_there_is_no_cancel_operation_at_all(self):
        """Art. 7.4 — "الإلغاء لا يتطلّب أي إجراء: يكفي ألّا يجدّد الوالد"."""
        self.assertFalse(
            [n for n in dir(services) if "cancel" in n.lower()],
            "cancellation must be the absence of renewal, not an operation",
        )


class ReminderTests(TestCase):
    """Art. 7.4 — reminders 7 days then 2 days before expiry."""

    def setUp(self):
        self.parent = make_parent()
        self.now = timezone.now()
        self.sub = Subscription.objects.create(
            parent=self.parent,
            plan=PlanCode.MONTHLY,
            started_at=self.now,
            ends_at=self.now + timedelta(days=30),
        )

    def test_no_reminder_while_expiry_is_far_off(self):
        self.assertIsNone(services.due_reminder(self.sub, self.now))

    def test_the_seven_day_reminder_comes_due(self):
        at = self.sub.ends_at - timedelta(days=6, hours=23)
        self.assertEqual(services.due_reminder(self.sub, at), 7)

    def test_the_two_day_reminder_takes_over(self):
        at = self.sub.ends_at - timedelta(days=1, hours=23)
        self.assertEqual(services.due_reminder(self.sub, at), 2)

    def test_no_reminder_after_expiry(self):
        at = self.sub.ends_at + timedelta(hours=1)
        self.assertIsNone(services.due_reminder(self.sub, at))

    def test_no_reminder_for_a_refunded_subscription(self):
        services.mark_refunded(self.sub)
        at = self.sub.ends_at - timedelta(days=1)
        self.assertIsNone(services.due_reminder(self.sub, at))


class RefundTests(TestCase):
    """Art. 7.5 — the client marks it, it stops immediately on the device."""

    def test_a_refund_wins_over_remaining_time(self):
        parent = make_parent()
        services.activate(code=make_code(PlanCode.ANNUAL).code, parent=parent)
        sub = services.current_subscription(parent)

        services.mark_refunded(sub)
        sub.refresh_from_db()

        self.assertEqual(sub.effective_state(), SubscriptionState.REFUNDED)

    def test_a_refunded_subscription_is_the_one_that_decides(self):
        """Even if an older row has a later end date, the refund must surface."""
        parent = make_parent()
        now = timezone.now()
        long_one = Subscription.objects.create(
            parent=parent,
            plan=PlanCode.ANNUAL,
            started_at=now,
            ends_at=now + timedelta(days=365),
        )
        services.mark_refunded(long_one)

        self.assertEqual(
            services.current_subscription(parent).effective_state(),
            SubscriptionState.REFUNDED,
        )


@override_settings(SUBSCRIPTION_SIGNING_KEY_HEX=TEST_SIGNING_KEY)
class SnapshotSigningTests(TestCase):
    """Art. 7.6 — a signed local copy the device can verify but not forge."""

    def setUp(self):
        self.parent = make_parent()

    def test_the_snapshot_signature_verifies_with_the_public_key(self):
        snap = services.build_snapshot(parent=self.parent)
        self.assertTrue(
            verify_payload(snap["payload"], snap["signature"], snap["public_key"])
        )

    def test_tampering_with_any_field_breaks_the_signature(self):
        """This is the whole point: a child editing the local cache gains nothing."""
        snap = services.build_snapshot(parent=self.parent)

        for field, value in (
            ("state", SubscriptionState.ACTIVE),
            ("ends_at_ms", 9999999999999),
            ("plan", PlanCode.ANNUAL),
            ("parent_id", 999),
            ("grace_ends_at_ms", 9999999999999),
        ):
            with self.subTest(field=field):
                forged = dict(snap["payload"])
                forged[field] = value
                self.assertFalse(
                    verify_payload(forged, snap["signature"], snap["public_key"]),
                    f"forging {field} was not detected",
                )

    def test_a_parent_with_no_subscription_gets_a_signed_expired_snapshot(self):
        """Signed, not absent — the device must be able to trust the negative too."""
        snap = services.build_snapshot(parent=self.parent)

        self.assertEqual(snap["payload"]["state"], SubscriptionState.EXPIRED)
        self.assertTrue(
            verify_payload(snap["payload"], snap["signature"], snap["public_key"])
        )

    def test_the_snapshot_carries_the_contract_windows(self):
        snap = services.build_snapshot(parent=self.parent)

        self.assertEqual(snap["offline_window_days"], 7)
        self.assertEqual(snap["grace_days"], 3)
        self.assertEqual(snap["revalidate_after_hours"], 24)

    def test_blocking_and_stars_are_advertised_as_on_in_every_state(self):
        """Art. 7.1 — never punish the child for the parent's payment delay."""
        now = timezone.now()
        cases = {
            "no subscription": None,
            "active": (PlanCode.MONTHLY, now + timedelta(days=10), None),
            "grace": (PlanCode.MONTHLY, now - timedelta(days=1), None),
            "expired": (PlanCode.MONTHLY, now - timedelta(days=40), None),
            "refunded": (PlanCode.ANNUAL, now + timedelta(days=300), now),
        }
        for label, spec in cases.items():
            with self.subTest(state=label):
                Subscription.objects.filter(parent=self.parent).delete()
                if spec:
                    plan, ends_at, refunded = spec
                    Subscription.objects.create(
                        parent=self.parent,
                        plan=plan,
                        started_at=now - timedelta(days=1),
                        ends_at=ends_at,
                        refunded_at=refunded,
                    )
                caps = services.build_snapshot(parent=self.parent)["capabilities"]
                self.assertTrue(caps["blocking_active"])
                self.assertTrue(caps["stars_active"])
                self.assertTrue(caps["saved_lessons_accessible"])

    def test_ai_generation_is_the_only_capability_ever_withdrawn(self):
        now = timezone.now()
        Subscription.objects.create(
            parent=self.parent,
            plan=PlanCode.MONTHLY,
            started_at=now - timedelta(days=40),
            ends_at=now - timedelta(days=10),
        )
        caps = services.build_snapshot(parent=self.parent)["capabilities"]

        self.assertFalse(caps["can_generate_new_lessons"])
        self.assertEqual(
            [k for k, v in caps.items() if v is False],
            ["can_generate_new_lessons"],
        )

    def test_grace_still_allows_ai_generation(self):
        now = timezone.now()
        Subscription.objects.create(
            parent=self.parent,
            plan=PlanCode.MONTHLY,
            started_at=now - timedelta(days=31),
            ends_at=now - timedelta(days=1),
        )
        caps = services.build_snapshot(parent=self.parent)["capabilities"]
        self.assertTrue(caps["can_generate_new_lessons"])


@override_settings(SUBSCRIPTION_SIGNING_KEY_HEX=TEST_SIGNING_KEY)
class SubscriptionApiTests(TestCase):
    """The HTTP surface the app talks to."""

    def setUp(self):
        self.parent = make_parent()
        self.client = APIClient()
        self.client.force_authenticate(self.parent)
        self.install_id = str(make_install().id)

    def test_status_requires_authentication(self):
        anonymous = APIClient()
        self.assertIn(
            anonymous.get("/api/subscriptions/status/").status_code, (401, 403)
        )

    def test_status_returns_a_verifiable_snapshot(self):
        response = self.client.get("/api/subscriptions/status/")

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertTrue(
            verify_payload(body["payload"], body["signature"], body["public_key"])
        )

    def test_starting_a_trial_returns_201_and_a_trial_snapshot(self):
        response = self.client.post(
            "/api/subscriptions/trial/", {"install_id": self.install_id}
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.json()["payload"]["state"], SubscriptionState.TRIAL)

    def test_a_second_trial_on_the_same_device_is_409(self):
        self.client.post("/api/subscriptions/trial/", {"install_id": self.install_id})
        response = self.client.post(
            "/api/subscriptions/trial/", {"install_id": self.install_id}
        )
        self.assertEqual(response.status_code, 409)

    def test_activating_a_code_returns_an_active_snapshot(self):
        code = make_code(PlanCode.MONTHLY)
        response = self.client.post(
            "/api/subscriptions/activate/",
            {"install_id": self.install_id, "code": code.code},
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["payload"]["state"], SubscriptionState.ACTIVE)

    def test_reusing_a_code_is_409_and_an_unknown_code_is_400(self):
        code = make_code()
        self.client.post(
            "/api/subscriptions/activate/",
            {"install_id": self.install_id, "code": code.code},
        )
        again = self.client.post(
            "/api/subscriptions/activate/",
            {"install_id": self.install_id, "code": code.code},
        )
        unknown = self.client.post(
            "/api/subscriptions/activate/",
            {"install_id": self.install_id, "code": "ZZZZZ-ZZZZZ"},
        )

        self.assertEqual(again.status_code, 409)
        self.assertEqual(unknown.status_code, 400)

    def test_the_install_record_captures_content_free_diagnostics_only(self):
        self.client.post(
            "/api/subscriptions/trial/",
            {
                "install_id": self.install_id,
                "android_release": "14",
                "device_model": "SM-A155F",
                "app_version": "0.1.0",
            },
        )
        install = Install.objects.get(id=self.install_id)

        self.assertEqual(install.android_release, "14")
        self.assertEqual(install.device_model, "SM-A155F")
        self.assertEqual(install.parent, self.parent)

    def test_no_price_is_ever_returned_to_the_app(self):
        """Art. 7.2 — the app shows no price, no buy button, no payment link."""
        code = make_code(PlanCode.MONTHLY)
        self.client.post(
            "/api/subscriptions/activate/",
            {"install_id": self.install_id, "code": code.code},
        )
        body = self.client.get("/api/subscriptions/status/").content.decode()

        for forbidden in ("1000", "10000", "price", "amount", "dzd", "دج"):
            self.assertNotIn(forbidden, body.lower(), f"{forbidden!r} leaked to the app")
