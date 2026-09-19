"""The password-reset code: six digits, emailed, short-lived, hashed at rest.

**Why a code and not a link.** A reset link has to be opened by the app, and the
app has no deep links — no intent filter, no `assetlinks.json`, no App Links
verification. A link would therefore open a browser, which would need its own
reset page, which would need its own session handling, and the parent would end
up carrying a password between two places. A six-digit code stays inside the app,
works in every mail client ever written, and is the same errand the parent
already performs with the activation code of Article 7.3 — read a short string on
one screen, type it on another.

**Why the code is hashed.** Six digits is a million possibilities, which a laptop
exhausts in microseconds against an unsalted digest. Anyone who reads this table
would otherwise hold a live reset for every account with a code outstanding. It
goes through Django's password hasher for the same reason a password does, and
the short lifetime is a second line rather than the only one.

What actually stops guessing over the network is not the hash, it is
[`ATTEMPTS`]: five wrong tries and the code is dead, whichever endpoint burnt
them. A million possibilities and five guesses is a one-in-two-hundred-thousand
chance, and the parent simply asks for another code.
"""

from __future__ import annotations

import secrets
from datetime import timedelta

from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from django.db import models
from django.utils import timezone

#: How long a code is good for. Long enough to leave the app, open a mail client,
#: wait for delivery and come back; short enough that a code read over somebody's
#: shoulder is usually already worthless.
LIFETIME = timedelta(minutes=15)

#: Wrong guesses before the code is destroyed.
ATTEMPTS = 5

#: The shortest gap between two codes for one account.
#:
#: Without it, anyone who knows a parent's address can empty a hundred messages
#: into their inbox by tapping a button, and the parent cannot tell which code is
#: current. Inside the window the server answers exactly as it does outside it —
#: the caller is never told whether a message was actually sent.
COOLDOWN = timedelta(seconds=60)


def _mint() -> str:
    """A uniformly random six-digit string, leading zeros kept.

    `secrets`, not `random`: the latter's Mersenne Twister can be reconstructed
    from a handful of outputs, and the outputs here are mailed to people.
    """
    return f"{secrets.randbelow(1_000_000):06d}"


class PasswordResetCode(models.Model):
    """One issued code. Rows are kept after use as a short audit trail."""

    parent = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="password_reset_codes",
    )
    code_hash = models.CharField(max_length=256, editable=False)
    created_at = models.DateTimeField(default=timezone.now, editable=False)
    expires_at = models.DateTimeField(editable=False)
    attempts = models.PositiveSmallIntegerField(default=0)
    used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "password reset code"
        verbose_name_plural = "password reset codes"
        indexes = [models.Index(fields=["parent", "-created_at"])]

    def __str__(self) -> str:
        return f"reset for {self.parent_id} at {self.created_at:%Y-%m-%d %H:%M}"

    # -- state ------------------------------------------------------------

    @property
    def is_live(self) -> bool:
        return (
            self.used_at is None
            and self.attempts < ATTEMPTS
            and timezone.now() < self.expires_at
        )

    def matches(self, code: str) -> bool:
        """Check a typed code, spending one attempt whether or not it is right.

        The attempt is spent **before** the comparison and saved either way. A
        counter that only advances on failure can be sidestepped by a client that
        hangs up mid-request, and the difference is the whole protection.
        """
        if not self.is_live:
            return False

        self.attempts += 1
        self.save(update_fields=["attempts"])
        return check_password(code, self.code_hash)


def issue(parent) -> str | None:
    """Mint a code for `parent`, or return None if one was just sent.

    Any earlier unused code is retired in the same breath, so a parent holding
    two messages can only succeed with the newer one — which is the one they will
    reach for anyway.
    """
    now = timezone.now()
    live = PasswordResetCode.objects.filter(parent=parent, used_at__isnull=True)

    if live.filter(created_at__gt=now - COOLDOWN).exists():
        return None

    # Retired rather than deleted: the row is what shows, later, that a reset was
    # attempted at all.
    live.update(used_at=now)

    code = _mint()
    PasswordResetCode.objects.create(
        parent=parent,
        code_hash=make_password(code),
        created_at=now,
        expires_at=now + LIFETIME,
    )
    return code


def redeem(parent, code: str) -> PasswordResetCode | None:
    """The newest live code for `parent` if `code` matches it, else None."""
    newest = (
        PasswordResetCode.objects.filter(parent=parent, used_at__isnull=True)
        .order_by("-created_at")
        .first()
    )
    if newest is None or not newest.matches(code):
        return None
    return newest
