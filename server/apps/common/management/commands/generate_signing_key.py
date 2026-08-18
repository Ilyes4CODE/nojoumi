"""Generate the Ed25519 keypair for subscription snapshots (Art. 7.6).

    python manage.py generate_signing_key

The private half goes in `server/.env` and never leaves the server. The public
half is embedded in the Android app, which is what lets the device verify a
cached snapshot offline without being able to forge one.
"""

from __future__ import annotations

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Generate an Ed25519 keypair for signing subscription snapshots"

    def handle(self, *args, **options):
        private = Ed25519PrivateKey.generate()
        private_hex = private.private_bytes(
            encoding=serialization.Encoding.Raw,
            format=serialization.PrivateFormat.Raw,
            encryption_algorithm=serialization.NoEncryption(),
        ).hex()
        public_hex = (
            private.public_key()
            .public_bytes(
                encoding=serialization.Encoding.Raw,
                format=serialization.PublicFormat.Raw,
            )
            .hex()
        )

        self.stdout.write("")
        self.stdout.write(self.style.WARNING("--- server/.env (SECRET, never commit) ---"))
        self.stdout.write(f"SUBSCRIPTION_SIGNING_KEY_HEX={private_hex}")
        self.stdout.write("")
        self.stdout.write(self.style.SUCCESS("--- embed this in the Android app ---"))
        self.stdout.write(f"subscriptionPublicKeyHex = \"{public_hex}\"")
        self.stdout.write("")
        self.stdout.write(
            "Rotating this key invalidates every cached snapshot on every device, "
            "so they all fall back to free mode until they next reach the server. "
            "Blocking and stars keep working throughout (Art. 7.1)."
        )
