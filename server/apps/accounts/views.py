from __future__ import annotations

from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.generics import CreateAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from rest_framework_simplejwt.views import TokenObtainPairView

from . import install_binding
from .serializers import (
    InstallAwareTokenSerializer,
    ParentSerializer,
    RegisterSerializer,
)


class RegisterView(CreateAPIView):
    """Create a parent account. Open, but throttled."""

    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "register"

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        install_id = serializer.validated_data.get("install_id")
        if install_id is not None:
            from apps.devices.models import Install

            from .install_binding import MAX_ACCOUNTS_PER_INSTALL

            # Checked before the account is created, not after: a registration
            # that makes a ParentUser and then refuses to bind it leaves an
            # orphan the parent cannot sign in with and cannot create again.
            #
            # The limit is the same one `bind()` enforces (three, from
            # 2026-09-25). Counting the join table rather than `Install.parent`,
            # which by design names only the first account.
            existing = Install.objects.filter(id=install_id).first()
            if existing is not None and existing.accounts.count() >= MAX_ACCOUNTS_PER_INSTALL:
                return Response(
                    {
                        "detail": (
                            f"هذا الهاتف مرتبط بـ{MAX_ACCOUNTS_PER_INSTALL} حسابات بالفعل. "
                            "سجّل الدخول بأحدها، أو احذف بيانات التطبيق للبدء من جديد."
                        )
                    },
                    status=status.HTTP_409_CONFLICT,
                )

        user = serializer.save()

        if install_id is not None:
            install_binding.bind(
                install_id=install_id,
                parent=user,
                android_release=serializer.validated_data.get("android_release", ""),
                device_model=serializer.validated_data.get("device_model", ""),
                app_version=serializer.validated_data.get("app_version", ""),
            )

        return Response(ParentSerializer(user).data, status=status.HTTP_201_CREATED)


class SignInView(TokenObtainPairView):
    """Sign in, and claim the device for this account.

    A thin subclass so the one-account-per-device rule applies to sign-in and not
    only to registration — see `InstallAwareTokenSerializer` for why that is the
    path that actually matters.
    """

    serializer_class = InstallAwareTokenSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "signin"


class MeView(APIView):
    """The authenticated parent's own record."""

    permission_classes = [IsAuthenticated]

    @extend_schema(
        responses=ParentSerializer,
        summary="The authenticated parent",
        description="Contains no child data whatsoever (Art. 14).",
    )
    def get(self, request):
        return Response(ParentSerializer(request.user).data)
