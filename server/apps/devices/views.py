"""The heartbeat: a phone saying "Lunio is still installed here".

Client request, 2026-09-27: a parent should learn when the child deletes the
app. An app may not prevent its own removal — that was built, and Play Protect
refused the entire app for it (D-96) — so this does the one thing that is
allowed: it notices when a phone stops checking in, and `alert_silent_devices`
tells the parent.

The phone calls this from a background WorkManager job every few hours, **whether
or not anyone opens Lunio**. That is the whole design. A signal sent only when
the app is opened cannot tell "deleted" from "not used this weekend", and a
parent woken by a false alarm stops believing the true one.
"""

from __future__ import annotations

from django.core.exceptions import ValidationError
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from .models import Install


class HeartbeatSerializer(serializers.Serializer):
    install_id = serializers.UUIDField()


class HeartbeatView(APIView):
    """Record that this install is still alive. Always 204.

    **Unauthenticated, on purpose.** The worker runs in the background for weeks
    at a time, and access tokens live five minutes; a heartbeat that needed one
    would stop the moment the parent's session aged out, which is exactly when
    it would start raising false alarms.

    What that costs: anyone who knows an install's id could keep it looking
    alive and suppress one "may have been deleted" email. The id is a random
    122-bit UUID that is never shown to anyone, and suppressing an email exposes
    nothing. That is a trade worth making for a signal that never needs a login.

    **It never creates an install.** An unknown id answers 204 and writes
    nothing; otherwise any caller could fill the table by inventing UUIDs.
    """

    permission_classes = [AllowAny]
    authentication_classes: list = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "heartbeat"

    @extend_schema(
        request=HeartbeatSerializer,
        responses={204: None},
        summary="Background heartbeat from an installed app",
    )
    def post(self, request):
        serializer = HeartbeatSerializer(data=request.data)
        if not serializer.is_valid():
            # Still 204. A malformed id is a client bug, and a background job has
            # nobody to show an error to; answering differently would only give a
            # prober something to measure.
            return Response(status=status.HTTP_204_NO_CONTENT)

        # One UPDATE by primary key, no read first: this is called by every phone
        # every few hours, and it should cost the database as little as a write
        # can. `.update()` also skips `auto_now`, so `last_seen_at` keeps meaning
        # "last real activity" and is not moved by a background ping.
        try:
            Install.objects.filter(pk=serializer.validated_data["install_id"]).update(
                heartbeat_at=timezone.now(),
                # The phone is back, so a later silence is a new one, worth a new
                # email.
                silence_alerted_at=None,
            )
        except ValidationError:
            pass

        return Response(status=status.HTTP_204_NO_CONTENT)
