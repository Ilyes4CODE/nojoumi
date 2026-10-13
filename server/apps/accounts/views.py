from __future__ import annotations

from django.db import transaction
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.generics import CreateAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from rest_framework_simplejwt.views import TokenObtainPairView

from . import deletion, install_binding
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

        # **One transaction for the account and the device binding.** Without it
        # the account is committed first and the binding second, so anything
        # that fails in between leaves an account that exists, cannot be signed
        # into from this phone, and burns its email address for good.
        #
        # Found on production on 2026-09-25: the code for three accounts per
        # phone was deployed without its migration, `bind()` raised because the
        # join table did not exist, and every registration made one orphan and
        # returned 500. The migration was the cause; this is why the cause left
        # debris behind it.
        #
        # The limit refusal above still runs first and returns 409 without
        # touching the database. This covers the failures that are not a limit.
        with transaction.atomic():
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


class AccountDeleteView(APIView):
    """Delete the signed-in parent's account. Google Play requires it in-app.

    **The password is asked again**, not just the token. The phone this runs on is
    the child's phone, and a session that is signed in on it says nothing about
    who is holding it. A wrong password answers 403 rather than 401: the app's
    client treats 401 as an expired token, refreshes, and retries — it would then
    report a typo as "signed out".

    What goes and what stays is in `deletion.py`, shared with the web page.
    """

    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "account_delete"

    @extend_schema(
        summary="Delete the authenticated parent's account",
        description="Requires the current password. Payment records are kept, detached.",
        responses={204: None},
    )
    def post(self, request):
        password = request.data.get("password")
        if not isinstance(password, str) or not password:
            return Response(
                {"detail": "أدخل كلمة المرور لتأكيد الحذف."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not request.user.check_password(password):
            return Response(
                {"detail": "كلمة المرور غير صحيحة."},
                status=status.HTTP_403_FORBIDDEN,
            )
        deletion.delete_account(request.user)
        return Response(status=status.HTTP_204_NO_CONTENT)
