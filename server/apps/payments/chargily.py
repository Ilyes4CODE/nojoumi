"""Chargily Pay v2 adapter.

**Nothing here is written from memory.** docs/CONVENTIONS.md forbids that for this gateway,
and every fact below was fetched from `dev.chargily.com` on **2026-08-18** and is
quoted in `docs/decisions.md` D-35 with its source URL. Re-verify before the
Phase 7 delivery; a payment gateway is exactly the kind of API that changes a
field name between minor releases.

What was verified, and what it decides here:

* **Base URLs.** Test `https://pay.chargily.net/test/api/v2`, live
  `https://pay.chargily.net/api/v2`. Which one is in use is a settings value, not
  a constant, because shipping the test URL is a silent catastrophe and shipping
  the live one during development is a noisy one.
* **Auth.** `Authorization: Bearer <secret key>`.
* **Webhook signature.** Header **`signature`**, HMAC-SHA256 of the **raw request
  body**, hex-encoded, keyed with the API secret key.
* **Webhook envelope.** Root fields `id, entity, livemode, type, data,
  created_at, updated_at`. The event id is the root `id`; the checkout is in
  `data`.
* **Checkout status.** "Can be one of": `pending`, `processing`, `paid`,
  `failed`, `canceled`. That is the complete published list, so [STATUS_MAP] is
  exhaustive and anything else is refused rather than guessed at.

**What is still not established, and is handled by refusing:** the documentation
shows `checkout.paid`, `checkout.failed` and `checkout.canceled` but does *not*
claim the list is complete. So the decision is taken from `data.status`, which is
documented exhaustively, and `type` is only used to confirm the event concerns a
checkout at all. An event about anything else is recorded and ignored.

Article 7.7 governs everything in this file: no card number, no expiry, no CVV,
in any form, ever. The gateway never sends them and we never ask.
"""

from __future__ import annotations

import hashlib
import hmac
import json
import logging
from typing import Any

import requests
from django.conf import settings

from .models import TransactionStatus

log = logging.getLogger("lunio.payments")


class ChargilyNotConfigured(RuntimeError):
    """Raised where a Chargily specific is required but not configured."""


class ChargilyError(RuntimeError):
    """The gateway refused or could not be reached."""


# Verified 2026-08-18 — https://dev.chargily.com/pay-v2/the-quick-guide/create-a-checkout
TEST_BASE_URL = "https://pay.chargily.net/test/api/v2"
LIVE_BASE_URL = "https://pay.chargily.net/api/v2"

# Verified 2026-08-18 — https://dev.chargily.com/pay-v2/webhooks
SIGNATURE_HEADER = "signature"

# Verified 2026-08-18 — https://dev.chargily.com/pay-v2/api-reference/checkouts/checkout-object
#
# Deliberately exhaustive and deliberately conservative: `processing` is money in
# flight, not money received, so it maps to PENDING. Mapping an in-flight payment
# to PAID would activate a subscription that may still fail.
STATUS_MAP: dict[str, str] = {
    "pending": TransactionStatus.PENDING,
    "processing": TransactionStatus.PENDING,
    "paid": TransactionStatus.PAID,
    "failed": TransactionStatus.FAILED,
    "canceled": TransactionStatus.CANCELED,
}


def base_url() -> str:
    """The API root for the configured mode.

    `CHARGILY_LIVE_MODE` must be set explicitly. There is no "guess from the key
    prefix": a key that looks like a test key on a live endpoint, or the reverse,
    should fail at configuration time and not at the first real payment.
    """
    configured = settings.CHARGILY_BASE_URL.strip()
    if configured:
        return configured.rstrip("/")
    return LIVE_BASE_URL if settings.CHARGILY_LIVE_MODE else TEST_BASE_URL


