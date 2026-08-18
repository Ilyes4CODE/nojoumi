from __future__ import annotations

from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.devices.models import Install

from . import services


class InstallRefSerializer(serializers.Serializer):
    """The app's own random install UUID (see apps/devices/models.py)."""

    install_id = serializers.UUIDField()
    android_release = serializers.CharField(max_length=32, required=False, allow_blank=True)
    device_model = serializers.CharField(max_length=64, required=False, allow_blank=True)
    app_version = serializers.CharField(max_length=32, required=False, allow_blank=True)

    def resolve(self, parent) -> Install:
        data = self.validated_data
        install, _ = Install.objects.get_or_create(id=data["install_id"])
        install.android_release = data.get("android_release") or install.android_release
        install.device_model = data.get("device_model") or install.device_model
        install.app_version = data.get("app_version") or install.app_version
        if install.parent_id is None:
            install.parent = parent
        install.save()
        return install


SNAPSHOT_DESCRIPTION = (
    "Returns the Ed25519-signed subscription snapshot. The device caches it and "
    "may work offline on it for 7 days, revalidating every 24 h (Art. 7.6). The "
    "device may downgrade the state as time passes; it can never upgrade it, "
    "because it cannot forge the signature.\n\n"
    "`capabilities.blocking_active` and `capabilities.stars_active` are always "
    "true, in every state — Art. 7.1 forbids punishing the child for the "
    "parent's payment delay. Only `can_generate_new_lessons` is ever withdrawn."
)


class StatusView(APIView):
    """GET the signed snapshot. The app calls this every 24 h (Art. 7.6)."""

    permission_classes = [IsAuthenticated]

    @extend_schema(
        responses={200: OpenApiTypes.OBJECT},
        summary="Signed subscription snapshot",
        description=SNAPSHOT_DESCRIPTION,
    )
    def get(self, request):
        return Response(services.build_snapshot(parent=request.user))


class StartTrialView(APIView):
    """POST once per device (Art. 7.1)."""

    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "subscription"

    @extend_schema(
        request=InstallRefSerializer,
        responses={201: OpenApiTypes.OBJECT, 409: OpenApiTypes.OBJECT},
        summary="Start the free trial",
        description=(
            "7 days, all features, **once per device** (Art. 7.1). Returns 409 if "
            "this install has already had its trial. The check is on the device, "
            "not the account — a new email address does not reset it."
        ),
    )
    def post(self, request):
        ref = InstallRefSerializer(data=request.data)
        ref.is_valid(raise_exception=True)
        install = ref.resolve(request.user)

        try:
            services.start_trial(parent=request.user, install=install)
        except services.TrialAlreadyUsed as exc:
            # 409: the request was well formed, the device has simply already had
            # its one trial. The app shows this and offers the web page.
            return Response({"detail": str(exc)}, status=status.HTTP_409_CONFLICT)

        return Response(
            services.build_snapshot(parent=request.user),
            status=status.HTTP_201_CREATED,
        )


class ActivateSerializer(InstallRefSerializer):
    code = serializers.CharField(max_length=32)


class ActivateView(APIView):
    """POST the activation code from the external payment page (Art. 7.3)."""

    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "subscription"

    @extend_schema(
        request=ActivateSerializer,
        responses={
            200: OpenApiTypes.OBJECT,
            400: OpenApiTypes.OBJECT,
            409: OpenApiTypes.OBJECT,
        },
        summary="Redeem an activation code",
        description=(
            "The parent pays on an independent web page outside the app "
            "(Art. 7.2), receives a code, and enters it here once (Art. 7.3 "
            "step 5). Codes are single use: 409 if already redeemed, 400 if "
            "unknown. Redeeming while a subscription is still running **adds** "
            "the new period to the remainder (Art. 7.4)."
        ),
    )
    def post(self, request):
        payload = ActivateSerializer(data=request.data)
        payload.is_valid(raise_exception=True)
        install = payload.resolve(request.user)

        try:
            services.activate(
                code=payload.validated_data["code"],
                parent=request.user,
                install=install,
            )
        except services.CodeAlreadyUsed as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_409_CONFLICT)
        except services.CodeInvalid as exc:
            return Response(
                {"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST
            )

        return Response(services.build_snapshot(parent=request.user))
