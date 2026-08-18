from __future__ import annotations

from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

ParentUser = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, style={"input_type": "password"})

    class Meta:
        model = ParentUser
        fields = ("email", "phone", "password")
        extra_kwargs = {"phone": {"required": False}}

    def validate_password(self, value: str) -> str:
        validate_password(value)
        return value

    def create(self, validated_data):
        return ParentUser.objects.create_user(**validated_data)


class ParentSerializer(serializers.ModelSerializer):
    """The parent's own record. Deliberately thin — there is nothing else to say."""

    class Meta:
        model = ParentUser
        fields = ("id", "email", "phone", "date_joined")
        read_only_fields = fields
