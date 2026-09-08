"""The lesson-processing endpoint.

Article 14, restated as the contract for this module: the image arrives in the
request, is handed to the provider, and is gone when the response is written.
Nothing is stored — not the image, not the summary, not the cards, not the
questions. The result goes to the phone and lives only there (AD-6).

There is deliberately no model, no queryset and no serializer `.save()` in this
app. If a future change adds one, `tests/test_privacy.py` fails.
"""

from __future__ import annotations

import logging

from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.ai.processors import LessonProcessingError
from apps.ai.providers import get_processor

from .serializers import LessonRequestSerializer, LessonResultSerializer

log = logging.getLogger("lunio.lessons")


class ProcessLessonView(APIView):
    """POST a page photo, get back a summary, cards and questions."""

    parser_classes = [MultiPartParser]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "lesson"

    @extend_schema(
        request=LessonRequestSerializer,
        responses={
            200: LessonResultSerializer,
            422: None,
            502: None,
        },
        summary="Process one lesson page",
        description=(
            "Send a photograph of one schoolbook page; receive a summary, "
            "memorization cards and review questions.\n\n"
            "**The image is not stored anywhere** — it is read from the request, "
            "passed to the provider, and dropped (Art. 14). No copy is kept on "
            "the server in any form, for any duration."
        ),
    )
    def post(self, request):
        request_serializer = LessonRequestSerializer(data=request.data)
        request_serializer.is_valid(raise_exception=True)
        data = request_serializer.validated_data

        upload = data["image"]
        processor = get_processor()

        # The only moment the bytes exist in our process. Bound to a local, passed
        # once, never assigned to self, a module global, a cache or a model.
        image_bytes = upload.read()
        try:
            result = processor.process(
                image_bytes=image_bytes,
                content_type=upload.content_type or "image/jpeg",
                grade=data["grade"],
                subject=data.get("subject") or None,
                card_count=data["card_count"],
                question_count=data["question_count"],
            )
        except LessonProcessingError as exc:
            # Size and provider only. Never the bytes, never the lesson text.
            log.info(
                "lesson processing failed: provider=%s bytes=%d retryable=%s",
                processor.name,
                len(image_bytes),
                exc.retryable,
            )
            return Response(
                {"detail": str(exc), "retryable": exc.retryable},
                status=status.HTTP_502_BAD_GATEWAY
                if exc.retryable
                else status.HTTP_422_UNPROCESSABLE_ENTITY,
            )
        finally:
            # Explicit, for the reader more than for the interpreter: the last
            # reference we control is dropped here.
            del image_bytes

        if not result.is_usable():
            return Response(
                {
                    "detail": "لم نتمكّن من استخراج درس واضح من هذه الصورة.",
                    "retryable": False,
                },
                status=status.HTTP_422_UNPROCESSABLE_ENTITY,
            )

        log.info(
            "lesson processed: provider=%s model=%s cards=%d questions=%d ms=%d",
            result.provider,
            result.model,
            len(result.cards),
            len(result.questions),
            result.latency_ms,
        )
        return Response(LessonResultSerializer(result).data, status=status.HTTP_200_OK)
