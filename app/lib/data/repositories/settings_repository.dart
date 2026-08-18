import 'package:drift/drift.dart';
import 'package:nojoumi_stars/nojoumi_stars.dart';
import 'package:nojoumi_time/nojoumi_time.dart';

import '../local/database.dart';
import '../local/tables.dart';

/// Reads and writes the six parent-adjustable numbers of appendix §5.
///
/// The single rule this class exists to enforce: **an out-of-range value never
/// reaches the database.** Every write goes through [StarRules], whose
/// constructor validates against the appendix's published ranges and throws
/// rather than clamping. A clamped value is a contract violation nobody notices;
/// a thrown one is a bug report.
class SettingsRepository {
  SettingsRepository(this._db);

  final NojoumiDatabase _db;

  static const int _singletonId = 1;

  Future<SettingsRow> read() =>
      (_db.select(_db.appSettings)..where((t) => t.id.equals(_singletonId)))
          .getSingle();

  Stream<SettingsRow> watch() =>
      (_db.select(_db.appSettings)..where((t) => t.id.equals(_singletonId)))
          .watchSingle();

  /// The rules as the engine wants them.
  ///
  /// Throws if the stored row is out of range. That is intentional: the only way
  /// such a row exists is a migration bug or a hand-edited database, and both
  /// should stop the app rather than quietly award the wrong number of stars.
  static StarRules rulesOf(SettingsRow row) => StarRules(
        starValueSeconds: row.starValueSeconds,
        dailyCeilingUnits: row.dailyCeilingUnits,
        minimumTimeOnTargetMs: row.minimumTimeOnTargetMs,
        expiryMode: row.expiryMode == ExpiryModeRow.weekly
            ? ExpiryMode.weekly
            : ExpiryMode.daily,
        welcomeUnits: row.welcomeUnits,
        dailySessionCards: row.dailySessionCards,
        dailyQuestionCount: row.dailyQuestionCount,
      );

  Stream<StarRules> watchRules() => watch().map(rulesOf);

  Future<StarRules> readRules() async => rulesOf(await read());

  /// Persist a new set of rules.
  ///
  /// Takes a [StarRules] rather than loose integers so the validation has
  /// already happened by the time this is called — the type is the guard.
  Future<void> writeRules(StarRules rules) async {
    await (_db.update(_db.appSettings)
          ..where((t) => t.id.equals(_singletonId)))
        .write(
      AppSettingsCompanion(
        starValueSeconds: Value(rules.starValueSeconds),
        dailyCeilingUnits: Value(rules.dailyCeilingUnits),
        minimumTimeOnTargetMs: Value(rules.minimumTimeOnTargetMs),
        expiryMode: Value(rules.expiryMode == ExpiryMode.weekly
            ? ExpiryModeRow.weekly
            : ExpiryModeRow.daily),
        welcomeUnits: Value(rules.welcomeUnits),
        dailySessionCards: Value(rules.dailySessionCards),
        dailyQuestionCount: Value(rules.dailyQuestionCount),
      ),
    );
  }

  /// The child's timezone offset, injected into every [DayKey] rather than read
  /// from the device — so changing the timezone cannot silently move the day
  /// boundary and hand out a second daily ceiling.
  Future<int> utcOffsetMinutes() async => (await read()).utcOffsetMinutes;

  /// Article 15.2 — both of these default to **off**, and the app is fully
  /// usable with both off. The 12 Play testers evaluate it that way.
  Future<void> setBlockingEnabled(bool value) => _write(
        AppSettingsCompanion(blockingEnabled: Value(value)),
      );

  Future<void> setLauncherMode(bool value) => _write(
        AppSettingsCompanion(launcherMode: Value(value)),
      );

  /// Appendix §4 — the parent may pause play without destroying the balance.
  Future<void> setPlayPaused(bool value) => _write(
        AppSettingsCompanion(playPaused: Value(value)),
      );

  /// A school level, e.g. «السنة الرابعة ابتدائي». Not an identifier (D-11):
  /// it is a pedagogical parameter, sent per lesson request and never stored
  /// server-side.
  Future<void> setGrade(String grade) => _write(
        AppSettingsCompanion(grade: Value(grade.trim())),
      );

  Future<void> setOnboardingStep(int step) => _write(
        AppSettingsCompanion(onboardingStep: Value(step)),
      );

  /// D-13 — which weekday closes the week for the test and the purge.
  Future<void> setExpiryWeekday(int weekday) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      throw ArgumentError.value(weekday, 'weekday', 'must be 1..7');
    }
    return _write(AppSettingsCompanion(expiryWeekday: Value(weekday)));
  }

  /// Stores the salted hash of the parent's PIN. The PIN itself is never
  /// stored and never recoverable — reset goes through the parent's server
  /// account (D-10).
  Future<void> setPin({required String hash, required String salt}) => _write(
        AppSettingsCompanion(pinHash: Value(hash), pinSalt: Value(salt)),
      );

  Future<void> setUtcOffsetMinutes(int minutes) => _write(
        AppSettingsCompanion(utcOffsetMinutes: Value(minutes)),
      );

  Future<void> _write(AppSettingsCompanion companion) async {
    await (_db.update(_db.appSettings)
          ..where((t) => t.id.equals(_singletonId)))
        .write(companion);
  }
}
