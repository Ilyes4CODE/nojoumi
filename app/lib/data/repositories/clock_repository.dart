import 'package:drift/drift.dart';
import 'package:nojoumi_time/nojoumi_time.dart';

import '../../platform/clock_source.dart';
import '../local/database.dart';

/// The app's only way to learn what time it is.
///
/// AD-2: nothing in `lib/` calls `DateTime.now()`. Everything asks this class,
/// which reads the platform once, folds the reading into the persisted
/// [ClockState] through the pure [TrustedClock], writes the new state back, and
/// hands out a [TrustedInstant] carrying its own trust level.
///
/// The state is persisted on **every** resolution, including the untrusted path.
/// That is the point: the forward-only high-water mark and the tamper counter
/// only work if a tampered reading is recorded, not discarded.
class ClockRepository {
  ClockRepository(this._db, this._source, {TrustedClock clock = const TrustedClock()})
      : _clock = clock;

  final NojoumiDatabase _db;
  final ClockSource _source;
  final TrustedClock _clock;

  static const int _singletonId = 1;

  /// Resolve the current instant, persisting whatever we learned.
  ///
  /// If the platform cannot be asked at all, the result is
  /// [TrustLevel.untrusted] rather than an exception: every caller already has
  /// to handle untrusted time, and turning a channel failure into a crash would
  /// take the whole app down over a question it is designed to answer safely.
  Future<TrustedInstant> now() async {
    final ClockReading reading;
    try {
      reading = await _source.read();
    } on Object catch (error) {
      await _logEvent('clock_source_unavailable', error.toString());
      final state = await readState();
      return TrustedInstant(
        epochMs: state.highWaterEpochMs,
        level: TrustLevel.untrusted,
      );
    }

    final state = await readState();
    final resolution = _clock.resolve(state, reading);
    await _writeState(resolution.state);
    if (resolution.tamper != null) {
      await _logEvent('clock_tamper', resolution.tamper!.name);
    }
    return resolution.instant;
  }

  /// Record a server timestamp as the anchor.
  ///
  /// Article 7.6's 24-hour subscription revalidation carries a signed server
  /// time, so it doubles as the clock anchor and no extra network call exists
  /// anywhere in the app.
  Future<void> anchorTo(int serverEpochMs) async {
    final reading = await _source.read();
    final anchored = _clock.anchor(
      await readState(),
      serverEpochMs: serverEpochMs,
      reading: reading,
    );
    await _writeState(anchored);
    await _logEvent('clock_anchored', '');
  }

  Future<ClockState> readState() async {
    final row = await (_db.select(_db.clockStates)
          ..where((t) => t.id.equals(_singletonId)))
        .getSingle();
    return ClockState(
      anchorServerEpochMs: row.anchorServerEpochMs,
      anchorElapsedRealtimeMs: row.anchorElapsedRealtimeMs,
      anchorBootId: row.anchorBootId,
      highWaterEpochMs: row.highWaterEpochMs,
      lastBootId: row.lastBootId,
      lastElapsedRealtimeMs: row.lastElapsedRealtimeMs,
      tamperCount: row.tamperCount,
      lastTamperSignal: _signalFromName(row.lastTamperSignal),
    );
  }

  Future<void> _writeState(ClockState state) async {
    await (_db.update(_db.clockStates)..where((t) => t.id.equals(_singletonId)))
        .write(
      ClockStatesCompanion(
        anchorServerEpochMs: Value(state.anchorServerEpochMs),
        anchorElapsedRealtimeMs: Value(state.anchorElapsedRealtimeMs),
        anchorBootId: Value(state.anchorBootId),
        highWaterEpochMs: Value(state.highWaterEpochMs),
        lastBootId: Value(state.lastBootId),
        lastElapsedRealtimeMs: Value(state.lastElapsedRealtimeMs),
        tamperCount: Value(state.tamperCount),
        lastTamperSignal: Value(state.lastTamperSignal?.name),
      ),
    );
  }

  /// Diagnostics for the parent's dashboard. Never lesson content, never image
  /// bytes, never anything about the child (Art. 14).
  Future<void> _logEvent(String type, String detail) async {
    final state = await readState();
    await _db.into(_db.eventLog).insert(
          EventLogCompanion.insert(
            type: type,
            detail: Value(detail),
            atMs: state.highWaterEpochMs,
          ),
        );
  }

  static TamperSignal? _signalFromName(String? name) {
    if (name == null) return null;
    for (final signal in TamperSignal.values) {
      if (signal.name == name) return signal;
    }
    return null;
  }
}
