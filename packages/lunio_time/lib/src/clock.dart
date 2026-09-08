import 'day_key.dart';

/// How much we trust a resolved instant.
///
/// This is the whole point of the package. Article 6.8 says changing the device
/// date or time must never produce balance, and Article 7.6 says the same for
/// the subscription. Both rules reduce to: *some* decisions may only be made on
/// time we can defend.
enum TrustLevel {
  /// Derived from a server timestamp plus elapsed monotonic time inside the
  /// same boot session. Immune to wall-clock changes. Full trust.
  serverAnchored,

  /// No usable server anchor, but the wall clock is at or ahead of our
  /// high-water mark and nothing contradicts it. Good enough to keep an
  /// honest offline family working.
  monotonic,

  /// The wall clock contradicts something we know: it moved backwards, or it
  /// jumped forward without the corresponding monotonic time having passed.
  /// No stars, no new day, no subscription extension.
  untrusted,
}

/// Why trust was downgraded. Recorded so the parent dashboard can say
/// something truthful instead of the app silently refusing to award stars.
enum TamperSignal {
  /// Wall clock is behind the highest time we have already seen.
  wallClockMovedBackwards,

  /// Wall clock jumped forward by more than the monotonic clock advanced
  /// within one boot session — only possible if someone set the clock.
  wallClockJumpedForward,

  /// The anchor belongs to a previous boot, so monotonic extrapolation from it
  /// is no longer valid. Not an accusation, just a loss of certainty.
  anchorLostToReboot,

  /// Offline for longer than the allowed provisional window.
  anchorTooOld,
}

/// One observation of the platform's clocks. Supplied by the Kotlin layer;
/// nothing in this package reads a clock itself.
class ClockReading {
  const ClockReading({
    required this.wallClockMs,
    required this.elapsedRealtimeMs,
    required this.bootId,
  });

  /// `System.currentTimeMillis()`. User-settable, therefore untrusted input.
  final int wallClockMs;

  /// `SystemClock.elapsedRealtime()` — monotonic since boot, and it keeps
  /// counting through deep sleep. Resets to ~0 on reboot. Not user-settable,
  /// which is exactly why it is the backbone of this design.
  final int elapsedRealtimeMs;

  /// Stable for the lifetime of one boot, different after a reboot. Lets us
  /// tell "the monotonic clock went backwards" (impossible) from "the device
  /// rebooted" (ordinary).
  final String bootId;
}

/// Everything the clock must remember across process death and reboots.
/// Persisted by the app layer; this package never does IO.
class ClockState {
  const ClockState({
    this.anchorServerEpochMs,
    this.anchorElapsedRealtimeMs,
    this.anchorBootId,
    this.highWaterEpochMs = 0,
    this.lastBootId,
    this.lastElapsedRealtimeMs = 0,
    this.tamperCount = 0,
    this.lastTamperSignal,
  });

  /// Server time at the moment of the last successful sync.
  final int? anchorServerEpochMs;

  /// `elapsedRealtime` captured in the same instant as [anchorServerEpochMs].
  final int? anchorElapsedRealtimeMs;

  /// Boot session the anchor was captured in.
  final String? anchorBootId;

  /// The latest instant we have ever resolved. Time never runs backwards, so
  /// neither does this. This single value is what makes "set the clock back to
  /// replay yesterday" pointless.
  final int highWaterEpochMs;

  final String? lastBootId;
  final int lastElapsedRealtimeMs;

  final int tamperCount;
  final TamperSignal? lastTamperSignal;

  bool get hasAnchor =>
      anchorServerEpochMs != null &&
      anchorElapsedRealtimeMs != null &&
      anchorBootId != null;

