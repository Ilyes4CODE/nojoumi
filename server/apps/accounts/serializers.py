from __future__ import annotations

from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

ParentUser = get_user_model()


class InstallFieldsMixin(serializers.Serializer):
    """The app's install UUID, carried by register and by sign-in alike.

    Optional on the wire so that an older build, a curl call, or the developer
    poking at the API still works. It is the *view* that decides whether a
    missing id is acceptable — see `install_binding.py` for what the id anchors
    and, more importantly, what it does not.
    """

    install_id = serializers.UUIDField(required=False, allow_null=True)
    android_release = serializers.CharField(
        max_length=32, required=False, allow_blank=True
    )
    device_model = serializers.CharField(
        max_length=64, required=False, allow_blank=True
    )
    app_version = serializers.CharField(
        max_length=32, required=False, allow_blank=True
    )


class RegisterSerializer(InstallFieldsMixin, serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, style={"input_type": "password"})

    class Meta:
        model = ParentUser
        # The install fields are declared on the mixin and are not model
        # columns, so they must be named here too — a ModelSerializer builds its
        # field set from `Meta.fields`, and a declared field left out of it is
        # silently absent from `validated_data`. That is how the device binding
        # appeared to work while binding nothing.
        fields = (
            "email",
            "phone",
            "password",
            "install_id",
            "android_release",
            "device_model",
            "app_version",
        )
        extra_kwargs = {"phone": {"required": False}}

    def validate_password(self, value: str) -> str:
        validate_password(value)
        return value

    def create(self, validated_data):
        # The install fields describe the device, not the account. Strip them
        # before they reach `create_user`, which would reject them as unknown
        # columns — and which must never be given anything device-shaped anyway.
        for field in ("install_id", "android_release", "device_model", "app_version"):
            validated_data.pop(field, None)
        return ParentUser.objects.create_user(**validated_data)


class ParentSerializer(serializers.ModelSerializer):
    """The parent's own record. Deliberately thin — there is nothing else to say."""

    class Meta:
        model = ParentUser
        fields = ("id", "email", "phone", "date_joined")
        read_only_fields = fields


class InstallAwareTokenSerializer(InstallFieldsMixin, TokenObtainPairSerializer):
    """Sign-in, plus the one-account-per-device rule.

    Enforced here rather than only at registration because registration is not
    the way a second account arrives on a phone. A parent creates account B on
    their own device, hands the phone to the child, and the child signs in with
    it — no registration involved. Checking only at register would leave the rule
    protecting the least likely path.

    The check runs **after** the credentials are verified, never before. Refusing
    an unknown email because the device is claimed would tell an attacker holding
    the phone which addresses exist.
    """

    def validate(self, attrs):
        install_id = attrs.pop("install_id", None)
        android_release = attrs.pop("android_release", "")
        device_model = attrs.pop("device_model", "")
        app_version = attrs.pop("app_version", "")

        data = super().validate(attrs)

        if install_id is not None:
            from . import install_binding

            try:
                install_binding.bind(
                    install_id=install_id,
                    parent=self.user,
                    android_release=android_release,
                    device_model=device_model,
                    app_version=app_version,
                )
            except install_binding.InstallAlreadyClaimed as exc:
                raise serializers.ValidationError({"detail": str(exc)}) from exc

        return data
