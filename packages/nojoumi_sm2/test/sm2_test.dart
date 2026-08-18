import 'package:nojoumi_sm2/nojoumi_sm2.dart';
import 'package:nojoumi_time/nojoumi_time.dart';
import 'package:test/test.dart';

final DayKey day0 = DayKey.fromEpochMs(
  DateTime.utc(2026, 8, 15, 16).millisecondsSinceEpoch,
  utcOffsetMinutes: DayKey.algeriaUtcOffsetMinutes,
);

DayKey plus(int days) => DayKey(day0.daysSinceEpoch + days);

CardSchedule card([String id = 'c1']) => CardSchedule(cardId: id);

void main() {
  const sm2 = Sm2Scheduler();

  group('the SM-2 interval ladder', () {
    test('a new card recalled correctly comes back tomorrow', () {
      final r = sm2.review(card: card(), grade: Sm2Grade.correctEasy, today: day0);

      expect(r.repetitions, 1);
      expect(r.intervalDays, 1);
      expect(r.dueDay, plus(1));
      expect(r.lastReviewedDay, day0);
    });

    test('the second success jumps to six days', () {
      var c = sm2.review(card: card(), grade: Sm2Grade.correctEasy, today: day0);
      c = sm2.review(card: c, grade: Sm2Grade.correctEasy, today: plus(1));

      expect(c.repetitions, 2);
      expect(c.intervalDays, 6);
      expect(c.dueDay, plus(7));
    });

    test('from the third success the interval scales by the ease factor', () {
      var c = sm2.review(card: card(), grade: Sm2Grade.correctHesitant, today: day0);
      c = sm2.review(card: c, grade: Sm2Grade.correctHesitant, today: plus(1));
      expect(c.easePermille, 2500, reason: 'grade 4 leaves ease unchanged');

      c = sm2.review(card: c, grade: Sm2Grade.correctHesitant, today: plus(7));
      expect(c.intervalDays, 15, reason: 'round(6 × 2.5)');
      expect(c.repetitions, 3);
    });

    test('a long correct run grows the interval without ever drifting', () {
      var c = card();
      var today = day0;
      for (var i = 0; i < 8; i++) {
        c = sm2.review(card: c, grade: Sm2Grade.correctHesitant, today: today);
        today = c.dueDay!;
      }
      // Ease untouched at 2.5 by grade 4 throughout: 1, 6, 15, 38, 95, 238, 595, 365(capped)
      expect(c.easePermille, 2500);
      expect(c.intervalDays, lessThanOrEqualTo(365));
      expect(c.repetitions, 8);
    });

    test('the interval is capped so a card never disappears for years', () {
      const capped = Sm2Scheduler(maximumIntervalDays: 30);
      var c = card();
      var today = day0;
      for (var i = 0; i < 10; i++) {
        c = capped.review(card: c, grade: Sm2Grade.correctEasy, today: today);
        today = c.dueDay!;
      }
      expect(c.intervalDays, 30);
    });

    test('the interval always advances, even at the minimum ease', () {
      var c = const CardSchedule(
        cardId: 'weak',
        repetitions: 5,
        intervalDays: 1,
        easePermille: CardSchedule.minimumEasePermille,
      );
      c = sm2.review(card: c, grade: Sm2Grade.correctHard, today: day0);
      expect(c.intervalDays, greaterThan(1),
          reason: 'round(1 × 1.3) = 1 would stall the card forever');
    });
  });

  group('lapses — Article 2\'s "weak cards resurface automatically"', () {
    test('a wrong answer resets the run and brings the card back tomorrow', () {
      var c = sm2.review(card: card(), grade: Sm2Grade.correctEasy, today: day0);
      c = sm2.review(card: c, grade: Sm2Grade.correctEasy, today: plus(1));
      expect(c.intervalDays, 6);

      c = sm2.review(card: c, grade: Sm2Grade.wrongButFamiliar, today: plus(7));

      expect(c.repetitions, 0);
      expect(c.intervalDays, 1);
      expect(c.dueDay, plus(8));
      expect(c.lapses, 1);
    });

    test('lapses accumulate and mark the card as weak', () {
      var c = card();
      for (var i = 0; i < 3; i++) {
        c = sm2.review(card: c, grade: Sm2Grade.blackout, today: plus(i));
      }
      expect(c.lapses, 3);
      expect(c.repetitions, 0);
    });

    test('repeated failure drives the ease to the 1.3 floor and stops', () {
      var c = card();
      for (var i = 0; i < 20; i++) {
        c = sm2.review(card: c, grade: Sm2Grade.blackout, today: plus(i));
      }
      expect(c.easePermille, CardSchedule.minimumEasePermille);
    });
  });

  group('the ease formula is exact in permille, not approximated', () {
    final deltas = <Sm2Grade, int>{
      Sm2Grade.correctEasy: 100,
      Sm2Grade.correctHesitant: 0,
      Sm2Grade.correctHard: -140,
      Sm2Grade.wrongAlmost: -320,
      Sm2Grade.wrongButFamiliar: -540,
      Sm2Grade.blackout: -800,
    };

    deltas.forEach((grade, delta) {
      test('grade ${grade.value} moves ease by $delta permille', () {
        final start = const CardSchedule(cardId: 'x', easePermille: 2500);
        final after = sm2.review(card: start, grade: grade, today: day0);
        final expected = 2500 + delta;
        expect(
          after.easePermille,
          expected < CardSchedule.minimumEasePermille
              ? CardSchedule.minimumEasePermille
              : expected,
        );
      });
    });

    test('ease never falls below 1.3', () {
      final low = const CardSchedule(cardId: 'x', easePermille: 1350);
      final after = sm2.review(card: low, grade: Sm2Grade.blackout, today: day0);
      expect(after.easePermille, CardSchedule.minimumEasePermille);
      expect(after.ease, 1.3);
    });
  });

  group('deriving the grade from what the star engine already saw (D-22)', () {
    Sm2Grade g({
      bool correct = true,
      int attempt = 1,
      bool revealed = false,
      int ms = 3000,
    }) =>
        Sm2Grade.fromObservation(
          correct: correct,
          attemptNumber: attempt,
          solutionRevealed: revealed,
          msOnTarget: ms,
        );

    test('fast and right on the first try is the top grade', () {
      expect(g(ms: 2000), Sm2Grade.correctEasy);
    });

    test('right but slow is one grade lower — slow is not easy', () {
      expect(g(ms: 15000), Sm2Grade.correctHesitant);
    });

    test('right only on a later attempt still counts as recalled, barely', () {
      expect(g(attempt: 3).recalled, isTrue);
      expect(g(attempt: 3), Sm2Grade.correctHard);
    });

    test('revealing the solution is never a recall, however fast', () {
      final grade = g(revealed: true, ms: 500);
      expect(grade.recalled, isFalse,
          reason: 'Art. 6.1: no stars after the solution was revealed, and no '
              'scheduling credit either');
    });

    test('one wrong first attempt is a lapse, several is a blackout', () {
      expect(g(correct: false), Sm2Grade.wrongButFamiliar);
      expect(g(correct: false, attempt: 3), Sm2Grade.blackout);
    });

    test('the fast threshold is injectable, not hardcoded for one age', () {
      expect(
        Sm2Grade.fromObservation(
          correct: true,
          attemptNumber: 1,
          solutionRevealed: false,
          msOnTarget: 9000,
          fastMs: 12000,
        ),
        Sm2Grade.correctEasy,
      );
    });
  });

  group('due dates', () {
    test('a never-reviewed card is due immediately', () {
      expect(card().isDue(day0), isTrue);
      expect(card().isNew, isTrue);
    });

    test('a card is due on its due day, not the day after', () {
      final c = sm2.review(card: card(), grade: Sm2Grade.correctEasy, today: day0);
      expect(c.isDue(day0), isFalse);
      expect(c.isDue(plus(1)), isTrue);
      expect(c.isDue(plus(5)), isTrue);
    });

    test('overdue is measured in whole days', () {
      final c = sm2.review(card: card(), grade: Sm2Grade.correctEasy, today: day0);
      expect(c.overdueBy(plus(1)), 0);
      expect(c.overdueBy(plus(4)), 3);
      expect(c.overdueBy(day0), -1);
    });

    test('a review can never schedule a card for the same day (Art. 6.2)', () {
      // Article 6.2 forbids counting the same card twice in one day, so the
      // scheduler must never hand it back today.
      for (final grade in Sm2Grade.values) {
        final c = sm2.review(card: card(), grade: grade, today: day0);
        expect(c.dueDay!.daysSinceEpoch, greaterThan(day0.daysSinceEpoch),
            reason: 'grade ${grade.value} scheduled the card for today');
      }
    });
  });

  group('the scheduler is pure', () {
    test('review returns a new schedule and leaves the input alone', () {
      final original = card();
      sm2.review(card: original, grade: Sm2Grade.blackout, today: day0);

      expect(original.repetitions, 0);
      expect(original.lapses, 0);
      expect(original.dueDay, isNull);
    });
  });
}
