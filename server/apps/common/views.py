"""Health, and nothing else."""

from __future__ import annotations

from django.db import connection
from django.utils import timezone
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView


class HealthView(APIView):
    """Is the server up, and is its database answering?

    Exists because "the app is not connecting to the backend" is the least
    actionable sentence in the project. Without an endpoint like this, a phone
    that cannot reach the server, a phone pointed at the wrong address, a server
    that is up but wedged on its database, and a genuine app bug all produce the
    same silence on screen. This turns four possibilities into one answer.

    Unauthenticated on purpose: it is checked *before* sign-in, on the setup
    screen, which is exactly where a wrong `LUNIO_API_BASE` shows up. It reveals
    nothing — a timestamp and a boolean — and holds no counters that could
    describe a user.

    The `server_time_ms` is not decoration. `TrustedClock` anchors on a server
    timestamp (AD-2), and having one available before the parent has an account
    means a fresh install can establish trusted time on its first screen instead
    of running on `monotonic` until the first authenticated call.
    """

    permission_classes = [AllowAny]
    authentication_classes: list = []

    @extend_schema(
        responses={200: OpenApiTypes.OBJECT},
        summary="Health check",
        description=(
            "Unauthenticated liveness probe. Returns the server time in epoch "
            "milliseconds, which the app may use as a clock anchor (Art. 6.8, "
            "AD-2)."
        ),
    )
    def get(self, request):
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            database_ok = True
        except Exception:  # noqa: BLE001 - a probe reports, it does not raise
            # A 200 with `database: false` is more useful than a 500: the app can
            # say "the server is reachable but not healthy", which is a different
            # instruction to the developer than "unreachable".
            database_ok = False

        return Response(
            {
                "status": "ok" if database_ok else "degraded",
                "database": database_ok,
                "server_time_ms": int(timezone.now().timestamp() * 1000),
            }
        )
