"""Base settings for the Nojoumi server.

Contract-driven configuration is marked with its article. Anything so marked is
not a preference — changing it changes whether we are in breach.
"""

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent

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
TEMPLATES = []

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "dev.sqlite3",
    }
}

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
        "subscription": "20/hour",
    },
}

# Art. 7.6 — Ed25519 private key for signing the subscription snapshot. The app
# embeds only the matching public key. Generate with:
#     python manage.py generate_signing_key
SUBSCRIPTION_SIGNING_KEY_HEX = os.environ.get("SUBSCRIPTION_SIGNING_KEY_HEX", "")

# Art. 7.7 — kept server-side only, never in the app file.
CHARGILY_SECRET_KEY = os.environ.get("CHARGILY_SECRET_KEY", "")
CHARGILY_WEBHOOK_SECRET = os.environ.get("CHARGILY_WEBHOOK_SECRET", "")
CHARGILY_BASE_URL = os.environ.get("CHARGILY_BASE_URL", "")

SPECTACULAR_SETTINGS = {
    "TITLE": "Nojoumi API",
    "DESCRIPTION": (
        "Server for the Nojoumi Android app. Holds parent accounts, "
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
# Gemini reports thinking tokens separately, so they are a cost rather than a
# truncation risk.
_gemini_thinking = os.environ.get("GEMINI_THINKING_BUDGET", "").strip()
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
