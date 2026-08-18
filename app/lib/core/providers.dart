import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojoumi_stars/nojoumi_stars.dart';
import 'package:nojoumi_time/nojoumi_time.dart';

import '../data/local/database.dart';
import '../data/repositories/clock_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/star_repository.dart';
import '../platform/clock_source.dart';

/// The composition root.
///
/// AD-9: providers expose immutable state, widgets read providers and dispatch
/// intents, and no business rule lives in a widget. Everything below is either a
/// wiring provider (build one object) or a derivation (turn stored rows into the
/// value types the pure packages already understand).
///
/// Every provider here is overridable, which is what lets a widget test run the
/// real screens against an in-memory database and a scripted clock.

/// The one local database (Art. 14 — all child data, here and nowhere else).
///
/// Overridden in tests with an in-memory instance.
final databaseProvider = Provider<NojoumiDatabase>((ref) {
  final db = NojoumiDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Where clock readings come from. Android gets the real channel; the
/// developer's desktop and `flutter test` get the dev stand-in.
final clockSourceProvider = Provider<ClockSource>((ref) {
  return ClockSource.forPlatform();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

final clockRepositoryProvider = Provider<ClockRepository>((ref) {
  return ClockRepository(
    ref.watch(databaseProvider),
    ref.watch(clockSourceProvider),
  );
});

final starRepositoryProvider = Provider<StarRepository>((ref) {
  return StarRepository(ref.watch(databaseProvider));
});

/// The settings row, live. Everything the parent can change flows from here.
final settingsProvider = StreamProvider<SettingsRow>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

/// The six appendix §5 numbers as the engine wants them.
///
/// Deriving rather than storing means an out-of-range row throws here, at one
/// well-defined place, instead of silently producing wrong awards deep in a
/// session.
final starRulesProvider = Provider<AsyncValue<StarRules>>((ref) {
  return ref.watch(settingsProvider).whenData(SettingsRepository.rulesOf);
});

/// The child's UTC offset, injected into every [DayKey] rather than read from
/// the device — so changing the timezone cannot hand out a second daily ceiling.
final utcOffsetProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).maybeWhen(
        data: (row) => row.utcOffsetMinutes,
        orElse: () => DayKey.algeriaUtcOffsetMinutes,
      );
});

/// The current trusted instant.
///
/// AD-2: this is the only way anything in the app learns the time. It is a
/// [NotifierProvider] rather than a plain future because the answer genuinely
/// changes — a day rolls over, an anchor arrives, someone moves the clock — and
/// every consumer must be able to ask again without reaching for
/// `DateTime.now()` in frustration.
final trustedNowProvider =
    AsyncNotifierProvider<TrustedNowNotifier, TrustedInstant>(
  TrustedNowNotifier.new,
);

class TrustedNowNotifier extends AsyncNotifier<TrustedInstant> {
  @override
  Future<TrustedInstant> build() {
    return ref.watch(clockRepositoryProvider).now();
  }

  /// Re-read the platform clock. Call on resume, after a sync, and whenever a
  /// day boundary might have passed.
  Future<TrustedInstant> refresh() async {
    final next = await ref.read(clockRepositoryProvider).now();
    state = AsyncData(next);
    return next;
  }

  /// Fold in a signed server timestamp (Art. 7.6 revalidation doubles as the
  /// clock anchor), then re-read.
  Future<void> anchorTo(int serverEpochMs) async {
    await ref.read(clockRepositoryProvider).anchorTo(serverEpochMs);
    await refresh();
  }
}

/// Today, in the child's civil timezone, derived from trusted time only.
final todayProvider = Provider<AsyncValue<DayKey>>((ref) {
  final offset = ref.watch(utcOffsetProvider);
  return ref
      .watch(trustedNowProvider)
      .whenData((now) => now.dayKey(utcOffsetMinutes: offset));
});

/// Whether the app may currently make any earning decision at all.
///
/// Article 6.8 hangs on this one boolean: an untrusted clock earns nothing. It
/// is exposed on its own so the child's screen can say why, instead of silently
/// refusing to award and looking broken.
final clockIsTrustworthyProvider = Provider<bool>((ref) {
  return ref.watch(trustedNowProvider).maybeWhen(
        data: (now) => now.isTrustworthy,
        orElse: () => false,
      );
});

/// Today's progress: balance, ceiling, play time, session state.
final todayProgressProvider = StreamProvider<DayProgress>((ref) {
  final day = ref.watch(todayProvider).value;
  if (day == null) return const Stream<DayProgress>.empty();
  return ref.watch(starRepositoryProvider).watchDay(day);
});

/// Seconds of play the child can spend right now.
///
/// Zero means Article 4.7's "blocking returns" — and the parent's pause switch
/// (appendix §4) reads as zero too, because to the child the difference is a
/// message, not a mechanism.
final playSecondsRemainingProvider = Provider<int>((ref) {
  final rules = ref.watch(starRulesProvider).value;
  final day = ref.watch(todayProgressProvider).value;
  final paused = ref.watch(settingsProvider).value?.playPaused ?? false;
  if (rules == null || day == null || paused) return 0;
  return day.remainingPlaySeconds(rules);
});
