"""The heartbeat, and the email a parent gets when their child's phone goes quiet.

Client request, 2026-09-27: a parent should learn when the child deletes Lunio.
Preventing removal got the whole app blocked by Play Protect (D-96); noticing it
from the server is allowed everywhere, and this is that.

Two failures matter and they pull against each other. **A false alarm** — a flat
battery reported as a deletion — teaches the parent to ignore the next one, so
the true alarm is wasted. **A mass false alarm** is worse: the first run after
deploy, if it counted every existing phone as silent, would email every parent
in the system at once. The first class below exists for that one.
"""

from __future__ import annotations

import uuid
from datetime import timedelta
from io import StringIO
from unittest import mock

from django.contrib.auth import get_user_model
from django.core import mail
from django.core.cache import cache
from django.core.management import call_command
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone

from apps.accounts import install_binding, mailer
from apps.devices.management.commands.alert_silent_devices import SILENCE
from apps.devices.models import Install

ParentUser = get_user_model()
HEARTBEAT = reverse("devices:heartbeat")


def a_parent(n: int = 0):
    return ParentUser.objects.create_user(email=f"wali{n}@bayt.dz", password="n7-Sabah-Khayr-2026")


def bound_install(*parents, heartbeat_ago=None):
    install = Install.objects.create(id=uuid.uuid4())
    for parent in parents:
        install_binding.bind(install_id=install.id, parent=parent)
    if heartbeat_ago is not None:
        Install.objects.filter(pk=install.pk).update(
            heartbeat_at=timezone.now() - heartbeat_ago
        )
    install.refresh_from_db()
    return install


def run(*args):
    out = StringIO()
    call_command("alert_silent_devices", *args, stdout=out, stderr=StringIO())
    return out.getvalue()


class DeployDayDoesNotEmailEveryone(TestCase):
    """The failure that would have been worst, and would have happened first."""

    def test_devices_that_never_sent_a_heartbeat_are_never_reported(self):
        # Every install from before this feature — and any older build still in
        # use — has no heartbeat. Their `last_seen_at` is weeks old. Reporting
        # them would email every parent on the day this ships.
        for n in range(5):
            install = bound_install(a_parent(n))
            Install.objects.filter(pk=install.pk).update(
                last_seen_at=timezone.now() - timedelta(days=60)
            )

        run()

        self.assertEqual(mail.outbox, [])


class TheHeartbeat(TestCase):
    def setUp(self):
        cache.clear()

    def post(self, install_id):
        return self.client.post(
            HEARTBEAT, {"install_id": str(install_id)}, content_type="application/json"
        )

    def test_it_records_that_the_phone_is_alive(self):
        install = bound_install(a_parent())
        self.assertEqual(self.post(install.id).status_code, 204)

        install.refresh_from_db()
        self.assertIsNotNone(install.heartbeat_at)

    def test_it_ends_a_reported_silence(self):
        # So a phone that comes back and later goes quiet again is reported again.
        install = bound_install(a_parent(), heartbeat_ago=SILENCE * 2)
        Install.objects.filter(pk=install.pk).update(silence_alerted_at=timezone.now())

        self.post(install.id)

        install.refresh_from_db()
        self.assertIsNone(install.silence_alerted_at)

    def test_it_never_creates_an_install(self):
        # Otherwise any caller could fill the table by inventing UUIDs.
        stranger = uuid.uuid4()
        self.assertEqual(self.post(stranger).status_code, 204)
        self.assertFalse(Install.objects.filter(pk=stranger).exists())

    def test_a_malformed_id_is_still_204(self):
        # A background job has nobody to show an error to, and a different
        # answer would only give a prober something to measure.
        response = self.client.post(
            HEARTBEAT, {"install_id": "not-a-uuid"}, content_type="application/json"
        )
        self.assertEqual(response.status_code, 204)

    def test_it_does_not_move_last_seen(self):
        # `last_seen_at` means "last real activity". A background ping is not
        # activity, and letting it move that field would erase the difference.
        install = bound_install(a_parent())
        before = timezone.now() - timedelta(days=3)
        Install.objects.filter(pk=install.pk).update(last_seen_at=before)

        self.post(install.id)

        install.refresh_from_db()
        self.assertEqual(install.last_seen_at, before)

    def test_it_needs_no_login(self):
        # The worker runs for weeks; access tokens last five minutes. A heartbeat
        # that needed one would stop — and start raising false alarms — the
        # moment the parent's session aged out.
        install = bound_install(a_parent())
        # No Authorization header at all — the test client sends none.
        self.assertEqual(self.post(install.id).status_code, 204)


