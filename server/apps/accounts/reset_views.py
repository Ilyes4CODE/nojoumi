"""Password reset: ask for a code, check it, set a new password.

Three endpoints rather than two. The middle one exists purely so the app can tell
a parent that their code is wrong **before** asking them to invent a password —
being made to type a new password twice and only then told the code expired is
the kind of small cruelty that gets an app deleted. It costs nothing in safety
because both endpoints spend from the same five-attempt budget on the same row.

**Requesting a code says whether the address has an account** — the client's
choice on 2026-09-25, reversing the original design; see
`PasswordResetRequestView` for what that trades and what it buys.

Checking and confirming a code still answer with one sentence for a wrong code,
an expired code, a burnt-out code and an unknown address. By that point the
parent has already been told the address is real, so distinguishing them there
would add nothing but a second way to probe.
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
from .models import normalised_email

log = logging.getLogger(__name__)
ParentUser = get_user_model()

#: Said for a wrong code, an expired code, a code that ran out of attempts, and
#: an address with no account. One sentence for four states, on purpose.
BAD_CODE = "الرمز غير صحيح أو انتهت صلاحيته. اطلب رمزاً جديداً."

#: A code has just been sent.
SENT = "أرسلنا رمزاً إلى بريدك. تحقّق من صندوق الوارد، ومن مجلّد الرسائل غير المرغوبة."

#: Within the cooldown: the previous code is still valid.
RECENTLY_SENT = "أرسلنا إليك رمزاً قبل لحظات، وما زال صالحاً. تحقّق من بريدك، ومن مجلّد الرسائل غير المرغوبة."

#: No account has this address.
NO_ACCOUNT = "لا يوجد حساب بهذا البريد الإلكتروني. تحقّق من كتابته، أو أنشئ حساباً جديداً."

#: The account exists; the mail server refused the message.
SEND_FAILED = "تعذّر إرسال البريد الآن. حاول مرة أخرى بعد قليل."


def _parent(email: str):
    """The active account for an address, found with one index lookup.

    `email__iexact` read every row: SQLite's query plan for it is `SCAN TABLE`,
    because a case-insensitive LIKE cannot use an ordinary index. Addresses are
    stored lowercased (`normalised_email`), so lowercasing the input turns this
    into an exact match on a unique column — `SEARCH ... USING INDEX (email=?)`
    — which costs the same at ten parents as at a million.
    `test_password_reset.py` asserts that plan, so a return to `iexact` fails a
    test instead of quietly slowing down as the client grows.
    """
    return ParentUser.objects.filter(
        email=normalised_email(email), is_active=True
    ).first()


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
    """Send a code to the address — and say plainly when there is no account.

    **Changed on 2026-09-25, at the client's request.** This endpoint used to
    answer identically for an address with an account and one without, so it
    could not be used to find out which addresses exist. The client asked for
    the opposite: tell the parent at once when they have typed an address we do
    not know, rather than have them wait for a message that will never come.

    That trade was stated and taken. What it gives up is that anyone holding the
    phone can now ask "does this address have an account?" — and the throttle
    below is what keeps that a single question rather than a lookup service:
    fifteen an hour per caller, shared with the other two reset endpoints.

    **What it buys besides the message**, and this turned out to be the larger
    gain: a send failure no longer has to be hidden. Silence was only ever there
    so that a failure would not reveal a real address. With existence answered
    openly there is nothing left for silence to protect, and it had a real cost —
    a mailbox that the shell could reach and the web process could not looked,
    from outside, exactly like a mailbox that worked. It now says so.
    """

    permission_classes = [AllowAny]
    authentication_classes: list = []
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "password_reset"

    @extend_schema(
        request=ResetRequestSerializer,
        responses={200: None, 404: None, 503: None},
        summary="Request a password-reset code",
        description=(
            "200 when a code was sent (or one was sent in the last minute and is "
            "still valid). 404 when no account has this address. 503 when the "
            "account exists but the mail server refused the message."
        ),
    )
    def post(self, request):
        serializer = ResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        parent = _parent(serializer.validated_data["email"])
        if parent is None:
            return Response({"detail": NO_ACCOUNT}, status=status.HTTP_404_NOT_FOUND)

        code = reset_codes.issue(parent)
        if code is None:
            # Inside the cooldown. The code from a moment ago is still live, so
            # the honest answer is "check your inbox", not a second message the
            # parent cannot tell apart from the first.
            return Response({"detail": RECENTLY_SENT})

        try:
            mailer.send_reset_code(parent, code)
        except Exception:
            log.exception("could not send a reset code to parent %s", parent.pk)
            # The code is retired rather than left live: the parent never
            # received it, and a valid code nobody has is only an open door.
            reset_codes.PasswordResetCode.objects.filter(
                parent=parent, used_at__isnull=True
            ).update(used_at=timezone.now())
            return Response(
                {"detail": SEND_FAILED},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

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
