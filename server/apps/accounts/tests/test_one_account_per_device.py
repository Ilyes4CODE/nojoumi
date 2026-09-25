"""How many accounts fit on one phone — client request, 2026-08-28, amended 2026-09-25.

**One, then three.** The original rule was one account per phone. The client
raised it to three for households where more than one adult uses the same
handset, and asked that the subscription stay with the *device* rather than with
whichever account paid — that half is proven in
`apps/devices/tests/test_three_accounts.py`.

The rule extends the anchor Article 7.1 already uses for the free trial (the
app's random install UUID, «مرة واحدة لكل جهاز») from the trial to the account
itself. Raising the number did not change the anchor, only the count.

**What these tests are not claiming.** Clearing the app's data produces a new
UUID and therefore a new device as far as the server is concerned. Closing that
would need a persistent hardware identifier, which Play policy and Article 14
both forbid — see `install_binding.py`. So this is a rule against casual
account-swapping on a shared family phone, which is what was asked for, and the
client must never be told it is a security boundary.
"""

from __future__ import annotations

import uuid

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import TestCase
from django.urls import reverse

from apps.devices.models import Install

ParentUser = get_user_model()

PASSWORD = "Lunio-test-2026"


class OneAccountPerDevice(TestCase):
    def setUp(self):
        # Throttle counters live in the cache and survive between tests in a
        # class. This file registers several accounts per test and would
        # otherwise spend the 10/hour register budget and start asserting on
        # 429s — a failure that looks like the feature and is not.
        cache.clear()
        self.register_url = reverse("accounts:register")
        self.token_url = reverse("accounts:token")
        self.install = str(uuid.uuid4())

    def register(self, email, install_id=None):
        body = {"email": email, "password": PASSWORD}
        if install_id is not None:
            body["install_id"] = install_id
        return self.client.post(self.register_url, body, content_type="application/json")

    def sign_in(self, email, install_id=None, password=PASSWORD):
        body = {"email": email, "password": password}
        if install_id is not None:
            body["install_id"] = install_id
        return self.client.post(self.token_url, body, content_type="application/json")

    # --- registration -------------------------------------------------------

    def test_the_first_account_claims_the_device(self):
        response = self.register("first@lunio.test", self.install)
        self.assertEqual(response.status_code, 201)

        install = Install.objects.get(id=self.install)
        self.assertIsNotNone(install.parent_id)
        self.assertEqual(install.parent.email, "first@lunio.test")

    def test_three_accounts_may_register_on_the_same_device(self):
        # Registration and sign-in have to agree. They did not for one commit:
        # sign-in allowed three while registration still refused the second, so
        # a household could only add a parent by creating the account on another
        # phone first.
        for name in ("first", "second", "third"):
            response = self.register(f"{name}@lunio.test", self.install)
            self.assertEqual(response.status_code, 201, response.json())

    def test_the_fourth_registration_is_refused(self):
        for name in ("first", "second", "third"):
            self.register(f"{name}@lunio.test", self.install)
        response = self.register("fourth@lunio.test", self.install)

        self.assertEqual(response.status_code, 409)
        self.assertIn("احذف بيانات التطبيق", response.json()["detail"])

    def test_the_refused_registration_leaves_no_account_behind(self):
        # The reason the check runs before `serializer.save()`. Creating the
        # account first and refusing to bind afterwards would strand an orphan
        # account on every attempt — and burn an email address that could then
        # never be registered.
        for name in ("first", "second", "third"):
            self.register(f"{name}@lunio.test", self.install)
        self.register("fourth@lunio.test", self.install)

        self.assertFalse(ParentUser.objects.filter(email="fourth@lunio.test").exists())

    def test_a_different_device_is_free_to_register(self):
        self.register("first@lunio.test", self.install)
        response = self.register("second@lunio.test", str(uuid.uuid4()))
        self.assertEqual(response.status_code, 201)

    # --- sign-in, which is the path that actually matters --------------------

    def test_a_second_and_third_account_may_sign_in(self):
        # The amendment of 2026-09-25. Registration is not how a second account
        # arrives on a phone — a parent creates account B elsewhere and signs in
        # with it here — so this is the path the limit actually governs.
        self.register("first@lunio.test", self.install)
        for name in ("second", "third"):
            self.register(f"{name}@lunio.test", str(uuid.uuid4()))
            response = self.sign_in(f"{name}@lunio.test", self.install)
            self.assertEqual(response.status_code, 200, response.json())

    def test_signing_in_with_a_fourth_account_is_refused(self):
        # The limit still exists; it moved. Without this the amendment reads as
        # "remove the rule", which is not what was asked for.
        self.register("first@lunio.test", self.install)
        for name in ("second", "third", "fourth"):
            self.register(f"{name}@lunio.test", str(uuid.uuid4()))

        for name in ("second", "third"):
            self.assertEqual(
                self.sign_in(f"{name}@lunio.test", self.install).status_code, 200
            )

        response = self.sign_in("fourth@lunio.test", self.install)
        self.assertEqual(response.status_code, 400)
        self.assertIn("احذف بيانات التطبيق", str(response.json()))

    def test_the_owning_account_can_sign_in_again(self):
        # The ordinary case, and it must stay idempotent: the app sends its
        # install id on every sign-in.
        self.register("first@lunio.test", self.install)
        for _ in range(3):
            response = self.sign_in("first@lunio.test", self.install)
            self.assertEqual(response.status_code, 200)
            self.assertIn("access", response.json())

    def test_wrong_credentials_fail_before_the_device_is_consulted(self):
        # Order matters. Refusing an unknown email *because the device is
        # claimed* would tell somebody holding the phone which addresses exist.
        self.register("first@lunio.test", self.install)
        response = self.sign_in("first@lunio.test", self.install, password="wrong-one")
        self.assertEqual(response.status_code, 401)

    def test_an_unclaimed_device_is_claimed_by_whoever_signs_in(self):
        # The reinstall path: app data cleared, new UUID, same account.
        self.register("first@lunio.test", self.install)
        fresh = str(uuid.uuid4())

        response = self.sign_in("first@lunio.test", fresh)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(Install.objects.get(id=fresh).parent.email, "first@lunio.test")

    # --- older clients -------------------------------------------------------

    def test_a_request_without_an_install_id_still_works(self):
        # Optional on the wire so a curl call or an older build is not broken by
        # a rule that is about phones.
        self.assertEqual(self.register("nobody@lunio.test").status_code, 201)
        self.assertEqual(self.sign_in("nobody@lunio.test").status_code, 200)


class RegistrationLeavesNothingBehindWhenBindingFails(TestCase):
    """Found on production, 2026-09-25.

    The three-account code was deployed without its migration. `bind()` raised
    because the join table did not exist, and every registration committed an
    account, failed to bind it, and returned 500 — leaving an account nobody
    could use and an email address nobody could register again.

    The migration was the cause. This is the reason the cause left debris: the
    account and the binding were two commits rather than one.
    """

    def setUp(self):
        cache.clear()

    def test_a_failed_binding_rolls_the_account_back(self):
        from unittest import mock

        with mock.patch(
            "apps.accounts.views.install_binding.bind",
            side_effect=RuntimeError("relation devices_installaccount does not exist"),
        ):
            with self.assertRaises(RuntimeError):
                self.client.post(
                    reverse("accounts:register"),
                    {
                        "email": "orphan@lunio.test",
                        "password": PASSWORD,
                        "install_id": str(uuid.uuid4()),
                    },
                    content_type="application/json",
                )

        self.assertFalse(
            ParentUser.objects.filter(email="orphan@lunio.test").exists(),
            "the account was committed even though the device could not be bound",
        )
