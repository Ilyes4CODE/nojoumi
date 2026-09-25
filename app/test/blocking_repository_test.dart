import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/data/local/tables.dart';
import 'package:lunio/data/repositories/blocking_repository.dart';
import 'package:lunio/data/repositories/settings_repository.dart';
import 'package:lunio/data/repositories/star_repository.dart';
import 'package:lunio/platform/blocking_channel.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

import 'support/test_db.dart';

/// What crosses the channel into the Kotlin engine, and what must never cross it.
///
/// The engine enforces against the last snapshot it was handed and has no way to
/// judge its age: from inside `BlockPolicy`, a state that is three days old and one
/// that arrived a moment ago are the same value. Everything that could go wrong at
/// this seam therefore goes wrong *silently*, on a child's phone, in one of two
/// shapes — a child who earned stars stays locked out, or one whose time ran out
/// keeps playing.
///
/// So these tests are about the push itself, not about the rules. The rules are
/// Article 5 and 6 and they are settled in `lunio_stars`; what is settled here is
/// that the numbers those rules produced actually arrive, whole.
void main() {
  late LunioDatabase db;
  late RecordingBlockingChannel channel;
  late BlockingRepository repository;
  late SettingsRepository settingsRepository;

  final rules = StarRules();
  const day = DayKey(20693); // 2026-08-27

  setUp(() async {
    db = await freshDatabase();
    channel = RecordingBlockingChannel();
    repository = BlockingRepository(db, channel, StarRepository(db));
    settingsRepository = SettingsRepository(db);
  });

  tearDown(() => db.close());

  Future<void> block(String packageName) => repository.setPolicy(
        packageName: packageName,
        label: packageName,
        policy: AppPolicy.blockedGame,
        nowMs: 0,
      );

  Future<void> sync({DayProgress? progress}) async {
    await repository.sync(
      settings: await settingsRepository.read(),
      progress: progress ?? const DayProgress(dayKey: day),
      rules: rules,
    );
  }

  group('Article 15.2 — blocking is opt-in', () {
    test('the default install pushes a disabled engine', () async {
      await sync();
      expect(channel.last!.enabled, isFalse);
    });

    test('the parent switch is what arms it', () async {
      await settingsRepository.setBlockingEnabled(true);
      await sync();
      expect(channel.last!.enabled, isTrue);
    });
  });

  group('the package list', () {
    test('only apps marked as games are sent', () async {
      await block('com.example.game');
      await repository.setPolicy(
        packageName: 'com.example.calculator',
        label: 'Calculator',
        policy: AppPolicy.allowed,
        nowMs: 0,
      );
      await sync();

      expect(channel.last!.blockedPackages, ['com.example.game']);
    });

    test('a hidden app is not a blocked app', () async {
      // Hiding removes an app from the child's home screen in launcher mode.
      // Blocking stops it opening at all. A parent who hid an app did not
      // necessarily mean to make it cost stars, and promoting one to the other
      // would be us deciding for them.
      await repository.setPolicy(
        packageName: 'com.example.bank',
        label: 'Bank',
        policy: AppPolicy.hidden,
        nowMs: 0,
      );
      await sync();

      expect(channel.last!.blockedPackages, isEmpty);
    });

    test('every push carries the whole list, never a partial one', () async {
      // The regression this guards: a cheaper "balance only" push that sent an
      // empty list for the field it skipped would unblock every game on the
      // phone, and the engine could not tell that from a parent who had
      // deliberately cleared their list.
      await block('com.example.game');
      await block('com.example.other');
      await settingsRepository.setBlockingEnabled(true);

      await sync();
      await sync(
        progress: const DayProgress(
          dayKey: day,
          earnedUnits: 500,
        ),
      );

      expect(channel.pushes, hasLength(2));
      for (final push in channel.pushes) {
        expect(
          push.blockedPackages,
          containsAll(['com.example.game', 'com.example.other']),
        );
      }
    });
  });

  group('Article 4.7 — the balance the engine enforces on', () {
    test('an empty balance arrives as zero seconds', () async {
      await sync();
      expect(channel.last!.remainingPlaySeconds, 0);
    });

    test('five stars arrive as five minutes at the default rate', () async {
      // 1 star = 1 minute (Art. 5, parent-adjustable). The conversion is done by
      // `lunio_stars`, not by the engine and not here — the engine is handed
      // seconds precisely so no second implementation of the contract exists.
      await sync(
        progress: const DayProgress(
          dayKey: day,
          earnedUnits: 5 * starUnit,
        ),
      );
      expect(channel.last!.remainingPlaySeconds, 300);
    });

    test('play already consumed is subtracted before the push', () async {
      await sync(
        progress: const DayProgress(
          dayKey: day,
          earnedUnits: 5 * starUnit,
          usedPlaySeconds: 120,
        ),
      );
      expect(channel.last!.remainingPlaySeconds, 180);
    });
  });

  group('Article 4.7 — the play time the engine measured comes back', () {
    test('nothing is written when the child was not playing', () async {
      // The ordinary resume: no game was opened, so the ledger must not gain a
      // row. A repository that wrote a zero-second consumption on every resume
      // would fill the append-only ledger with noise (AD-4).
      final consumed = await repository.collectPlayTime(day: day, rules: rules);
      expect(consumed, isNull);
    });

    test('the drain empties the engine tally exactly once', () async {
      channel.pendingSeconds = 45;

      final first = await repository.collectPlayTime(day: day, rules: rules);
      final second = await repository.collectPlayTime(day: day, rules: rules);

      expect(first, isNotNull);
      // The second call finds nothing. If the drain were a read followed by a
      // separate clear, the seconds could be counted twice — or, with the
      // opposite race, lost entirely.
      expect(second, isNull);
    });
  });

  group('appendix §4 — the parent pause', () {
    test('the pause crosses as its own flag, not as a zeroed balance', () async {
      // Zeroing the balance would have been simpler and would have blocked just
      // as effectively — and the block card would then have told the child
      // "play time is over" while the balance on the home screen said otherwise.
      await settingsRepository.setPlayPaused(true);
      await sync(
        progress: const DayProgress(
          dayKey: day,
          earnedUnits: 10 * starUnit,
        ),
      );

      expect(channel.last!.playPaused, isTrue);
      expect(channel.last!.remainingPlaySeconds, 600);
    });
  });
}

