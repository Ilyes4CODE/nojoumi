"""One account per phone — client request, 2026-08-28.

The rule extends the anchor Article 7.1 already uses for the free trial (the
app's random install UUID, «مرة واحدة لكل جهاز») from the trial to the account
itself.

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

    def test_a_second_account_on_the_same_device_is_refused(self):
        self.register("first@lunio.test", self.install)
        response = self.register("second@lunio.test", self.install)

        self.assertEqual(response.status_code, 409)
        self.assertIn("حساب آخر", response.json()["detail"])

    def test_the_refused_registration_leaves_no_account_behind(self):
        # The reason the check runs before `serializer.save()`. Creating the
        # account first and refusing to bind afterwards would strand an orphan
        # account on every attempt — and burn an email address that could then
        # never be registered.
        self.register("first@lunio.test", self.install)
        self.register("second@lunio.test", self.install)

        self.assertFalse(ParentUser.objects.filter(email="second@lunio.test").exists())

    def test_a_different_device_is_free_to_register(self):
        self.register("first@lunio.test", self.install)
        response = self.register("second@lunio.test", str(uuid.uuid4()))
        self.assertEqual(response.status_code, 201)

    # --- sign-in, which is the path that actually matters --------------------

    def test_signing_in_with_a_second_account_is_refused(self):
        # Registration is not how a second account arrives on a phone. A parent
        # creates account B elsewhere and signs in with it here. Checking only at
        # register would leave the rule guarding the least likely path.
        self.register("first@lunio.test", self.install)
        self.register("second@lunio.test", str(uuid.uuid4()))

        response = self.sign_in("second@lunio.test", self.install)
        self.assertEqual(response.status_code, 400)
        self.assertIn("حساب آخر", str(response.json()))

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
