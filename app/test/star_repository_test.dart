import 'package:flutter_test/flutter_test.dart';
import 'package:nojoumi/data/local/database.dart';
import 'package:nojoumi/data/local/tables.dart';
import 'package:nojoumi/data/repositories/star_repository.dart';
import 'package:nojoumi_stars/nojoumi_stars.dart';
import 'package:nojoumi_time/nojoumi_time.dart';

import 'support/test_db.dart';

/// The pure package already proves Articles 5 and 6 in isolation (89 tests).
/// What is unproven until here is that the *database* keeps those guarantees:
/// that a granted star and its Article 6.2 dedupe row live or die together, that
/// the ledger stays the authority for the balance (AD-4), and that a rejection
/// leaves evidence behind rather than nothing.
void main() {
  late NojoumiDatabase db;
  late StarRepository stars;

  final rules = StarRules();
  final today = DayKey.fromEpochMs(
    DateTime.utc(2026, 3, 10, 9).millisecondsSinceEpoch,
    utcOffsetMinutes: DayKey.algeriaUtcOffsetMinutes,
  );

  /// Trusted time, since almost every test is about something other than the
  /// clock. The untrusted case gets its own test below.
  const trusted = TrustedInstant(
    epochMs: 1772000000000,
    level: TrustLevel.serverAnchored,
  );

  Attempt goodCard(int id, {int attemptNumber = 1, int ms = 3000}) => Attempt(
        targetId: StarRepository.targetKeyFor(EarnKind.memorizeCardFirstTime, id),
        kind: EarnKind.memorizeCardFirstTime,
        attemptNumber: attemptNumber,
        correct: true,
        msOnTarget: ms,
      );

  setUp(() async {
    db = await freshDatabase();
    stars = StarRepository(db);
  });

  tearDown(() async => db.close());

  group('AD-4 — the ledger is the authority', () {
    test('the derived balance matches the day row after a mixed sequence',
        () async {
      for (var i = 1; i <= 6; i++) {
        await stars.recordAttempt(
          rules: rules,
          attempt: goodCard(i),
          now: trusted,
          day: today,
        );
      }
      await stars.parentAdjust(
        day: today,
        deltaUnits: 3 * starUnit,
        now: trusted,
      );
      await stars.parentAdjust(
        day: today,
        deltaUnits: -2 * starUnit,
        now: trusted,
      );
      await stars.awardWeeklyTest(
        day: today,
        correct: 9,
        total: 10,
        now: trusted,
      );

      final day = await stars.dayProgress(today);
      final derived = await stars.derivedBalanceUnits(today);

      // 6 cards + 3 granted − 2 deducted + 40 for a 90% weekly test.
      expect(day.balanceUnits, (6 + 3 - 2 + 40) * starUnit);
      expect(derived, day.balanceUnits,
          reason: 'the ledger and the cached day row must never disagree');
    });

    test('an expiry is a negative ledger row, not a silent reset', () async {
      await stars.recordAttempt(
        rules: rules,
        attempt: goodCard(1),
        now: trusted,
        day: today,
      );
      await stars.rollOverTo(to: today.next, rules: rules, now: trusted);

      final expiryRows = await (db.select(db.starLedger)
            ..where((t) => t.kind.equalsValue(LedgerKind.expiry)))
          .get();

      expect(expiryRows, hasLength(1));
      expect(expiryRows.single.starUnits, -1 * starUnit);
      expect(expiryRows.single.dayKey, today.daysSinceEpoch,
          reason: 'the expiry belongs to the day whose balance died');
      expect((await stars.dayProgress(today.next)).balanceUnits, 0);
    });
  });

  group('Article 6 — the database keeps the joint conditions', () {
    test('6.2 — the same card cannot be counted twice in one day', () async {
      final first = await stars.recordAttempt(
        rules: rules,
        attempt: goodCard(42),
        now: trusted,
        day: today,
      );
      final second = await stars.recordAttempt(
        rules: rules,
        attempt: goodCard(42),
        now: trusted,
        day: today,
      );

      expect(first.decision.granted, isTrue);
      expect(second.decision.granted, isFalse);
      expect(second.decision.rejection, Rejection.alreadyCountedToday);
      expect(await stars.derivedBalanceUnits(today), 1 * starUnit);
    });

    test('6.2 — the same id in a later day is a new opportunity', () async {
      await stars.recordAttempt(
        rules: rules,
        attempt: goodCard(42),
        now: trusted,
        day: today,
      );
      final tomorrow = today.next;
      final again = await stars.recordAttempt(
        rules: rules,
        attempt: goodCard(42),
        now: trusted,
        day: tomorrow,
      );
      expect(again.decision.granted, isTrue);
    });

    test('6.4 — an award that would cross the ceiling lands exactly on it',
        () async {
      // 20 stars is the appendix's lowest legal ceiling, so this needs 10
      // review questions at 2 stars rather than 60 cards.
      final low = StarRules(dailyCeilingUnits: 20 * starUnit);
      for (var i = 1; i <= 11; i++) {
        await stars.recordAttempt(
          rules: low,
          attempt: Attempt(
            targetId: StarRepository.targetKeyFor(EarnKind.reviewQuestion, i),
            kind: EarnKind.reviewQuestion,
            attemptNumber: 1,
            correct: true,
            msOnTarget: 4000,
          ),
          now: trusted,
          day: today,
        );
      }

      final day = await stars.dayProgress(today);
      expect(day.earnedUnits, 20 * starUnit);
      expect(await stars.derivedBalanceUnits(today), 20 * starUnit);

      final capped = await (db.select(db.attempts)
            ..where((t) => t.cappedByCeiling.equals(true)))
          .get();
      expect(capped, isEmpty,
          reason: 'ten questions at 2 stars land on 20 exactly, with no trim');

      final refused = await (db.select(db.attempts)
            ..where(
              (t) => t.rejection.equalsValue(RejectionRow.dailyCeilingReached),
            ))
          .get();
      expect(refused, hasLength(1),
          reason: 'the eleventh question is refused, and the refusal is recorded');
    });

    test('6.8 — an untrusted clock grants nothing, and the attempt is still '
        'recorded as evidence', () async {
      const untrusted = TrustedInstant(
        epochMs: 1772000000000,
        level: TrustLevel.untrusted,
      );
      final result = await stars.recordAttempt(
        rules: rules,
        attempt: goodCard(7),
        now: untrusted,
        day: today,
      );

      expect(result.decision.rejection, Rejection.untrustedClock);
      expect(await stars.derivedBalanceUnits(today), 0);

      final rows = await db.select(db.attempts).get();
      expect(rows, hasLength(1));
      expect(rows.single.trustLevel, TrustLevelRow.untrusted);
      expect(rows.single.rejection, RejectionRow.untrustedClock,
          reason: 'AD-4 — the client asking "why no star?" gets a query, '
              'not a guess');
    });

    test('a rejected attempt leaves no counted-target row behind', () async {
      await stars.recordAttempt(
        rules: rules,
        attempt: goodCard(3, ms: 900),
        now: trusted,
        day: today,
      );
      expect(await db.select(db.countedTargets).get(), isEmpty,
          reason: 'a card that earned nothing must remain earnable today');
    });
  });

  group('Article 5 — the bonuses', () {
    test('the session bonus needs the day complete and is granted once',
        () async {
      await stars.setTaskCounts(day: today, total: 3, answered: 2);
      expect(
        (await stars.awardSessionBonus(now: trusted, day: today)).rejection,
        Rejection.sessionIncomplete,
      );

      await stars.setTaskCounts(day: today, total: 3, answered: 3);
      expect(
        (await stars.awardSessionBonus(now: trusted, day: today)).awardedUnits,
        Article5.fullSessionBonus,
      );
      expect(
        (await stars.awardSessionBonus(now: trusted, day: today)).rejection,
        Rejection.alreadyAwardedToday,
      );
      expect(await stars.derivedBalanceUnits(today), 5 * starUnit);
    });

    test('the attendance bonus needs a run of two days (Art. 6.6 resets it)',
        () async {
      await stars.markDayActive(today.previous);
      await stars.markDayActive(today);
      expect(
        (await stars.awardStreakBonus(now: trusted, day: today)).awardedUnits,
        Article5.streakBonus,
      );

      // A missed day, then a new day: the run restarts at one.
      final later = DayKey(today.daysSinceEpoch + 3);
      await stars.markDayActive(later);
      expect(
        (await stars.awardStreakBonus(now: trusted, day: later)).rejection,
        Rejection.streakTooShort,
      );
    });
  });

  group('appendix §5 — the welcome balance', () {
    test('is granted once, ever, even across day boundaries', () async {
      final first = await stars.grantWelcomeOnce(
        rules: rules,
        day: today,
        now: trusted,
      );
      expect(first, isNotNull);
      expect(await stars.derivedBalanceUnits(today), 10 * starUnit);

      expect(
        await stars.grantWelcomeOnce(rules: rules, day: today, now: trusted),
        isNull,
      );
      expect(
        await stars.grantWelcomeOnce(rules: rules, day: today.next, now: trusted),
        isNull,
      );
    });
  });

  group('appendix §2 — play time', () {
    test('consumption never exceeds the balance, and zero means blocking '
        'returns', () async {
      await stars.recordAttempt(
        rules: rules,
        attempt: goodCard(1),
        now: trusted,
        day: today,
      );

      // One star at the default value is 60 seconds.
      final over = await stars.consumePlay(rules: rules, day: today, seconds: 90);
      expect(over.secondsConsumed, 60);
      expect(over.remainingSeconds, 0);
      expect(over.blockingShouldReturn, isTrue);

      final again =
          await stars.consumePlay(rules: rules, day: today, seconds: 30);
      expect(again.secondsConsumed, 0,
          reason: 'an exhausted balance cannot go negative');
    });
  });

  group('appendix §4 — the parent is above the system', () {
    test('a deduction cannot push the balance below zero', () async {
      await stars.parentAdjust(day: today, deltaUnits: 2 * starUnit, now: trusted);
      await stars.parentAdjust(
        day: today,
        deltaUnits: -10 * starUnit,
        now: trusted,
      );
      final day = await stars.dayProgress(today);
      expect(day.balanceUnits, 0);
      expect(await stars.derivedBalanceUnits(today), 0,
          reason: 'the clamp must be recorded in the ledger, not applied '
              'silently on top of it');
    });

    test('a parent grant works on an untrusted clock', () async {
      const untrusted = TrustedInstant(
        epochMs: 1772000000000,
        level: TrustLevel.untrusted,
      );
      await stars.parentAdjust(
        day: today,
        deltaUnits: 5 * starUnit,
        now: untrusted,
      );
      expect(await stars.derivedBalanceUnits(today), 5 * starUnit,
          reason: 'a parent rewarding good behaviour must work on a phone '
              'whose clock we distrust');
    });
  });

  group('Article 6.7 — expiry', () {
    test('weekly mode carries the balance inside one week', () async {
      final weekly = StarRules(expiryMode: ExpiryMode.weekly);
      await stars.recordAttempt(
        rules: weekly,
        attempt: goodCard(1),
        now: trusted,
        day: today,
      );
      final carried =
          await stars.rollOverTo(to: today.next, rules: weekly, now: trusted);
      expect(carried.balanceUnits, 1 * starUnit);
      expect(carried.earnedUnits, 0,
          reason: 'carried balance must not consume tomorrow earning ceiling');
    });
  });
}