  ClockState copyWith({
    int? anchorServerEpochMs,
    int? anchorElapsedRealtimeMs,
    String? anchorBootId,
    int? highWaterEpochMs,
    String? lastBootId,
    int? lastElapsedRealtimeMs,
    int? tamperCount,
    TamperSignal? lastTamperSignal,
    bool clearTamperSignal = false,
  }) {
    return ClockState(
      anchorServerEpochMs: anchorServerEpochMs ?? this.anchorServerEpochMs,
      anchorElapsedRealtimeMs:
          anchorElapsedRealtimeMs ?? this.anchorElapsedRealtimeMs,
      anchorBootId: anchorBootId ?? this.anchorBootId,
      highWaterEpochMs: highWaterEpochMs ?? this.highWaterEpochMs,
      lastBootId: lastBootId ?? this.lastBootId,
      lastElapsedRealtimeMs:
          lastElapsedRealtimeMs ?? this.lastElapsedRealtimeMs,
      tamperCount: tamperCount ?? this.tamperCount,
      lastTamperSignal: clearTamperSignal
          ? null
          : (lastTamperSignal ?? this.lastTamperSignal),
    );
  }
}

/// A point in time the app is allowed to make decisions on, carrying the
/// evidence for how much it can be trusted.
///
/// Nothing outside this package may construct one from a wall clock. The star
/// engine and the subscription machine take this type and never `DateTime.now()`,
/// which is what makes Articles 6.8 and 7.6 testable with no device attached.
class TrustedInstant {
  const TrustedInstant({required this.epochMs, required this.level});

  final int epochMs;
  final TrustLevel level;

  bool get isTrustworthy => level != TrustLevel.untrusted;

  DayKey dayKey({int utcOffsetMinutes = DayKey.algeriaUtcOffsetMinutes}) =>
      DayKey.fromEpochMs(epochMs, utcOffsetMinutes: utcOffsetMinutes);

  @override
  String toString() =>
      'TrustedInstant(${DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true).toIso8601String()}, $level)';
}

/// The result of folding a [ClockReading] into a [ClockState].
class ClockResolution {
  const ClockResolution({
    required this.instant,
    required this.state,
    this.tamper,
  });

  final TrustedInstant instant;

  /// The state to persist. Always persist it, including on the untrusted path —
  /// that is how the high-water mark and the tamper counter survive.
  final ClockState state;

  final TamperSignal? tamper;
}

/// Tuning knobs. Defaults are chosen to match the contract, not invented.
class ClockPolicy {
  const ClockPolicy({
    this.wallClockJumpToleranceMs = 90000,
    this.maxAnchorAgeMs = 7 * 86400000,
  });

  /// How far the wall clock may disagree with the monotonic clock inside one
  /// boot session before we call it tampering. Generous enough to absorb NTP
  /// corrections and the imprecision of two readings taken microseconds apart;
  /// far too small to hide a child stealing a day.
  final int wallClockJumpToleranceMs;

  /// How long an anchor stays usable with no server contact. 7 days, matching
  /// the offline window Article 7.6 grants the subscription cache — one number,
  /// one rule to explain to the client.
  final int maxAnchorAgeMs;
}

/// Pure, allocation-light resolver. No IO, no clock reads, no singletons.
class TrustedClock {
  const TrustedClock({this.policy = const ClockPolicy()});

  final ClockPolicy policy;

