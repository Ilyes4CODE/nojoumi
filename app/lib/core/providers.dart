import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_subscription/lunio_subscription.dart';
import 'package:lunio_time/lunio_time.dart';

import 'config.dart';
import '../data/local/database.dart';
import '../data/repositories/blocking_repository.dart';
import '../data/repositories/clock_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/remote/api_client.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/lesson_repository.dart';
import '../data/repositories/star_repository.dart';
import '../data/repositories/subscription_repository.dart';
import '../data/repositories/token_store.dart';
import '../data/repositories/weekly_test_repository.dart';
import '../platform/blocking_channel.dart';
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
final databaseProvider = Provider<LunioDatabase>((ref) {
  final db = LunioDatabase();
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

/// The one HTTP client.
///
/// Built on [tokenStoreProvider], never on [authRepositoryProvider].
///
/// The earlier version reached for the repository through closures and called
/// it "lazy enough to say so without a cycle". It was not. On a device the first
/// call through `ApiClient._send` threw `CircularDependencyError` from inside
/// Riverpod, **before the request was sent** — so nothing reached the server and
/// nothing appeared in its log. Register, sign-in, the trial, the lesson
/// endpoint and the subscription status were all dead; only the health probe
/// worked, because it calls `dio.get` directly and never asks for a token.
///
/// The token is data. `TokenStore` depends on the database and on nothing else,
/// so both sides can depend on it and neither depends on the other.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final tokens = ref.watch(tokenStoreProvider);
  return ApiClient(
    baseUrl: ref.watch(apiBaseProvider),
    readToken: tokens.accessToken,
    readRefreshToken: tokens.refreshToken,
    writeAccessToken: tokens.writeAccess,
    endSession: tokens.clear,
  );
});

/// Where the server is.
///
/// A provider rather than a direct `AppConfig` read so that a test can point the
/// real graph at an address that refuses immediately. In the app it is exactly
/// `AppConfig.apiBase`, which arrives through `--dart-define`.
final apiBaseProvider = Provider<String>((ref) => AppConfig.apiBase);

/// The parent's tokens, and nothing else. See `token_store.dart`.
final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(ref.watch(databaseProvider));
});

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
      return AuthRepository(
        ref.watch(tokenStoreProvider),
        ref.watch(apiClientProvider),
        ref.watch(settingsRepositoryProvider),
      );
    });

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository(
    ref.watch(databaseProvider),
    ref.watch(apiClientProvider),
  );
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(
    ref.watch(databaseProvider),
    ref.watch(apiClientProvider),
    ref.watch(authRepositoryProvider),
  );
});

/// What the app may currently do (Art. 7.1).
///
/// Three of the four capabilities are constants by contract — blocking, stars and
/// saved lessons never stop — so the only question this ever answers is whether
/// **new** AI lessons can be generated. That shape is deliberate: it makes it
/// structurally hard to write a feature that punishes the child for the parent's
/// payment delay.
final capabilitiesProvider = FutureProvider<Capabilities?>((ref) async {
  final now = ref.watch(trustedNowProvider).value;
  if (now == null) return null;
  // Watching the cache row is what refreshes this after an activation.
  ref.watch(subscriptionCacheProvider);
  return ref.watch(subscriptionRepositoryProvider).capabilities(now);
});

final subscriptionCacheProvider = StreamProvider<SubscriptionCacheRow>((ref) {
  return ref.watch(subscriptionRepositoryProvider).watch();
});

final weeklyTestRepositoryProvider = Provider<WeeklyTestRepository>((ref) {
  return WeeklyTestRepository(
    ref.watch(databaseProvider),
    ref.watch(starRepositoryProvider),
  );
});

/// Whether the weekly test is due today.
///
/// Three conditions, all of which must hold (D-13): the parent's chosen weekday,
/// no test already run for this week, and at least five cards to test. A test on
/// two cards would hand out 10-40 stars for nothing and would trigger Article 14's
/// purge on a week that barely happened.
final weeklyTestDueProvider = FutureProvider<bool>((ref) async {
  final day = ref.watch(todayProvider).value;
  final settings = ref.watch(settingsProvider).value;
  if (day == null || settings == null) return false;

  // Watching today's progress is what re-runs this after a session, so the
  // prompt appears the moment the fifth card exists rather than on next launch.
  ref.watch(todayProgressProvider);

  return ref
      .watch(weeklyTestRepositoryProvider)
      .isDue(today: day, expiryWeekday: settings.expiryWeekday);
});

