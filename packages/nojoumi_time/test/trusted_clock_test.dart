import 'package:nojoumi_time/nojoumi_time.dart';
import 'package:test/test.dart';

/// A realistic starting point: 2026-08-14 16:00 UTC.
const int t0 = 1786924800000;
const int oneHour = 3600000;
const int oneDay = 86400000;

ClockReading r({
  required int wall,
  required int elapsed,
  String boot = 'boot-1',
}) =>
    ClockReading(wallClockMs: wall, elapsedRealtimeMs: elapsed, bootId: boot);

void main() {
  const clock = TrustedClock();

  group('server-anchored time (Art. 6.8 — the protected reference)', () {
    test('an anchor plus monotonic time gives full trust', () {
      final state = clock.anchor(
        const ClockState(),
        serverEpochMs: t0,
        reading: r(wall: t0, elapsed: 10000),
      );

      final res = clock.resolve(state, r(wall: t0 + 5000, elapsed: 15000));

      expect(res.instant.level, TrustLevel.serverAnchored);
      expect(res.instant.epochMs, t0 + 5000);
      expect(res.tamper, isNull);
    });

    test(
        'the wall clock is IGNORED while anchored: jumping it a day forward '
        'does not move trusted time (Art. 12 scenario 12)', () {
      final state = clock.anchor(
        const ClockState(),
        serverEpochMs: t0,
        reading: r(wall: t0, elapsed: 10000),
      );

      // The child sets the clock a day ahead. Only 60 seconds really passed.
      final res = clock.resolve(
        state,
        r(wall: t0 + oneDay, elapsed: 10000 + 60000),
      );

      expect(res.instant.level, TrustLevel.serverAnchored);
      expect(res.instant.epochMs, t0 + 60000,
          reason: 'anchored time follows the monotonic clock, not the wall clock');
      expect(res.instant.dayKey(), const TrustedInstant(epochMs: t0, level: TrustLevel.serverAnchored).dayKey(),
          reason: 'still the same civil day, so no new daily ceiling');
    });

    test('dragging the clock backwards while anchored changes nothing', () {
      final state = clock.anchor(
        const ClockState(),
        serverEpochMs: t0,
        reading: r(wall: t0, elapsed: 10000),
      );

      final res = clock.resolve(
        state,
        r(wall: t0 - oneDay, elapsed: 10000 + 30000),
      );

      expect(res.instant.epochMs, t0 + 30000);
      expect(res.instant.level, TrustLevel.serverAnchored);
    });

    test('an anchor older than the 7-day offline window degrades to monotonic',
        () {
      final state = clock.anchor(
        const ClockState(),
        serverEpochMs: t0,
        reading: r(wall: t0, elapsed: 0),
      );

      final res = clock.resolve(
        state,
        r(wall: t0 + 8 * oneDay, elapsed: 8 * oneDay),
      );

      expect(res.instant.level, TrustLevel.monotonic);
      expect(res.tamper, TamperSignal.anchorTooOld);
      expect(res.instant.epochMs, t0 + 8 * oneDay,
          reason: 'still the best estimate available, just no longer certain');
    });
  });

  group('no anchor, same boot session — the monotonic clock is the witness', () {
    ClockState seeded() => clock
        .resolve(
          const ClockState(),
          r(wall: t0, elapsed: 10000),
        )
        .state;

    test('an honest offline child keeps earning: wall clock tracks monotonic',
        () {
      final res = clock.resolve(seeded(), r(wall: t0 + 60000, elapsed: 70000));

      expect(res.instant.level, TrustLevel.monotonic);
      expect(res.instant.epochMs, t0 + 60000);
      expect(res.tamper, isNull);
    });

    test(
        'a forward jump the monotonic clock does not corroborate is provable '
        'tampering, and time stays where it really is', () {
      // 12 hours of wall clock, 2 minutes of real elapsed time.
      final res = clock.resolve(
        seeded(),
        r(wall: t0 + 12 * oneHour, elapsed: 10000 + 120000),
      );

      expect(res.instant.level, TrustLevel.untrusted);
      expect(res.tamper, TamperSignal.wallClockJumpedForward);
      expect(res.instant.epochMs, t0 + 120000,
          reason: 'we advance by the monotonic delta only');
      expect(res.state.tamperCount, 1);
    });

    test('a backwards jump is caught and time does not regress', () {
      final res = clock.resolve(
        seeded(),
        r(wall: t0 - 6 * oneHour, elapsed: 10000 + 5000),
      );

      expect(res.instant.level, TrustLevel.untrusted);
      expect(res.tamper, TamperSignal.wallClockMovedBackwards);
      expect(res.instant.epochMs, greaterThanOrEqualTo(t0));
    });

    test('an NTP-sized correction is tolerated, not treated as an attack', () {
      final res = clock.resolve(
        seeded(),
        r(wall: t0 + 40000, elapsed: 10000 + 1000),
      );

      expect(res.instant.level, TrustLevel.monotonic,
          reason: '40s of drift correction is inside the 90s tolerance');
      expect(res.tamper, isNull);
    });
  });

  group('across a reboot (Art. 12 scenario 11 territory)', () {
    test('a reboot loses the anchor but time still cannot go backwards', () {
      var state = clock.anchor(
        const ClockState(),
        serverEpochMs: t0,
        reading: r(wall: t0, elapsed: 500000),
      );
      state = clock.resolve(state, r(wall: t0, elapsed: 600000)).state;

      // Reboot: elapsedRealtime resets, boot id changes, and the child has set
      // the clock back a week.
      final res = clock.resolve(
        state,
        r(wall: t0 - 7 * oneDay, elapsed: 3000, boot: 'boot-2'),
      );

      expect(res.instant.level, TrustLevel.untrusted);
      expect(res.tamper, TamperSignal.wallClockMovedBackwards);
      expect(res.instant.epochMs, greaterThanOrEqualTo(t0),
          reason: 'the high-water mark survives reboots');
    });

    test('an ordinary reboot with an intact clock keeps working', () {
      final state = clock.anchor(
        const ClockState(),
        serverEpochMs: t0,
        reading: r(wall: t0, elapsed: 500000),
      );

      final res = clock.resolve(
        state,
        r(wall: t0 + 5 * 60000, elapsed: 40000, boot: 'boot-2'),
      );

      expect(res.instant.level, TrustLevel.monotonic);
      expect(res.instant.epochMs, t0 + 5 * 60000);
      expect(res.tamper, TamperSignal.anchorLostToReboot,
          reason: 'not an accusation — just a documented loss of certainty');
    });

    test('re-anchoring after reconnect restores full trust and clears the flag',
        () {
      var state = clock
          .resolve(
            const ClockState(tamperCount: 3,
                lastTamperSignal: TamperSignal.wallClockJumpedForward),
            r(wall: t0, elapsed: 1000),
          )
          .state;
      expect(state.lastTamperSignal, isNotNull);

      state = clock.anchor(
        state,
        serverEpochMs: t0 + oneHour,
        reading: r(wall: t0, elapsed: 2000),
      );
      final res = clock.resolve(state, r(wall: t0, elapsed: 3000));

      expect(res.instant.level, TrustLevel.serverAnchored);
      expect(res.instant.epochMs, t0 + oneHour + 1000);
      expect(res.state.lastTamperSignal, isNull);
      expect(res.state.tamperCount, 3, reason: 'history is kept, flag is not');
    });
  });

  group('the high-water mark', () {
    test('never regresses, over a long tampering sequence', () {
      var state = clock.anchor(
        const ClockState(),
        serverEpochMs: t0,
        reading: r(wall: t0, elapsed: 0),
      );

      var previousHigh = state.highWaterEpochMs;
      final attack = <ClockReading>[
        r(wall: t0 + oneDay, elapsed: 1000),
        r(wall: t0 - oneDay, elapsed: 2000),
        r(wall: t0 + 30 * oneDay, elapsed: 3000, boot: 'boot-2'),
        r(wall: t0, elapsed: 4000, boot: 'boot-2'),
        r(wall: t0 - 400 * oneDay, elapsed: 5000, boot: 'boot-3'),
      ];

      for (final reading in attack) {
        final res = clock.resolve(state, reading);
        expect(res.state.highWaterEpochMs, greaterThanOrEqualTo(previousHigh));
        expect(res.instant.epochMs, greaterThanOrEqualTo(previousHigh));
        previousHigh = res.state.highWaterEpochMs;
        state = res.state;
      }
    });

    test('trustworthiness is the single gate the star engine reads', () {
      expect(
        const TrustedInstant(epochMs: t0, level: TrustLevel.serverAnchored)
            .isTrustworthy,
        isTrue,
      );
      expect(
        const TrustedInstant(epochMs: t0, level: TrustLevel.monotonic)
            .isTrustworthy,
        isTrue,
      );
      expect(
        const TrustedInstant(epochMs: t0, level: TrustLevel.untrusted)
            .isTrustworthy,
        isFalse,
      );
    });
  });
}