def _secret_key() -> str:
    key = settings.CHARGILY_SECRET_KEY.strip()
    if not key:
        raise ChargilyNotConfigured(
            "CHARGILY_SECRET_KEY is empty. It lives in server/.env only — never "
            "in .env.example, never in the app, never in a commit (Art. 7.7)."
        )

    # The promise `base_url` makes, finally enforced. That docstring has always
    # said a key on the wrong endpoint "should fail at configuration time and not
    # at the first real payment" — nothing checked it.
    #
    # It matters on exactly one day: the switch to live. Chargily prefixes its
    # keys `test_` and `live_`, and the two mistakes are not symmetrical:
    #
    #  * a **live key on the test endpoint** takes no money and looks like a
    #    working system, so it is discovered by a parent whose payment never
    #    arrives;
    #  * a **test key on the live endpoint** fails every payment on the day the
    #    client announced the app.
    #
    # Both are silent until a real person is holding a phone. `CHARGILY_BASE_URL`
    # is checked too, because setting it overrides the mode flag entirely — which
    # means the flag can read `1` while every request still goes to the sandbox.
    live = settings.CHARGILY_LIVE_MODE
    override = settings.CHARGILY_BASE_URL.strip()
    if override:
        live = LIVE_BASE_URL.rstrip("/") == override.rstrip("/")

    if live and key.startswith("test_"):
        raise ChargilyNotConfigured(
            "live mode is on but CHARGILY_SECRET_KEY is a test key. Nothing "
            "would be charged and every payment would appear to work."
        )
    if not live and key.startswith("live_"):
        raise ChargilyNotConfigured(
            "CHARGILY_SECRET_KEY is a live key but live mode is off. Set "
            "CHARGILY_LIVE_MODE=1 only once the webhook address is a public "
            "HTTPS host that stays up — a live payment whose confirmation never "
            "arrives cannot be recovered by the parent."
        )
    return key


def map_status(gateway_status: str) -> str:
    """Translate a gateway status into ours, or refuse.

    Refusing on an unknown value is the whole point. Chargily could add a status
    tomorrow, and the failure mode must be "this webhook was not applied, here is
    the row saying why" rather than a payment silently recorded as something it
    is not.
    """
    try:
        return STATUS_MAP[gateway_status]
    except KeyError as exc:
        raise ChargilyNotConfigured(
            f"unmapped Chargily status {gateway_status!r}. The documented set is "
            f"{sorted(STATUS_MAP)}; re-read the checkout object reference before "
            "adding to STATUS_MAP — mapping an unknown status to PAID would "
            "activate a subscription that was never paid."
        ) from exc


def body_digest(raw_body: bytes) -> str:
    """SHA-256 of the raw body. Stored instead of the body itself (Art. 7.7)."""
    return hashlib.sha256(raw_body).hexdigest()


def extract_event_id(raw_body: bytes, headers: Any) -> str:
    """The gateway's unique event id, used for idempotency.

    Verified: the webhook envelope carries a root-level `id`. Falling back to the
    body digest keeps a byte-identical replay blocked even if that field is ever
    missing — weaker, because two genuinely distinct events could serialise
    identically, but never weaker than having no guard at all.
    """
    try:
        payload = json.loads(raw_body.decode("utf-8"))
        event_id = payload.get("id")
        if isinstance(event_id, str) and event_id:
            return event_id
    except (UnicodeDecodeError, json.JSONDecodeError, AttributeError):
        pass
    return body_digest(raw_body)


