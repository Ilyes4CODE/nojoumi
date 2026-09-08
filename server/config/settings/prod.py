"""Production settings.

Written for a cPanel/Passenger host, which is what the client's account offers.
The Article 3 stack names Docker + Nginx + Gunicorn; shared cPanel gives none of
those, and that is a deviation to record rather than to hide — see
`docs/deploy-cpanel.md`.

**Everything here refuses rather than defaults.** A production server that
quietly falls back to SQLite, or to `DEBUG=True`, or to `ALLOWED_HOSTS=["*"]`,
is worse than one that will not start: the first is discovered by a customer,
the second by whoever ran the deploy, ten seconds later.
"""

from urllib.parse import unquote, urlparse

from .base import *  # noqa: F401,F403
from .base import os  # noqa: F401

DEBUG = False


def _required(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(
            f"{name} is not set. Production settings refuse to start without it "
            "rather than fall back to a development default."
        )
    return value


# A comma-separated list. Django serves nothing to a Host header not on it, and
# that is the point: the app answers on its own domain and nowhere else.
ALLOWED_HOSTS = [h.strip() for h in _required("DJANGO_ALLOWED_HOSTS").split(",") if h.strip()]

# Django 4+ checks the Origin of an unsafe request against this list. The payment
# page posts to itself, so without these entries every checkout returns 403.
CSRF_TRUSTED_ORIGINS = [f"https://{host}" for host in ALLOWED_HOSTS]

SECRET_KEY = _required("DJANGO_SECRET_KEY")


# --------------------------------------------------------------------- database
def _database_from_url(url: str) -> dict:
    """Parse `DATABASE_URL` without adding a dependency for it.

    Handles postgres and mysql. The password is unquoted because a generated
    cPanel password very often contains `@` or `/`, and a URL-encoded one that is
    passed through raw fails authentication with a message about the host.
    """
    parsed = urlparse(url)
    engines = {
        "postgres": "django.db.backends.postgresql",
        "postgresql": "django.db.backends.postgresql",
        "mysql": "django.db.backends.mysql",
    }
    scheme = parsed.scheme.split("+")[0]
    if scheme not in engines:
        raise RuntimeError(
            f"DATABASE_URL scheme {scheme!r} is not supported. The agreed stack "
            "is PostgreSQL; MySQL works but is a change the client must accept."
        )
    return {
        "ENGINE": engines[scheme],
        "NAME": parsed.path.lstrip("/"),
        "USER": unquote(parsed.username or ""),
        "PASSWORD": unquote(parsed.password or ""),
        "HOST": parsed.hostname or "localhost",
        "PORT": str(parsed.port or ""),
        "CONN_MAX_AGE": 60,
    }


DATABASES = {"default": _database_from_url(_required("DATABASE_URL"))}


# --------------------------------------------------------------------- security
#
# Passenger terminates TLS in front of the application, so Django sees plain HTTP
# and would otherwise redirect for ever. This header is what tells it the request
# arrived encrypted.
#
# **It is only safe because nothing but the host's own proxy can set it.** On a
# host where the application is reachable directly, trusting this header lets a
# client claim HTTPS it does not have.
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SECURE_SSL_REDIRECT = os.environ.get("DJANGO_SSL_REDIRECT", "1") == "1"

SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# A year, and only after the certificate is known good — an HSTS header is
# remembered by the browser and cannot be withdrawn early.
SECURE_HSTS_SECONDS = int(os.environ.get("DJANGO_HSTS_SECONDS", "31536000"))
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = False

SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"


# ---------------------------------------------------------------------- logging
#
# To stdout, which Passenger captures. **Nothing here may log a lesson image, a
# summary, a card, or anything card-shaped** (Art. 7.7, Art. 14) — the payment
# and AI modules already log ids and statuses only, and this must not widen that.
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "plain": {"format": "%(asctime)s %(levelname)s %(name)s %(message)s"},
    },
    "handlers": {
        "console": {"class": "logging.StreamHandler", "formatter": "plain"},
    },
    "root": {"handlers": ["console"], "level": "INFO"},
    "loggers": {
        "django.request": {"handlers": ["console"], "level": "WARNING", "propagate": False},
    },
}
