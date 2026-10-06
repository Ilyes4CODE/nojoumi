"""Base settings for the Lunio server.

Contract-driven configuration is marked with its article. Anything so marked is
not a preference — changing it changes whether we are in breach.
"""

import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent.parent

# `server/.env` is loaded here, before the first `os.environ.get` below.
#
# It was missing until 2026-08-28, and the failure was invisible in exactly the
# way that costs the most time: every `os.environ.get` has a default, so the
# server started, migrated, registered accounts and issued tokens perfectly —
# on a hardcoded insecure SECRET_KEY, with no Chargily keys and no AI key. The
# first symptom was a 500 from the lesson endpoint saying "GROQ_API_KEY is not
# configured" about a key that was sitting in `.env` all along.
#
# `override=False` on purpose: a real environment variable always wins. In
# Docker and on the VPS the configuration arrives through the environment
# (Art. 3's deployment), and a `.env` left in an image must never quietly
# outrank it. On the developer's machine nothing sets these, so the file is
# what is used.
load_dotenv(BASE_DIR / ".env", override=False)

SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "dev-only-insecure-key")
DEBUG = os.environ.get("DJANGO_DEBUG", "0") == "1"
ALLOWED_HOSTS = [
    h.strip()
    for h in os.environ.get("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")
    if h.strip()
]

INSTALLED_APPS = [
    "django.contrib.contenttypes",
    "django.contrib.auth",
    "rest_framework",
    "drf_spectacular",
    "apps.accounts",
    "apps.ai",
    "apps.common",
    "apps.devices",
    "apps.lessons",
    "apps.payments",
    "apps.subscriptions",
    # The payment page of Art. 7.2 — the one surface that shows a price.
    "apps.web",
    # Serves that page's illustrations in development. Behind Nginx in
    # production (Art. 3), where `collectstatic` puts them.
    "django.contrib.staticfiles",
]

# The server knows the parent, never the child (Art. 14, AD-6).
AUTH_USER_MODEL = "accounts.ParentUser"

# Django applies no validators at all when this setting is absent, which let
# "1234" through until a test caught it. It matters more here than in an ordinary
# app: this password guards the subscription *and* is the recovery path for the
# parent PIN (decisions.md D-10). A child who guesses it unlocks the phone.
AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation."
        "UserAttributeSimilarityValidator"
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
        "OPTIONS": {"min_length": 8},
    },
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.middleware.common.CommonMiddleware",
]

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {"context_processors": []},
    }
]

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "dev.sqlite3",
    }
}

# --- Email ------------------------------------------------------------------
# Used by exactly one thing: the password-reset code (apps/accounts/mailer.py).
# There is no newsletter, no receipt and no notification — Article 14 keeps the
# server's knowledge of a family down to an address and a subscription.
#
# Development prints the message to the console. **Production overrides all of
# this and refuses to start without it** (config/settings/prod.py): a reset that
# silently goes nowhere looks identical to one that worked, and the parent is
# left refreshing an inbox.
# Development writes each message to a file rather than to the console, for two
# reasons found the hard way on 2026-09-19.
#
# **The console backend cannot print this message on Windows.** Python opens
# stdout in the console's own code page — cp1252 here — and the subject line is
# Arabic, so `write_message` raises `UnicodeEncodeError` and nothing is printed.
# The reset endpoint then answers 200 anyway, exactly as it is designed to (a
# visible send failure is an account-enumeration oracle), so a developer asks for
# a code, is told cheerfully that one was sent, and there is no code anywhere.
#
# **A .eml file is the better tool regardless.** This message is HTML with
# inline illustrations; opening the file in a mail client shows what a parent
# will actually see, which a wall of base64 in a terminal does not.
# Overridable from `.env`, so a developer who wants to see the message land in a
# real inbox — the only way to answer "does it go to spam" and "do the
# illustrations show" — can point this at an SMTP server without editing code.
EMAIL_BACKEND = os.environ.get(
    "EMAIL_BACKEND", "django.core.mail.backends.filebased.EmailBackend"
)
EMAIL_FILE_PATH = BASE_DIR / "sent_emails"

EMAIL_HOST = os.environ.get("EMAIL_HOST", "")
EMAIL_PORT = int(os.environ.get("EMAIL_PORT", "587") or "587")
EMAIL_HOST_USER = os.environ.get("EMAIL_HOST_USER", "")
EMAIL_HOST_PASSWORD = os.environ.get("EMAIL_HOST_PASSWORD", "")
EMAIL_USE_TLS = os.environ.get("EMAIL_USE_TLS", "0") == "1"
EMAIL_USE_SSL = os.environ.get("EMAIL_USE_SSL", "0") == "1"

DEFAULT_FROM_EMAIL = os.environ.get("DEFAULT_FROM_EMAIL", "Lunio <no-reply@localhost>")

