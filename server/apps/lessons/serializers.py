"""Request and response shapes for lesson processing.

Note what the request does **not** accept: no child name, no age in years, no
photo of a person, no location, no device identifier of the child. `grade` is a
school level, which is pedagogical and not identifying (Art. 14, D-11).
"""

from __future__ import annotations

from django.conf import settings
from rest_framework import serializers

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic"}


class LessonRequestSerializer(serializers.Serializer):
    """One page photo plus the pedagogical context needed to summarise it."""

    image = serializers.ImageField(write_only=True)
    grade = serializers.CharField(max_length=64)
    subject = serializers.CharField(max_length=64, required=False, allow_blank=True)

    # How many cards and questions to generate. Sent by the app from the parent's
    # settings, and bounded here by the appendix's published ranges (§5: session
    # size 5–30) and D-15 (questions 0–15). The bounds live here, not as literals
    # in a provider adapter — see docs/decisions.md D-24.
    card_count = serializers.IntegerField(min_value=5, max_value=30, default=12)
    question_count = serializers.IntegerField(min_value=0, max_value=15, default=5)

    def validate_image(self, value):
        """Reject anything Django would have had to spool to disk.

        The size ceiling is not a performance guard, it is an Article 14 guard:
        settings keep the in-memory upload handler as the only handler, so an
        oversized upload must be refused explicitly rather than silently
        discarded or written to a temporary file.
        """
        limit = settings.LESSON_IMAGE_MAX_BYTES
        if value.size > limit:
            mb = limit / (1024 * 1024)
            raise serializers.ValidationError(
                f"الصورة كبيرة جداً. الحد الأقصى {mb:.0f} ميغابايت."
            )
        if value.content_type and value.content_type not in ALLOWED_CONTENT_TYPES:
            raise serializers.ValidationError("نوع الصورة غير مدعوم.")
        return value


class MemorizationCardSerializer(serializers.Serializer):
    front = serializers.CharField()
    back = serializers.CharField()


class ReviewQuestionSerializer(serializers.Serializer):
    prompt = serializers.CharField()
    choices = serializers.ListField(child=serializers.CharField())
    correct_index = serializers.IntegerField()


class LessonResultSerializer(serializers.Serializer):
    """The response. Contains no image and nothing echoing one back."""

    summary = serializers.CharField()
    cards = MemorizationCardSerializer(many=True)
    questions = ReviewQuestionSerializer(many=True)
    provider = serializers.CharField()
    model = serializers.CharField()
    latency_ms = serializers.IntegerField()
