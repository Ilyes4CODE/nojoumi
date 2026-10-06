"""The health check must notice a missed `migrate`.

Twice, new code reached the server without its migration. Both times the site
stayed up, `/api/health/` answered "ok", and every sign-in from the app returned
500 — the app sends its device id, and the device table no longer matched the
code. The second time, a parent who had just reset their password saw only
«تعذّر تسجيل الدخول», and the reset itself looked broken.
"""

from __future__ import annotations

from unittest import mock

from django.test import TestCase
from django.urls import reverse


class TheHealthCheck(TestCase):
    def get(self):
        return self.client.get(reverse("common:health")).json()

    def test_a_migrated_server_is_ok(self):
        body = self.get()
        self.assertEqual(body["status"], "ok")
        self.assertEqual(body["migrations_pending"], 0)

    def test_a_missed_migrate_shows_up_as_degraded(self):
        # The plan is faked rather than a migration being un-applied: rolling a
        # real migration back mid-test would leave the test database in a state
        # the next test does not expect.
        with mock.patch(
            "django.db.migrations.executor.MigrationExecutor.migration_plan",
            return_value=[("devices", "0004"), ("devices", "0005")],
        ):
            body = self.get()

        self.assertEqual(body["status"], "degraded")
        self.assertEqual(body["migrations_pending"], 2)

    def test_it_publishes_a_count_and_never_the_names(self):
        # Migration names describe the schema; an unauthenticated probe has no
        # business publishing that.
        with mock.patch(
            "django.db.migrations.executor.MigrationExecutor.migration_plan",
            return_value=[("devices", "0004_install_heartbeat_at")],
        ):
            raw = self.client.get(reverse("common:health")).content.decode()
        self.assertNotIn("heartbeat", raw)
        self.assertNotIn("devices", raw)
