"""The Gemini adapter, which had no tests until it became the live provider.

Switched from Groq on 2026-10-06 at the client's request. The first real page
through it failed in one of two identical runs: the model spent 1583 tokens
"thinking", those came out of the same output allowance as the answer, and the
JSON was cut off mid-string. Nothing checked any of this, because nothing tested
the adapter at all.

These run without the network: `requests.post` is replaced with a recorder that
returns a staged Gemini response. What they cannot prove is that Google behaves
as staged — that is `tools/eval/run_eval.py` against real pages, run on the same
day.
"""

from __future__ import annotations

import json
from unittest import mock

from django.test import SimpleTestCase, override_settings

from apps.ai.processors import LessonProcessingError
from apps.ai.providers import GEMINI_MAX_OUTPUT_TOKENS, GeminiProcessor

GOOD_LESSON = {
    "readable": True,
    "summary": "ملخّص الدرس عن الحج وأركانه.",
    "cards": [{"front": f"سؤال {i}", "back": f"جواب {i}"} for i in range(12)],
    "questions": [
        {"prompt": f"سؤال {i}؟", "choices": ["أ", "ب", "ج", "د"], "correct_index": 1}
        for i in range(8)
    ],
}


def gemini_reply(payload: dict | None = None, *, finish="STOP", text=None, thoughts=0):
    response = mock.Mock()
    response.status_code = 200
    response.json.return_value = {
        "candidates": [
            {
                "finishReason": finish,
                "content": {
                    "parts": [{"text": text if text is not None else json.dumps(payload, ensure_ascii=False)}]
                },
            }
        ],
        "usageMetadata": {
            "promptTokenCount": 1488,
            "candidatesTokenCount": 760,
            "thoughtsTokenCount": thoughts,
        },
    }
    return response


@override_settings(
    GEMINI_API_KEY="test-key",
    GEMINI_MODEL="gemini-3.6-flash",
    GEMINI_BILLING_ENABLED=True,
    GEMINI_THINKING_BUDGET=0,
)
class WhatIsSent(SimpleTestCase):
    def process(self, reply=None):
        with mock.patch("apps.ai.providers.requests.post", return_value=reply or gemini_reply(GOOD_LESSON)) as post:
            result = GeminiProcessor().process(
                image_bytes=b"\xff\xd8 not really a jpeg",
                content_type="image/jpeg",
                grade="السنة الخامسة ابتدائي",
                card_count=12,
                question_count=8,
            )
        return result, post.call_args.kwargs["json"]

    def test_thinking_is_switched_off(self):
        # Left on, it ate the answer's allowance and truncated the JSON.
        _, body = self.process()
        self.assertEqual(body["generationConfig"]["thinkingConfig"], {"thinkingBudget": 0})

    def test_the_output_ceiling_is_generous(self):
        # A fully vowelled Arabic page produced 1789 tokens with thinking off.
        # Billing is on tokens produced, so the ceiling costs nothing; the old
        # one, sized to an estimate, was 2924 and sat 1100 tokens from failure.
        _, body = self.process()
        self.assertEqual(body["generationConfig"]["maxOutputTokens"], GEMINI_MAX_OUTPUT_TOKENS)
        self.assertGreaterEqual(GEMINI_MAX_OUTPUT_TOKENS, 8192)

    def test_the_answer_shape_is_enforced_by_the_server(self):
        _, body = self.process()
        config = body["generationConfig"]
        self.assertEqual(config["responseMimeType"], "application/json")
        self.assertEqual(config["responseSchema"], GeminiProcessor.RESPONSE_SCHEMA)

    def test_the_key_travels_in_a_header_not_the_url(self):
        # A key in the query string ends up in access logs and proxies.
        with mock.patch("apps.ai.providers.requests.post", return_value=gemini_reply(GOOD_LESSON)) as post:
            GeminiProcessor().process(
                image_bytes=b"x", content_type="image/jpeg", grade="g",
                card_count=12, question_count=8,
            )
        self.assertEqual(post.call_args.kwargs["headers"]["x-goog-api-key"], "test-key")
        self.assertNotIn("key=", post.call_args.args[0] if post.call_args.args else "")

    def test_a_good_reply_becomes_a_lesson(self):
        result, _ = self.process()
        self.assertEqual(len(result.cards), 12)
        self.assertEqual(len(result.questions), 8)
        self.assertTrue(result.summary)


