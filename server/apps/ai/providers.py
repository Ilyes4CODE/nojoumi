"""Concrete processors, and the one place a provider is chosen.

Neither adapter writes the image anywhere. Both receive `bytes`, base64-encode
them into the request body, and let the local reference go out of scope with the
function. No file, no temp path, no cache key, no log line.
"""

from __future__ import annotations

import base64
import json
import random
import logging
import time
from typing import Any

import requests
from django.conf import settings

from .processors import (
    LessonProcessingError,
    LessonProcessor,
    LessonResult,
    MemorizationCard,
    ReviewQuestion,
)
from .prompts import SYSTEM_PROMPT, user_prompt

log = logging.getLogger("lunio.ai")

_TIMEOUT_SECONDS = 90


def _completion_budget(card_count: int, question_count: int) -> int:
    """How many completion tokens a lesson of this size plausibly needs.

    Measured against real pages: an Arabic summary runs ~300 tokens, a card ~60,
    a four-choice question ~120. The headroom covers models that emit reasoning
    tokens before the answer, which Qwen does.
    """
    return 500 + card_count * 50 + question_count * 100



def _shuffled(question: ReviewQuestion) -> ReviewQuestion:
    """Move the right answer somewhere unpredictable.

    **Language models put the correct choice first far more often than chance**,
    and the effect is strong enough to be visible in a handful of lessons — it
    was reported from the device on 2026-08-30 as the answer *always* being
    first. Left alone it does not merely look sloppy: a child works out within a
    day that the top option is usually right, the review stops measuring recall,
    and Article 5's two stars for a correct review question are paid for a
    pattern rather than for knowing anything.

    Shuffled **here**, once, on the way out of the provider. Every consumer is
    downstream of this point — the daily session, the weekly test, and anything
    added later — so there is no second place to remember. Doing it at display
    time instead would put the same logic in two screens and let one of them
    drift.

    `random`, not `secrets`: this is presentation order, not a secret. Nothing is
    protected by it and nobody gains by predicting it — the answer is on the
    screen either way.
    """
    order = list(range(len(question.choices)))
    random.shuffle(order)
    return ReviewQuestion(
        prompt=question.prompt,
        choices=tuple(question.choices[i] for i in order),
        # Where the right answer *landed*, which is not the same as where it
        # came from: `order` maps new position -> old, so the new index is the
        # position holding the old one.
        correct_index=order.index(question.correct_index),
    )


def _parse_duration(value: str) -> float | None:
    """Parse Groq's duration strings: "18.382s", "2m52.8s", "500ms"."""
    text = value.strip().lower()
    if not text:
        return None
    try:
        if text.endswith("ms"):
            return float(text[:-2]) / 1000
        total = 0.0
        number = ""
        for char in text:
            if char.isdigit() or char == ".":
                number += char
            elif char == "m":
                total += float(number or 0) * 60
                number = ""
            elif char == "s":
                total += float(number or 0)
                number = ""
        return total + float(number) if number else total
    except ValueError:
        return None


def _retry_after(response) -> float | None:
    """How long the provider wants us to wait.

    Prefers the standard `Retry-After`, then Groq's own rate-limit reset headers.
    The token bucket is the binding limit on the free tier (8 000 tokens/minute
    observed), and one lesson page costs roughly 1 800 prompt tokens, so pacing a
    ten-image acceptance run matters.
    """
    header = response.headers.get("retry-after")
    if header:
        try:
            return float(header)
        except ValueError:
            pass
    candidates = [
        _parse_duration(response.headers.get("x-ratelimit-reset-tokens", "")),
        _parse_duration(response.headers.get("x-ratelimit-reset-requests", "")),
    ]
    waits = [c for c in candidates if c]
    return max(waits) if waits else None


