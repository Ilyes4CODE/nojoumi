"""Chargily adapter — **deliberately incomplete**.

CLAUDE.md: "Chargily has thin public documentation. Never write Chargily code
from memory. Ask the developer to paste the current docs."

So this module defines the *shape* of the integration and leaves every
Chargily-specific fact as an explicit hole. Everything around it — transaction
records, webhook idempotency, replay rejection, activation-code issuing — is
built and tested, because none of that depends on Chargily's specifics.

What is still needed from the client (Art. 7.8, due before Phase 6):

  1. Test-mode and live-mode API keys.
  2. The checkout-creation endpoint: URL, request fields, response fields.
  3. The webhook **signature header name and algorithm** (HMAC-SHA256 over the
     raw body is the usual shape, but "usual" is not "verified").
  4. The exact status vocabulary, so `STATUS_MAP` can be filled in.
  5. Whether the event payload carries a stable unique event id, and its field
     name. Without one, idempotency has to hash the body instead — workable, but
     weaker, and worth knowing in advance.

Until items 3 and 5 are answered, `verify_signature` refuses everything. That is
the correct failure mode: an unverified webhook must never activate a
subscription (Art. 7.3).
"""

from __future__ import annotations

import hashlib

from .models import TransactionStatus


class ChargilyNotConfigured(RuntimeError):
    """Raised where a Chargily specific is required but not yet documented."""


# Fill in from the current documentation. Left empty on purpose: a guessed
# mapping would silently mark a failed payment as paid.
STATUS_MAP: dict[str, str] = {
    # "paid": TransactionStatus.PAID,
    # "failed": TransactionStatus.FAILED,
    # "canceled": TransactionStatus.CANCELED,
}


def map_status(gateway_status: str) -> str:
    """Translate a gateway status into ours, or refuse."""
    try:
        return STATUS_MAP[gateway_status]
    except KeyError as exc:
        raise ChargilyNotConfigured(
            f"unmapped Chargily status {gateway_status!r}. Fill STATUS_MAP from "
            "the current documentation rather than guessing — mapping an unknown "
            "status to PAID would activate a subscription that was never paid."
        ) from exc


def body_digest(raw_body: bytes) -> str:
    """SHA-256 of the raw body. Stored instead of the body itself (Art. 7.7)."""
    return hashlib.sha256(raw_body).hexdigest()


def extract_event_id(raw_body: bytes, headers) -> str:
    """The gateway's unique event id, used for idempotency.

    Falls back to the body digest, which still blocks a byte-identical replay —
    the common case for a gateway retry — but cannot distinguish two genuinely
    distinct events that happen to serialise identically. Replace with the real
    field once documented.
    """
    return body_digest(raw_body)


def verify_signature(raw_body: bytes, headers) -> bool:
    """Verify the webhook signature.

    Returns False until the header name and algorithm are supplied. Article 7.3
    requires rejecting any unsigned notification, so "not yet implemented" must
    mean "rejected", never "accepted".
    """
    return False
