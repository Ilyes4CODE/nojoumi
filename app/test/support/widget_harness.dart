import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nojoumi/core/providers.dart';
import 'package:nojoumi/core/theme.dart';
import 'package:nojoumi/data/local/database.dart';
import 'package:nojoumi/data/local/tables.dart';
import 'package:nojoumi/l10n/app_localizations.dart';

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
}) async {
  await tester.pumpWidget(
    ProviderScope(
      // The guard goes first so a caller's own override still wins. Without it,
      // a screen that reaches the data layer quietly constructs a real device
      // database — Drift only warns, and the test keeps passing while proving
      // something other than what it claims.
      overrides: [_noDatabaseInWidgetTests, ...overrides],
      child: MaterialApp(
        theme: NojoumiTheme.light(),
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
  int dailySessionCards = 12,
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
  );
}
