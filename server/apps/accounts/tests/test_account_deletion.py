"""Deleting an account, from the app and from the web.

Google Play refuses an app that lets people create an account without letting
them delete it, and asks for the deletion route twice: inside the app, and as a
web page that works for someone who has already uninstalled. Both were added on
2026-10-13, during the first Play submission, when the Data safety form asked
for the URL and there was nothing to put in it.

The interesting tests are not "does it delete". They are **what it leaves
behind** — the payment trail and the trial-once-per-phone rule must survive the
person — and **what it refuses**: a deletion that only needs a stolen token, or
a web form that guesses passwords without limit.
"""

from __future__ import annotations

from datetime import timedelta

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient

from apps.devices.models import Install, InstallAccount
from apps.payments.models import Transaction, TransactionStatus
from apps.subscriptions.models import Subscription
from apps.subscriptions.plans import PlanCode, SubscriptionState

ParentUser = get_user_model()

API = reverse("accounts:delete")
PAGE = reverse("account-delete")
TOKEN = reverse("accounts:token")
ME = reverse("accounts:me")

PASSWORD = "n7-Sabah-Khayr-2026"


class DeletionBase(TestCase):
    def setUp(self):
        cache.clear()  # throttle counters survive between tests otherwise
        self.parent = ParentUser.objects.create_user(email="wali@bayt.dz", password=PASSWORD)
        now = timezone.now()
        self.subscription = Subscription.objects.create(
            parent=self.parent, plan=PlanCode.ANNUAL, state=SubscriptionState.ACTIVE,
            started_at=now, ends_at=now + timedelta(days=300),
        )
        self.payment = Transaction.objects.create(
            amount_dzd=5000, plan=PlanCode.ANNUAL, status=TransactionStatus.PAID,
            parent=self.parent, gateway_payment_id="chg_1",
        )
        self.install = Install.objects.create(parent=self.parent)
        InstallAccount.objects.create(install=self.install, parent=self.parent)

        self.api = APIClient()
        tokens = self.api.post(TOKEN, {"email": "wali@bayt.dz", "password": PASSWORD}, format="json")
        self.access = tokens.json()["access"]
        self.api.credentials(HTTP_AUTHORIZATION=f"Bearer {self.access}")

    def gone(self) -> bool:
        return not ParentUser.objects.filter(pk=self.parent.pk).exists()


