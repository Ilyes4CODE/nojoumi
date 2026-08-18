import 'package:flutter_test/flutter_test.dart';
import 'package:nojoumi/data/local/database.dart';
import 'package:nojoumi/data/repositories/settings_repository.dart';
import 'package:nojoumi_stars/nojoumi_stars.dart';

import 'support/test_db.dart';
import 'support/widget_harness.dart';

/// The appendix §5 defaults exist in three places: the column defaults in
/// `tables.dart`, the constructor defaults in `StarRules`, and the test helper
/// in `widget_harness.dart`. Three copies of a contract number is two too many,
/// and this is the test that keeps them from drifting apart quietly.
void main() {
  late NojoumiDatabase db;

  setUp(() async => db = await freshDatabase());
  tearDown(() async => db.close());

  test('a fresh install carries exactly the appendix §5 defaults', () async {
    final row = await SettingsRepository(db).read();

    expect(row.starValueSeconds, 60, reason: 'one star = 1 minute');
    expect(row.dailyCeilingUnits, 60 * starUnit, reason: '60 stars a day');
    expect(row.minimumTimeOnTargetMs, 1500, reason: '1.5 s on a card');
    expect(row.welcomeUnits, 10 * starUnit, reason: '10 welcome stars');
    expect(row.dailySessionCards, 12);
    expect(row.dailyQuestionCount, 5, reason: 'decisions.md D-15');
    expect(row.expiryWeekday, DateTime.friday, reason: 'decisions.md D-13');
  });

  test('Article 15.2 — blocking and launcher mode are off on a fresh install',
      () async {
    final row = await SettingsRepository(db).read();
    expect(row.blockingEnabled, isFalse);
    expect(row.launcherMode, isFalse);
    expect(row.onboardingStep, 0);
  });

  test('Article 14 — the settings row holds nothing identifying the child',
      () async {
    final row = await SettingsRepository(db).read();
    // `grade` is the only pedagogical field, and a school level is not an
    // identity (D-11). If a name, birth date or photo column ever appears, this
    // list stops matching and the test fails.
    expect(row.toJson().keys.toSet(), {
      'id',
      'pinHash',
      'pinSalt',
      'starValueSeconds',
      'dailyCeilingUnits',
      'minimumTimeOnTargetMs',
      'expiryMode',
      'welcomeUnits',
      'welcomeGranted',
      'dailySessionCards',
      'dailyQuestionCount',
      'expiryWeekday',
      'blockingEnabled',
      'launcherMode',
      'playPaused',
      'grade',
      'onboardingStep',
      'utcOffsetMinutes',
    });
  });

  test('the widget-test helper agrees with the database defaults', () async {
    final stored = await SettingsRepository(db).read();
    expect(fakeSettings(), stored,
        reason: 'a widget test that stages the wrong defaults proves the '
            'wrong thing');
  });

  test('the stored defaults produce a valid StarRules', () async {
    final rules = await SettingsRepository(db).readRules();
    expect(rules.dailyPlayCapSeconds, 3600, reason: '60 stars × 1 minute');
    expect(rules.playableSecondsFor(50), 30, reason: 'half a star is 30 s');
  });
}
