"""Email the parent when Lunio stops checking in from their child's phone.

    python manage.py alert_silent_devices
    python manage.py alert_silent_devices --dry-run

Run by cron every hour (see `docs/deploy-cpanel.md`). Client request,
2026-09-27: a parent should learn when the child deletes the app. An app may not
prevent its own removal — Play Protect blocked the whole app for trying (D-96) —
but the server can notice a phone going quiet, and that is allowed everywhere.

## Who gets an email

A device qualifies when **all** of these hold:

* it has sent at least one heartbeat — `heartbeat_at` is set. Silence from a
  device that never spoke means nothing: every install from before this feature,
  and any older build still in use, has no heartbeat and is never reported. This
  is the condition that stops the first run after deploy emailing every parent
  in the system;
* its last heartbeat is older than [SILENCE] — forty-eight hours, against a
  worker that pings every six, so eight missed pings in a row. ColorOS and its
  kin delay background work aggressively; the margin is for them;
* it has not already been reported for this silence;
* it has a parent to tell.

Every account bound to the phone is told — up to three (D-94's household rule).
The subscription follows the device; so does this.

## Idempotent, and it retries

Running it twice sends nothing twice: a device is marked reported as soon as its
email goes out. If the send **fails**, the device is not marked, so the next run
an hour later tries again instead of the parent never hearing.
"""

from __future__ import annotations

from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.accounts import mailer
from apps.devices.models import Install

#: How long a phone may be quiet before its parent is told.
SILENCE = timedelta(hours=48)


class Command(BaseCommand):
    help = "Email parents whose child's phone has stopped checking in."

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="list who would be emailed, and send nothing",
        )

    def handle(self, *args, dry_run: bool = False, **options):
        now = timezone.now()

        silent = (
            Install.objects.filter(
                heartbeat_at__isnull=False,
                heartbeat_at__lt=now - SILENCE,
                silence_alerted_at__isnull=True,
            )
            .select_related("parent")
            .prefetch_related("accounts__parent")
        )

        reported = failed = 0
        for install in silent:
            parents = _parents_of(install)
            if not parents:
                continue

            if dry_run:
                for parent in parents:
                    self.stdout.write(
                        f"would email {parent.email} — install {install.pk} "
                        f"quiet since {install.heartbeat_at:%Y-%m-%d %H:%M}"
                    )
                continue

            try:
                for parent in parents:
                    mailer.send_device_silent(parent, last_heard=install.heartbeat_at)
            except Exception as exc:
                failed += 1
                # Not marked, on purpose: the next run tries again.
                self.stderr.write(f"could not alert for install {install.pk}: {exc}")
                continue

            # Marked with a conditional update, so a heartbeat that landed while
            # the email was going out is not overwritten — that phone is back.
            Install.objects.filter(
                pk=install.pk, heartbeat_at=install.heartbeat_at
            ).update(silence_alerted_at=now)
            reported += 1

        if not dry_run:
            self.stdout.write(f"reported {reported} silent device(s), {failed} failed")


def _parents_of(install):
    """Every account bound to this phone, deduplicated, first binding first."""
    seen: dict[int, object] = {}
    for binding in install.accounts.all():
        seen.setdefault(binding.parent_id, binding.parent)
    if install.parent_id is not None:
        seen.setdefault(install.parent_id, install.parent)
    return [p for p in seen.values() if getattr(p, "is_active", True)]
