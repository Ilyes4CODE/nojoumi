import 'package:nojoumi_stars/nojoumi_stars.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// The client's own worked example, from the appendix «آلية النجوم ووقت اللعب»
/// §3 «مثال ليوم كامل», encoded verbatim.
///
/// | 16:00 | balance zero, Nojoumi opens with 12 cards and 5 questions | 0 stars  |
/// | 16:05 | 10 of 12 cards correct                                   | 10 stars |
/// | 16:12 | 4 review questions correct                               | 18 stars |
/// | 16:14 | finished the full session, completion bonus              | 23 stars |
/// | 16:15 | back to the home screen, games open, 23-minute counter   | 23 min   |
/// | 16:30 | played 15 minutes then left for dinner, counter stopped  | 8 min    |
/// | 18:00 | played the rest, balance ended, blocking returned        | 0        |
/// | 18:08 | wanted more, went back to review, earned 12 more stars   | 12 min   |
///
/// Footnote: "مجموع اليوم: 35 دقيقة لعب مقابل حوالي 25 دقيقة مراجعة فعلية."
///
/// If a refactor ever breaks the client's printed example, this test fails
/// before the client notices.
void main() {
  const engine = StarEngine();
  final rules = StarRules(); // all defaults: 1 star = 1 minute, ceiling 60

  test('appendix §3 reproduces exactly: 0 -> 10 -> 18 -> 23 stars', () {
    // 16:00 — the day's session is 12 cards + 5 questions.
    var day = today(tasksTotal: 17, tasksAnswered: 0);
    expect(unitsToStars(day.balanceUnits), 0.0);

    // 16:05 — 10 of the 12 cards correct, first time, 1 star each.
    for (var i = 0; i < 10; i++) {
      final a = goodAttempt(
        kind: EarnKind.memorizeCardFirstTime,
        targetId: 'card-$i',
      );
      final d = engine.evaluate(
        rules: rules,
        day: day,
        attempt: a,
        now: trusted(),
      );
      expect(d.granted, isTrue);
      day = engine.applyEarned(day, a, d);
    }
    expect(unitsToStars(day.balanceUnits), 10.0, reason: '16:05 -> 10 نجوم');

    // 16:12 — 4 review questions correct, 2 stars each.
    for (var i = 0; i < 4; i++) {
      final a = goodAttempt(kind: EarnKind.reviewQuestion, targetId: 'q-$i');
      final d = engine.evaluate(
        rules: rules,
        day: day,
        attempt: a,
        now: trusted(),
      );
      day = engine.applyEarned(day, a, d);
    }
    expect(unitsToStars(day.balanceUnits), 18.0, reason: '16:12 -> 18 نجمة');

    // 16:14 — all 17 tasks answered (2 cards and 1 question were wrong, which
    // costs the stars but not the completion, per decisions.md D-5).
    day = day.copyWith(tasksAnswered: 17);
    final bonus = engine.sessionBonus(day: day, now: trusted());
    expect(bonus.awardedStars, 5.0);
    day = day.copyWith(
      grantedUnits: day.grantedUnits + bonus.awardedUnits,
      sessionBonusAwarded: true,
    );
    expect(unitsToStars(day.balanceUnits), 23.0, reason: '16:14 -> 23 نجمة');

    // 16:15 — the counter opens at 23 minutes.
    expect(day.remainingPlaySeconds(rules), 23 * 60, reason: '16:15 -> 23 دقيقة');

    // 16:30 — played 15 minutes, then left for dinner. The counter stopped.
    var play = engine.consumePlay(rules: rules, day: day, seconds: 15 * 60);
    day = play.day;
    expect(play.secondsConsumed, 15 * 60);
    expect(day.remainingPlaySeconds(rules), 8 * 60, reason: '16:30 -> 8 دقائق');
    expect(play.blockingShouldReturn, isFalse);

    // 18:00 — came back and played the rest. Balance ended, blocking returned.
    play = engine.consumePlay(rules: rules, day: day, seconds: 8 * 60);
    day = play.day;
    expect(day.remainingPlaySeconds(rules), 0, reason: '18:00 -> 0');
    expect(play.blockingShouldReturn, isTrue,
        reason: 'appendix §2: عند وصول الرصيد إلى الصفر، يعود الحجب فوراً');

    // 18:08 — wanted more, went back to review, earned 12 more stars.
    // Review cards pay 0.5 each, so 24 cards.
    for (var i = 0; i < 24; i++) {
      final a = goodAttempt(
        kind: EarnKind.cardInLaterReview,
        targetId: 'review-$i',
      );
      final d = engine.evaluate(
        rules: rules,
        day: day,
        attempt: a,
        now: trusted(),
      );
      expect(d.granted, isTrue);
      day = engine.applyEarned(day, a, d);
    }
    expect(day.remainingPlaySeconds(rules), 12 * 60, reason: '18:08 -> 12 دقيقة');

    // The appendix's footnote: 35 minutes of play across the whole day.
    expect(unitsToStars(day.balanceUnits), 35.0);
    expect(rules.playableSecondsFor(day.balanceUnits), 35 * 60,
        reason: 'مجموع اليوم: 35 دقيقة لعب');
  });

  test('earning more mid-day extends the counter without resetting what was used',
      () {
    var day = today(earnedUnits: 10 * starUnit);
    day = engine.consumePlay(rules: rules, day: day, seconds: 10 * 60).day;
    expect(day.remainingPlaySeconds(rules), 0);

    final a = goodAttempt(kind: EarnKind.reviewQuestion, targetId: 'q-late');
    final d = engine.evaluate(
      rules: rules,
      day: day,
      attempt: a,
      now: trusted(),
    );
    day = engine.applyEarned(day, a, d);

    expect(day.remainingPlaySeconds(rules), 2 * 60,
        reason: 'appendix §2: الطفل يستطيع في أي لحظة العودة إلى المهام');
    expect(day.usedPlaySeconds, 10 * 60, reason: 'consumption is not rewound');
  });
}
