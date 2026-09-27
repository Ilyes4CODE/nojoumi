"""Prove the Chargily key works, or say exactly why it does not.

    python manage.py check_chargily

**Why this exists.** On 2026-09-27 the client pressed a plan on the payment
page and got «تعذّر بدء عملية الدفع». Nothing on the page, and nothing reachable
over HTTP, said why: the checkout view logs the gateway's refusal and shows the
parent a generic failure, which is right for the parent and useless for whoever
has to fix it.

The cause was a dead secret key. It had been pasted into a conversation on day
one, was rightly regenerated in the Chargily dashboard, and the regeneration
killed the copy in `.env`. Every checkout then reached Chargily and was refused
with `401 Unauthenticated` — a fact that took a manual probe to establish.

This is that probe, kept. Same shape as `check_email`, and for the same reason:
a failure that is invisible from outside should be one command away from
visible, run by the person who deployed it, on the machine that is failing.

## What it does, and what it deliberately does not

It calls `GET /balance`. **Read-only**: it moves no money, creates no checkout,
writes no transaction, and cannot charge anybody. It is safe to run against the
live account at any time.

It reports the four things that actually go wrong, each with a different fix:

1. the key is empty, or its prefix does not match the mode (a test key with
   `CHARGILY_LIVE_MODE=1`, or the reverse) — caught before any network call;
2. Chargily cannot be reached at all;
3. Chargily answers but refuses the key — regenerated, revoked, or mistyped;
4. the key is accepted.
"""

from __future__ import annotations

import requests
from django.core.management.base import BaseCommand, CommandError

from apps.payments import chargily


class Command(BaseCommand):
    help = "Check that the Chargily secret key is accepted. Read-only; charges nothing."

    def handle(self, *args, **options):
        ok = self.style.SUCCESS

        base = chargily.base_url()
        live = base.rstrip("/") == chargily.LIVE_BASE_URL.rstrip("/")
        self.stdout.write("")
        self.stdout.write(f"  mode      {'LIVE' if live else 'test'}")
        self.stdout.write(f"  endpoint  {base}")

        # -- 1. the key itself, before any network --------------------------
        try:
            key = chargily._secret_key()
        except chargily.ChargilyNotConfigured as exc:
            raise CommandError(f"no usable key: {exc}") from exc
        except chargily.ChargilyError as exc:
            # The mode guard: a live key in test mode or the reverse.
            raise CommandError(f"the key does not match the mode: {exc}") from exc

        self.stdout.write(f"  key       {key[:8]}...{key[-4:]} ({len(key)} characters)")
        self.stdout.write("")

        # -- 2 and 3. ask Chargily --------------------------------------------
        self.stdout.write("asking Chargily (read-only, charges nothing)...")
        try:
            response = requests.get(
                f"{base}/balance",
                headers={
                    "Authorization": f"Bearer {key}",
                    "Accept": "application/json",
                },
                timeout=20,
            )
        except requests.RequestException as exc:
            raise CommandError(
                f"could not reach Chargily at all: {exc}\n"
                "  The server has no route to the gateway — a firewall, DNS, or an "
                "outage on their side."
            ) from exc

        if response.status_code == 401:
            raise CommandError(
                "Chargily REFUSED the key (401 Unauthenticated).\n\n"
                "  The key in .env is not a valid key for this account. The usual\n"
                "  cause: it was regenerated in the Chargily dashboard, which kills\n"
                "  the old one immediately.\n\n"
                "  Fix: Chargily dashboard -> Developers corner -> API keys, copy the\n"
                "  current SECRET key into CHARGILY_SECRET_KEY in .env, then\n"
                "      touch ~/nojoumi/tmp/restart.txt\n"
                "  and run this again."
            )

        if response.status_code >= 400:
            raise CommandError(
                f"Chargily answered HTTP {response.status_code}: {response.text[:200]}"
            )

        self.stdout.write(ok("  the key is ACCEPTED."))
        self.stdout.write("")
        self.stdout.write(
            "The payment page should now start a checkout. If it still fails,\n"
            "the web process may be holding the old key — restart it:\n"
            "    touch ~/nojoumi/tmp/restart.txt"
        )
