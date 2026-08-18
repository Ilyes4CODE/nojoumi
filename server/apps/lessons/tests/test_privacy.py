"""Article 14 and Article 7.7, as executable guards.

These are the tests that matter most on this server, because the obligations they
cover are invisible to inspection. Nobody can look at a running server and see
that a lesson image was *not* stored. So it is asserted here, and re-asserted on
every commit.

Four of them are structural: they scan the whole project rather than one view, so
a future feature that adds an ImageField or a `card_number` column fails the
build instead of shipping.
"""

from __future__ import annotations

import builtins
import io
import logging
import os
import tempfile
from pathlib import Path

from django.apps import apps
from django.conf import settings
from django.contrib.auth import get_user_model
from django.db import models
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.ai.processors import (
    LessonProcessor,
    LessonResult,
    MemorizationCard,
    ReviewQuestion,
)

# A tiny valid PNG, so ImageField validation passes without Pillow guesswork.
PNG_1PX = (
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"
    b"\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01"
    b"\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"
)

# A marker we can search for anywhere it must not appear.
SECRET_MARKER = b"NOJOUMI-IMAGE-BYTES-MUST-NEVER-PERSIST"


class RecordingProcessor(LessonProcessor):
    """A processor that remembers only that it was called, and with how much."""

    name = "recording"

    def __init__(self) -> None:
        self.calls: list[int] = []
        self.saw_marker = False

    def process(
        self,
        *,
        image_bytes,
        content_type,
        grade,
        subject=None,
        card_count,
        question_count,
    ):
        self.calls.append(len(image_bytes))
        self.counts = (card_count, question_count)
        self.saw_marker = SECRET_MARKER in image_bytes
        return LessonResult(
            summary="ملخّص تجريبي للدرس.",
            cards=(MemorizationCard(front="سؤال", back="جواب"),),
            questions=(
                ReviewQuestion(
                    prompt="سؤال مراجعة",
                    choices=("أ", "ب", "ج", "د"),
                    correct_index=1,
                ),
            ),
            provider=self.name,
            model="test",
            latency_ms=1,
        )


def image_upload(extra: bytes = b"") -> io.BytesIO:
    """A PNG with an optional marker appended after the IEND chunk."""
    buf = io.BytesIO(PNG_1PX + extra)
    buf.name = "lesson.png"
    return buf


class StructuralPrivacyTests(TestCase):
    """Guards that scan the project, not a request."""

    def test_no_model_anywhere_can_hold_a_file_or_image(self):
        """Art. 14: "لا تخزين للصور … لا تُحفظ نسخة على الخادم في أي حال."

        The cheapest way to guarantee that is to make it impossible to express.
        """
        offenders = []
        for model in apps.get_models():
            for field in model._meta.get_fields():
                if isinstance(
                    field,
                    (models.FileField, models.ImageField, models.BinaryField),
                ):
                    offenders.append(
                        f"{model._meta.label}.{field.name} "
                        f"({type(field).__name__})"
                    )
        self.assertEqual(
            offenders,
            [],
            "Article 14 forbids storing images on the server. These fields could "
            f"hold one: {offenders}",
        )

    def test_no_model_field_looks_like_card_data(self):
        """Art. 7.7: the server stores only transaction id, amount, status, times.

        "لا يجمع التطبيق ولا الخادم أي بيانات بطاقة بنكية إطلاقاً — لا رقم بطاقة،
        ولا تاريخ صلاحية، ولا رمز تحقّق."
        """
        forbidden = (
            "card_number",
            "cardnumber",
            "pan",
            "cvv",
            "cvc",
            "card_holder",
            "cardholder",
            "expiry",
            "expiration_month",
            "expiration_year",
            "security_code",
        )
        offenders = []
        for model in apps.get_models():
            for field in model._meta.get_fields():
                name = getattr(field, "name", "").lower()
                if name in forbidden:
                    offenders.append(f"{model._meta.label}.{name}")
        self.assertEqual(
            offenders,
            [],
            "Article 7.7 is absolute: the server never holds card data. "
            f"Offending fields: {offenders}",
        )

    def test_lessons_app_defines_no_models_at_all(self):
        """AD-6: the server holds no child data, so this app stores nothing."""
        self.assertEqual(
            list(apps.get_app_config("lessons").get_models()),
            [],
            "the lessons app must remain stateless — a model here would mean "
            "lesson content is being persisted server-side",
        )

    def test_only_the_in_memory_upload_handler_is_configured(self):
        """The Article 14 trap.

        With Django's default handlers, any upload above 2.5 MB is written to a
        temporary file on disk *before our code runs*. A schoolbook photo is
        routinely 3–6 MB, so defaults alone would breach Article 14.
        """
        self.assertEqual(
            list(settings.FILE_UPLOAD_HANDLERS),
            ["django.core.files.uploadhandler.MemoryFileUploadHandler"],
            "TemporaryFileUploadHandler would spool the lesson image to disk",
        )

    def test_upload_limits_sit_above_the_largest_accepted_image(self):
        """Otherwise an accepted image could still be spooled."""
        self.assertGreater(
            settings.FILE_UPLOAD_MAX_MEMORY_SIZE,
            settings.LESSON_IMAGE_MAX_BYTES,
        )
        self.assertGreaterEqual(
            settings.DATA_UPLOAD_MAX_MEMORY_SIZE,
            settings.FILE_UPLOAD_MAX_MEMORY_SIZE,
        )

    def test_no_media_root_is_configured(self):
        """Nothing to write to, so nothing can be written by accident."""
        self.assertIn(getattr(settings, "MEDIA_ROOT", None), (None, "", Path("")))


