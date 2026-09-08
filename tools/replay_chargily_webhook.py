"""Post a correctly signed Chargily webhook at the local server.

**Why this exists.** Article 11.7 asks for a complete test-mode Chargily payment
through to in-app activation. The real gateway calls our webhook over the public
internet, which needs a reachable HTTPS URL — open question Q19, and a tunnel on
the developer's machine until the client's VPS exists (Art. 19 only commits them
to one before Phase 7).

Everything *except* that last hop can be exercised locally, and this script is the
last hop: it takes a checkout id the real Chargily test API returned, wraps it in
the documented event envelope, signs it with the same secret key the gateway
would use, and posts it. What that proves is the half we own — signature
verification, status mapping, idempotency, activation-code issue. What it cannot
prove is that Chargily's servers can reach ours, which only a tunnel or the VPS
can settle.

It is a **development tool and nothing more**. It holds no key of its own: the
secret is read from `server/.env`, the same file the server reads, so this script
can never sign anything the server would not have accepted anyway.

    python tools/replay_chargily_webhook.py --checkout-id 01k... --status paid

Run it from the repository root, with the dev server already running.
"""

from __future__ import annotations

import argparse
import hashlib
import hmac
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENV = ROOT / "server" / ".env"


def secret_key() -> str:
    """Read CHARGILY_SECRET_KEY from server/.env.

    Deliberately not from the environment and not from a flag: a key on a command
    line lands in the shell history, and this is the one value in the project that
    Article 7.7 puts entirely off limits outside `.env`.
    """
    if not ENV.exists():
        sys.exit(f"no {ENV} — copy .env.example and fill in the test keys")

    for line in ENV.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("CHARGILY_SECRET_KEY=") and not line.startswith("#"):
            value = line.split("=", 1)[1].strip()
            if value:
                return value
    sys.exit("CHARGILY_SECRET_KEY is empty in server/.env")


def envelope(checkout_id: str, status: str, plan: str, amount: int) -> dict:
    """The documented event shape: {id, entity, livemode, type, data, ...}.

    The event `id` and the checkout `id` are different things, and an earlier
    draft of the webhook read the status from the root — which found nothing and
    mapped an empty string. The shape below is the one that caught that.
    """
    return {
        "id": f"evt_replay_{checkout_id}",
        "entity": "event",
        "livemode": False,
        "type": "checkout.paid" if status == "paid" else f"checkout.{status}",
        "data": {
            "id": checkout_id,
            "entity": "checkout",
            "amount": amount,
            "currency": "dzd",
            "status": status,
            "metadata": [{"plan": plan}],
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--checkout-id",
        required=True,
        help="the id returned by POST /api/payments/checkout/",
    )
    parser.add_argument(
        "--status",
        default="paid",
        choices=["paid", "failed", "canceled", "expired", "processing"],
        help="the checkout status to report (default: paid)",
    )
    parser.add_argument("--plan", default="monthly", choices=["monthly", "annual"])
    parser.add_argument("--amount", type=int, default=1000)
    parser.add_argument(
        "--url",
        default="http://127.0.0.1:8000/api/payments/webhook/chargily/",
    )
    parser.add_argument(
        "--break-signature",
        action="store_true",
        help="send a wrong signature on purpose; the server must answer 400",
    )
    args = parser.parse_args()

    # Signed over the exact bytes that are sent. Re-serialising between signing
    # and sending would change the bytes and invalidate the signature — which is
    # the single most common way to get this wrong.
    body = json.dumps(
        envelope(args.checkout_id, args.status, args.plan, args.amount)
    ).encode("utf-8")

    signature = hmac.new(
        secret_key().encode("utf-8"), body, hashlib.sha256
    ).hexdigest()
    if args.break_signature:
        signature = "0" * len(signature)

    request = urllib.request.Request(
        args.url,
        data=body,
        headers={"Content-Type": "application/json", "signature": signature},
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            print(response.status, response.read().decode("utf-8", "replace"))
    except urllib.error.HTTPError as exc:
        # A 400 here is a pass when --break-signature was used, and a failure
        # otherwise. The script prints and does not judge.
        print(exc.code, exc.read().decode("utf-8", "replace"))
    except urllib.error.URLError as exc:
        sys.exit(f"cannot reach {args.url}: {exc.reason} — is the dev server up?")


if __name__ == "__main__":
    main()
