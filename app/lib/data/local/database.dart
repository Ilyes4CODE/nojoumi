import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

/// The one local database. Article 14's "البيانات على الجهاز" in code form.
///
/// Opened from the app's **private** directory. Never external storage, never a
/// path the gallery or a backup agent scans: a lesson image or a summary landing
/// somewhere shared would breach Art. 14 as surely as uploading it would.
@DriftDatabase(
  tables: [
    AppSettings,
    ManagedApps,
    Lessons,
    LessonImages,
    Cards,
    Questions,
    TaskInstances,
    Attempts,
    StarLedger,
    DayProgressRows,
    CountedTargets,
    StreakStates,
    WeeklyTests,
    WeeklyTestItems,
    PlaySessions,
    SubscriptionCaches,
    ClockStates,
    AuthTokens,
    EventLog,
  ],
)
class LunioDatabase extends _$LunioDatabase {
  LunioDatabase() : super(_openOnDevice());

  /// For tests and for the eval tooling: an in-memory database with the same
  /// schema, so the whole local model is verifiable with no phone attached.
  LunioDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // v1 -> v2 adds `auth_tokens`. Nothing has shipped, so no install carries
    // v1 — but the step is written properly anyway, because the first
    // migration written under pressure after a release is the one that goes
    // wrong, and this is the cheap moment to exercise the path.
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(authTokens);
      // v2 -> v3 adds the install UUID. Added as a column with an empty
      // default rather than backfilled here: the value is generated on the
      // first read that finds it blank, so an upgraded install and a fresh
      // one take the same path and only one of them has to be right.
      if (from < 3) await m.addColumn(appSettings, appSettings.installId);
      // v3 -> v4 adds the parent's free-play seconds to the day. A plain
      // column with a zero default: an install upgrading mid-day has no free
      // play, which is exactly right — the parent had not given any.
      if (from < 4) {
        await m.addColumn(dayProgressRows, dayProgressRows.freePlaySeconds);
      }
      // v4 -> v5 turns the memorization cards off on installs that already
      // exist. A changed Dart default reaches new installs only; the settings
      // row on a phone already holds 12, and without this the client's own
      // device would be the one place the change did not happen.
      //
      // Written as a statement rather than through the repository because a
      // migration must not depend on `StarRules` still validating the value it
      // is writing — the two versions of that class do not have to agree.
      if (from < 5) {
        await customStatement('UPDATE app_settings SET daily_session_cards = 0');
      }
      // v5 -> v6 clears the cards out of a day that was already built.
      //
      // A separate step rather than part of v5 because the development phone
      // had already taken v5 before this was written, and a migration that has
      // run does not run again. Any install arriving from v4 takes both and
      // ends up in the same place.
      //
      // **Only the unanswered ones.** A card already answered earned its star
      // under the rules in force at the time, and the ledger has to keep
      // agreeing with the day it describes.
      //
      // Ordinals rather than names because a migration must not depend on
      // today's `TaskKind`/`TaskState` still having today's shape: 0 is
      // `memorize`, 0 is `pending`, and both are frozen at this version.
      if (from < 6) {
        await customStatement(
          'DELETE FROM task_instances WHERE kind = 0 AND state = 0',
        );
      }
    },
    beforeOpen: (details) async {
      // Foreign keys are OFF by default in SQLite. The purge relies on
      // ON DELETE CASCADE from Lessons to images, cards and questions, so
      // leaving them off would silently orphan rows the contract says must
      // be deleted (Art. 14).
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.wasCreated) {
        await _seedSingletons();
      }
    },
  );

  /// The four singleton rows must exist before anything reads them. Every
  /// default here comes from appendix §5, not from taste.
  Future<void> _seedSingletons() async {
    await into(appSettings).insert(
      AppSettingsCompanion(id: const Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
    await into(streakStates).insert(
      StreakStatesCompanion(id: const Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
    await into(clockStates).insert(
      ClockStatesCompanion(id: const Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
    await into(subscriptionCaches).insert(
      SubscriptionCachesCompanion(id: const Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
    await into(authTokens).insert(
      AuthTokensCompanion(id: const Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Exposed so `beforeOpen` can be replicated in tests that build the schema
  /// by hand.
  Future<void> seedForTesting() => _seedSingletons();
}

QueryExecutor _openOnDevice() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'lunio.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