class WhoIsTold(TestCase):
    def test_a_phone_quiet_past_the_threshold_is_reported(self):
        install = bound_install(a_parent(), heartbeat_ago=SILENCE + timedelta(hours=1))

        run()

        self.assertEqual(len(mail.outbox), 1)
        self.assertEqual(mail.outbox[0].to, ["wali0@bayt.dz"])
        install.refresh_from_db()
        self.assertIsNotNone(install.silence_alerted_at)

    def test_a_phone_quiet_for_less_is_left_alone(self):
        # Six-hourly pings, forty-eight hours of margin: eight missed in a row
        # before anyone is told, because some OEMs delay background work hard.
        bound_install(a_parent(), heartbeat_ago=SILENCE - timedelta(hours=1))
        run()
        self.assertEqual(mail.outbox, [])

    def test_one_silence_is_one_email(self):
        # The job runs hourly. Without the mark a parent would get an email every
        # hour for as long as the phone stayed off.
        bound_install(a_parent(), heartbeat_ago=SILENCE * 2)
        run()
        run()
        run()
        self.assertEqual(len(mail.outbox), 1)

    def test_every_parent_on_the_phone_is_told(self):
        # Up to three accounts per phone (D-94); the subscription follows the
        # device, and so does this.
        bound_install(a_parent(0), a_parent(1), a_parent(2), heartbeat_ago=SILENCE * 2)
        run()
        self.assertEqual(
            sorted(m.to[0] for m in mail.outbox),
            ["wali0@bayt.dz", "wali1@bayt.dz", "wali2@bayt.dz"],
        )

    def test_a_phone_with_no_parent_is_skipped(self):
        install = Install.objects.create(id=uuid.uuid4())
        Install.objects.filter(pk=install.pk).update(
            heartbeat_at=timezone.now() - SILENCE * 2
        )
        run()
        self.assertEqual(mail.outbox, [])

    def test_a_failed_send_is_retried_next_run(self):
        # Marked only when the email actually went out. Otherwise one transient
        # SMTP failure would mean the parent never hears.
        install = bound_install(a_parent(), heartbeat_ago=SILENCE * 2)

        with mock.patch.object(mailer, "send_device_silent", side_effect=OSError("smtp down")):
            run()
        install.refresh_from_db()
        self.assertIsNone(install.silence_alerted_at)

        run()
        self.assertEqual(len(mail.outbox), 1)

    def test_a_dry_run_sends_nothing(self):
        bound_install(a_parent(), heartbeat_ago=SILENCE * 2)
        output = run("--dry-run")
        self.assertIn("would email wali0@bayt.dz", output)
        self.assertEqual(mail.outbox, [])


class TheMessage(TestCase):
    def test_it_says_may_and_says_it_will_not_repeat(self):
        # A flat battery looks exactly like a deletion. A message that claimed
        # certainty would be wrong often enough to be ignored.
        bound_install(a_parent(), heartbeat_ago=SILENCE * 2)
        run()

        html = mail.outbox[0].alternatives[0][0]
        self.assertIn("قد يعني هذا", html)
        self.assertIn("مطفأ أو بلا إنترنت", html)
        self.assertIn("لن نرسل غيرها", html)
        self.assertIn('dir="rtl"', html)
        self.assertIn('bgcolor="#FFFFFF"', html)
        self.assertTrue(mail.outbox[0].body.strip())
