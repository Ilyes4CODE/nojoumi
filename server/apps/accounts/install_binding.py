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


#: How many parent accounts may sign in on one phone.
#:
#: One, by the client's request of 2026-08-28. **Three** from 2026-09-25, at
#: their request, for a household where more than one adult uses the same phone.
#: The subscription follows the *device* rather than any of the accounts, so the
#: second and third parents see what the first one paid for — see
#: `subscriptions.services.current_subscription`.
#:
#: Still not a security boundary, for exactly the reason in this module's
#: docstring: clearing the app's data mints a new UUID and a fresh device. Three
#: is a number about households, not about attackers.
MAX_ACCOUNTS_PER_INSTALL = 3


def bind(*, install_id, parent, android_release="", device_model="", app_version=""):
    """Record that [parent] uses [install_id], or raise if the phone is full.

    Idempotent for an account already bound, because the app sends its install id
    on every sign-in and a parent signing in again on their own phone is the
    ordinary case, not a violation.
    """
    from apps.devices.models import InstallAccount

    install, _ = Install.objects.get_or_create(id=install_id)

    _, created = InstallAccount.objects.get_or_create(install=install, parent=parent)
    if created and install.accounts.count() > MAX_ACCOUNTS_PER_INSTALL:
        # Undone rather than guarded by a prior count: two sign-ins racing would
        # both read "two bound" and both insert. Inserting first and checking
        # after makes the database the arbiter, which is the only one that can be.
        InstallAccount.objects.filter(install=install, parent=parent).delete()
        raise InstallAlreadyClaimed(
            f"هذا الهاتف مرتبط بـ{MAX_ACCOUNTS_PER_INSTALL} حسابات بالفعل. "
            "سجّل الدخول بأحدها، أو احذف بيانات التطبيق للبدء من جديد."
        )

    # `Install.parent` stays the **first** account bound to the phone: the trial,
    # the activation code and every existing query already read it, and widening
    # its meaning would rewrite semantics in code that works.
    if install.parent_id is None:
        install.parent = parent
    # Content-free diagnostics (Art. 18): enough to reason about an OEM-specific
    # failure report, and nothing that describes a person.
    install.android_release = android_release or install.android_release
    install.device_model = device_model or install.device_model
    install.app_version = app_version or install.app_version
    install.save()
    return install
