import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/core/providers.dart';
import 'package:lunio/core/theme.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/data/local/tables.dart';
import 'package:lunio/data/repositories/session_repository.dart';
import 'package:lunio/features/session/session_controller.dart';
import 'package:lunio/l10n/app_localizations.dart';
import 'package:lunio/platform/blocking_channel.dart';
import 'package:lunio_time/lunio_time.dart';

/// Widget tests run against **provider overrides, not the database**.
///
/// The first attempt wired the real Drift database into `testWidgets` and every
/// test hung: `testWidgets` runs its body in a fake-async zone, the database
/// completes its futures in the real one, and `pumpAndSettle` spins fake time
/// forever waiting for a query that is making no progress. Adding `runAsync`
/// around it did not fix it either.
///
/// The right split, and the reason this file exists: **the database is already
/// proven** — 15 schema tests and 24 repository tests exercise it directly, in
/// plain `test()` bodies where real async works. What is unproven is the widget
/// layer, and the widget layer only needs *values*. So these tests hand the
/// widgets fixed values and assert what is drawn.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Locale locale = const Locale('ar'),
  Size? surfaceSize,
}) async {
  // A long settings list is taller than the default 800×600 test window, and a
  // widget a ListView never built is a widget a finder cannot see — which reads
  // as "the control is missing" when it is merely below the fold. Tests that
  // assert on a whole screen pass a taller surface instead of scrolling.
  if (surfaceSize != null) {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  await tester.pumpWidget(
    ProviderScope(
      // The guard goes first so a caller's own override still wins. Without it,
      // a screen that reaches the data layer quietly constructs a real device
      // database — Drift only warns, and the test keeps passing while proving
      // something other than what it claims.
      // The guard goes first so a caller's own override still wins; the fake
      // session follows it for the same reason.
      overrides: [
        _noDatabaseInWidgetTests,
        _noPlatformChannelsInWidgetTests,
        fakeSession(),
        ...overrides,
      ],
      child: MaterialApp(
        theme: LunioTheme.light(),
        localizationsDelegates: const [
          AppL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppL10n.supportedLocales,
        locale: locale,
        home: child,
      ),
    ),
  );
  await tester.pump();
}

/// Fails loudly if a widget test reaches the data layer.
///
/// A widget that needs the database to render is a widget doing work AD-9 says
/// belongs in a provider. So this is not only a test convenience — it is where
/// that architectural rule stops being a comment and starts being enforced.
final _noDatabaseInWidgetTests = databaseProvider.overrideWith((ref) {
  throw UnsupportedError(
    'a widget test reached databaseProvider. Override the state provider the '
    'screen actually reads (settingsProvider, todayProgressProvider, '
    'sessionControllerProvider …) instead of opening a database — see '
    'decisions.md D-33.',
  );
});

/// Widget tests never reach a `MethodChannel`.
///
/// `BlockingChannel.forPlatform()` returns the real Android implementation in a
/// test run — `defaultTargetPlatform` is android — and the first call throws
/// `MissingPluginException` because no engine is behind it. That surfaced when
/// the child's home screen started reading `blockingStatusProvider` for the
/// "blocking is on but not running" banner: three unrelated tests about the star
/// balance began failing, with an error naming a plugin rather than the screen.
///
/// The stand-in reports every permission as missing, which is also the honest
/// answer off-device.
final _noPlatformChannelsInWidgetTests = blockingChannelProvider
    .overrideWithValue(const UnavailableBlockingChannel());

/// A session the child home can render without touching the database.
///
/// `ChildHomeScreen` watches `sessionControllerProvider` because reading it is
/// what *creates* the day — see the comment there, and
/// `session_reachability_test.dart` for the bug that made it necessary. A widget
/// test therefore has to stand in for the controller, or the harness's
/// no-database guard fires (D-33), which is exactly what it is for.
class FakeSessionController extends SessionController {
  FakeSessionController(this.session);

  final DailySession session;

  @override
  Future<DailySession> build() async => session;
}

/// An empty day, which is what most of these tests want: they assert on the
/// balance, the clock warning and the layout, none of which depend on tasks.
Override fakeSession({DailySession? session}) {
  final value =
      session ??
      DailySession(
        day: const DayKey(20500),
        tasks: const [],
        answeredTaskIds: const {},
        backlogCount: 0,
      );
  return sessionControllerProvider.overrideWith(
    () => FakeSessionController(value),
  );
}

/// A settings row with the appendix §5 defaults, overridable field by field.
///
/// Built by hand rather than read from the database so that a widget test states
/// its own preconditions in one line. The defaults here must stay in step with
/// `AppSettings`' column defaults; `settings_defaults_test.dart` asserts that.
SettingsRow fakeSettings({
  int starValueSeconds = 60,
  int dailyCeilingUnits = 6000,
  int minimumTimeOnTargetMs = 1500,
  ExpiryModeRow expiryMode = ExpiryModeRow.daily,
  int welcomeUnits = 1000,
  bool welcomeGranted = false,
  int dailySessionCards = 0,
  int dailyQuestionCount = 5,
  int expiryWeekday = DateTime.friday,
  bool blockingEnabled = false,
  bool launcherMode = false,
  bool playPaused = false,
  String grade = '',
  int onboardingStep = 0,
  int utcOffsetMinutes = 60,
  String pinHash = '',
  String pinSalt = '',
  // Empty, matching the column default. A fresh row has no id until
  // `SettingsRepository.installId()` mints one, and a helper that staged a
  // value would be staging a state the app never starts in.
  String installId = '',
}) {
  return SettingsRow(
    id: 1,
    pinHash: pinHash,
    pinSalt: pinSalt,
    starValueSeconds: starValueSeconds,
    dailyCeilingUnits: dailyCeilingUnits,
    minimumTimeOnTargetMs: minimumTimeOnTargetMs,
    expiryMode: expiryMode,
    welcomeUnits: welcomeUnits,
    welcomeGranted: welcomeGranted,
    dailySessionCards: dailySessionCards,
    dailyQuestionCount: dailyQuestionCount,
    expiryWeekday: expiryWeekday,
    blockingEnabled: blockingEnabled,
    launcherMode: launcherMode,
    playPaused: playPaused,
    grade: grade,
    onboardingStep: onboardingStep,
    utcOffsetMinutes: utcOffsetMinutes,
    installId: installId,
  );
}