/// One recorded call to `setState`.
class BlockingPush {
  BlockingPush({
    required this.enabled,
    required this.blockedPackages,
    required this.remainingPlaySeconds,
    required this.playPaused,
    required this.priceInStars,
    required this.uninstallGuard,
  });

  final bool enabled;
  final List<String> blockedPackages;
  final int remainingPlaySeconds;
  final bool playPaused;
  final String priceInStars;
  final bool uninstallGuard;
}

/// A channel that records instead of crossing to Kotlin.
///
/// Everything past this point is native and can only be verified on a phone; what
/// this stands in for is the boundary, not the engine.
class RecordingBlockingChannel implements BlockingChannel {
  final List<BlockingPush> pushes = [];

  BlockingPush? get last => pushes.isEmpty ? null : pushes.last;

  /// Nothing interrupts in a test. The guard is exercised on the JVM, in
  /// `UninstallGuardTest`, where the decision actually lives.
  @override
  Future<String?> consumePendingPinRequest() async => null;

  @override
  Future<void> openGuardGrace() async {}

  @override
  Future<void> push({
    required bool enabled,
    required List<String> blockedPackages,
    required int remainingPlaySeconds,
    required bool playPaused,
    required String priceInStars,
    required bool uninstallGuard,
  }) async {
    pushes.add(
      BlockingPush(
        enabled: enabled,
        blockedPackages: blockedPackages,
        remainingPlaySeconds: remainingPlaySeconds,
        playPaused: playPaused,
        priceInStars: priceInStars,
        uninstallGuard: uninstallGuard,
      ),
    );
  }

  /// Seconds the fake engine claims to have measured. Set by a test that wants
  /// to exercise the drain; zero otherwise, which is the ordinary case.
  int pendingSeconds = 0;

  @override
  Stream<int> playTicks() => const Stream<int>.empty();

  @override
  Future<int> drainConsumedSeconds() async {
    final seconds = pendingSeconds;
    pendingSeconds = 0;
    return seconds;
  }

  @override
  Future<BlockingStatus> status() async => const BlockingStatus();

  @override
  Future<List<InstalledApp>> launchableApps({bool includeIcons = true}) async =>
      const [];

  @override
  Future<bool> openUrl(String url) async => true;

  @override
  Future<bool> openAccessibilitySettings() async => true;

  @override
  Future<bool> openOverlaySettings() async => true;

  @override
  Future<bool> openBatterySettings() async => true;

  @override
  Future<bool> requestBatteryExemption() async => true;

  @override
  Future<bool> openAutostartSettings() async => true;
}
