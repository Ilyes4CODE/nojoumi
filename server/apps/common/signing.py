"""Ed25519 signing of the subscription snapshot.

Article 7.6: "يحتفظ التطبيق بنسخة **موقّعة رقمياً** تسمح له بالعمل دون اتصال
بالإنترنت لمدة 7 أيام" — the device's local copy is a *signed* cache, so the
device can verify what the server said without being able to forge it.

The split that makes this work:
  * the **private** key exists only in the server's environment;
  * the **public** key is embedded in the Android app;
  * so a child who edits the local database produces a snapshot that fails
    verification, and `nojoumi_subscription` treats an unverified snapshot as no
    subscription at all (free mode — blocking and stars keep working).

Canonicalisation matters as much as the algorithm: both sides must hash exactly
the same bytes. `canonical_bytes` is the contract for that, and it is boringly
strict on purpose — sorted keys, no whitespace, UTF-8, no non-ASCII escaping.
"""

from __future__ import annotations

import json

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives.asymmetric.ed25519 import (
    Ed25519PrivateKey,
    Ed25519PublicKey,
)
from django.conf import settings
from django.core.exceptions import ImproperlyConfigured


def canonical_bytes(payload: dict) -> bytes:
    """The exact bytes that get signed and verified.

    Any change here is a breaking protocol change: already-installed apps hold
    the old rule and would start rejecting valid snapshots. Version the payload
    instead of editing this function.
    """
    return json.dumps(
        payload,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")


def _private_key() -> Ed25519PrivateKey:
    raw = (settings.SUBSCRIPTION_SIGNING_KEY_HEX or "").strip()
    if not raw:
        raise ImproperlyConfigured(
            "SUBSCRIPTION_SIGNING_KEY_HEX is not set. Generate one with "
            "`python manage.py generate_signing_key` and put it in .env — "
            "Art. 7.6 requires the local subscription copy to be signed."
        )
    try:
        return Ed25519PrivateKey.from_private_bytes(bytes.fromhex(raw))
    except ValueError as exc:
        raise ImproperlyConfigured(
            "SUBSCRIPTION_SIGNING_KEY_HEX must be 32 bytes of hex (64 chars)"
        ) from exc


def public_key_hex() -> str:
    """The value that gets embedded in the Android app."""
    from cryptography.hazmat.primitives import serialization

    return (
        _private_key()
        .public_key()
        .public_bytes(
            encoding=serialization.Encoding.Raw,
            format=serialization.PublicFormat.Raw,
        )
        .hex()
    )


def sign_payload(payload: dict) -> str:
    """Sign a snapshot payload, returning a hex signature."""
    return _private_key().sign(canonical_bytes(payload)).hex()


def verify_payload(payload: dict, signature_hex: str, public_hex: str) -> bool:
    """Verify, the way the Android app will. Used by the tests as the app's proxy."""
    try:
        key = Ed25519PublicKey.from_public_bytes(bytes.fromhex(public_hex))
        key.verify(bytes.fromhex(signature_hex), canonical_bytes(payload))
    except (InvalidSignature, ValueError):
        return False
    return True