def verify_signature(raw_body: bytes, headers: Any) -> bool:
    """Verify the webhook signature.

    Article 7.3 requires rejecting any unsigned notification, so every failure
    path here returns False rather than raising — an exception on this endpoint
    would be a 500, and a 500 makes the gateway retry a request we intend to
    refuse.

    `compare_digest` rather than `==`: a byte-by-byte comparison leaks, through
    timing, how much of a forged signature was correct.
    """
    provided = headers.get(SIGNATURE_HEADER) or headers.get(
        SIGNATURE_HEADER.capitalize()
    )
    if not provided:
        return False

    try:
        secret = _secret_key()
    except ChargilyNotConfigured:
        return False

    expected = hmac.new(
        secret.encode("utf-8"),
        raw_body,
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(expected, str(provided).strip())


def checkout_of(payload: dict) -> dict:
    """The checkout object inside the webhook envelope.

    Verified envelope: `{id, entity, livemode, type, data, created_at,
    updated_at}`. A payload without a `data` object is not a shape we understand,
    and pretending otherwise would mean reading a status from nowhere.
    """
    data = payload.get("data")
    if not isinstance(data, dict):
        raise ChargilyNotConfigured(
            "webhook payload has no `data` object; expected the documented "
            "envelope {id, entity, livemode, type, data, created_at, updated_at}"
        )
    return data


def is_checkout_event(payload: dict) -> bool:
    """Whether this event concerns a checkout at all.

    The documentation shows `checkout.paid`, `checkout.failed` and
    `checkout.canceled` but does not say the list is exhaustive, so this matches
    the family rather than the members. The *decision* still comes from
    `data.status`, which is documented exhaustively.
    """
    event_type = payload.get("type")
    return isinstance(event_type, str) and event_type.startswith("checkout.")


def plan_from_metadata(checkout: dict) -> str:
    """Read the plan we stamped on the checkout when we created it.

    `metadata` is documented as an array, and the SDKs pass a list of objects,
    but a plain object is what several examples show. Both are accepted, because
    the cost of being wrong here is a paid subscription that fails to activate.
    """
    metadata = checkout.get("metadata")
    if isinstance(metadata, dict):
        candidate = metadata.get("plan")
        if isinstance(candidate, str):
            return candidate
    if isinstance(metadata, list):
        for entry in metadata:
            if isinstance(entry, dict) and isinstance(entry.get("plan"), str):
                return entry["plan"]
    return ""


def create_checkout(
    *,
    amount_dzd: int,
    plan: str,
    success_url: str,
    failure_url: str = "",
    webhook_endpoint: str = "",
    description: str = "",
    locale: str = "ar",
) -> dict:
    """Create a hosted checkout and return the gateway's checkout object.

    **Article 7.7 in one sentence: this is the only place a payment is created,
    and it never touches card data.** The parent enters their card exclusively on
    the `checkout_url` this returns, on Chargily's own page. We receive an id, an
    amount, a status and timestamps — nothing else, ever.

    Article 7.2 decides *who* calls this: the independent web page, never the
    Android app. The app shows no price, no buy button and no payment link.
    """
    payload: dict[str, Any] = {
        "amount": int(amount_dzd),
        "currency": "dzd",
        "success_url": success_url,
        "locale": locale,
        # The plan is stamped here because the webhook is the only thing that
        # comes back, and it must be able to say which subscription was bought
        # without us having to trust a client-supplied value at activation time.
        "metadata": {"plan": plan},
    }
    if failure_url:
        payload["failure_url"] = failure_url
    if webhook_endpoint:
        payload["webhook_endpoint"] = webhook_endpoint
    if description:
        payload["description"] = description

    try:
        return _post_checkout(payload)
    except ChargilyWebhookRejected as rejected:
        # Chargily resolves `webhook_endpoint` and refuses the whole checkout if
        # the host does not answer. In development that address is a tunnel, and
        # a tunnel from yesterday is a dead hostname.
        #
        # ### This used to retry without the field. That was the bug.
        #
        # The reasoning was that Chargily would fall back to the endpoint in its
        # own dashboard, so a checkout was better than an error. What it actually
        # produced, on 2026-08-30, was **five checkouts with no reachable webhook
        # at all** — the dashboard endpoint pointed at the same dead tunnel — each
        # one sitting at «في انتظار تأكيد Chargily» for ever. The parent paid
        # nothing and got nothing, and the server had no idea anything was wrong.
        #
        # A payment that never starts is recoverable in ten seconds: the parent
        # sees a failure and tries again. A payment that starts and can never be
        # confirmed is not recoverable at all by anyone but us, and the parent
        # has no way to know which of the two happened. So this fails, loudly,
        # **before** any money is involved.
        #
        # In production `CHARGILY_WEBHOOK_URL` is a real domain and this branch
        # never runs. It exists to stop a development mistake from looking like a
        # working payment.
        log.error(
            "Chargily refused webhook_endpoint %r, so no checkout was created. "
            "A checkout without a reachable webhook can never be confirmed. "
            "If this is a development tunnel, restart it with "
            "tools/webhook_tunnel.ps1 and restart the server.",
            payload.get("webhook_endpoint"),
        )
        raise ChargilyError(
            "The payment gateway could not reach this server's confirmation "
            "address, so no payment was started."
        ) from rejected


class ChargilyWebhookRejected(ChargilyError):
    """Chargily refused the checkout *because of* the webhook endpoint."""


def _post_checkout(payload: dict[str, Any]) -> dict:
    try:
        response = requests.post(
            f"{base_url()}/checkouts",
            headers={
                "Authorization": f"Bearer {_secret_key()}",
                "Content-Type": "application/json",
            },
            json=payload,
            timeout=settings.CHARGILY_TIMEOUT_SECONDS,
        )
    except requests.RequestException as exc:
        raise ChargilyError(f"could not reach Chargily: {exc}") from exc

    if response.status_code >= 400:
        # The body may name the offending field, which is the whole value of the
        # message. It carries no card data — the request never had any.
        detail = response.text[:300]
        if "webhook_endpoint" in detail:
            raise ChargilyWebhookRejected(
                f"Chargily refused the webhook endpoint (HTTP "
                f"{response.status_code}): {detail}"
            )
        raise ChargilyError(
            f"Chargily refused the checkout (HTTP {response.status_code}): "
            f"{detail}"
        )

    try:
        checkout = response.json()
    except ValueError as exc:
        raise ChargilyError("Chargily returned a non-JSON response") from exc

    if not isinstance(checkout, dict) or not checkout.get("checkout_url"):
        raise ChargilyError(
            "Chargily response carried no checkout_url; refusing to hand the "
            "parent a broken payment link"
        )
    return checkout