def _parse_payload(raw: str, *, provider: str, model: str, latency_ms: int,
                   usage: dict[str, int], card_limit: int | None = None,
                   question_limit: int | None = None) -> LessonResult:
    """Turn the provider's JSON into a LessonResult.

    On a parse failure we log the *shape* of the problem, never the content —
    lesson text is child data (Art. 14).
    """
    text = raw.strip()
    # Providers sometimes wrap JSON in a fenced block despite instructions.
    if text.startswith("```"):
        text = text.strip("`")
        if text.lower().startswith("json"):
            text = text[4:]
        text = text.strip()

    try:
        data: dict[str, Any] = json.loads(text)
    except json.JSONDecodeError as exc:
        log.warning("lesson payload was not valid JSON (%d chars)", len(text))
        raise LessonProcessingError(
            "تعذّر تحليل نتيجة المعالجة", retryable=True
        ) from exc

    if data.get("readable") is False:
        raise LessonProcessingError(
            "الصورة غير واضحة. أعد التصوير بإضاءة أفضل وصفحة مستوية.",
            retryable=False,
        )

    cards = tuple(
        MemorizationCard(front=str(c["front"]).strip(), back=str(c["back"]).strip())
        for c in data.get("cards", [])
        if str(c.get("front", "")).strip() and str(c.get("back", "")).strip()
    )

    questions: list[ReviewQuestion] = []
    for q in data.get("questions", []):
        choices = tuple(str(c).strip() for c in q.get("choices", []) if str(c).strip())
        idx = q.get("correct_index")
        if len(choices) < 2 or not isinstance(idx, int) or not 0 <= idx < len(choices):
            continue  # drop a malformed question rather than fail the lesson
        questions.append(
            _shuffled(
                ReviewQuestion(
                    prompt=str(q.get("prompt", "")).strip(),
                    choices=choices,
                    correct_index=idx,
                )
            )
        )

    # The parent asked for a number; a model that returns more has not followed
    # the request. Seen on 2026-10-06: one page of 22 came back with 16 cards for
    # 12 asked. Trimmed rather than refused — the extra items are well formed, and
    # failing a good lesson because it was generous would be the worse outcome.
    # Fewer than asked is left alone: a short page honestly has less in it.
    if card_limit is not None:
        cards = cards[:card_limit]
    if question_limit is not None:
        questions = questions[:question_limit]

    return LessonResult(
        summary=str(data.get("summary", "")).strip(),
        cards=cards,
        questions=tuple(questions),
        provider=provider,
        model=model,
        latency_ms=latency_ms,
        usage=usage,
    )


