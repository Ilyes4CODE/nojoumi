import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lunio_time/lunio_time.dart';

/// Where a [ClockReading] comes from.
///
/// `lunio_time` deliberately reads no clock (AD-2): it folds readings that
/// somebody else supplies. This is that somebody. Everything about *trust* stays
/// in the pure package; everything about *the platform* stays here.
abstract class ClockSource {
  /// Take one observation of the device's clocks.
  Future<ClockReading> read();

  /// The source to use for the current platform.
  ///
  /// Android gets the real thing. Everything else — the developer's Windows
  /// machine, a `flutter test` run — gets [DevClockSource], which cannot detect
  /// tampering and says so loudly.
  factory ClockSource.forPlatform() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return const PlatformClockSource();
    }
    return DevClockSource();
  }
}

/// The Android implementation, over `MethodChannel`.
///
/// The Kotlin side returns three values and computes nothing:
///
///  * `wallClockMs` — `System.currentTimeMillis()`. User-settable, and that is
///    the whole point: it is the input we do not trust.
///  * `elapsedRealtimeMs` — `SystemClock.elapsedRealtime()`. Documented as
///    milliseconds since boot **including deep sleep**, and not settable by the
///    user. It is the witness the tamper checks are built on.
///  * `bootId` — an opaque token that is stable within one boot and different
///    after a reboot. See `docs/android-behaviour-notes.md` V9 for how it is
///    derived and what still has to be checked on hardware.
///
/// **UNVERIFIED-ON-HARDWARE.** No part of this has run on a phone.
class PlatformClockSource implements ClockSource {
  const PlatformClockSource();

  static const MethodChannel channel = MethodChannel('dz.lunio/clock');

  @override
  Future<ClockReading> read() async {
    final map = await channel.invokeMapMethod<String, Object?>('read');
    if (map == null) {
      throw const ClockSourceUnavailable('clock channel returned null');
    }
    final wall = map['wallClockMs'];
    final elapsed = map['elapsedRealtimeMs'];
    final bootId = map['bootId'];
    if (wall is! int || elapsed is! int || bootId is! String) {
      throw ClockSourceUnavailable('malformed clock reading: $map');
    }
    return ClockReading(
      wallClockMs: wall,
      elapsedRealtimeMs: elapsed,
      bootId: bootId,
    );
  }
}

/// A stand-in for platforms that have no `elapsedRealtime` and no boot identity.
///
/// It fabricates a monotonic clock from a [Stopwatch] started when the object
/// was created, and a boot id that lives for exactly one process. That is enough
/// to run the app on a desktop and enough for tests to drive the machinery — and
/// it is **not** enough to detect anything. A process restart looks like a
/// reboot to it, so the forward-only high-water mark is the only protection left.
///
/// It is never selected on Android. If it ever is, that is a bug, not a fallback.
class DevClockSource implements ClockSource {
  DevClockSource({DateTime Function()? wallClock})
    : _wallClock = wallClock ?? DateTime.now,
      _bootId = 'dev-${DateTime.now().microsecondsSinceEpoch}' {
    _sinceStart.start();
  }

  final DateTime Function() _wallClock;
  final String _bootId;
  final Stopwatch _sinceStart = Stopwatch();

  @override
  Future<ClockReading> read() async {
    return ClockReading(
      wallClockMs: _wallClock().millisecondsSinceEpoch,
      elapsedRealtimeMs: _sinceStart.elapsedMilliseconds,
      bootId: _bootId,
    );
  }
}

/// The platform could not be asked what time it is.
///
/// Callers must treat this as [TrustLevel.untrusted], never as "assume it is
/// fine": Article 6.8 and Article 7.6 both hang on not granting anything when we
/// cannot defend the time.
class ClockSourceUnavailable implements Exception {
  const ClockSourceUnavailable(this.message);

  final String message;

  @override
  String toString() => 'ClockSourceUnavailable: $message';
}
