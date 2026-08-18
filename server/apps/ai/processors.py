"""The one interface every lesson processor implements (AD-5).

Article 3 names Claude API (Vision + Text). Groq is a development-time choice
pending the client's written confirmation. Both sit behind this interface so the
switch is a settings change, not a rewrite — and so the Flutter app never learns
which provider is in use and never holds a key (Art. 7.7).

Article 14 rules that apply to every implementation, without exception:
  * the image is received as bytes, used inside the call, and dropped;
  * it is never written to disk, never logged, never cached, never returned;
  * the provider must not train on API inputs.
"""

from __future__ import annotations

import abc
from dataclasses import dataclass, field


@dataclass(frozen=True)
class MemorizationCard:
    """One flashcard. `front` is the prompt, `back` is the answer."""

    front: str
    back: str


@dataclass(frozen=True)
class ReviewQuestion:
    """One multiple-choice review question."""

    prompt: str
    choices: tuple[str, ...]
    correct_index: int

    def __post_init__(self) -> None:
        if not 0 <= self.correct_index < len(self.choices):
            raise ValueError("correct_index outside choices")


@dataclass(frozen=True)
class LessonResult:
    """What a processor returns. Contains no image and no identifiers."""

    summary: str
    cards: tuple[MemorizationCard, ...]
    questions: tuple[ReviewQuestion, ...]

    # Content-free telemetry, for the client's API cost tracking (Art. 17 puts
    # AI cost on their account, so they are owed the numbers).
    provider: str = ""
    model: str = ""
    latency_ms: int = 0
    usage: dict[str, int] = field(default_factory=dict)

    def is_usable(self) -> bool:
        """The minimum shape the acceptance run (Art. 11.3) measures."""
        return bool(self.summary.strip()) and bool(self.cards)


class LessonProcessingError(Exception):
    """A provider failure the caller may safely show to the parent."""

    def __init__(
        self,
        message: str,
        *,
        retryable: bool = False,
        retry_after_seconds: float | None = None,
    ) -> None:
        super().__init__(message)
        self.retryable = retryable
        # How long the provider asked us to wait. Surfacing it means the app can
        # say "حاول بعد دقيقة" instead of "حدث خطأ", and the eval harness can
        # pace a ten-image run instead of hammering a rate limit.
        self.retry_after_seconds = retry_after_seconds


class LessonProcessor(abc.ABC):
    """Turn one photographed lesson page into a summary, cards and questions."""

    name: str = "abstract"

    @abc.abstractmethod
    def process(
        self,
        *,
        image_bytes: bytes,
        content_type: str,
        grade: str,
        subject: str | None = None,
        card_count: int,
        question_count: int,
    ) -> LessonResult:
        """Process and return.

        Args:
            image_bytes: the page, in memory. **Must not be persisted anywhere.**
            content_type: the declared MIME type.
            grade: school grade, e.g. "السنة الرابعة ابتدائي". A pedagogical
                parameter, not an identifier — see docs/decisions.md D-11.
            subject: optional subject hint.
            card_count: how many memorization cards to produce. Comes from the
                parent's session size (appendix §5, range 5–30). Required with no
                default on purpose: a default here would be a contract number
                living as a literal, which AD-1 exists to prevent.
            question_count: how many review questions (D-15, range 0–15).

        Raises:
            LessonProcessingError: on any provider failure.
        """
        raise NotImplementedError
