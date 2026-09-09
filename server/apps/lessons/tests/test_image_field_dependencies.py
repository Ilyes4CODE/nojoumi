"""The lesson upload needs Pillow, and nothing in our source says so.

**The bug this exists for.** `LessonRequestSerializer.image` is a
`serializers.ImageField`, which delegates to Django's `forms.ImageField`, which
does `from PIL import Image` **at validation time**. No line of this project
imports PIL. So the dependency is invisible to a linter, to an unused-import
check, to code review, and to the test suite — and it was missing from
`requirements.txt` until 2026-09-09.

On the production host every lesson upload returned 500 with
`ModuleNotFoundError: No module named 'PIL'`, while the identical request
succeeded locally in 3.2 seconds. The developer's machine happened to have
Pillow installed for unrelated reasons, so nothing local could ever have shown
it. The client reported it as "the AI is not working"; the request never reached
the AI.

Two tests, because the two failure modes are different:

* the declaration can be dropped from `requirements.txt` while the developer's
  machine still has the package;
* the field could be changed to something that no longer validates an image at
  all, which would pass a declaration check and break the contract's promise
  that an unreadable photograph is refused rather than sent to the model.
"""

from __future__ import annotations

import io
import pathlib

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import SimpleTestCase

from apps.lessons.serializers import LessonRequestSerializer


class PillowIsDeclared(SimpleTestCase):
    def test_requirements_pins_pillow(self):
        # The package is never imported by name in this project, so this file is
        # the only thing that will notice it going missing.
        requirements = (
            pathlib.Path(__file__).resolve().parents[3] / "requirements.txt"
        ).read_text(encoding="utf-8")

        self.assertIn(
            "Pillow==",
            requirements,
            "ImageField needs Pillow at validation time. Without it every "
            "lesson upload returns 500 on a clean install, and only on a clean "
            "install.",
        )


class TheImageFieldActuallyValidates(SimpleTestCase):
    """Exercises the field, which is what proves Pillow is really usable."""

    @staticmethod
    def _jpeg() -> bytes:
        from PIL import Image

        buffer = io.BytesIO()
        Image.new("RGB", (32, 32), (250, 250, 250)).save(buffer, "JPEG")
        return buffer.getvalue()

    def test_a_real_photograph_is_accepted(self):
        serializer = LessonRequestSerializer(
            data={
                "image": SimpleUploadedFile("page.jpg", self._jpeg(), "image/jpeg"),
                "grade": "السنة الخامسة ابتدائي",
                "card_count": 12,
                "question_count": 8,
            }
        )
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_a_file_that_is_not_an_image_is_refused(self):
        # Article 11.3 measures the pipeline on lesson photographs. Anything else
        # must be turned away here rather than spent on a model call.
        serializer = LessonRequestSerializer(
            data={
                "image": SimpleUploadedFile(
                    "page.jpg", b"this is not a picture", "image/jpeg"
                ),
                "grade": "السنة الخامسة ابتدائي",
                "card_count": 12,
                "question_count": 8,
            }
        )
        self.assertFalse(serializer.is_valid())
        self.assertIn("image", serializer.errors)
