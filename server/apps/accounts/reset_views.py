"""Password reset: ask for a code, check it, set a new password.

Three endpoints rather than two. The middle one exists purely so the app can tell
a parent that their code is wrong **before** asking them to invent a password —
being made to type a new password twice and only then told the code expired is
the kind of small cruelty that gets an app deleted. It costs nothing in safety
because both endpoints spend from the same five-attempt budget on the same row.

**Every answer here is the same for an address that exists and one that does
not.** Not as a formality: this server's whole account list is parents of school
children in one country, and "does this address have an account" is a question
worth refusing to answer. So:

  * requesting a code always returns 200, whether or not an account was found,
    whether or not a message was actually sent, and whether or not the mail
    server accepted it;
  * a wrong code, an expired code, a burnt-out code and an unknown address all
    return the same 400 and the same sentence;
  * the *timing* is left alone deliberately — an unknown address skips the mail
    send and answers faster, which is measurable. Closing that would mean
    sleeping a request thread on a shared host, which costs more than the leak is
    worth here. Written down rather than pretended away.
"""

from __future__ import annotations

import logging

from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from . import mailer, reset_codes

log = logging.getLogger(__name__)
ParentUser = get_user_model()

#: Said for a wrong code, an expired code, a code that ran out of attempts, and
#: an address with no account. One sentence for four states, on purpose.
BAD_CODE = "الرمز غير صحيح أو انتهت صلاحيته. اطلب رمزاً جديداً."

#: Said whether or not anything was sent.
SENT = "إذا كان هذا البريد مسجَّلاً لدينا، فقد أرسلنا إليه رمزاً. تحقّق من بريدك، ومن مجلّد الرسائل غير المرغوبة."


def _parent(email: str):
    return ParentUser.objects.filter(email__iexact=email.strip(), is_active=True).first()


class ResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()


class ResetVerifySerializer(serializers.Serializer):
    email = serializers.EmailField()
    # Not an IntegerField: "012345" is a valid code and an integer field would
    # hand us 12345.
    code = serializers.RegexField(r"^\d{6}$", trim_whitespace=True)


class ResetConfirmSerializer(ResetVerifySerializer):
    password = serializers.CharField(write_only=True, style={"input_type": "password"})

    def validate_password(self, value: str) -> str:
        # The same rules registration uses. A reset that accepts "123456" is a
        # door beside the lock.
        validate_password(value)
        return value


class PasswordResetRequestView(APIView):
    """Send a code to the address, if it belongs to an account."""

    permission_classes = [AllowAny]
    authentication_classes: list = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "password_reset"

    @extend_schema(
        request=ResetRequestSerializer,
        responses={200: None},
        summary="Request a password-reset code",
        description="Always 200. The response never reveals whether the address has an account.",
    )
    def post(self, request):
        serializer = ResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        parent = _parent(serializer.validated_data["email"])
        if parent is not None:
            code = reset_codes.issue(parent)
            if code is not None:
                try:
                    mailer.send_reset_code(parent, code)
                except Exception:
                    # Swallowed on the wire, loud in the log. A 500 here would
                    # answer the one question this endpoint exists to refuse: an
                    # unknown address cannot fail to send, so a failure means the
                    # address is real.
                    log.exception("could not send a reset code to parent %s", parent.pk)

        return Response({"detail": SENT})


class PasswordResetVerifyView(APIView):
    """Is this code good? Spends one of the five attempts."""

    permission_classes = [AllowAny]
    authentication_classes: list = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "password_reset"

    @extend_schema(
        request=ResetVerifySerializer,
        responses={200: None, 400: None},
        summary="Check a reset code before asking for a new password",
    )
    def post(self, request):
        serializer = ResetVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        parent = _parent(serializer.validated_data["email"])
        if parent is None or reset_codes.redeem(parent, serializer.validated_data["code"]) is None:
            return Response({"detail": BAD_CODE}, status=status.HTTP_400_BAD_REQUEST)

        return Response({"detail": "الرمز صحيح."})


class PasswordResetConfirmView(APIView):
    """Set the new password.

    **Every other session ends here**, because `CHECK_REVOKE_TOKEN` binds a hash
    of the password into each token. A parent resetting because somebody else got
    into their account would otherwise change the password and leave that person
    signed in — which is the one thing a reset is supposed to prevent.
    """

    permission_classes = [AllowAny]
    authentication_classes: list = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "password_reset"

    @extend_schema(
        request=ResetConfirmSerializer,
        responses={200: None, 400: None},
        summary="Set a new password with a reset code",
    )
    def post(self, request):
        # A weak password is rejected here, before the code is looked at, so a
        # parent who picks "123456" does not also burn one of their five
        # attempts. Reported plainly too: their own choice is not a secret.
        serializer = ResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        parent = _parent(serializer.validated_data["email"])
        if parent is None:
            return Response({"detail": BAD_CODE}, status=status.HTTP_400_BAD_REQUEST)

        row = reset_codes.redeem(parent, serializer.validated_data["code"])
        if row is None:
            return Response({"detail": BAD_CODE}, status=status.HTTP_400_BAD_REQUEST)

        parent.set_password(serializer.validated_data["password"])
        parent.save(update_fields=["password"])

        row.used_at = timezone.now()
        row.save(update_fields=["used_at"])

        log.info("password reset completed for parent %s", parent.pk)
        return Response({"detail": "تم تغيير كلمة المرور. سجّل الدخول بكلمتك الجديدة."})
