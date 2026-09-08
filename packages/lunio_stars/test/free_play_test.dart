import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';
import 'package:test/test.dart';

/// Article 6.9 — play time the parent hands over directly.
///
/// Asked for by the client on 2026-08-30: a button for free play, with a
/// duration on it. The interesting part is not that it adds time; it is which
/// clauses it is and is not exempt from.
void main() {
  final rules = StarRules();
  const day = DayKey(20500);

  group('what free play does', () {
    test('adds to the play time available', () {
      const none = DayProgress(dayKey: day);
      const hour = DayProgress(dayKey: day, freePlaySeconds: 3600);

      expect(none.remainingPlaySeconds(rules), 0);
      expect(hour.remainingPlaySeconds(rules), 3600);
    });

    test('is spent through the same counter as earned time', () {
      // One pool on purpose: no order-of-consumption rule to get wrong, and no
      // way for two counters to disagree about when play ends.
      const progress = DayProgress(
        dayKey: day,
        grantedUnits: 1000, // 10 stars -> 600 s
        freePlaySeconds: 3600,
        usedPlaySeconds: 1200,
      );

      expect(progress.remainingPlaySeconds(rules), 600 + 3600 - 1200);
    });

    test('running out of it falls back on what the child earned', () {
      // What a parent expects without being told: the gift ends, the child's
      // own balance is still theirs.
      const progress = DayProgress(
        dayKey: day,
        grantedUnits: 1000, // 600 s
        freePlaySeconds: 1800,
        usedPlaySeconds: 1800,
      );

      expect(progress.remainingPlaySeconds(rules), 600);
    });

    test('play still ends when everything is spent', () {
      const progress = DayProgress(
        dayKey: day,
        freePlaySeconds: 1800,
        usedPlaySeconds: 5000,
      );

      expect(progress.remainingPlaySeconds(rules), 0);
      expect(progress.playExhausted(rules), isTrue);
    });
  });

  group('what it does not touch', () {
    test('Article 5 — it grants no stars', () {
      const progress = DayProgress(dayKey: day, freePlaySeconds: 7200);

      expect(
        progress.balanceUnits,
        0,
        reason: 'the child did not earn anything, and Article 5\'s table is the '
            'only thing that may put stars in the balance',
      );
    });

    test('Article 6.4 — it does not consume the daily ceiling', () {
      // The ceiling caps what the child *earns*. A parent handing over an
      // evening cannot cost the child stars they have not earned yet.
      const progress = DayProgress(dayKey: day, freePlaySeconds: 10800);

      expect(progress.remainingCeilingUnits(rules), rules.dailyCeilingUnits);
    });

    test('Article 6.7 — it belongs to the day and does not carry over', () {
      // Nothing to assert about tomorrow beyond this: the field lives on
      // DayProgress, so tomorrow's day has its own, at zero. This test exists
      // so that moving it anywhere else fails loudly — a free-play pool stored
      // per-child rather than per-day would be exactly the hoarding of play
      // hours the clause forbids.
      const today = DayProgress(dayKey: day, freePlaySeconds: 3600);
      const tomorrow = DayProgress(dayKey: DayKey(20501));

      expect(today.freePlaySeconds, 3600);
      expect(tomorrow.freePlaySeconds, 0);
      expect(tomorrow.remainingPlaySeconds(rules), 0);
    });

    test('consuming play still stops at what is available', () {
      // Article 4.7 — the engine never lets more be spent than exists, and
      // free play must not open a hole in that.
      const progress = DayProgress(dayKey: day, freePlaySeconds: 60);
      final consumed = const StarEngine().consumePlay(
        rules: rules,
        day: progress,
        seconds: 5000,
      );

      expect(consumed.day.usedPlaySeconds, 60);
      expect(consumed.day.remainingPlaySeconds(rules), 0);
    });
  });
}