class FromTheApp(DeletionBase):
    def test_the_right_password_deletes_the_account(self):
        response = self.api.post(API, {"password": PASSWORD}, format="json")
        self.assertEqual(response.status_code, 204)
        self.assertTrue(self.gone())

    def test_a_token_alone_is_not_enough(self):
        # The parent's phone is the child's phone. A signed-in session on it is
        # not proof that the parent is the one tapping.
        response = self.api.post(API, {}, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertFalse(self.gone())

    def test_a_wrong_password_is_403_not_401(self):
        # 401 would make the app's client refresh the token and retry, and then
        # report "signed out" for what was a typo.
        response = self.api.post(API, {"password": "not-it"}, format="json")
        self.assertEqual(response.status_code, 403)
        self.assertFalse(self.gone())
        self.assertIn("كلمة المرور", response.json()["detail"])

    def test_it_needs_a_session(self):
        response = APIClient().post(API, {"password": PASSWORD}, format="json")
        self.assertEqual(response.status_code, 401)
        self.assertFalse(self.gone())

    def test_the_old_token_stops_working(self):
        self.api.post(API, {"password": PASSWORD}, format="json")
        self.assertEqual(self.api.get(ME).status_code, 401)

    def test_the_address_can_be_registered_again(self):
        self.api.post(API, {"password": PASSWORD}, format="json")
        again = APIClient().post(
            reverse("accounts:register"),
            {"email": "wali@bayt.dz", "password": PASSWORD},
            format="json",
        )
        self.assertEqual(again.status_code, 201)

    def test_guessing_is_throttled(self):
        statuses = [
            self.api.post(API, {"password": f"guess-{i}"}, format="json").status_code
            for i in range(12)
        ]
        self.assertIn(429, statuses)


class WhatItLeavesBehind(DeletionBase):
    def setUp(self):
        super().setUp()
        response = self.api.post(API, {"password": PASSWORD}, format="json")
        assert response.status_code == 204, response.content

    def test_the_subscription_goes_with_the_account(self):
        self.assertFalse(Subscription.objects.filter(pk=self.subscription.pk).exists())

    def test_the_phone_binding_goes(self):
        self.assertFalse(InstallAccount.objects.filter(install=self.install).exists())

    def test_the_payment_record_stays_without_a_name_on_it(self):
        # The accounting trail of money actually received. It never held an
        # email or card data; now it does not even point at the account.
        self.payment.refresh_from_db()
        self.assertIsNone(self.payment.parent_id)
        self.assertEqual(self.payment.amount_dzd, 5000)

    def test_the_phone_still_remembers_its_trial(self):
        # Article 7.1 puts the trial on the device. If deleting the account took
        # the install with it, delete-and-register would be a free month forever.
        self.install.refresh_from_db()
        self.assertIsNone(self.install.parent_id)


class FromTheWeb(DeletionBase):
    def post(self, email="wali@bayt.dz", password=PASSWORD, confirm="on"):
        data = {"email": email, "password": password}
        if confirm:
            data["confirm"] = confirm
        return self.client.post(PAGE, data)

    def test_the_page_opens_without_an_account(self):
        # A reviewer opens it cold, and so does a parent who uninstalled.
        page = self.client.get(PAGE)
        self.assertEqual(page.status_code, 200)
        body = page.content.decode()
        self.assertIn("Lunio", body)
        self.assertIn("حذف الحساب", body)
        self.assertIn("Delete your Lunio account", body)

    def test_the_page_says_what_is_deleted_and_what_is_kept(self):
        # Play's requirement for this page, not a courtesy.
        body = self.client.get(PAGE).content.decode()
        for phrase in ("الاشتراك", "سجلّ الدفع", "ما يبقى"):
            self.assertIn(phrase, body)

    def test_the_right_pair_deletes_the_account(self):
        response = self.post()
        self.assertEqual(response.status_code, 200)
        self.assertIn("تمّ حذف حسابك", response.content.decode())
        self.assertTrue(self.gone())

    def test_the_address_is_matched_case_insensitively(self):
        self.post(email="  Wali@Bayt.DZ ")
        self.assertTrue(self.gone())

    def test_a_wrong_password_deletes_nothing(self):
        response = self.post(password="not-it")
        self.assertEqual(response.status_code, 400)
        self.assertFalse(self.gone())

    def test_an_unknown_address_gets_the_same_answer_as_a_wrong_password(self):
        # Otherwise the form tells anyone which addresses have an account.
        wrong_password = self.post(password="not-it").content.decode()
        cache.clear()
        no_account = self.post(email="nobody@bayt.dz").content.decode()
        self.assertIn("البريد الإلكتروني أو كلمة المرور غير صحيحة", wrong_password)
        self.assertIn("البريد الإلكتروني أو كلمة المرور غير صحيحة", no_account)

    def test_it_must_be_confirmed(self):
        response = self.post(confirm=None)
        self.assertEqual(response.status_code, 400)
        self.assertFalse(self.gone())

    def test_guessing_is_throttled(self):
        statuses = [self.post(password=f"guess-{i}").status_code for i in range(12)]
        self.assertIn(429, statuses)
        self.assertFalse(self.gone())

    def test_the_password_is_never_echoed_back(self):
        body = self.post(password="secret-typo-123").content.decode()
        self.assertNotIn("secret-typo-123", body)


class ThePrivacyPolicyPointsHere(TestCase):
    def test_the_policy_links_to_the_deletion_page(self):
        body = self.client.get(reverse("privacy")).content.decode()
        self.assertIn(PAGE, body)
