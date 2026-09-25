import 'dart:math';

import 'package:drift/drift.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

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

  final LunioDatabase _db;

  static const int _singletonId = 1;

  Future<SettingsRow> read() => (_db.select(
    _db.appSettings,
  )..where((t) => t.id.equals(_singletonId))).getSingle();

  Stream<SettingsRow> watch() => (_db.select(
    _db.appSettings,
  )..where((t) => t.id.equals(_singletonId))).watchSingle();

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
    await (_db.update(
      _db.appSettings,
    )..where((t) => t.id.equals(_singletonId))).write(
      AppSettingsCompanion(
        starValueSeconds: Value(rules.starValueSeconds),
        dailyCeilingUnits: Value(rules.dailyCeilingUnits),
        minimumTimeOnTargetMs: Value(rules.minimumTimeOnTargetMs),
        expiryMode: Value(
          rules.expiryMode == ExpiryMode.weekly
              ? ExpiryModeRow.weekly
              : ExpiryModeRow.daily,
        ),
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

  /// This installation's UUID, generated on first use and never changed after.
  ///
  /// Generated lazily rather than seeded with the singleton row so that an
  /// install upgraded from schema v2 and a fresh one take the same path — only
  /// one of them then has to be right. Written inside a transaction because two
  /// providers reading it at startup would otherwise race and mint two ids, and
  /// the second would silently claim a second device on the server.
  ///
  /// `Random.secure()` rather than a package: a v4 UUID is 122 random bits and
  /// six fixed ones, and adding a dependency for that is a dependency to keep
  /// current forever.
  Future<String> installId() async {
    final existing = (await read()).installId;
    if (existing.isNotEmpty) return existing;

    return _db.transaction(() async {
      final current = (await read()).installId;
      if (current.isNotEmpty) return current;
      final generated = _uuidV4();
      await _write(AppSettingsCompanion(installId: Value(generated)));
      return generated;
    });
  }

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    // Version 4, variant 10xx — the two fields that make it a valid v4.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  /// Article 15.2 — both of these default to **off**, and the app is fully
  /// usable with both off. The 12 Play testers evaluate it that way.
  Future<void> setBlockingEnabled(bool value) =>
      _write(AppSettingsCompanion(blockingEnabled: Value(value)));

  Future<void> setLauncherMode(bool value) =>
      _write(AppSettingsCompanion(launcherMode: Value(value)));

  /// Appendix §4 — the parent may pause play without destroying the balance.
  Future<void> setPlayPaused(bool value) =>
      _write(AppSettingsCompanion(playPaused: Value(value)));

  /// Ask for the PIN before Lunio can be uninstalled or its data cleared.
  ///
  /// Client request, 2026-09-25. It needs the accessibility service, which is
  /// the same permission blocking needs — so a parent who turns this on without
  /// blocking still has to grant it, and the settings screen says so.
  Future<void> setUninstallGuard(bool value) =>
      _write(AppSettingsCompanion(uninstallGuard: Value(value)));

  /// A school level, e.g. «السنة الرابعة ابتدائي». Not an identifier (D-11):
  /// it is a pedagogical parameter, sent per lesson request and never stored
  /// server-side.
  Future<void> setGrade(String grade) =>
      _write(AppSettingsCompanion(grade: Value(grade.trim())));

  Future<void> setOnboardingStep(int step) =>
      _write(AppSettingsCompanion(onboardingStep: Value(step)));

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
  Future<void> setPin({required String hash, required String salt}) =>
      _write(AppSettingsCompanion(pinHash: Value(hash), pinSalt: Value(salt)));

  Future<void> setUtcOffsetMinutes(int minutes) =>
      _write(AppSettingsCompanion(utcOffsetMinutes: Value(minutes)));

  Future<void> _write(AppSettingsCompanion companion) async {
    await (_db.update(
      _db.appSettings,
    )..where((t) => t.id.equals(_singletonId))).write(companion);
  }
}
