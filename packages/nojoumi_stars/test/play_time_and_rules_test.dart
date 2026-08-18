import 'package:nojoumi_stars/nojoumi_stars.dart';
import 'package:nojoumi_time/nojoumi_time.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  const engine = StarEngine();

  group('appendix §2 — how the balance is spent', () {
    test('1 star = 1 minute by default', () {
      final rules = StarRules();
      expect(rules.playableSecondsFor(1 * starUnit), 60);
      expect(rules.playableSecondsFor(30 * starUnit), 30 * 60);
    });

    test('half a star is 30 seconds, not a rounded minute (decisions.md D-4)',
        () {
      final rules = StarRules();
      expect(rules.playableSecondsFor(starUnit ~/ 2), 30);
    });

    test('at the minimum star value, half a star is 15 seconds and stays exact',
        () {
      final rules = StarRules(starValueSeconds: 30); // 0.5 min
      expect(rules.playableSecondsFor(starUnit ~/ 2), 15);
      expect(rules.playableSecondsFor(3 * starUnit + 50), 105);
    });

    test('at the maximum star value, one star buys three minutes', () {
      final rules = StarRules(starValueSeconds: 180);
      expect(rules.playableSecondsFor(1 * starUnit), 180);
    });

    test('consumption never goes past zero', () {
      final rules = StarRules();
      final day = today(earnedUnits: 2 * starUnit);
      final play = engine.consumePlay(rules: rules, day: day, seconds: 999999);

      expect(play.secondsConsumed, 120);
      expect(play.remainingSeconds, 0);
      expect(play.blockingShouldReturn, isTrue);
    });

    test('consuming zero or negative seconds changes nothing', () {
      final rules = StarRules();
      final day = today(earnedUnits: 5 * starUnit);
      expect(engine.consumePlay(rules: rules, day: day, seconds: 0).secondsConsumed, 0);
      expect(engine.consumePlay(rules: rules, day: day, seconds: -60).secondsConsumed, 0);
      expect(
        engine.consumePlay(rules: rules, day: day, seconds: -60).remainingSeconds,
        5 * 60,
      );
    });

    test('second-by-second consumption sums exactly, with no drift', () {
      final rules = StarRules(starValueSeconds: 90); // 1.5 min per star
      var day = today(earnedUnits: 7 * starUnit + 50); // 7.5 stars -> 675 s
      expect(day.remainingPlaySeconds(rules), 675);

      for (var i = 0; i < 675; i++) {
        day = engine.consumePlay(rules: rules, day: day, seconds: 1).day;
      }
      expect(day.remainingPlaySeconds(rules), 0);
      expect(day.usedPlaySeconds, 675);
    });

    test('the daily play cap is the ceiling expressed in minutes (D-2)', () {
      expect(StarRules().dailyPlayCapSeconds, 60 * 60);
      expect(
        StarRules(dailyCeilingUnits: 30 * starUnit, starValueSeconds: 120)
            .dailyPlayCapSeconds,
        60 * 60,
      );
      expect(
        StarRules(dailyCeilingUnits: 150 * starUnit, starValueSeconds: 180)
            .dailyPlayCapSeconds,
        450 * 60,
      );
    });
  });

  group('expiry boundaries', () {
    test('the anchor day 2026-08-14 is a Friday', () {
      expect(DateTime.utc(2026, 8, 14).weekday, DateTime.friday);
      expect(StarEngine.weekdayOf(theDay), DateTime.friday);
    });

    test('weekdayOf agrees with DateTime over 400 consecutive days', () {
      for (var i = 0; i < 400; i++) {
        final day = theDay.daysSinceEpoch + i;
        final expected =
            DateTime.fromMillisecondsSinceEpoch(day * 86400000, isUtc: true)
                .weekday;
        expect(StarEngine.weekdayOf(DayKey(day)), expected, reason: 'day +$i');
      }
    });

    test('daily mode expires on every day change', () {
      final rules = StarRules();
      expect(
        engine.balanceExpires(from: theDay, to: theDay.next, rules: rules),
        isTrue,
      );
    });

    test('weekly mode does not expire inside the week', () {
      final rules = StarRules(expiryMode: ExpiryMode.weekly);
      // Friday -> Saturday, same week when the week starts on Friday.
      expect(
        engine.balanceExpires(from: theDay, to: theDay.next, rules: rules),
        isFalse,
      );
    });

    test('weekly mode expires when it crosses the expiry weekday', () {
      final rules = StarRules(expiryMode: ExpiryMode.weekly);
      final nextFriday = DayKey(theDay.daysSinceEpoch + 7);
      expect(
        engine.balanceExpires(from: theDay, to: nextFriday, rules: rules),
        isTrue,
      );
      // Thursday -> Friday also crosses.
      final thursday = theDay.previous;
      expect(
        engine.balanceExpires(from: thursday, to: theDay, rules: rules),
        isTrue,
      );
    });

    test('rolling over always clears the same-day dedupe and the bonus flags',
        () {
      final rules = StarRules(expiryMode: ExpiryMode.weekly);
      final day = today(
        earnedUnits: 20 * starUnit,
        counted: {'card-1', 'card-2'},
        tasksTotal: 12,
        tasksAnswered: 12,
        sessionBonusAwarded: true,
        streakBonusAwarded: true,
      );
      final next = engine.rollOver(day: day, to: theDay.next, rules: rules);

      expect(next.countedTargetIds, isEmpty);
      expect(next.sessionBonusAwarded, isFalse);
      expect(next.streakBonusAwarded, isFalse);
      expect(next.tasksAnswered, 0);
      expect(next.balanceUnits, 20 * starUnit, reason: 'weekly mode keeps it');
    });
  });

  group('StarRules validates against the appendix §5 ranges', () {
    test('the documented defaults are accepted', () {
      final r = StarRules();
      expect(r.starValueSeconds, 60);
      expect(unitsToStars(r.dailyCeilingUnits), 60.0);
      expect(r.minimumTimeOnTargetMs, 1500);
      expect(r.expiryMode, ExpiryMode.daily);
      expect(unitsToStars(r.welcomeUnits), 10.0);
      expect(r.dailySessionCards, 12);
      expect(r.dailyQuestionCount, 5);
    });

    test('every range boundary is accepted at both ends', () {
      expect(() => StarRules(starValueSeconds: 30), returnsNormally);
      expect(() => StarRules(starValueSeconds: 180), returnsNormally);
      expect(() => StarRules(dailyCeilingUnits: 20 * starUnit), returnsNormally);
      expect(() => StarRules(dailyCeilingUnits: 150 * starUnit), returnsNormally);
      expect(() => StarRules(minimumTimeOnTargetMs: 1000), returnsNormally);
      expect(() => StarRules(minimumTimeOnTargetMs: 5000), returnsNormally);
      expect(() => StarRules(welcomeUnits: 0), returnsNormally);
      expect(() => StarRules(welcomeUnits: 30 * starUnit), returnsNormally);
      expect(() => StarRules(dailySessionCards: 5), returnsNormally);
      expect(() => StarRules(dailySessionCards: 30), returnsNormally);
    });

    test('out-of-range values throw instead of being silently clamped', () {
      expect(() => StarRules(starValueSeconds: 20), throwsArgumentError);
      expect(() => StarRules(starValueSeconds: 240), throwsArgumentError);
      expect(() => StarRules(starValueSeconds: 75), throwsArgumentError,
          reason: 'half-minute steps only');
      expect(() => StarRules(dailyCeilingUnits: 19 * starUnit), throwsArgumentError);
      expect(
          () => StarRules(dailyCeilingUnits: 151 * starUnit), throwsArgumentError);
      expect(() => StarRules(minimumTimeOnTargetMs: 999), throwsArgumentError);
      expect(() => StarRules(minimumTimeOnTargetMs: 5001), throwsArgumentError);
      expect(() => StarRules(welcomeUnits: -100), throwsArgumentError);
      expect(() => StarRules(welcomeUnits: 31 * starUnit), throwsArgumentError);
      expect(() => StarRules(dailySessionCards: 4), throwsArgumentError);
      expect(() => StarRules(dailySessionCards: 31), throwsArgumentError);
      expect(() => StarRules(dailyQuestionCount: -1), throwsArgumentError);
      expect(() => StarRules(dailyQuestionCount: 16), throwsArgumentError);
    });

    test('copyWith re-validates rather than trusting the caller', () {
      expect(() => StarRules().copyWith(dailyCeilingUnits: 5 * starUnit),
          throwsArgumentError);
      expect(StarRules().copyWith(starValueSeconds: 120).starValueSeconds, 120);
    });
  });

  group('the engine is pure', () {
    test('evaluate never mutates the day it was given', () {
      final rules = StarRules();
      final day = today();
      final a = goodAttempt();

      engine.evaluate(rules: rules, day: day, attempt: a, now: trusted());

      expect(day.earnedUnits, 0);
      expect(day.countedTargetIds, isEmpty);
    });

    test('applyEarned returns a new day and leaves the old one alone', () {
      final rules = StarRules();
      final day = today();
      final a = goodAttempt();
      final d = engine.evaluate(rules: rules, day: day, attempt: a, now: trusted());
      final next = engine.applyEarned(day, a, d);

      expect(day.earnedUnits, 0);
      expect(next.earnedUnits, 100);
      expect(day.countedTargetIds, isEmpty);
      expect(next.countedTargetIds, {'card-1'});
    });

    test('a rejected decision changes nothing', () {
      final rules = StarRules();
      final day = today(earnedUnits: 500);
      final a = goodAttempt(correct: false);
      final d = engine.evaluate(rules: rules, day: day, attempt: a, now: trusted());

      expect(engine.applyEarned(day, a, d).earnedUnits, 500);
      expect(engine.applyEarned(day, a, d).countedTargetIds, isEmpty);
    });
  });
}