# A dead SMTP host must not hold a worker open on a shared plan.
EMAIL_TIMEOUT = 10

LANGUAGE_CODE = "ar"
TIME_ZONE = "Africa/Algiers"
USE_I18N = True
USE_TZ = True

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

REST_FRAMEWORK = {
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
    "DEFAULT_THROTTLE_RATES": {
        "lesson": "30/hour",
        "register": "10/hour",
        # Sign-in gets its own bucket, deliberately more generous than register.
        # Sharing the register scope was tried and is wrong twice over: a parent
        # who mistypes a password three times would be locked out of their own
        # phone for an hour, and account creation — the expensive, abusable
        # operation — would have its budget spent by ordinary logins.
        "signin": "30/hour",
        "subscription": "20/hour",
        # Creating a checkout costs us a gateway call and creates a row, and the
        # endpoint is unauthenticated by contract design (Art. 7.3). The limit is
        # what keeps that from being an amplification vector.
        "checkout": "20/hour",
        # Password reset shares one bucket across all three of its endpoints, so
        # the budget cannot be widened by bouncing between them. Generous enough
        # for a parent who mistypes a code twice and then asks for a fresh one;
        # far too small to walk a million six-digit codes.
        "password_reset": "15/hour",
        # The background heartbeat. A phone sends one every six hours, so this is
        # far above any honest rate — it is here to bound a caller hammering the
        # endpoint, not to shape real traffic. Keyed per IP, and a household
        # behind one address has at most a few phones.
        "heartbeat": "30/hour",
    },
}

# Art. 3 leaves the token lifetimes to us. Written down rather than defaulted,
# because both numbers are decisions.
#
# `CHECK_REVOKE_TOKEN` binds a hash of the parent's password into every token and
# checks it on each request. It is here for the password reset: without it, a
# parent who resets because somebody else got into their account changes the
# password and leaves that person signed in for as long as their refresh token
# lasts, which is the one outcome a reset exists to prevent.
#
# **It signs every currently-issued token out, once.** A token minted before this
# setting carries no hash claim and is refused, and refreshing it produces
# another token with no claim, so the parent signs in again. That is the correct
# moment for this change: before the app is in anyone's hands but the client's.
SIMPLE_JWT = {
    "CHECK_REVOKE_TOKEN": True,
}

# Art. 7.6 — Ed25519 private key for signing the subscription snapshot. The app
# embeds only the matching public key. Generate with:
#     python manage.py generate_signing_key
SUBSCRIPTION_SIGNING_KEY_HEX = os.environ.get("SUBSCRIPTION_SIGNING_KEY_HEX", "")

# --- Chargily Pay v2 -------------------------------------------------------
# Art. 7.7 — kept server-side only, never in the app file, never in
# .env.example, never in a commit. The Android app holds no key of any kind.
#
# Every constant these feed is documented in apps/payments/chargily.py with the
# URL it was verified from on 2026-08-18. Re-verify before Phase 7.
CHARGILY_SECRET_KEY = os.environ.get("CHARGILY_SECRET_KEY", "")

# The publishable key. Not used by the server at all — it belongs to the payment
# web page — but it is read here so that a deployment which forgot it fails at
# configuration rather than at the parent's first payment.
CHARGILY_PUBLIC_KEY = os.environ.get("CHARGILY_PUBLIC_KEY", "")

# Explicit, never inferred from the key prefix. A test key pointed at the live
# endpoint and a live key pointed at the test one both fail confusingly; making
# the mode a deliberate setting turns that into a one-line configuration review.
CHARGILY_LIVE_MODE = os.environ.get("CHARGILY_LIVE_MODE", "0") == "1"

# Overrides the mode-derived base URL. Empty in normal use.
CHARGILY_BASE_URL = os.environ.get("CHARGILY_BASE_URL", "")

CHARGILY_TIMEOUT_SECONDS = int(os.environ.get("CHARGILY_TIMEOUT_SECONDS", "20"))

# Where Chargily sends the parent back to, and where it posts the webhook.
# The webhook URL must be publicly reachable HTTPS — open question Q19.
CHARGILY_SUCCESS_URL = os.environ.get("CHARGILY_SUCCESS_URL", "")
CHARGILY_FAILURE_URL = os.environ.get("CHARGILY_FAILURE_URL", "")
CHARGILY_WEBHOOK_URL = os.environ.get("CHARGILY_WEBHOOK_URL", "")

SPECTACULAR_SETTINGS = {
    "TITLE": "Lunio API",
    "DESCRIPTION": (
        "Server for the Lunio Android app. Holds parent accounts, "
        "subscriptions and transactions. Holds no child data and no lesson "
        "images (Art. 14)."
    ),
    "VERSION": "0.1.0",
}

