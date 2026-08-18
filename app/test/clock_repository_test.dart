import 'package:flutter_test/flutter_test.dart';
import 'package:nojoumi/data/local/database.dart';
import 'package:nojoumi/data/repositories/clock_repository.dart';
import 'package:nojoumi_time/nojoumi_time.dart';

import 'support/fake_clock_source.dart';
import 'support/test_db.dart';

/// `nojoumi_time` proves the *rules* in 21 tests. What is unproven until here is
/// that the rules survive the round trip through SQLite: that the forward-only
/// high-water mark is actually persisted, that a tamper signal is recorded where
/// the parent dashboard can read it, and that a dead clock channel degrades to
/// untrusted instead of taking the app down.
///
/// Article 12 scenario 12 is run for real on hardware. These tests are what make
/// that run a confirmation rather than a discovery.
void main() {
  late NojoumiDatabase db;
  late FakeClockSource source;
  late ClockRepository clock;

  // 2026-03-10T09:00:00Z, an arbitrary but fixed starting point.
  const start = 1773133200000;

  setUp(() async {
    db = await freshDatabase();
    source = FakeClockSource(wallClockMs: start, elapsedRealtimeMs: 120000);
    clock = ClockRepository(db, source);
  });

  tearDown(() async => db.close());

  group('ordinary use', () {
    test('a first reading is monotonic, not server-anchored', () async {
      final now = await clock.now();
      expect(now.epochMs, start);
      expect(now.level, TrustLevel.monotonic,
          reason: 'nothing has been anchored yet, so full trust is not earned');
    });

    test('time advancing normally keeps trust and raises the high-water mark',
        () async {
      await clock.now();
      source.advance(const Duration(hours: 2));
      final later = await clock.now();

      expect(later.epochMs, start + const Duration(hours: 2).inMilliseconds);
      expect(later.level, TrustLevel.monotonic);
      expect((await clock.readState()).highWaterEpochMs, later.epochMs);
    });

    test('anchoring to server time earns full trust', () async {
      await clock.anchorTo(start);
      source.advance(const Duration(minutes: 30));
      final now = await clock.now();

      expect(now.level, TrustLevel.serverAnchored);
      expect(now.epochMs, start + const Duration(minutes: 30).inMilliseconds);
    });
  });

  group('Article 6.8 / 7.6 — the clock cannot be used to manufacture value', () {
    test('winding the clock back is refused, recorded, and does not move time',
        () async {
      await clock.now();
      source.jumpWallClock(-const Duration(days: 1));
      final now = await clock.now();

      expect(now.level, TrustLevel.untrusted);
      expect(now.epochMs, greaterThanOrEqualTo(start),
          reason: 'time is forward-only; yesterday cannot be replayed');

      final state = await clock.readState();
      expect(state.tamperCount, 1);
      expect(state.lastTamperSignal, TamperSignal.wallClockMovedBackwards);
    });

    test('jumping the clock forward inside one boot is refused', () async {
      await clock.now();
      // The monotonic clock advances a minute; the wall clock claims a week.
      source.advance(const Duration(minutes: 1));
      source.jumpWallClock(const Duration(days: 7));
      final now = await clock.now();

      expect(now.level, TrustLevel.untrusted);
      expect(
        now.epochMs,
        lessThan(start + const Duration(days: 7).inMilliseconds),
        reason: 'a subscription must not be extendable by setting the date',
      );
      expect(
        (await clock.readState()).lastTamperSignal,
        TamperSignal.wallClockJumpedForward,
      );
    });

    test('the tamper is written to the event log for the parent dashboard',
        () async {
      await clock.now();
      source.jumpWallClock(-const Duration(hours: 5));
      await clock.now();

      final events = await db.select(db.eventLog).get();
      expect(events, hasLength(1));
      expect(events.single.type, 'clock_tamper');
      expect(events.single.detail, TamperSignal.wallClockMovedBackwards.name);
    });

    test('the high-water mark survives the app being restarted', () async {
      await clock.now();
      source.advance(const Duration(days: 3));
      final high = (await clock.now()).epochMs;

      // A brand-new repository over the same database, as after process death.
      final revived = ClockRepository(db, source);
      source.jumpWallClock(-const Duration(days: 10));
      final now = await revived.now();

      expect(now.level, TrustLevel.untrusted);
      expect(now.epochMs, greaterThanOrEqualTo(high),
          reason: 'persistence is the whole point — a restart must not '
              'reset the forward-only mark');
    });
  });

  group('reboots', () {
    test('a reboot loses the anchor and downgrades trust, without accusing '
        'anyone', () async {
      await clock.anchorTo(start);
      expect((await clock.now()).level, TrustLevel.serverAnchored);

      source.advance(const Duration(hours: 6));
      source.reboot(upSince: const Duration(minutes: 2));
      final now = await clock.now();

      expect(now.level, TrustLevel.monotonic,
          reason: 'the monotonic clock restarted, so extrapolation is no '
              'longer valid — but nothing was tampered with');
      expect(
        (await clock.readState()).lastTamperSignal,
        TamperSignal.anchorLostToReboot,
      );
    });

    test('winding the clock back across a reboot is still refused', () async {
      await clock.now();
      source.advance(const Duration(days: 2));
      final high = (await clock.now()).epochMs;

      source.reboot();
      source.jumpWallClock(-const Duration(days: 5));
      final now = await clock.now();

      expect(now.level, TrustLevel.untrusted);
      expect(now.epochMs, high,
          reason: 'across a reboot the only surviving invariant is that time '
              'never runs backwards');
    });
  });

  group('a clock we cannot read at all', () {
    test('degrades to untrusted rather than throwing', () async {
      await clock.now();
      source.failing = true;

      final now = await clock.now();
      expect(now.level, TrustLevel.untrusted);
      expect(now.epochMs, start,
          reason: 'the last defensible instant, not a guess');

      final events = await db.select(db.eventLog).get();
      expect(events.single.type, 'clock_source_unavailable');
    });
  });
}
