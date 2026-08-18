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
    EventLog,
  ],
)
class NojoumiDatabase extends _$NojoumiDatabase {
  NojoumiDatabase() : super(_openOnDevice());

  /// For tests and for the eval tooling: an in-memory database with the same
  /// schema, so the whole local model is verifiable with no phone attached.
  NojoumiDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
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
  }

  /// Exposed so `beforeOpen` can be replicated in tests that build the schema
  /// by hand.
  Future<void> seedForTesting() => _seedSingletons();
}

QueryExecutor _openOnDevice() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'nojoumi.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