# --- Article 14: the lesson image must never reach disk -----------------------
#
# This is the single most important block in this file, and it is easy to get
# wrong by omission.
#
# By default Django streams any upload larger than FILE_UPLOAD_MAX_MEMORY_SIZE
# (2.5 MB) into a **temporary file on disk** via TemporaryFileUploadHandler,
# before a single line of our code runs. A photograph of a schoolbook page is
# routinely 3–6 MB. So with default settings, Django itself would write the
# child's lesson image to disk and we would be in breach of Article 14 without
# having written any code to do it.
#
# Therefore: the memory handler is the ONLY handler, and the in-memory limits are
# raised above the largest image we accept. Anything bigger is rejected by the
# serializer with a clear message rather than silently spooled.
FILE_UPLOAD_HANDLERS = [
    "django.core.files.uploadhandler.MemoryFileUploadHandler",
]

LESSON_IMAGE_MAX_BYTES = int(os.environ.get("LESSON_IMAGE_MAX_BYTES", 8 * 1024 * 1024))

# Comfortably above LESSON_IMAGE_MAX_BYTES so an accepted image is always held in
# memory, never spooled.
FILE_UPLOAD_MAX_MEMORY_SIZE = LESSON_IMAGE_MAX_BYTES + (2 * 1024 * 1024)
DATA_UPLOAD_MAX_MEMORY_SIZE = FILE_UPLOAD_MAX_MEMORY_SIZE

# No MEDIA_ROOT is configured on purpose. There is nothing to serve, and an
# absent setting cannot be accidentally written to.
MEDIA_ROOT = None
MEDIA_URL = None

# --- Article 3 / Article 14: lesson processing --------------------------------
LESSON_PROCESSOR = os.environ.get("LESSON_PROCESSOR", "groq")
GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "")
GROQ_MODEL = os.environ.get("GROQ_MODEL", "")
# "none" turns off Qwen3's chain-of-thought, which is pure cost here — measured
# 714 completion tokens instead of 1 768 for identical output. Set to "" to omit
# the parameter entirely if a future model rejects it.
GROQ_REASONING_EFFORT = os.environ.get("GROQ_REASONING_EFFORT", "none")
ANTHROPIC_API_KEY = os.environ.get("ANTHROPIC_API_KEY", "")
ANTHROPIC_MODEL = os.environ.get("ANTHROPIC_MODEL", "")

# --- Gemini (client request, 2026-08-17) --------------------------------------
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "")
# Leave empty to omit thinkingConfig entirely, which is the only thing
# gemini-3.6-flash accepts — `thinkingBudget: 0` returns HTTP 400 on that model
# and `thinkingLevel` is not a field in v1beta (measured 2026-08-17). Unlike Groq,
# How many tokens Gemini may spend "thinking" before it answers. **Zero by
# default**, measured 2026-10-06.
#
# The comment that stood here said thinking tokens were "a cost rather than a
# truncation risk". That was wrong: they come out of the same `maxOutputTokens`
# allowance as the answer. Left unset, gemini-3.6-flash spent 1583 tokens
# thinking on one page, the JSON was cut off at 366 characters in one of two
# identical runs, and the parent saw «تعذّر تحليل نتيجة المعالجة».
#
# Turning a page into a fixed schema is transcription, not reasoning: with
# thinking off, three real pages each gave 12 cards and 8 questions in 5.8-8.0 s.
# An explicit empty value still means "send no thinkingConfig", for a model that
# ever refuses the field again — as gemini-3.6-flash did in August.
_gemini_thinking = os.environ.get("GEMINI_THINKING_BUDGET", "0").strip()
GEMINI_THINKING_BUDGET = int(_gemini_thinking) if _gemini_thinking else None
# Art. 14 gate. Google's terms permit model improvement and human review of
# content on the FREE tier, and forbid both on the PAID tier. The adapter refuses
# to run until somebody states here that billing is on.
GEMINI_BILLING_ENABLED = os.environ.get("GEMINI_BILLING_ENABLED", "0") == "1"

# --- Logging: never log image bytes or lesson content (Art. 14) ---------------
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {"plain": {"format": "%(levelname)s %(name)s %(message)s"}},
    "handlers": {
        "console": {"class": "logging.StreamHandler", "formatter": "plain"},
    },
    "loggers": {
        # Pillow narrates the structure of an image at DEBUG level — chunk names,
        # offsets, sizes — and DRF's ImageField runs Pillow over every uploaded
        # lesson page. That is third-party logging derived from the child's
        # image, so it is pinned to WARNING here rather than left to inherit the
        # root level. Without this, anyone who raises logging to DEBUG to chase
        # an unrelated bug silently starts emitting lines about every page a
        # child photographs (Art. 14: no logs of image bytes).
        #
        # Enforced by apps/lessons/tests/test_privacy.py — which caught exactly
        # this leak on its first run.
        "PIL": {"level": "WARNING", "propagate": True},
    },
    "root": {"handlers": ["console"], "level": "INFO"},
}