@override_settings(
    GEMINI_API_KEY="test-key",
    GEMINI_MODEL="gemini-3.6-flash",
    GEMINI_BILLING_ENABLED=True,
    GEMINI_THINKING_BUDGET=0,
)
class WhatGoesWrong(SimpleTestCase):
    def process(self, reply):
        with mock.patch("apps.ai.providers.requests.post", return_value=reply):
            return GeminiProcessor().process(
                image_bytes=b"x", content_type="image/jpeg", grade="g",
                card_count=12, question_count=8,
            )

    def test_a_cut_off_answer_is_named_as_too_long(self):
        # The exact failure of 2026-10-06: MAX_TOKENS with *partial* text. It used
        # to fall through to the JSON parser and come out as "could not parse the
        # result", which sends everyone looking at the wrong thing.
        partial = json.dumps(GOOD_LESSON, ensure_ascii=False)[:366]
        with self.assertLogs("lunio.ai", level="WARNING"):
            with self.assertRaises(LessonProcessingError) as raised:
                self.process(gemini_reply(text=partial, finish="MAX_TOKENS", thoughts=1583))
        self.assertIn("طويلة جداً", str(raised.exception))

    def test_an_unreadable_page_is_refused_with_its_own_message(self):
        unreadable = {**GOOD_LESSON, "readable": False, "cards": [], "questions": []}
        with self.assertRaises(LessonProcessingError):
            self.process(gemini_reply(unreadable))

    def test_a_safety_block_is_a_clear_refusal(self):
        blocked = mock.Mock(status_code=200)
        blocked.json.return_value = {"promptFeedback": {"blockReason": "SAFETY"}}
        with self.assertLogs("lunio.ai", level="WARNING"):
            with self.assertRaises(LessonProcessingError):
                self.process(blocked)

    def test_a_rate_limit_is_retryable(self):
        throttled = mock.Mock(status_code=429, headers={"Retry-After": "7"}, text="quota", content=b"quota")
        throttled.json.return_value = {}
        with self.assertRaises(LessonProcessingError) as raised:
            self.process(throttled)
        self.assertTrue(raised.exception.retryable)

    def test_a_server_error_is_retryable(self):
        # 500 rather than 503: a 503 is now retried with real pauses (see
        # AHighDemandSpikeIsAbsorbed), which would make this test sleep six seconds.
        broken = mock.Mock(status_code=500, headers={}, text="unavailable", content=b"unavailable")
        broken.json.return_value = {}
        with self.assertRaises(LessonProcessingError) as raised:
            self.process(broken)
        self.assertTrue(raised.exception.retryable)


class TheArticle14Gate(SimpleTestCase):
    """Google's free tier may use inputs to improve its models and lets human
    reviewers read them; Article 14 forbids both for a child's lesson page."""

    @override_settings(GEMINI_API_KEY="k", GEMINI_MODEL="m", GEMINI_BILLING_ENABLED=False)
    def test_it_refuses_to_run_unless_billing_is_declared(self):
        with self.assertRaises(LessonProcessingError) as raised:
            GeminiProcessor()
        self.assertIn("free tier", str(raised.exception))

    @override_settings(GEMINI_API_KEY="", GEMINI_MODEL="m", GEMINI_BILLING_ENABLED=True)
    def test_it_refuses_to_run_without_a_key(self):
        with self.assertRaises(LessonProcessingError):
            GeminiProcessor()

    @override_settings(GEMINI_API_KEY="k", GEMINI_MODEL="", GEMINI_BILLING_ENABLED=True)
    def test_it_refuses_to_guess_a_model(self):
        with self.assertRaises(LessonProcessingError):
            GeminiProcessor()