class GroqProcessor(LessonProcessor):
    """Development-time adapter (Groq, OpenAI-compatible chat completions).

    ⚠️ Article 14 requires a provider that does not train on API inputs. Groq's
    free-tier terms have **not** been verified yet, so this adapter must only be
    pointed at the developer's own sample photographs — never at a real child's
    schoolbook — until those terms are read. See docs/decisions.md Q10.
    """

    name = "groq"
    endpoint = "https://api.groq.com/openai/v1/chat/completions"

    def __init__(self, api_key: str | None = None, model: str | None = None) -> None:
        self.api_key = api_key or settings.GROQ_API_KEY
        self.model = model or settings.GROQ_MODEL
        # "none" disables reasoning on Qwen3 models. Settable to "" so a future
        # model that rejects the parameter can simply omit it.
        self.reasoning_effort = getattr(settings, "GROQ_REASONING_EFFORT", "none")
        if not self.api_key:
            raise LessonProcessingError("GROQ_API_KEY is not configured")
        if not self.model:
            raise LessonProcessingError(
                "GROQ_MODEL is not configured — set it explicitly rather than "
                "hardcoding a model name that may have been retired"
            )

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
        data_url = (
            f"data:{content_type};base64,"
            f"{base64.b64encode(image_bytes).decode('ascii')}"
        )
        body = {
            "model": self.model,
            "temperature": 0.2,
            # Bounding the completion is not an optimisation, it is required.
            # Groq rejects a request whose *estimated* total exceeds the
            # tokens-per-minute ceiling (8 000 on the free tier), and with no
            # max_tokens the estimate assumes a very large completion — so a
            # perfectly ordinary lesson page came back 400. Sizing it from the
            # requested counts keeps the estimate honest.
            "max_tokens": _completion_budget(card_count, question_count),
            # Verified working on qwen/qwen3.6-27b on 2026-08-15 (D-23), and on
            # qwen/qwen3.8-27b on 2026-09-27 when the new key lacked 3.6 (D-98).
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": user_prompt(
                                grade=grade,
                                subject=subject,
                                cards=card_count,
                                questions=question_count,
                            ),
                        },
                        {"type": "image_url", "image_url": {"url": data_url}},
                    ],
                },
            ],
        }

        # Qwen3.6 is a reasoning model: left alone it emits ~3 900 characters of
        # hidden reasoning before answering, which on a 1 860-token budget
        # truncated the JSON to 3 cards and no questions. Measured with reasoning
        # off: 714 completion tokens instead of 1 768, and byte-for-byte the same
        # 8 cards and 4 questions. Reasoning buys nothing when the task is
        # "transcribe this page into a fixed schema".
        if self.reasoning_effort:
            body["reasoning_effort"] = self.reasoning_effort

        started = time.monotonic()
        try:
            response = requests.post(
                self.endpoint,
                headers={"Authorization": f"Bearer {self.api_key}"},
                json=body,
                timeout=_TIMEOUT_SECONDS,
            )
        except requests.RequestException as exc:
            raise LessonProcessingError("تعذّر الاتصال بخدمة المعالجة", retryable=True) from exc
        latency_ms = int((time.monotonic() - started) * 1000)

        if response.status_code >= 400:
            # Status and length only. The body can echo prompt content.
            log.warning("groq returned %s (%d bytes)", response.status_code,
                        len(response.content))
            retryable = response.status_code >= 500 or response.status_code == 429
            message = "خدمة المعالجة غير متوفّرة حالياً"
            if response.status_code == 429:
                message = "الخدمة مشغولة. أعد المحاولة بعد لحظات."
            raise LessonProcessingError(
                message,
                retryable=retryable,
                retry_after_seconds=_retry_after(response),
            )

        payload = response.json()
        usage_raw = payload.get("usage") or {}
        usage = {
            "prompt_tokens": int(usage_raw.get("prompt_tokens", 0)),
            "completion_tokens": int(usage_raw.get("completion_tokens", 0)),
        }
        content = payload["choices"][0]["message"]["content"]
        return _parse_payload(
            content, provider=self.name, model=self.model,
            latency_ms=latency_ms, usage=usage,
            card_limit=card_count,
            question_limit=question_count,
        )


class ClaudeProcessor(LessonProcessor):
    """The contract's named provider (Art. 3: Claude API, Vision + Text).

    Deliberately left unimplemented rather than written from memory. Before this
    is filled in, the current Anthropic Messages API shape must be checked
    against live documentation — the same rule docs/CONVENTIONS.md applies to Chargily
    applies here.
    """

    name = "claude"

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
        raise LessonProcessingError(
            "ClaudeProcessor is not implemented yet. It is the contractually "
            "named provider (Art. 3) and must be in place for the Art. 11.3 "
            "acceptance run — but it will be written against current API "
            "documentation, not from memory."
        )


#: Gemini's output ceiling. See the note where it is used.
GEMINI_MAX_OUTPUT_TOKENS = 8192

#: Retries of a 503 "high demand" answer, and the base pause between them (it
#: grows: 2 s, then 4 s). Worst case adds ~6 s plus two requests, which still
#: fits the app's 90-second lesson timeout with a slow page.
_GEMINI_503_RETRIES = 2
_GEMINI_503_PAUSE_SECONDS = 2.0


