"""The parent account. The only person the server knows about.

Article 14 draws the line: the server holds the **parent**, never the child.
There is no child name here, no age, no photo, no location, no progress, no
stars. If a future feature seems to need any of that server-side, the feature is
wrong (AD-6).

Identity is an email address. The contract does not settle this — Art. 7.3 says
the activation code is "displayed on the page and sent to them" without naming a
channel (open question Q17). Email is the safe default: it needs no SMS gateway,
no per-message cost, and no phone-verification flow, none of which are in scope.
`phone` is optional and exists only so the client can deliver an activation code
by SMS if they later choose to; see docs/decisions.md D-25.
"""

from __future__ import annotations

from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone

# Django discovers models by importing `<app>.models` and nothing else, so a
# model declared in a sibling module is invisible to `makemigrations` until this
# line exists. It lives in its own file because a reset code is a mechanism with
# rules — a lifetime, an attempt budget, a cooldown — and those rules belong next
# to the table they constrain rather than buried under the account.
from .reset_codes import PasswordResetCode  # noqa: F401  (registers the model)


class ParentUserManager(BaseUserManager):
    """Email-based manager. There is no username."""

    use_in_migrations = True

    def _create(self, email: str, password: str | None, **extra):
        if not email:
            raise ValueError("email is required")
        user = self.model(email=normalised_email(email), **extra)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email: str, password: str | None = None, **extra):
        extra.setdefault("is_staff", False)
        extra.setdefault("is_superuser", False)
        return self._create(email, password, **extra)

    def create_superuser(self, email: str, password: str | None = None, **extra):
        extra.setdefault("is_staff", True)
        extra.setdefault("is_superuser", True)
        return self._create(email, password, **extra)

    def get_by_natural_key(self, username: str):
        """The account for an address, however the parent happened to type it.

        Every address is stored lowercased by `_create`, so lowercasing the input
        here makes the comparison exact — and an exact comparison on a unique
        column is a single index lookup (`SEARCH ... USING INDEX (email=?)`),
        the same cost at ten parents as at a million.

        Django's default compares the input **as typed**. With storage lowercased
        that meant a parent who typed `Wali@...` could reset their password —
        the reset path lowercases — and then fail to sign in with the very
        address they had just used, told the password was wrong a second after
        setting it.
        """
        return self.get(email=normalised_email(username))


def normalised_email(value: str) -> str:
    """How an address is stored, and therefore how it must be looked up.

    One function for both, so the two can never drift: an address normalised
    one way on the way in and another on the way out is an account nobody can
    find.
    """
    return (value or "").strip().lower()


class ParentUser(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)

    # Optional, and only for activation-code delivery if the client picks SMS.
    # Never required, never used for authentication.
    phone = models.CharField(max_length=32, blank=True)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(default=timezone.now)

    objects = ParentUserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS: list[str] = []

    class Meta:
        verbose_name = "parent"
        verbose_name_plural = "parents"

    def __str__(self) -> str:
        return self.email
