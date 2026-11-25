"""A parent signs in once, not once a day.

Reported by the client on 2026-11-25: "each day he should log in to the app".
SIMPLE_JWT carried only CHECK_REVOKE_TOKEN, so everything else was the library's
default — and the default refresh lifetime is **one day**. The app renews its
five-minute access token with the refresh token; a day after sign-in the refresh
was refused, the app ended the session, and the parent met the sign-in form
again the next morning.

The fix is a long refresh lifetime **and rotation**: every renewal hands back a
new refresh token, so a phone that is used keeps its session indefinitely, and
one that is abandoned for the whole lifetime has to sign in again. A password
change still ends every session (CHECK_REVOKE_TOKEN), which is the revocation
that matters on a family phone.
"""

from __future__ import annotations

from datetime import timedelta
from unittest import mock

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.utils import aware_utcnow

ParentUser = get_user_model()

TOKEN = reverse("accounts:token")
REFRESH = reverse("accounts:token-refresh")
ME = reverse("accounts:me")
PASSWORD = "n7-Sabah-Khayr-2026"


def later(days: int):
    """Run the token code as if `days` had passed since now."""
    moment = aware_utcnow() + timedelta(days=days)
    return mock.patch("rest_framework_simplejwt.tokens.aware_utcnow", return_value=moment)


class ASessionOutlivesADay(TestCase):
    def setUp(self):
        cache.clear()
        self.parent = ParentUser.objects.create_user(email="wali@bayt.dz", password=PASSWORD)
        self.api = APIClient()
        pair = self.api.post(TOKEN, {"email": "wali@bayt.dz", "password": PASSWORD}, format="json").json()
        self.refresh = pair["refresh"]

    def renew(self, refresh, *, days):
        with later(days):
            return self.api.post(REFRESH, {"refresh": refresh}, format="json")

    def test_the_morning_after_still_renews(self):
        # The exact report: signed in yesterday, opened the app today.
        response = self.renew(self.refresh, days=2)
        self.assertEqual(response.status_code, 200, response.content)
        self.assertIn("access", response.json())

    def test_a_month_away_still_renews(self):
        self.assertEqual(self.renew(self.refresh, days=30).status_code, 200)

    def test_renewing_hands_back_a_new_refresh_token(self):
        # Rotation is what makes the session slide: the app stores this one and
        # its clock starts again.
        body = self.renew(self.refresh, days=1).json()
        self.assertIn("refresh", body)
        self.assertNotEqual(body["refresh"], self.refresh)

    def test_a_renewal_restarts_the_clock(self):
        # What makes a phone in use never sign in again: renewed late in its
        # life, the session gets a whole new lifetime from that moment, not
        # from the original sign-in.
        #
        # Asserted on the claim rather than by renewing again months later: the
        # JWT library checks `iat` against the real clock, so a token minted
        # under a mocked future date reads as "not yet valid" to it.
        renewed_on = aware_utcnow() + timedelta(days=170)
        body = self.renew(self.refresh, days=170).json()
        exp = RefreshToken(body["refresh"], verify=False)["exp"]
        self.assertGreaterEqual(exp, (renewed_on + timedelta(days=179)).timestamp())

    def test_an_abandoned_phone_does_have_to(self):
        self.assertEqual(self.renew(self.refresh, days=400).status_code, 401)

    def test_a_password_change_still_ends_every_session(self):
        # The revocation a family phone needs: the parent changes the password
        # and whoever else was signed in is out.
        self.parent.set_password("K8-Masaa-Noor-2026")
        self.parent.save()
        self.assertEqual(self.renew(self.refresh, days=0).status_code, 401)

    def test_the_lifetime_is_written_into_the_token(self):
        token = RefreshToken(self.refresh)
        self.assertGreaterEqual(token["exp"] - token["iat"], 180 * 24 * 3600)

    def test_a_deleted_account_cannot_renew(self):
        self.parent.delete()
        self.assertEqual(self.renew(self.refresh, days=0).status_code, 401)
