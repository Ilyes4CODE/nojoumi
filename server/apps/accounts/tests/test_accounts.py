"""The parent account and JWT (Art. 3, Art. 14).

The most important test in this file is the last one: it asserts that the user
model holds nothing about the child.
"""

from __future__ import annotations

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

ParentUser = get_user_model()
STRONG = "Str0ng-Passw0rd!"


class RegistrationTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_a_parent_can_register_with_an_email(self):
        response = self.client.post(
            "/api/accounts/register/",
            {"email": "parent@example.com", "password": STRONG},
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(ParentUser.objects.count(), 1)

    def test_the_password_is_never_returned(self):
        response = self.client.post(
            "/api/accounts/register/",
            {"email": "parent@example.com", "password": STRONG},
        )
        self.assertNotIn("password", response.json())
        self.assertNotIn(STRONG, response.content.decode())

    def test_the_password_is_stored_hashed(self):
        self.client.post(
            "/api/accounts/register/",
            {"email": "parent@example.com", "password": STRONG},
        )
        user = ParentUser.objects.get()

        self.assertNotEqual(user.password, STRONG)
        self.assertTrue(user.check_password(STRONG))

    def test_a_weak_password_is_refused(self):
        response = self.client.post(
            "/api/accounts/register/", {"email": "p@example.com", "password": "1234"}
        )
        self.assertEqual(response.status_code, 400)

    def test_the_email_is_unique_and_case_normalised(self):
        self.client.post(
            "/api/accounts/register/",
            {"email": "Parent@Example.com", "password": STRONG},
        )
        duplicate = self.client.post(
            "/api/accounts/register/",
            {"email": "parent@example.com", "password": STRONG},
        )

        self.assertEqual(ParentUser.objects.get().email, "parent@example.com")
        self.assertEqual(duplicate.status_code, 400)

    def test_the_phone_is_optional(self):
        """Q17 is unresolved: the activation-code channel is not yet decided."""
        response = self.client.post(
            "/api/accounts/register/",
            {"email": "p@example.com", "password": STRONG},
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(ParentUser.objects.get().phone, "")


class TokenTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        ParentUser.objects.create_user("parent@example.com", password=STRONG)

    def test_valid_credentials_return_an_access_and_refresh_pair(self):
        response = self.client.post(
            "/api/accounts/token/",
            {"email": "parent@example.com", "password": STRONG},
        )

        self.assertEqual(response.status_code, 200)
        self.assertIn("access", response.json())
        self.assertIn("refresh", response.json())

    def test_wrong_credentials_are_refused(self):
        response = self.client.post(
            "/api/accounts/token/",
            {"email": "parent@example.com", "password": "wrong-password"},
        )
        self.assertEqual(response.status_code, 401)

    def test_the_access_token_authenticates_the_me_endpoint(self):
        token = self.client.post(
            "/api/accounts/token/",
            {"email": "parent@example.com", "password": STRONG},
        ).json()["access"]

        response = self.client.get(
            "/api/accounts/me/", HTTP_AUTHORIZATION=f"Bearer {token}"
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["email"], "parent@example.com")

    def test_me_requires_authentication(self):
        self.assertIn(self.client.get("/api/accounts/me/").status_code, (401, 403))

    def test_a_refresh_token_yields_a_new_access_token(self):
        refresh = self.client.post(
            "/api/accounts/token/",
            {"email": "parent@example.com", "password": STRONG},
        ).json()["refresh"]

        response = self.client.post("/api/accounts/token/refresh/", {"refresh": refresh})

        self.assertEqual(response.status_code, 200)
        self.assertIn("access", response.json())


class NoChildDataTests(TestCase):
    """Art. 14 / AD-6 — the server holds the parent, never the child."""

    def test_the_parent_model_has_no_field_about_a_child(self):
        forbidden = (
            "child", "child_name", "birth", "birthday", "birthdate", "age",
            "grade", "school", "photo", "avatar", "picture",
            "latitude", "longitude", "location", "gps", "address",
            "stars", "progress", "tasks",
        )
        names = {getattr(f, "name", "").lower() for f in ParentUser._meta.get_fields()}
        offenders = sorted(names & set(forbidden))

        self.assertEqual(
            offenders,
            [],
            "Article 14 forbids the server holding anything about the child. "
            f"Offending fields on the parent model: {offenders}",
        )

    def test_the_me_response_exposes_only_parent_fields(self):
        ParentUser.objects.create_user("parent@example.com", password=STRONG)
        client = APIClient()
        client.force_authenticate(ParentUser.objects.get())

        body = client.get("/api/accounts/me/").json()

        self.assertEqual(set(body), {"id", "email", "phone", "date_joined"})
