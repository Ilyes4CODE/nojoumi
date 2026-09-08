"""One account per device — Article 7.1's device rule, applied to accounts.

**Client request, 2026-08-28: a phone may hold one parent account and no more.**

The contract already binds the *trial* to a device rather than to an account, in
Article 7.1's «مرة واحدة لكل جهاز», and for a stated reason: otherwise a new email
address resets the seven free days. This module extends the same anchor — the
install UUID the app generates at first launch — to the account itself.

**What it is anchored to, and what it is deliberately not.** The identifier is a
random UUID stored in the app's own database (`apps/devices/models.py` has the
full reasoning). Not an advertising ID, which the Designed for Families programme
forbids; not IMEI, serial or MAC, which identify a person's hardware and are
unavailable to ordinary apps anyway; not anything derived from the child
(Art. 14).

**The accepted limitation is the same one Article 7.1 already accepts.** Clearing
the app's data or reinstalling produces a new UUID, and therefore a fresh device
as far as the server is concerned. Closing that hole needs a persistent hardware
identifier, which is exactly what Play policy and Article 14 forbid. So this is a
rule against casual account-swapping on a shared family phone — which is what was
asked for — and not a security boundary. It should never be described to the
client as the latter.
"""

from __future__ import annotations

from apps.devices.models import Install


class InstallAlreadyClaimed(Exception):
    """This device is already bound to a different parent account."""


def bind(*, install_id, parent, android_release="", device_model="", app_version=""):
    """Claim [install_id] for [parent], or raise if somebody else holds it.

    Idempotent for the account that already owns the install, because the app
    sends its install id on every sign-in and a parent signing in again on their
    own phone is the ordinary case, not a violation.
    """
    install, _ = Install.objects.get_or_create(id=install_id)

    if install.parent_id is not None and install.parent_id != parent.pk:
        raise InstallAlreadyClaimed(
            "هذا الهاتف مرتبط بحساب آخر. سجّل الدخول بالحساب نفسه، "
            "أو احذف بيانات التطبيق للبدء من جديد."
        )

    install.parent = parent
    # Content-free diagnostics (Art. 18): enough to reason about an OEM-specific
    # failure report, and nothing that describes a person.
    install.android_release = android_release or install.android_release
    install.device_model = device_model or install.device_model
    install.app_version = app_version or install.app_version
    install.save()
    return install