class GeminiProcessor(LessonProcessor):
    """Google Gemini adapter, requested by the client on 2026-08-17.

    ⚠️ **Article 14 requires the PAID tier.** Google's Gemini API terms are
    explicit that on Unpaid Services *"Google uses the content you submit… to
    provide, improve, and develop Google products and services"* and *"human
    reviewers may read, annotate, and process your API input and output"*. Both
    are prohibited by Article 14. Only on Paid Services does Google state that it
    *"doesn't use your prompts or responses to improve our products"*.

    So this adapter refuses to run unless the deployment declares that billing is
    enabled — see `GEMINI_BILLING_ENABLED`. That flag is a deliberate speed bump:
    it cannot verify Google's billing state, but it forces somebody to state, in
    configuration, that the contractual condition is met.

    Also note: Article 3 names Claude API. Using Gemini is a second deviation from
    a signed clause and needs the client's written agreement — see
    docs/decisions.md D-29.
    """

    name = "gemini"
    base_url = "https://generativelanguage.googleapis.com/v1beta"

    # The exact shape we want back. Gemini enforces a response schema server-side,
    # which is stronger than asking a model politely for JSON — malformed output
    # becomes impossible rather than unlikely.
    RESPONSE_SCHEMA = {
        "type": "object",
        "properties": {
            "readable": {"type": "boolean"},
            "summary": {"type": "string"},
            "cards": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "front": {"type": "string"},
                        "back": {"type": "string"},
                    },
                    "required": ["front", "back"],
                },
            },
            "questions": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "prompt": {"type": "string"},
                        "choices": {"type": "array", "items": {"type": "string"}},
                        "correct_index": {"type": "integer"},
                    },
                    "required": ["prompt", "choices", "correct_index"],
                },
            },
        },
        "required": ["readable", "summary", "cards", "questions"],
    }

    def __init__(self, api_key: str | None = None, model: str | None = None) -> None:
        self.api_key = api_key or settings.GEMINI_API_KEY
        self.model = model or settings.GEMINI_MODEL
        # Zero by default (see settings). None means "send no thinkingConfig at
        # all": in August gemini-3.6-flash refused `thinkingBudget: 0` with a 400;
        # by October it accepts it. If a model ever refuses it again, an empty
        # GEMINI_THINKING_BUDGET restores the old behaviour without a code change.
        self.thinking_budget = getattr(settings, "GEMINI_THINKING_BUDGET", None)

        if not self.api_key:
            raise LessonProcessingError("GEMINI_API_KEY is not configured")
        if not self.model:
            raise LessonProcessingError(
                "GEMINI_MODEL is not configured — set it explicitly. Google "
                "retires and renames models, and a remembered default fails "
                "silently at delivery time."
            )
        if not getattr(settings, "GEMINI_BILLING_ENABLED", False):
            raise LessonProcessingError(
                "Refusing to send a lesson image to Gemini's free tier. Google's "
                "terms say Unpaid Services are used to improve their models and "
                "may be read by human reviewers; Article 14 forbids both. Enable "
                "billing on the Google Cloud project, then set "
                "GEMINI_BILLING_ENABLED=1 in server/.env."
            )

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
        body = {
            "system_instruction": {"parts": [{"text": SYSTEM_PROMPT}]},
            "contents": [
                {
                    "role": "user",
                    "parts": [
                        {
                            "text": user_prompt(
                                grade=grade,
                                subject=subject,
                                cards=card_count,
                                questions=question_count,
                            )
                        },
                        {
                            "inline_data": {
                                "mime_type": content_type,
                                "data": base64.b64encode(image_bytes).decode("ascii"),
                            }
                        },
                    ],
                }
            ],
            "generationConfig": {
                "temperature": 0.2,
                # A ceiling, not a spend: Google bills the tokens actually produced,
                # so a generous cap costs nothing and a tight one costs a lesson.
                # The old value (the completion estimate + 1024) assumed 400-650
                # thinking tokens; on 2026-10-06 the model spent 1583 and cut the
                # JSON off mid-string. Even with thinking off, a fully vowelled
                # Arabic page (the Hajj lesson) produced 1789 tokens against an
                # estimate of 1900 — too close to trust.
                "maxOutputTokens": GEMINI_MAX_OUTPUT_TOKENS,
                "responseMimeType": "application/json",
                # A server-enforced schema, which Groq's json_object mode cannot
                # do: malformed output becomes impossible rather than unlikely.
                # Measured to *reduce* output tokens (154 vs 280) as well.
                "responseSchema": self.RESPONSE_SCHEMA,
            },
        }

        # Gemini 2.5+ models think before answering. As with Qwen, thinking is pure
        # cost when the task is transcribing a page into a fixed schema — and here
        # it also competes with maxOutputTokens, which truncated Groq's output
        # before this was understood (D-28).
        if self.thinking_budget is not None:
            body["generationConfig"]["thinkingConfig"] = {
                "thinkingBudget": self.thinking_budget
            }

        started = time.monotonic()
        # Google answers a demand spike with 503 "This model is currently
        # experiencing high demand", and it clears in seconds: on 2026-10-06 the
        # same rotated page failed once and succeeded on the very next attempt.
        # Passing that straight to the parent as «غير متوفّرة» turns a two-second
        # blip into a failed lesson. So a 503 is retried here, twice, with a short
        # pause — bounded so the whole thing stays well inside the app's 90-second
        # lesson timeout. Anything else (a 4xx, a 429 with its own wait) is not
        # retried: those will not improve in two seconds.
        for attempt in range(_GEMINI_503_RETRIES + 1):
            try:
                response = requests.post(
                    f"{self.base_url}/models/{self.model}:generateContent",
                    headers={
                        "x-goog-api-key": self.api_key,
                        "Content-Type": "application/json",
                    },
                    json=body,
                    timeout=_TIMEOUT_SECONDS,
                )
            except requests.RequestException as exc:
                raise LessonProcessingError(
                    "تعذّر الاتصال بخدمة المعالجة", retryable=True
                ) from exc
            if response.status_code != 503 or attempt == _GEMINI_503_RETRIES:
                break
            log.info("gemini 503 (high demand), retrying (%d/%d)", attempt + 1, _GEMINI_503_RETRIES)
            time.sleep(_GEMINI_503_PAUSE_SECONDS * (attempt + 1))
        latency_ms = int((time.monotonic() - started) * 1000)

        if response.status_code >= 400:
            log.warning(
                "gemini returned %s (%d bytes)",
                response.status_code,
                len(response.content),
            )
            retryable = response.status_code >= 500 or response.status_code == 429
            raise LessonProcessingError(
                "الخدمة مشغولة. أعد المحاولة بعد لحظات."
                if response.status_code == 429
                else "خدمة المعالجة غير متوفّرة حالياً",
                retryable=retryable,
                retry_after_seconds=_retry_after(response),
            )

        payload = response.json()
        candidates = payload.get("candidates") or []
        if not candidates:
            # Usually a safety block. Log the reason code, never the content.
            reason = (payload.get("promptFeedback") or {}).get("blockReason", "unknown")
            log.warning("gemini returned no candidate (reason=%s)", reason)
            raise LessonProcessingError(
                "تعذّرت معالجة هذه الصورة. أعد التصوير بإضاءة أفضل."
            )

        candidate = candidates[0]
        finish = candidate.get("finishReason", "")
        parts = (candidate.get("content") or {}).get("parts") or []
        text = "".join(p.get("text", "") for p in parts)

        if finish == "MAX_TOKENS":
            # A partial answer used to fall through to the JSON parser and come out
            # as «تعذّر تحليل نتيجة المعالجة», which sends everybody looking at the
            # wrong thing. A cut-off answer is a budget problem and is named as one.
            log.warning(
                "gemini hit MAX_TOKENS (%d chars produced, thinking=%s)",
                len(text),
                (payload.get("usageMetadata") or {}).get("thoughtsTokenCount", 0),
            )
            raise LessonProcessingError(
                "النتيجة طويلة جداً. قلّل عدد البطاقات أو الأسئلة.", retryable=False
            )

        usage_raw = payload.get("usageMetadata") or {}
        usage = {
            "prompt_tokens": int(usage_raw.get("promptTokenCount", 0)),
            "completion_tokens": int(usage_raw.get("candidatesTokenCount", 0)),
            "thinking_tokens": int(usage_raw.get("thoughtsTokenCount", 0)),
        }
        return _parse_payload(
            text,
            provider=self.name,
            model=self.model,
            latency_ms=latency_ms,
            usage=usage,
            card_limit=card_count,
            question_limit=question_count,
        )


_REGISTRY: dict[str, type[LessonProcessor]] = {
    GroqProcessor.name: GroqProcessor,
    GeminiProcessor.name: GeminiProcessor,
    ClaudeProcessor.name: ClaudeProcessor,
}


def get_processor(name: str | None = None) -> LessonProcessor:
    """Resolve the configured processor. The only place a provider is chosen."""
    key = (name or settings.LESSON_PROCESSOR or "").strip().lower()
    try:
        return _REGISTRY[key]()
    except KeyError as exc:
        raise LessonProcessingError(
            f"unknown LESSON_PROCESSOR {key!r}; known: {sorted(_REGISTRY)}"
        ) from exc
