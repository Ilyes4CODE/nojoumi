import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Article 5, "نظام احتساب النجوم", as a table-driven test.
void main() {
  const engine = StarEngine();
  final rules = StarRules();

  group('Article 5 — the award table', () {
    final cases = <String, (EarnKind, double)>{
      'بطاقة حفظ صحيحة (أول مرة) = 1': (EarnKind.memorizeCardFirstTime, 1.0),
      'بطاقة في مراجعة لاحقة = 0.5': (EarnKind.cardInLaterReview, 0.5),
      'سؤال مراجعة صحيح = 2': (EarnKind.reviewQuestion, 2.0),
    };

    cases.forEach((label, expected) {
      test(label, () {
        final d = engine.evaluate(
          rules: rules,
          day: today(),
          attempt: goodAttempt(kind: expected.$1),
          now: trusted(),
        );
        expect(d.granted, isTrue);
        expect(d.awardedStars, expected.$2);
      });
    });

    test('إكمال الجلسة اليومية كاملة = 5+ مكافأة', () {
      final d = engine.sessionBonus(
        day: today(tasksTotal: 12, tasksAnswered: 12),
        now: trusted(),
      );
      expect(d.awardedStars, 5.0);
    });

    test('يومان متتاليان دون انقطاع (مواظبة) = 3+', () {
      final d = engine.streakBonus(
        day: today(),
        streak: const StreakState(consecutiveDays: 2),
        now: trusted(),
      );
      expect(d.awardedStars, 3.0);
    });
  });

  group('half stars survive the arithmetic', () {
    test('0.5 stars is 50 internal units, never a float', () {
      expect(EarnKind.cardInLaterReview.baseUnits, 50);
      expect(starsToUnits(0.5), 50);
      expect(unitsToStars(50), 0.5);
    });

    test('a hundred half-star reviews add up to exactly 50 stars', () {
      var day = today();
      for (var i = 0; i < 100; i++) {
        final attempt = goodAttempt(
          kind: EarnKind.cardInLaterReview,
          targetId: 'card-$i',
        );
        final d = engine.evaluate(
          rules: rules,
          day: day,
          attempt: attempt,
          now: trusted(),
        );
        day = engine.applyEarned(day, attempt, d);
      }
      expect(day.earnedUnits, 5000);
      expect(unitsToStars(day.earnedUnits), 50.0);
    });
  });

  group('Article 5 — the streak counter (Art. 6.6)', () {
    final d1 = DayKey.fromEpochMs(utcMs(2026, 8, 10), utcOffsetMinutes: dz);

    test('a run builds day by day', () {
      var s = const StreakState();
      s = s.withActiveDay(d1);
      expect(s.consecutiveDays, 1);
      s = s.withActiveDay(d1.next);
      expect(s.consecutiveDays, 2);
      s = s.withActiveDay(d1.next.next);
      expect(s.consecutiveDays, 3);
      expect(s.best, 3);
    });

    test('the same day twice does not double-count', () {
      var s = const StreakState().withActiveDay(d1);
      s = s.withActiveDay(d1);
      expect(s.consecutiveDays, 1);
    });

    test('any missed day resets the counter to one', () {
      var s = const StreakState().withActiveDay(d1).withActiveDay(d1.next);
      expect(s.consecutiveDays, 2);
      s = s.withActiveDay(d1.next.next.next); // skipped a day
      expect(s.consecutiveDays, 1);
      expect(s.best, 2, reason: 'the record is kept even after a reset');
    });

    test('a one-day run earns no attendance bonus', () {
      final d = engine.streakBonus(
        day: today(),
        streak: const StreakState().withActiveDay(d1),
        now: trusted(),
      );
      expect(d.granted, isFalse);
      expect(d.rejection, Rejection.streakTooShort);
    });
  });
}
