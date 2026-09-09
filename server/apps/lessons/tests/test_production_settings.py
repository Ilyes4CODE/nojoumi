"""Production settings must not remove what Django needs to serve a request.

**The bug this exists for.** Adding WhiteNoise wrote:

    STORAGES = {**globals().get("STORAGES", {}), "staticfiles": {...}}

on the assumption that it was merging into Django's defaults. `base.py` never
defines STORAGES, so the merge began from `{}` and the result had **no
`default`**. A settings module that assigns STORAGES replaces `global_settings`
wholesale; there is no partial override.

Every request that touched an uploaded file then raised
`InvalidStorageError: Could not find config for 'default'` and returned 500 —
while registration, login, the payment page and every static asset kept working
perfectly. Reported by the client on 2026-09-09 as "the AI is not working". The
AI was never reached.

**Nothing caught it.** The suite runs on `config.settings.dev`, which never
touches STORAGES, and the deployment's own checks — `migrate`,
`check --database default`, `collectstatic`, a 200 on `/api/health/` — all pass
with a broken file-storage config. These tests import the production module
itself, which is the only way this class of defect is visible before a user
finds it.

It lives under `apps/lessons` deliberately: the lesson upload is the request
that broke, so the test sits beside the feature whose failure it describes.
"""

from __future__ import annotations

import importlib
import os
import unittest


class ProductionSettingsAreComplete(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # `config.settings.prod` refuses to import without a complete
        # environment, which is the behaviour we want — so it is supplied here
        # rather than weakened there.
        # Assigned, not `setdefault`: the development `.env` is already loaded
        # by the time a test runs, and it carries these keys with **empty**
        # values — which `setdefault` treats as present and leaves alone, so the
        # production module then refuses to import for the right reason at the
        # wrong moment.
        os.environ["DJANGO_SECRET_KEY"] = "test-only-not-a-real-key"
        os.environ["DJANGO_ALLOWED_HOSTS"] = "example.test"
        os.environ["DATABASE_URL"] = "mysql://u:p@localhost:3306/d"
        cls.prod = importlib.import_module("config.settings.prod")

    def test_storages_keeps_the_default_backend(self):
        self.assertIn(
            "default",
            self.prod.STORAGES,
            "removing 'default' breaks every request that touches an upload and "
            "breaks nothing else — which is exactly why it survived a deploy",
        )

    def test_storages_still_serves_static_through_whitenoise(self):
        self.assertIn("staticfiles", self.prod.STORAGES)
        self.assertIn("whitenoise", self.prod.STORAGES["staticfiles"]["BACKEND"])

    def test_whitenoise_sits_directly_after_the_security_middleware(self):
        # Early enough to answer a static request before anything else works for
        # it, late enough that the security headers still apply.
        self.assertIn("whitenoise", self.prod.MIDDLEWARE[1])
        self.assertIn("SecurityMiddleware", self.prod.MIDDLEWARE[0])

    def test_debug_is_off(self):
        # With debug on, a 500 renders every key in .env to whoever caused it.
        self.assertFalse(self.prod.DEBUG)

    def test_allowed_hosts_is_never_a_wildcard(self):
        self.assertNotIn("*", self.prod.ALLOWED_HOSTS)

    def test_the_environment_is_required_rather_than_defaulted(self):
        # A production server that quietly falls back to SQLite is discovered by
        # a customer; one that will not start is discovered by whoever deployed
        # it, ten seconds later.
        with self.assertRaises(RuntimeError):
            self.prod._required("LUNIO_DEFINITELY_NOT_SET")
