import 'package:drift/drift.dart' hide isNull;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:nojoumi/data/local/database.dart';
import 'package:nojoumi/data/local/tables.dart';

import 'support/test_db.dart';

/// The local schema, verified against a real SQLite engine.
///
/// These tests exist because the schema is where Article 14 either holds or
/// quietly fails. A mocked database would prove nothing about cascades,
/// defaults, or the primary key that enforces Article 6.2.
void main() {
  late NojoumiDatabase db;

  setUp(() async => db = await freshDatabase());
  tearDown(() async => db.close());

  group('the appendix §5 defaults are the schema defaults', () {
    test('a fresh install carries exactly the published values', () async {
      final s = await db.select(db.appSettings).getSingle();

      expect(s.starValueSeconds, 60, reason: '1 minute per star');
      expect(s.dailyCeilingUnits, 6000, reason: '60 stars');
      expect(s.minimumTimeOnTargetMs, 1500, reason: '1.5 seconds');
      expect(s.expiryMode, ExpiryModeRow.daily);
      expect(s.welcomeUnits, 1000, reason: '10 stars');
      expect(s.dailySessionCards, 12);
      expect(s.dailyQuestionCount, 5);
    });

    test('blocking and launcher mode are OFF by default (Art. 15.2)', () async {
      final s = await db.select(db.appSettings).getSingle();

      expect(s.blockingEnabled, isFalse);
      expect(s.launcherMode, isFalse);
    });

    test('the welcome balance has not been granted yet', () async {
      final s = await db.select(db.appSettings).getSingle();
      expect(s.welcomeGranted, isFalse);
    });

    test('the four singleton rows exist after creation', () async {
      expect(await db.select(db.appSettings).get(), hasLength(1));
      expect(await db.select(db.streakStates).get(), hasLength(1));
      expect(await db.select(db.clockStates).get(), hasLength(1));
      expect(await db.select(db.subscriptionCaches).get(), hasLength(1));
    });

    test('a device with no server contact starts as expired, not active',
        () async {
      final cache = await db.select(db.subscriptionCaches).getSingle();

      expect(cache.state, SubscriptionStateRow.expired);
      expect(cache.fetchedAtMs, isNull);
    });

    test('the trusted clock starts with no anchor and a zero high-water mark',
        () async {
      final clock = await db.select(db.clockStates).getSingle();

      expect(clock.anchorServerEpochMs, isNull);
      expect(clock.highWaterEpochMs, 0);
      expect(clock.tamperCount, 0);
    });
  });

  group('Article 6.2 — the same target cannot be counted twice in one day', () {
    test('the composite primary key refuses a duplicate', () async {
      Future<void> insert() => db.into(db.countedTargets).insert(
            CountedTargetsCompanion.insert(
              dayKey: 20680,
              kind: TaskKind.memorize,
              targetId: 7,
              atMs: 1,
            ),
          );

      await insert();
      await expectLater(insert(), throwsA(isA<SqliteException>()));
    });

    test('the same target on a different day is allowed', () async {
      await db.into(db.countedTargets).insert(
            CountedTargetsCompanion.insert(
              dayKey: 20680,
              kind: TaskKind.memorize,
              targetId: 7,
              atMs: 1,
            ),
          );
      await db.into(db.countedTargets).insert(
            CountedTargetsCompanion.insert(
              dayKey: 20681,
              kind: TaskKind.memorize,
              targetId: 7,
              atMs: 2,
            ),
          );

      expect(await db.select(db.countedTargets).get(), hasLength(2));
    });

    test('the same id as a different kind is a different target', () async {
      await db.into(db.countedTargets).insert(
            CountedTargetsCompanion.insert(
              dayKey: 20680,
              kind: TaskKind.memorize,
              targetId: 7,
              atMs: 1,
            ),
          );
      await db.into(db.countedTargets).insert(
            CountedTargetsCompanion.insert(
              dayKey: 20680,
              kind: TaskKind.exercise,
              targetId: 7,
              atMs: 2,
            ),
          );

      expect(await db.select(db.countedTargets).get(), hasLength(2));
    });
  });

  group('Article 14 — the weekly purge must actually cascade', () {
    Future<int> seedLesson() async {
      final lessonId = await db.into(db.lessons).insert(
            LessonsCompanion.insert(
              title: const Value('فضل العلم'),
              subject: const Value('تربية إسلامية'),
              grade: const Value('السنة الثالثة ابتدائي'),
              summary: 'ملخّص الدرس.',
              createdAtMs: 1000,
              weekKey: 2954,
            ),
          );
      await db.into(db.lessonImages).insert(
            LessonImagesCompanion.insert(
              lessonId: lessonId,
              filePath: '/data/user/0/dz.nojoumi/files/lesson1.jpg',
              capturedAtMs: 1000,
            ),
          );
      await db.into(db.cards).insert(
            CardsCompanion.insert(
              lessonId: lessonId,
              front: 'ما حكم طلب العلم؟',
              back: 'فريضة على كل مسلم.',
              repetitions: const Value(0),
              intervalDays: const Value(0),
              easePermille: const Value(2500),
              lapses: const Value(0),
            ),
          );
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              lessonId: lessonId,
              prompt: 'ما حكم طلب العلم؟',
              choicesJson: '["سنة","فريضة","مباح","مكروه"]',
              correctIndex: 1,
            ),
          );
      return lessonId;
    }

    test('foreign keys are enforced, so deletes cascade', () async {
      final lessonId = await seedLesson();

      await (db.delete(db.lessons)..where((t) => t.id.equals(lessonId))).go();

      expect(await db.select(db.lessonImages).get(), isEmpty);
      expect(await db.select(db.cards).get(), isEmpty);
      expect(await db.select(db.questions).get(), isEmpty);
    });

    test('an image row cannot point at a lesson that does not exist', () async {
      await expectLater(
        db.into(db.lessonImages).insert(
              LessonImagesCompanion.insert(
                lessonId: 999999,
                filePath: '/nowhere.jpg',
                capturedAtMs: 1,
              ),
            ),
        throwsA(isA<SqliteException>()),
        reason: 'without PRAGMA foreign_keys=ON this would silently succeed and '
            'orphan a file the purge would then never find',
      );
    });

    test(
        'the purge deletes images and questions but KEEPS the summary and the '
        'cards (Art. 14, decisions.md D-6)', () async {
      final lessonId = await seedLesson();

      // What the weekly purge does: files and exercises go, summary stays.
      await (db.delete(db.lessonImages)
            ..where((t) => t.lessonId.equals(lessonId)))
          .go();
      await (db.delete(db.questions)..where((t) => t.lessonId.equals(lessonId)))
          .go();
      await (db.update(db.lessons)..where((t) => t.id.equals(lessonId)))
          .write(const LessonsCompanion(purgedAtMs: Value(9999)));

      expect(await db.select(db.lessonImages).get(), isEmpty);
      expect(await db.select(db.questions).get(), isEmpty);

      final lesson = await db.select(db.lessons).getSingle();
      expect(lesson.summary, 'ملخّص الدرس.',
          reason: 'Art. 14 retains the summary');
      expect(await db.select(db.cards).get(), hasLength(1),
          reason: 'cards survive, or spaced repetition dies weekly (D-6)');
    });
  });

  group('AD-3 — no floating point anywhere a balance lives', () {
    test('every star and time column is an integer in SQLite', () async {
      final rows = await db
          .customSelect(
            "SELECT name, type FROM pragma_table_info('star_ledger') "
            "UNION ALL SELECT name, type FROM pragma_table_info('day_progress_rows') "
            "UNION ALL SELECT name, type FROM pragma_table_info('app_settings') "
            "UNION ALL SELECT name, type FROM pragma_table_info('cards')",
          )
          .get();

      expect(rows, isNotEmpty);
      final reals = rows
          .map((r) => (r.data['name'] as String, r.data['type'] as String))
          .where((c) => c.$2.toUpperCase().contains('REAL'))
          .toList();

      expect(
        reals,
        isEmpty,
        reason: 'AD-3: a REAL column holding a balance reintroduces exactly the '
            'drift integer star units exist to prevent. Found: $reals',
      );
    });
  });

  group('the schema holds no identifier of the child (Art. 14)', () {
    test('no column name suggests child identity', () async {
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      expect(tables, isNotEmpty);

      const forbidden = [
        'child_name',
        'full_name',
        'first_name',
        'last_name',
        'birth',
        'birthday',
        'birthdate',
        'photo',
        'avatar',
        'picture',
        'latitude',
        'longitude',
        'gps',
        'location',
        'address',
        'phone',
        'email',
        // Art. 7.7 — card data never touches this device either.
        'card_number',
        'cvv',
        'cvc',
        'pan',
        'expiry_date',
      ];

      final offenders = <String>[];
      for (final t in tables) {
        final name = t.data['name'] as String;
        final cols = await db
            .customSelect("SELECT name FROM pragma_table_info('$name')")
            .get();
        for (final c in cols) {
          final col = (c.data['name'] as String).toLowerCase();
          if (forbidden.contains(col)) offenders.add('$name.$col');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Article 14 forbids the app holding any identifier of the child, '
            'and Article 7.7 forbids card data anywhere. Found: $offenders',
      );
    });

    test('grade is stored, and grade alone', () async {
      final cols = await db
          .customSelect("SELECT name FROM pragma_table_info('app_settings')")
          .get();
      final names = cols.map((c) => c.data['name'] as String).toSet();

      expect(names, contains('grade'));
      expect(names, isNot(contains('age')));
      expect(names, isNot(contains('name')));
    });
  });
}
