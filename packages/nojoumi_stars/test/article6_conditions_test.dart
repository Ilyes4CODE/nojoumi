import 'package:nojoumi_stars/nojoumi_stars.dart';
import 'package:nojoumi_time/nojoumi_time.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Article 6 — "شروط الحصول على النجوم":
/// "لا تُمنح النجوم إلا باستيفاء الشروط التالية مجتمعة."
///
/// One test per bullet. Each starts from an attempt that satisfies every
/// condition and breaks exactly one, so a failure names the clause it broke.
void main() {
  const engine = StarEngine();
  final rules = StarRules();

  StarDecision run(Attempt a, {DayProgress? day, TrustedInstant? now}) =>
      engine.evaluate(
        rules: rules,
        day: day ?? today(),
        attempt: a,
        now: now ?? trusted(),
      );

  group('6.1 — correct on the FIRST attempt, and not after revealing the answer',
      () {
    test('a fully satisfying attempt earns its stars', () {
      expect(run(goodAttempt()).awardedStars, 1.0);
    });

    test('لا نجوم على الإجابة الخاطئة', () {
      final d = run(goodAttempt(correct: false));
      expect(d.granted, isFalse);
      expect(d.rejection, Rejection.wrongAnswer);
    });

    test('ولا بعد كشف الحل — no stars once the solution was revealed', () {
      final d = run(goodAttempt(solutionRevealed: true));
      expect(d.rejection, Rejection.solutionRevealed);
    });

    test('a correct answer on the second attempt earns nothing', () {
      final d = run(goodAttempt(attemptNumber: 2));
      expect(d.rejection, Rejection.notFirstAttempt);
    });

    test('the tenth attempt earns nothing either', () {
      expect(run(goodAttempt(attemptNumber: 10)).rejection,
          Rejection.notFirstAttempt);
    });
  });

  group('6.2 — not already counted the same day', () {
    test('the same card twice in one day pays once', () {
      final first = goodAttempt(targetId: 'card-7');
      var day = today();
      final d1 = run(first, day: day);
      expect(d1.granted, isTrue);
      day = engine.applyEarned(day, first, d1);

      final d2 = run(goodAttempt(targetId: 'card-7'), day: day);
      expect(d2.granted, isFalse);
      expect(d2.rejection, Rejection.alreadyCountedToday);
    });

    test('a different card on the same day still pays', () {
      final day = today(counted: {'card-7'});
      expect(run(goodAttempt(targetId: 'card-8'), day: day).granted, isTrue);
    });

    test('the same card tomorrow pays again — the rule is same-day only', () {
      final tomorrow = engine.rollOver(
        day: today(counted: {'card-7'}, earnedUnits: 500),
        to: theDay.next,
        rules: rules,
      );
      expect(tomorrow.countedTargetIds, isEmpty);
      expect(run(goodAttempt(targetId: 'card-7'), day: tomorrow).granted, isTrue);
    });
  });

  group('6.3 — must EXCEED the minimum time on the card (1.5 s default)', () {
    test('rapid random tapping earns nothing', () {
      final d = run(goodAttempt(msOnTarget: 200));
      expect(d.rejection, Rejection.belowMinimumTime);
    });

    test('exactly the threshold is not enough — the contract says "تجاوز"', () {
      expect(run(goodAttempt(msOnTarget: 1500)).rejection,
          Rejection.belowMinimumTime);
    });

    test('one millisecond over the threshold is enough', () {
      expect(run(goodAttempt(msOnTarget: 1501)).granted, isTrue);
    });

    test('the threshold follows the parent setting, not the default', () {
      final strict = StarRules(minimumTimeOnTargetMs: 5000);
      final d = engine.evaluate(
        rules: strict,
        day: today(),
        attempt: goodAttempt(msOnTarget: 3000),
        now: trusted(),
      );
      expect(d.rejection, Rejection.belowMinimumTime);
    });
  });

  group('6.4 — the daily star ceiling (60 stars default)', () {
    test('at the ceiling, nothing more is earned', () {
      final d = run(goodAttempt(), day: today(earnedUnits: 60 * starUnit));
      expect(d.granted, isFalse);
      expect(d.rejection, Rejection.dailyCeilingReached);
    });

    test('above the ceiling (parent lowered it mid-day) also stops earning', () {
      final d = run(goodAttempt(), day: today(earnedUnits: 90 * starUnit));
      expect(d.rejection, Rejection.dailyCeilingReached);
    });

    test('an award that would overshoot lands exactly on the ceiling', () {
      // 59.5 stars earned, a 2-star question would reach 61.5.
      final day = today(earnedUnits: 59 * starUnit + 50);
      final d = run(goodAttempt(kind: EarnKind.reviewQuestion), day: day);

      expect(d.granted, isTrue);
      expect(d.cappedByCeiling, isTrue);
      expect(d.awardedStars, 0.5);
      final after = engine.applyEarned(day, goodAttempt(), d);
      expect(after.earnedUnits, rules.dailyCeilingUnits);
    });

    test('parent grants are NOT subject to the ceiling (authority above the system)',
        () {
      final day = today(earnedUnits: 60 * starUnit);
      final after = engine.parentAdjust(day, 10 * starUnit);
      expect(after.balanceUnits, 70 * starUnit);
      expect(after.earnedUnits, 60 * starUnit,
          reason: 'grants must not consume the earning ceiling');
    });

    test('the ceiling respects the parent range: 20 stars minimum', () {
      final low = StarRules(dailyCeilingUnits: 20 * starUnit);
      final d = engine.evaluate(
        rules: low,
        day: today(earnedUnits: 20 * starUnit),
        attempt: goodAttempt(),
        now: trusted(),
      );
      expect(d.rejection, Rejection.dailyCeilingReached);
    });
  });

  group('6.5 — the session bonus needs 100% of the day\'s tasks', () {
    test('an incomplete session earns no bonus', () {
      final d = engine.sessionBonus(
        day: today(tasksTotal: 17, tasksAnswered: 16),
        now: trusted(),
      );
      expect(d.granted, isFalse);
      expect(d.rejection, Rejection.sessionIncomplete);
    });

    test('a complete session earns exactly 5 stars', () {
      final d = engine.sessionBonus(
        day: today(tasksTotal: 17, tasksAnswered: 17),
        now: trusted(),
      );
      expect(d.awardedStars, 5.0);
    });

    test('the bonus is once per day', () {
      final d = engine.sessionBonus(
        day: today(tasksTotal: 17, tasksAnswered: 17, sessionBonusAwarded: true),
        now: trusted(),
      );
      expect(d.rejection, Rejection.alreadyAwardedToday);
    });

    test(
        'completion means ANSWERED, not all-correct — appendix §3 grants the '
        'bonus to a child with 10/12 cards and 4/5 questions (decisions.md D-5)',
        () {
      final day = today(tasksTotal: 17, tasksAnswered: 17);
      expect(day.sessionComplete, isTrue);
      expect(engine.sessionBonus(day: day, now: trusted()).awardedStars, 5.0);
    });

    test('a day with no tasks is not a complete session', () {
      expect(today().sessionComplete, isFalse);
      expect(engine.sessionBonus(day: today(), now: trusted()).rejection,
          Rejection.sessionIncomplete);
    });
  });

  group('6.6 — the streak counts real consecutive days and resets on a gap', () {
    test('the attendance bonus is once per day', () {
      final d = engine.streakBonus(
        day: today(streakBonusAwarded: true),
        streak: const StreakState(consecutiveDays: 5),
        now: trusted(),
      );
      expect(d.rejection, Rejection.alreadyAwardedToday);
    });
  });

  group('6.7 — unused balance expires at end of day (no hoarding)', () {
    test('the default rules discard the balance overnight', () {
      final day = today(earnedUnits: 40 * starUnit, grantedUnits: 5 * starUnit);
      final next = engine.rollOver(day: day, to: theDay.next, rules: rules);

      expect(next.balanceUnits, 0);
      expect(next.usedPlaySeconds, 0);
      expect(next.dayKey, theDay.next);
    });

    test('weekly mode carries the balance to the next day', () {
      final weekly = StarRules(expiryMode: ExpiryMode.weekly);
      final day = today(earnedUnits: 40 * starUnit);
      final next = engine.rollOver(day: day, to: theDay.next, rules: weekly);

      expect(next.balanceUnits, 40 * starUnit);
      expect(next.earnedUnits, 0,
          reason: 'carried balance must not eat tomorrow\'s earning ceiling');
    });

    test('rolling over to the same day is not an expiry event', () {
      expect(
        engine.balanceExpires(from: theDay, to: theDay, rules: rules),
        isFalse,
      );
    });
  });

  group('6.8 — device date or time changes produce no balance', () {
    test('an untrusted clock rejects every kind of earning', () {
      final untrusted = trusted(level: TrustLevel.untrusted);

      expect(run(goodAttempt(), now: untrusted).rejection,
          Rejection.untrustedClock);
      expect(
        engine
            .sessionBonus(
              day: today(tasksTotal: 5, tasksAnswered: 5),
              now: untrusted,
            )
            .rejection,
        Rejection.untrustedClock,
      );
      expect(
        engine
            .streakBonus(
              day: today(),
              streak: const StreakState(consecutiveDays: 9),
              now: untrusted,
            )
            .rejection,
        Rejection.untrustedClock,
      );
    });

    test('the clock check wins over every other rejection reason', () {
      // A wrong answer, on the wrong attempt, too fast, already counted — the
      // reported cause is still the clock, because nothing may be awarded on
      // time we cannot defend.
      final d = run(
        goodAttempt(
          correct: false,
          attemptNumber: 4,
          msOnTarget: 10,
          targetId: 'card-1',
        ),
        day: today(counted: {'card-1'}, earnedUnits: 60 * starUnit),
        now: trusted(level: TrustLevel.untrusted),
      );
      expect(d.rejection, Rejection.untrustedClock);
    });

    test('an offline but monotonic clock still earns — honest families keep working',
        () {
      final d = run(goodAttempt(), now: trusted(level: TrustLevel.monotonic));
      expect(d.granted, isTrue);
    });
  });

  group('6.9 — the parent\'s authority is above the system', () {
    test('a grant works even when the clock is untrusted', () {
      final after = engine.parentAdjust(today(), 12 * starUnit);
      expect(after.balanceUnits, 12 * starUnit);
    });

    test('a deduction reduces the balance', () {
      final after = engine.parentAdjust(today(earnedUnits: 20 * starUnit),
          -5 * starUnit);
      expect(after.balanceUnits, 15 * starUnit);
    });

    test('a deduction cannot push the balance below zero', () {
      final after =
          engine.parentAdjust(today(earnedUnits: 3 * starUnit), -50 * starUnit);
      expect(after.balanceUnits, 0);
    });

    test('the welcome balance is 10 stars by default (appendix §5)', () {
      final after = engine.grantWelcome(today(), rules);
      expect(unitsToStars(after.balanceUnits), 10.0);
      expect(after.earnedUnits, 0);
    });
  });
}
