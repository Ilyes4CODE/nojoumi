"""Deleting a parent account, from the app or from the web page.

**Google Play requires both routes** for any app that lets people create an
account: a button inside the app, and a web page that works without it (for a
parent who has already uninstalled). Both end here, so the two cannot drift
into deleting different things.

## What goes, and what stays

Deleted with the account, by the foreign keys' own CASCADE:

- the email address, the phone number and the password hash;
- every subscription — **a paid period still running is lost**, and both
  routes say so before the parent confirms;
- the phone bindings (`InstallAccount`) and any password-reset codes.

Kept, detached from any person by SET_NULL:

- **payment records** (`Transaction`): amount, plan, status, dates and the
  gateway's id. They carry no name, email or card data (Art. 7.7), and they are
  the accounting trail of money actually received;
- the **install row** (`Install`): a random id that is not derived from the
  phone. It still remembers that this phone had its trial, which is the one rule
  Article 7.1 puts on the device rather than the account. Deleting it would hand
  out a fresh trial to anyone who deletes and re-registers.

There is nothing about the child to delete: the server never had any (Art. 14).
"""

from __future__ import annotations

import logging

from django.db import transaction

log = logging.getLogger("lunio.accounts")


def delete_account(user) -> None:
    """Delete `user` and everything that cascades from it, in one transaction."""
    user_id = user.pk
    with transaction.atomic():
        user.delete()
    # The id and nothing else: logging the address of someone who just asked to
    # be forgotten would keep the one thing they asked us to remove.
    log.info("account %s deleted at the parent's request", user_id)