/// Whether the parent has an account on this device.
///
/// The child never signs in and never sees this. It gates one thing only:
/// generating **new** lessons. Article 7.1 keeps blocking, stars and saved
/// lessons working regardless, and all three are local.
final isSignedInProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(authRepositoryProvider)
      .watch()
      .map((row) => row.accessToken.isNotEmpty);
});

/// The lessons saved on this device, newest first. Local only (Art. 14).
final lessonsProvider = StreamProvider<List<LessonRow>>((ref) {
  return ref.watch(lessonRepositoryProvider).watchLessons();
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
  return ref
      .watch(settingsProvider)
      .maybeWhen(
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
  return ref
      .watch(trustedNowProvider)
      .maybeWhen(data: (now) => now.isTrustworthy, orElse: () => false);
});

/// Today's progress: balance, ceiling, play time, session state.
final todayProgressProvider = StreamProvider<DayProgress>((ref) {
  final day = ref.watch(todayProvider).value;
  if (day == null) return const Stream<DayProgress>.empty();
  return ref.watch(starRepositoryProvider).watchDay(day);
});

/// `app_settings.onboarding_step` at or above this means setup is finished.
///
/// Lives in `core` rather than on the wizard so that providers can gate on it
/// without `core` importing `features` — the dependency only ever points one
/// way.
/// Raised from 4 to 5 on 2026-08-28, when the account step was inserted after
/// the welcome screen, and from 5 to 6 on 2026-09-25 for the game-list step.
/// It is the count of wizard steps, so it moves with them.
///
/// Note what this does to a device that finished setup under the previous build:
/// its stored step is one less than the sentinel, so it is sent back through the
/// wizard once. That is the right behaviour both times — the new step is one the
/// parent has not seen, and in the second case it is the one that decides which
/// apps are blocked at all, so a household that never sees it has blocking
/// switched on and nothing blocked.
///
/// `setup_games_step_test.dart` pins this against `SetupWizard.totalSteps`,
/// because the two are one fact written in two files and the failure mode of
/// forgetting is silent: the gate still opens, and the new step is simply never
/// shown to anyone who set up before it existed.
const int onboardingCompletedStep = 6;

/// Grants the one-time welcome balance of appendix §5, on the first day we can
/// actually defend.
///
/// It used to be granted at the end of the setup wizard. That was wrong in one
/// specific and damaging way: if the clock channel had not answered yet, the
/// resolved instant is epoch zero, so the ten stars were written to
/// 1970-01-01 — a day the child would never see again. The balance was not
/// lost exactly, but it was stranded, which to a parent is the same thing.
///
/// So the grant waits for a trustworthy instant instead. `grantWelcomeOnce`
/// checks and sets its flag inside one transaction, so waiting costs nothing
/// and cannot produce a double grant. An offline family still qualifies —
/// [TrustLevel.monotonic] is trustworthy; only a contradicted clock is not.
final welcomeGrantProvider = FutureProvider<int?>((ref) async {
  final settings = ref.watch(settingsProvider).value;
  final rules = ref.watch(starRulesProvider).value;
  final now = ref.watch(trustedNowProvider).value;
  final day = ref.watch(todayProvider).value;

  if (settings == null || rules == null || now == null || day == null) {
    return null;
  }
  if (settings.onboardingStep < onboardingCompletedStep) return null;
  if (settings.welcomeGranted || rules.welcomeUnits == 0) return null;
  if (!now.isTrustworthy) return null;

  final granted = await ref
      .read(starRepositoryProvider)
      .grantWelcomeOnce(rules: rules, day: day, now: now);
  return granted == null ? null : rules.welcomeUnits;
});

/// The attendance run of Article 5, reset by Article 6.6 on any missed day.
final streakProvider = FutureProvider<StreakState>((ref) {
  // Watching today's progress is what makes this refresh after a session is
  // completed — the run only ever advances at that moment (D-19).
  ref.watch(todayProgressProvider);
  return ref.watch(starRepositoryProvider).streak();
});

/// Every balance movement for today, newest first (AD-4).
final todayLedgerProvider = StreamProvider<List<StarLedgerRow>>((ref) {
  final day = ref.watch(todayProvider).value;
  if (day == null) return const Stream<List<StarLedgerRow>>.empty();
  return ref.watch(starRepositoryProvider).watchLedger(day);
});

/// Today's attempts that earned nothing, with the Article 6 condition that
/// stopped each one. This is the parent's answer to "why was no star granted?".
final todayRejectionsProvider = StreamProvider<List<AttemptRow>>((ref) {
  final day = ref.watch(todayProvider).value;
  if (day == null) return const Stream<List<AttemptRow>>.empty();
  return ref.watch(starRepositoryProvider).watchRejections(day);
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

// --- Blocking (AD-8) ------------------------------------------------------

/// The channel to the Kotlin engine. Android gets the real one; the developer's
/// desktop and `flutter test` get a stand-in that reports every permission as
/// missing rather than pretending.
final blockingChannelProvider = Provider<BlockingChannel>((ref) {
  return BlockingChannel.forPlatform();
});

final blockingRepositoryProvider = Provider<BlockingRepository>((ref) {
  return BlockingRepository(
    ref.watch(databaseProvider),
    ref.watch(blockingChannelProvider),
    ref.watch(starRepositoryProvider),
  );
});

/// What the parent still has to grant, read from the system every time.
///
/// Never cached across a resume: the parent leaves for a Settings screen and
/// comes back, and an answer from before they left is the one answer that is
/// certainly wrong. Invalidate this on `AppLifecycleState.resumed`.
final blockingStatusProvider = FutureProvider<BlockingStatus>((ref) {
  // Straight to the channel, not through the repository.
  //
  // Permission state is a pure platform question — the repository added nothing
  // to it but a dependency on the database. That went unnoticed until the
  // child's home screen started reading this for the "blocking is on but not
  // running" banner, and three tests about the star balance failed with an error
  // about `databaseProvider`. A provider should depend on what it actually
  // needs; anything else is a trap set for the next caller.
  return ref.watch(blockingChannelProvider).status();
});

final managedAppsProvider = StreamProvider<List<ManagedAppRow>>((ref) {
  return ref.watch(blockingRepositoryProvider).watchManagedApps();
});

/// The push that keeps the engine's inputs current — **the single most
/// load-bearing provider in the app.**
///
/// The engine holds a snapshot and enforces against it with no way to know how
/// old it is. From inside Kotlin a stale state and a correct one are the same
/// value, so every path that changes any input has to arrive here: a card
/// answered, a second of play consumed, a parent grant, a pause, an app
/// classified, the day rolling over. That is why this watches the derived
/// providers rather than being called from the screens that cause the changes —
/// a screen can be forgotten, a dependency edge cannot.
///
/// A missed push has two shapes and both are bad: a child who earned twenty
/// stars stays locked out, or one whose time ran out keeps playing.
final blockingSyncProvider = Provider<void>((ref) {
  final settings = ref.watch(settingsProvider).value;
  final progress = ref.watch(todayProgressProvider).value;
  final rules = ref.watch(starRulesProvider).value;
  // Watched for its change signal only — the package list is re-queried inside
  // `sync`, because a partial push would have to send something for the field it
  // skipped and an empty list unblocks the whole phone.
  ref.watch(managedAppsProvider);

  if (settings == null || progress == null || rules == null) return;

  ref
      .read(blockingRepositoryProvider)
      .sync(settings: settings, progress: progress, rules: rules);
});

// --- Server reachability --------------------------------------------------

/// Whether the server configured in this build is actually answering.
///
/// This exists because "the app is not connecting to the backend" is the least
/// actionable sentence in the project. Without it, a phone on the wrong network,
/// a build launched without `--dart-define`, a server bound to 127.0.0.1 and a
/// genuine bug all produce the same silence on a screen.
///
/// Deliberately **not** cached for the session: the answer changes when the
/// parent turns Wi-Fi on, and a stale "unreachable" is the one answer guaranteed
/// to be wrong by the time they look at it. `ref.invalidate` re-probes.
/// `autoDispose` so that leaving the screen and coming back re-probes rather
/// than replaying an answer from a minute ago. Reachability is the one value in
/// the app with no useful shelf life.
final serverHealthProvider = FutureProvider.autoDispose<ServerHealth>((ref) {
  return ref.watch(apiClientProvider).health();
});


/// The live play-time countdown, while Lunio is on screen.
///
/// Whatever the engine last reported, in seconds. Null until a game is opened —
/// there is nothing to count when nobody is playing, and a zero would read as
/// "no time left" rather than "not playing".
///
/// `autoDispose`, because a stream nobody is watching should not hold the
/// EventChannel open: the Kotlin side drops its sink the moment Dart cancels,
/// and emitting then costs a null check.
final playTicksProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.watch(blockingChannelProvider).playTicks();
});