@override_settings(
    GEMINI_API_KEY="test-key",
    GEMINI_MODEL="gemini-3.6-flash",
    GEMINI_BILLING_ENABLED=True,
    GEMINI_THINKING_BUDGET=0,
)
class TheCountsAreWhatWasAsked(SimpleTestCase):
    def test_extra_cards_are_trimmed_to_the_request(self):
        # Seen on a real page on 2026-10-06: 16 cards returned for 12 asked.
        generous = {**GOOD_LESSON, "cards": [{"front": f"f{i}", "back": f"b{i}"} for i in range(16)]}
        with mock.patch("apps.ai.providers.requests.post", return_value=gemini_reply(generous)):
            result = GeminiProcessor().process(
                image_bytes=b"x", content_type="image/jpeg", grade="g",
                card_count=12, question_count=8,
            )
        self.assertEqual(len(result.cards), 12)
        self.assertEqual(len(result.questions), 8)

    def test_fewer_than_asked_is_left_alone(self):
        # A short page honestly has less in it; padding would invent content.
        short = {**GOOD_LESSON, "cards": GOOD_LESSON["cards"][:5]}
        with mock.patch("apps.ai.providers.requests.post", return_value=gemini_reply(short)):
            result = GeminiProcessor().process(
                image_bytes=b"x", content_type="image/jpeg", grade="g",
                card_count=12, question_count=8,
            )
        self.assertEqual(len(result.cards), 5)


@override_settings(
    GEMINI_API_KEY="test-key",
    GEMINI_MODEL="gemini-3.6-flash",
    GEMINI_BILLING_ENABLED=True,
    GEMINI_THINKING_BUDGET=0,
)
class AHighDemandSpikeIsAbsorbed(SimpleTestCase):
    """Google's 503 "currently experiencing high demand" clears in seconds.

    On 2026-10-06 one page failed with it and succeeded on the next attempt.
    Without a retry here the parent would have seen «غير متوفّرة» for a blip.
    """

    @staticmethod
    def overloaded():
        r = mock.Mock(status_code=503, headers={}, text="high demand", content=b"high demand")
        r.json.return_value = {}
        return r

    def process(self, replies):
        with mock.patch("apps.ai.providers.time.sleep") as slept, mock.patch(
            "apps.ai.providers.requests.post", side_effect=replies
        ) as post:
            try:
                result = GeminiProcessor().process(
                    image_bytes=b"x", content_type="image/jpeg", grade="g",
                    card_count=12, question_count=8,
                )
            except LessonProcessingError as exc:
                result = exc
        return result, post.call_count, slept

    def test_one_503_then_success_is_a_lesson(self):
        with self.assertLogs("lunio.ai", level="INFO"):
            result, calls, _ = self.process([self.overloaded(), gemini_reply(GOOD_LESSON)])
        self.assertEqual(len(result.cards), 12)
        self.assertEqual(calls, 2)

    def test_it_gives_up_after_two_retries(self):
        # Bounded: three requests at most, so a real outage reaches the parent
        # well inside the app's 90-second timeout.
        with self.assertLogs("lunio.ai", level="INFO"):
            result, calls, slept = self.process([self.overloaded()] * 3)
        self.assertIsInstance(result, LessonProcessingError)
        self.assertTrue(result.retryable)
        self.assertEqual(calls, 3)
        self.assertEqual(sum(c.args[0] for c in slept.call_args_list), 6.0)

    def test_a_rate_limit_is_not_retried_here(self):
        # A 429 carries its own wait, which is longer than any pause worth
        # holding a request open for.
        throttled = mock.Mock(status_code=429, headers={"Retry-After": "30"}, text="q", content=b"q")
        throttled.json.return_value = {}
        with self.assertLogs("lunio.ai", level="WARNING"):
            _, calls, _ = self.process([throttled, gemini_reply(GOOD_LESSON)])
        self.assertEqual(calls, 1)
