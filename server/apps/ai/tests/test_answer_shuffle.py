"""The right answer must not always be first.

Reported from the device on 2026-08-30. Language models put the correct choice at
index 0 far more often than chance, and the bias is strong enough to notice in a
handful of lessons.

Left alone it is not a cosmetic problem. A child works out within a day that the
top option is usually right, the review stops measuring recall, and Article 5's
two stars for a correct review question are paid for spotting a pattern rather
than for knowing anything — which quietly empties the review half of Article 4.3.
"""

from __future__ import annotations

import json
from collections import Counter

from django.test import TestCase

from apps.ai.providers import _parse_payload


def payload(count: int, correct: int = 0) -> str:
    return json.dumps(
        {
            "summary": "ملخّص",
            "cards": [{"front": "س", "back": "ج"}],
            "questions": [
                {
                    "prompt": f"سؤال {i}",
                    "choices": ["ألف", "باء", "جيم", "دال"],
                    "correct_index": correct,
                }
                for i in range(count)
            ],
        },
        ensure_ascii=False,
    )


class TheAnswerMoves(TestCase):
    def parse(self, text: str):
        return _parse_payload(
            text, provider="test", model="test", latency_ms=1, usage={}
        )

    def test_the_correct_answer_is_not_always_first(self):
        # Every question arrives with the answer at index 0 — exactly what the
        # model does. After shuffling they must not all still be there.
        result = self.parse(payload(60))
        positions = Counter(q.correct_index for q in result.questions)

        self.assertGreater(
            len(positions), 1, msg="every answer is still in the same position"
        )
        # 60 questions over 4 choices is ~15 each. Above half is a shuffle that
        # is not shuffling.
        self.assertLess(positions[0], 30, msg="index 0 is still dominant")

    def test_the_answer_text_still_matches_the_index(self):
        # The only thing worse than a predictable answer is a wrong one. `order`
        # maps new position -> old, so the new index is the position holding the
        # old one — easy to invert by mistake, and invisible until a child is
        # marked wrong for being right.
        text = json.dumps(
            {
                "summary": "ملخّص",
                "cards": [],
                "questions": [
                    {
                        "prompt": "أيّها صحيح؟",
                        "choices": ["صح", "خطأ ١", "خطأ ٢", "خطأ ٣"],
                        "correct_index": 0,
                    }
                ],
            },
            ensure_ascii=False,
        )
        for _ in range(50):
            question = self.parse(text).questions[0]
            self.assertEqual(question.choices[question.correct_index], "صح")

    def test_every_choice_survives_the_shuffle(self):
        result = self.parse(payload(1))
        self.assertEqual(
            sorted(result.questions[0].choices),
            sorted(["ألف", "باء", "جيم", "دال"]),
        )

    def test_an_answer_that_was_not_first_is_still_correct(self):
        result = self.parse(payload(1, correct=2))
        question = result.questions[0]
        self.assertEqual(question.choices[question.correct_index], "جيم")

    def test_a_two_choice_question_still_works(self):
        # The smallest shuffle. `random.shuffle` on two items is a coin flip and
        # the mapping has to survive both outcomes.
        text = json.dumps(
            {
                "summary": "ملخّص",
                "cards": [],
                "questions": [
                    {
                        "prompt": "نعم أم لا؟",
                        "choices": ["نعم", "لا"],
                        "correct_index": 0,
                    }
                ],
            },
            ensure_ascii=False,
        )
        for _ in range(30):
            question = self.parse(text).questions[0]
            self.assertEqual(question.choices[question.correct_index], "نعم")