  /// Fold a platform reading into state, producing the instant to act on.
  ///
  /// The order of the branches *is* the security argument:
  ///  1. anchored inside the same boot session -> monotonic, so unforgeable;
  ///  2. same boot session but no anchor -> the wall clock is checkable
  ///     against the monotonic delta, so a jump is provable;
  ///  3. after a reboot -> the monotonic clock is gone, so all we can enforce
  ///     is that time never runs backwards.
  ClockResolution resolve(ClockState state, ClockReading reading) {
    final sameBoot = state.lastBootId == reading.bootId;
    final anchorUsable = state.hasAnchor &&
        state.anchorBootId == reading.bootId &&
        reading.elapsedRealtimeMs >= state.anchorElapsedRealtimeMs!;

    TamperSignal? tamper;
    int epochMs;
    TrustLevel level;

    if (anchorUsable) {
      final anchorAge =
          reading.elapsedRealtimeMs - state.anchorElapsedRealtimeMs!;
      epochMs = state.anchorServerEpochMs! + anchorAge;
      if (anchorAge > policy.maxAnchorAgeMs) {
        level = TrustLevel.monotonic;
        tamper = TamperSignal.anchorTooOld;
      } else {
        level = TrustLevel.serverAnchored;
      }
    } else {
      if (state.hasAnchor && state.anchorBootId != reading.bootId) {
        tamper = TamperSignal.anchorLostToReboot;
      }

      if (sameBoot) {
        // Inside one boot session the monotonic clock is the witness: the wall
        // clock may not advance by more than it did.
        final monotonicDelta =
            reading.elapsedRealtimeMs - state.lastElapsedRealtimeMs;
        final wallDelta = reading.wallClockMs - state.highWaterEpochMs;
        if (wallDelta > monotonicDelta + policy.wallClockJumpToleranceMs) {
          tamper = TamperSignal.wallClockJumpedForward;
          epochMs = state.highWaterEpochMs + monotonicDelta;
          level = TrustLevel.untrusted;
        } else if (reading.wallClockMs < state.highWaterEpochMs) {
          tamper = TamperSignal.wallClockMovedBackwards;
          epochMs = state.highWaterEpochMs + monotonicDelta;
          level = TrustLevel.untrusted;
        } else {
          epochMs = reading.wallClockMs;
          level = TrustLevel.monotonic;
        }
      } else {
        // Across a reboot the only invariant left is that time moved forward.
        if (reading.wallClockMs < state.highWaterEpochMs) {
          tamper = TamperSignal.wallClockMovedBackwards;
          epochMs = state.highWaterEpochMs;
          level = TrustLevel.untrusted;
        } else {
          epochMs = reading.wallClockMs;
          level = TrustLevel.monotonic;
        }
      }
    }

    // Forward-only, always, on every path.
    if (epochMs < state.highWaterEpochMs) epochMs = state.highWaterEpochMs;

    final next = ClockState(
      anchorServerEpochMs: state.anchorServerEpochMs,
      anchorElapsedRealtimeMs: state.anchorElapsedRealtimeMs,
      anchorBootId: state.anchorBootId,
      highWaterEpochMs:
          epochMs > state.highWaterEpochMs ? epochMs : state.highWaterEpochMs,
      lastBootId: reading.bootId,
      lastElapsedRealtimeMs: reading.elapsedRealtimeMs,
      tamperCount: tamper == null ? state.tamperCount : state.tamperCount + 1,
      lastTamperSignal: tamper ?? state.lastTamperSignal,
    );

    return ClockResolution(
      instant: TrustedInstant(epochMs: epochMs, level: level),
      state: next,
      tamper: tamper,
    );
  }

  /// Record a fresh server timestamp. Called after any authenticated response
  /// that carries server time — the subscription revalidation of Article 7.6
  /// doubles as the clock anchor, so no extra network call is needed.
  ClockState anchor(
    ClockState state, {
    required int serverEpochMs,
    required ClockReading reading,
  }) {
    final high = serverEpochMs > state.highWaterEpochMs
        ? serverEpochMs
        : state.highWaterEpochMs;
    return ClockState(
      anchorServerEpochMs: serverEpochMs,
      anchorElapsedRealtimeMs: reading.elapsedRealtimeMs,
      anchorBootId: reading.bootId,
      highWaterEpochMs: high,
      lastBootId: reading.bootId,
      lastElapsedRealtimeMs: reading.elapsedRealtimeMs,
      tamperCount: state.tamperCount,
      // A successful anchor clears the flag: whatever the clock was doing, we
      // now know the real time again.
      lastTamperSignal: null,
    );
  }
}
