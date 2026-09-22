"""Prove the mail configuration works, or say exactly why it does not.

    python manage.py check_email
    python manage.py check_email --to you@example.com

**Why this exists.** `PasswordResetRequestView` swallows every send failure on
purpose: a 500 for a real address and a 200 for an invented one answers the one
question that endpoint refuses to answer. The cost of that guarantee is that a
broken mailbox is invisible from outside — the parent sees a cheerful "check your
inbox", the caller sees 200, and the only trace is a line in a log nobody is
watching.

On 2026-09-23 that cost a full debugging cycle: the reset endpoint answered 200
on production, the settings were present (the server refuses to boot without
them), and no message arrived. Nothing reachable over HTTP could tell the
difference between "sent" and "the mail server refused us".

So the diagnosis moves to where it belongs — a command run by whoever deployed
the thing, on the machine that is failing, printing the real exception instead of
hiding it. It is not reachable over the network, so it gives an attacker nothing.

## What it checks, in the order things actually break

1. **The settings are there at all**, and SSL/TLS are not both on.
2. **The host resolves and the port opens.** This is the step that fails on a
   shared host: `mail.yourdomain.com` resolves to the server's own public IP, and
   the firewall often refuses a connection from the machine to itself on 465.
   `localhost` is the usual fix, and the error here says so.
3. **The credentials are accepted.** A mistyped password fails here, not above,
   and the two look nothing alike.
4. **A message is actually delivered** to `--to`.
"""

from __future__ import annotations

import socket
import ssl
import time

from django.conf import settings
from django.core.mail import EmailMultiAlternatives, get_connection
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = "Check that this server can actually send mail, and say why if not."

    def add_arguments(self, parser):
        parser.add_argument(
            "--to",
            default=settings.EMAIL_HOST_USER,
            help="where to send the test message (default: the sending mailbox)",
        )

    def handle(self, *args, **options):
        ok = self.style.SUCCESS
        bad = self.style.ERROR
        note = self.style.WARNING

        host = settings.EMAIL_HOST
        port = settings.EMAIL_PORT
        use_ssl = settings.EMAIL_USE_SSL
        use_tls = settings.EMAIL_USE_TLS

        self.stdout.write("")
        self.stdout.write(f"  backend   {settings.EMAIL_BACKEND}")
        self.stdout.write(f"  host      {host}:{port}")
        self.stdout.write(
            f"  security  {'implicit TLS (SSL)' if use_ssl else 'STARTTLS' if use_tls else 'NONE'}"
        )
        self.stdout.write(f"  user      {settings.EMAIL_HOST_USER}")
        self.stdout.write(
            f"  password  {len(settings.EMAIL_HOST_PASSWORD)} characters"
            if settings.EMAIL_HOST_PASSWORD
            else bad("  password  EMPTY")
        )
        self.stdout.write(f"  from      {settings.DEFAULT_FROM_EMAIL}")
        self.stdout.write("")

        # -- 1. the settings themselves -----------------------------------
        if "smtp" not in settings.EMAIL_BACKEND:
            raise CommandError(
                "this is not the SMTP backend, so nothing will ever leave the "
                "server. Production sets EMAIL_BACKEND to the smtp one."
            )
        if not host or not settings.EMAIL_HOST_PASSWORD:
            raise CommandError("EMAIL_HOST or EMAIL_HOST_PASSWORD is empty in .env")
        if use_ssl and use_tls:
            raise CommandError(
                "EMAIL_USE_SSL and EMAIL_USE_TLS cannot both be on. "
                "Port 465 is SSL=1, TLS=0. Port 587 is SSL=0, TLS=1."
            )

        # -- 2. can we even open the socket? ------------------------------
        self.stdout.write("opening the connection...")
        started = time.time()
        try:
            with socket.create_connection((host, port), timeout=10):
                pass
        except socket.gaierror as exc:
            raise CommandError(
                f"{host} does not resolve from this machine ({exc}).\n"
                "  Check the spelling, or use 'localhost'."
            ) from exc
        except (OSError, socket.timeout) as exc:
            raise CommandError(
                f"cannot reach {host}:{port} from this machine ({exc}).\n\n"
                "  This is the usual failure on shared hosting: the mail host\n"
                "  resolves to the server's own public IP, and the firewall\n"
                "  refuses the machine connecting to itself on that port.\n\n"
                "  Try in .env:\n"
                "      EMAIL_HOST=localhost\n"
                "      EMAIL_PORT=25\n"
                "      EMAIL_USE_SSL=0\n"
                "      EMAIL_USE_TLS=0\n"
                "  then restart. Mail to localhost stays inside the machine, so\n"
                "  it needs no encryption and no password."
            ) from exc
        self.stdout.write(ok(f"  connected in {time.time() - started:.2f}s"))

        # -- 3. do the credentials work? ----------------------------------
        self.stdout.write("authenticating...")
        connection = get_connection(fail_silently=False)
        try:
            connection.open()
        except ssl.SSLError as exc:
            raise CommandError(
                f"TLS failed ({exc}).\n"
                "  Port 465 wants EMAIL_USE_SSL=1; port 587 wants EMAIL_USE_TLS=1. "
                "A mismatch looks exactly like this."
            ) from exc
        except Exception as exc:
            raise CommandError(
                f"{type(exc).__name__}: {exc}\n\n"
                "  If this says authentication failed, the password in .env is\n"
                "  not the mailbox password. Note that python-dotenv reads an\n"
                "  unquoted value literally to end of line — but strips a pair\n"
                "  of surrounding quotes, which silently changes a password\n"
                "  that happens to start and end with one."
            ) from exc
        self.stdout.write(ok("  credentials accepted"))

        # -- 4. deliver something -----------------------------------------
        recipient = options["to"]
        self.stdout.write(f"sending to {recipient}...")
        message = EmailMultiAlternatives(
            subject="Lunio — mail configuration test",
            body=(
                "If you are reading this, this server can send the password "
                "reset code.\n\n"
                f"host: {host}:{port}\nfrom: {settings.DEFAULT_FROM_EMAIL}\n"
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[recipient],
            connection=connection,
        )
        try:
            sent = message.send(fail_silently=False)
        except Exception as exc:
            raise CommandError(f"the server accepted us but refused the message:\n  {exc}") from exc
        finally:
            connection.close()

        if not sent:
            raise CommandError("the backend reported nothing sent, with no error")

        self.stdout.write(ok(f"  delivered to {recipient}"))
        self.stdout.write("")
        self.stdout.write(
            note(
                "Now open that inbox. Accepting a message is not the same as\n"
                "delivering it - check it is there, and that it is not in spam."
            )
        )
