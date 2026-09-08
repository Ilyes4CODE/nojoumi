import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/data/repositories/lesson_repository.dart';
import 'package:lunio_stars/lunio_stars.dart';

/// What the app asks the server to generate from one photographed page.
///
/// **The bug this exists for.** Capture used to send the parent's *daily*
/// settings as the generation size. On 2026-08-31 `dailySessionCards` became 0
/// (D-85, cards removed at the client's request) and the app started asking for
/// zero cards — which `LessonUploadSerializer` refuses, because appendix §5
/// bounds a session at 5–30. Every capture would have failed validation, and
/// nothing on the screen would have connected "could not read the page" to a
/// setting about session size.
///
/// Nothing failed at the time: the app compiled, the tests passed, and the
/// server was right to refuse. The two ends simply disagreed about what the
/// number meant.
void main() {
  group('the request stays inside the server ranges', () {
    // Mirrored from server/apps/lessons/serializers.py. If those move, this
    // fails and somebody has to look at both ends — which is the point.
    test('card count is within 5–30', () {
      expect(LessonYield.cards, inInclusiveRange(5, 30));
    });

    test('question count is within 0–15', () {
      expect(LessonYield.questions, inInclusiveRange(0, 15));
    });

    test('a page yields at least the daily defaults it has to feed', () {
      // Otherwise a parent raising the daily count finds an empty review: the
      // day cannot present material that was never generated.
      final rules = StarRules();
      expect(LessonYield.questions, greaterThanOrEqualTo(rules.dailyQuestionCount));
    });

    test('cards are generated even while they are not being asked', () {
      // D-85 turned the cards off as *one setting*, so that reversing it is one
      // setting too. That is only true if the material keeps being produced —
      // otherwise reversing it would find nothing for every lesson captured in
      // between.
      expect(
        LessonYield.cards,
        greaterThan(0),
        reason: 'the amendment is reversible only while the cards still exist',
      );
      expect(StarRules().dailySessionCards, 0, reason: 'and they are off today');
    });
  });

  test('capture does not size the request from a daily setting', () {
    // The shape of the original mistake, guarded at the source. `dailySession`
    // and `dailyQuestion` say how much a child does in a day; this request says
    // how much a page contains, and the two are free to disagree.
    final source = File(
      'lib/features/lesson/capture_screen.dart',
    ).readAsStringSync();

    for (final line in source.split('\n')) {
      final code = line.trimLeft();
      if (code.startsWith('//')) continue;
      if (!code.contains('cardCount:') && !code.contains('questionCount:')) {
        continue;
      }
      expect(
        code.contains('rules.'),
        isFalse,
        reason:
            'the generation size came from a daily setting again:\n  $code\n'
            'That is what sent card_count: 0 to a server that requires 5–30.',
      );
    }
  });
}