class RequestPrivacyTests(TestCase):
    """Guards that watch an actual request go through."""

    def setUp(self):
        self.user = get_user_model().objects.create_user(
            "parent@example.com", password="Str0ng-Passw0rd!"
        )
        self.client = APIClient()
        self.client.force_authenticate(self.user)
        self.processor = RecordingProcessor()
        patcher = self.settings()  # no-op, keeps symmetry with override below
        del patcher

    def _post(self, extra: bytes = b"", **kwargs):
        from apps.lessons import views

        original = views.get_processor
        views.get_processor = lambda *a, **k: self.processor
        try:
            return self.client.post(
                "/api/lessons/process/",
                {
                    "image": image_upload(extra),
                    "grade": "السنة الرابعة ابتدائي",
                    **kwargs,
                },
                format="multipart",
            )
        finally:
            views.get_processor = original

    def test_the_request_succeeds_and_reaches_the_processor(self):
        response = self._post(SECRET_MARKER)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(self.processor.calls), 1)
        self.assertTrue(
            self.processor.saw_marker,
            "the processor must receive the real bytes, otherwise the rest of "
            "these tests prove nothing",
        )

    def test_no_file_is_written_to_disk_during_the_request(self):
        """The core Article 14 assertion."""
        writes: list[str] = []
        real_open = builtins.open

        def watching_open(file, mode="r", *args, **kwargs):
            if any(flag in str(mode) for flag in ("w", "a", "x", "+")):
                writes.append(f"{file!r} mode={mode!r}")
            return real_open(file, mode, *args, **kwargs)

        builtins.open = watching_open
        try:
            response = self._post(SECRET_MARKER)
        finally:
            builtins.open = real_open

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            writes,
            [],
            f"something opened a file for writing during lesson processing: {writes}",
        )

    def test_no_new_file_appears_in_the_temp_directory(self):
        tmp = Path(tempfile.gettempdir())
        before = set(os.listdir(tmp))

        response = self._post(SECRET_MARKER)
        self.assertEqual(response.status_code, 200)

        new_files = set(os.listdir(tmp)) - before
        leaked = []
        for name in new_files:
            path = tmp / name
            try:
                if path.is_file() and SECRET_MARKER in path.read_bytes():
                    leaked.append(name)
            except OSError:
                continue
        self.assertEqual(leaked, [], f"image bytes found in temp files: {leaked}")

    def test_image_bytes_never_reach_the_logs(self):
        stream = io.StringIO()
        handler = logging.StreamHandler(stream)
        root = logging.getLogger()
        root.addHandler(handler)
        previous = root.level
        root.setLevel(logging.DEBUG)
        try:
            response = self._post(SECRET_MARKER)
        finally:
            root.removeHandler(handler)
            root.setLevel(previous)

        self.assertEqual(response.status_code, 200)
        logged = stream.getvalue()
        self.assertNotIn(SECRET_MARKER.decode("ascii"), logged)
        self.assertNotIn("IHDR", logged, "a PNG header leaked into the logs")

    def test_the_response_echoes_no_image_data_back(self):
        response = self._post(SECRET_MARKER)

        self.assertEqual(response.status_code, 200)
        body = response.content
        self.assertNotIn(SECRET_MARKER, body)
        self.assertNotIn(b"IHDR", body)
        self.assertNotIn(b"base64", body.lower())
        # And the response shape is exactly what the phone needs, nothing more.
        self.assertEqual(
            set(response.json()),
            {"summary", "cards", "questions", "provider", "model", "latency_ms"},
        )

    @override_settings(LESSON_IMAGE_MAX_BYTES=64)
    def test_an_oversized_image_is_refused_explicitly(self):
        """Refused with a message, never silently discarded or spooled."""
        response = self._post(b"x" * 5000)

        self.assertEqual(response.status_code, 400)
        self.assertIn("image", response.json())
        self.assertEqual(
            self.processor.calls, [], "an oversized image must not reach a provider"
        )

    def test_card_and_question_counts_come_from_the_request_not_the_adapter(self):
        """D-24: a contract number must never be a literal in a provider."""
        response = self._post(card_count=20, question_count=3)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(self.processor.counts, (20, 3))

    def test_counts_outside_the_appendix_ranges_are_refused(self):
        """Appendix §5 bounds the session at 5–30 cards; D-15 bounds questions."""
        for field, bad in (
            ("card_count", 4),
            ("card_count", 31),
            ("question_count", -1),
            ("question_count", 16),
        ):
            with self.subTest(field=field, value=bad):
                response = self._post(**{field: bad})
                self.assertEqual(response.status_code, 400)
                self.assertIn(field, response.json())

    def test_the_defaults_match_the_appendix(self):
        """12 cards and 5 questions, as in appendix §5 and its worked example."""
        response = self._post()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(self.processor.counts, (12, 5))

    def test_the_endpoint_requires_authentication(self):
        anonymous = APIClient()
        response = anonymous.post(
            "/api/lessons/process/",
            {"image": image_upload(), "grade": "السنة الرابعة ابتدائي"},
            format="multipart",
        )
        self.assertIn(response.status_code, (401, 403))
