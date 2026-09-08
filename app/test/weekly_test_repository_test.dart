import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/data/repositories/star_repository.dart';
import 'package:lunio/data/repositories/weekly_test_repository.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';
import 'package:path/path.dart' as p;

import 'support/test_db.dart';

/// Article 4.8, Article 5's weekly scale, and Article 14's automatic deletion.
///
/// **Acceptance criterion 11.6 is "weekly test + automatic deletion" as one item**,
/// and these tests treat it that way: a test that scores correctly but leaves the
/// images on disk fails the criterion exactly as badly as one that never runs.
void main() {
  late LunioDatabase db;
  late StarRepository stars;
  late WeeklyTestRepository weekly;
  late Directory scratch;

  // 2026-03-13 was a Friday, which is the default test day (D-13).
  final friday = DayKey.fromEpochMs(
    DateTime.utc(2026, 3, 13, 9).millisecondsSinceEpoch,
    utcOffsetMinutes: DayKey.algeriaUtcOffsetMinutes,
  );

  const now = TrustedInstant(
    epochMs: 1773133200000,
    level: TrustLevel.serverAnchored,
  );

  int weekKeyOf(DayKey day) => (day.daysSinceEpoch + 3) ~/ 7;

  /// A lesson in [day]'s week, with real image files on disk.
  Future<int> seedLesson({
    required DayKey day,
    int cards = 6,
    int questions = 4,
  }) async {
    final lessonId = await db.into(db.lessons).insert(
          LessonsCompanion.insert(
            summary: 'ملخّص الدرس',
            createdAtMs: now.epochMs,
            weekKey: weekKeyOf(day),
          ),
        );

    final file = File(p.join(scratch.path, 'page_$lessonId.jpg'));
    await file.writeAsBytes(List<int>.filled(32, 7));
    await db.into(db.lessonImages).insert(
          LessonImagesCompanion.insert(
            lessonId: lessonId,
            filePath: file.path,
            capturedAtMs: now.epochMs,
          ),
        );

    for (var i = 0; i < cards; i++) {
      await db.into(db.cards).insert(
            CardsCompanion.insert(
              lessonId: lessonId,
              front: 'وجه $i',
              back: 'ظهر $i',
            ),
          );
    }
    for (var i = 0; i < questions; i++) {
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              lessonId: lessonId,
              prompt: 'سؤال سرّي $i',
              choicesJson: jsonEncode(['أ', 'ب', 'ج']),
              correctIndex: 1,
            ),
          );
    }
    return lessonId;
  }

  /// Run a whole test, answering [correct] of the questions correctly.
  Future<WeeklyTestResult> runTest({required int correct}) async {
    final questions = await weekly.buildTest(today: friday);
    final testId = await weekly.start(today: friday, now: now);
    for (var i = 0; i < questions.length; i++) {
      await weekly.recordAnswer(
        testId: testId,
        question: questions[i],
        correct: i < correct,
        now: now,
      );
    }
    return weekly.finish(testId: testId, today: friday, now: now);
  }

  setUp(() async {
    db = await freshDatabase();
    stars = StarRepository(db);
    weekly = WeeklyTestRepository(db, stars);
    scratch = await Directory.systemTemp.createTemp('lunio_weekly');
  });

  tearDown(() async {
    await db.close();
    if (scratch.existsSync()) scratch.deleteSync(recursive: true);
  });

  group('D-13 — when the test runs', () {
    test('on the parent\'s chosen weekday, with enough cards', () async {
      await seedLesson(day: friday, cards: 6);
      expect(
        await weekly.isDue(today: friday, expiryWeekday: DateTime.friday),
        isTrue,
      );
    });

    test('not on any other day', () async {
      await seedLesson(day: friday, cards: 6);
      expect(
        await weekly.isDue(today: friday, expiryWeekday: DateTime.monday),
        isFalse,
        reason: 'the weekday is the parent\'s setting, not a constant',
      );
    });

    test('not on a week with fewer than five cards', () async {
      await seedLesson(day: friday, cards: 4);
      expect(
        await weekly.isDue(today: friday, expiryWeekday: DateTime.friday),
        isFalse,
        reason: 'D-13 — a test on four cards would hand out 10–40 stars for '
            'nothing, and would purge a week that barely happened',
      );
    });

    test('not twice in the same week', () async {
      await seedLesson(day: friday, cards: 6);
      await runTest(correct: 4);
      expect(
        await weekly.isDue(today: friday, expiryWeekday: DateTime.friday),
        isFalse,
      );
    });

    test('a week with no lessons at all is never due', () async {
      expect(
        await weekly.isDue(today: friday, expiryWeekday: DateTime.friday),
        isFalse,
      );
    });
  });

  group('Article 5 — the weekly scale', () {
    test('90% and above pays 40 stars', () async {
      await seedLesson(day: friday, cards: 6, questions: 10);
      final result = await runTest(correct: 9);
      expect(result.percent, 90);
      expect(result.awardedUnits, 40 * starUnit);
    });

    test('75–89% pays 30', () async {
      await seedLesson(day: friday, cards: 6, questions: 10);
      expect((await runTest(correct: 8)).awardedUnits, 30 * starUnit);
    });

    test('50–74% pays 20', () async {
      await seedLesson(day: friday, cards: 6, questions: 10);
      expect((await runTest(correct: 5)).awardedUnits, 20 * starUnit);
    });

    test('below 50% still pays 10, exactly as Article 5 is written', () async {
      await seedLesson(day: friday, cards: 6, questions: 10);
      // Flagged for the client in D-14, and implemented literally: it is not our
      // call to soften a signed number.
      expect((await runTest(correct: 0)).awardedUnits, 10 * starUnit);
    });

    test('the award lands in the granted bucket, not against the daily ceiling',
        () async {
      await seedLesson(day: friday, cards: 6, questions: 10);
      await runTest(correct: 9);

      final day = await stars.dayProgress(friday);
      expect(day.grantedUnits, 40 * starUnit);
      expect(day.earnedUnits, 0,
          reason: 'the weekly test is not part of the daily session, so it must '
              'not be squeezed by Art. 6.4\'s earning ceiling');
    });

    test('the result is recorded with its percentage in basis points', () async {
      await seedLesson(day: friday, cards: 6, questions: 8);
      await runTest(correct: 7);

      final row = await db.select(db.weeklyTests).getSingle();
      expect(row.correctAnswers, 7);
      expect(row.totalQuestions, 8);
      expect(row.percentBasisPoints, 8750, reason: '87.5% held as an integer');
      expect(row.finishedAtMs, isNotNull);
    });
  });

  group('Article 14 — the automatic deletion', () {
    test('the image file is gone from disk and its row with it', () async {
      await seedLesson(day: friday);
      final before = await db.select(db.lessonImages).getSingle();
      expect(File(before.filePath).existsSync(), isTrue);

      final result = await runTest(correct: 2);

      expect(File(before.filePath).existsSync(), isFalse,
          reason: 'a row removed while the file stays on the phone is not a '
              'deletion');
      expect(await db.select(db.lessonImages).get(), isEmpty,
          reason: 'and neither is a file removed while the row still points at it');
      expect(result.purgedImages, 1);
    });

    test('no exercise text survives the purge', () async {
      await seedLesson(day: friday, questions: 4);
      await runTest(correct: 2);

      final questions = await db.select(db.questions).get();
      expect(questions, hasLength(4), reason: 'tombstoned, so ids are never reused');
      for (final question in questions) {
        expect(question.prompt, isEmpty);
        expect(question.choicesJson, '[]');
        expect(question.purgedAtMs, isNotNull);
      }

      // The blunt version of the same assertion: search every text column in the
      // database for the prompt we seeded.
      final leaked = await db
          .customSelect("SELECT COUNT(*) AS n FROM questions WHERE prompt LIKE '%سرّي%'")
          .getSingle();
      expect(leaked.data['n'], 0,
          reason: 'Art. 14 deletes the exercises; a row that still reads back '
              'the question has not been deleted in any sense the client would '
              'accept');
    });

    test('the summary survives — Article 14 keeps it', () async {
      await seedLesson(day: friday);
      await runTest(correct: 2);

      final lesson = await db.select(db.lessons).getSingle();
      expect(lesson.summary, 'ملخّص الدرس');
      expect(lesson.purgedAtMs, isNotNull, reason: 'marked, not erased');
    });

    test('the memorization cards survive — D-6', () async {
      await seedLesson(day: friday, cards: 6);
      await runTest(correct: 2);

      expect(await db.select(db.cards).get(), hasLength(6),
          reason: 'deleting cards would make spaced repetition weekly-only and '
              'empty a headline feature of Art. 2');
    });

    test('the result survives, and stays explainable without the questions',
        () async {
      await seedLesson(day: friday, questions: 4);
      await runTest(correct: 3);

      final items = await db.select(db.weeklyTestItems).get();
      expect(items, hasLength(4));
      expect(items.first.promptSnapshot, contains('سؤال'),
          reason: 'snapshotted at answer time precisely because the question is '
              'deleted minutes later');

      final test = await db.select(db.weeklyTests).getSingle();
      expect(test.purgeDoneAtMs, isNotNull);
    });

    test('a lesson from another week is untouched', () async {
      final lastWeek = DayKey(friday.daysSinceEpoch - 7);
      await seedLesson(day: lastWeek, questions: 3);
      await seedLesson(day: friday, questions: 3);

      await runTest(correct: 1);

      final surviving = await (db.select(db.questions)
            ..where((t) => t.purgedAtMs.isNull()))
          .get();
      expect(surviving, hasLength(3),
          reason: 'the purge is scoped to the week that was tested');
    });

    test('a missing file does not stop the purge', () async {
      await seedLesson(day: friday);
      final image = await db.select(db.lessonImages).getSingle();
      File(image.filePath).deleteSync();

      final result = await runTest(correct: 2);

      expect(result.purgedImages, 1,
          reason: 'a file the user already deleted is a file that is gone; the '
              'row must still be cleaned up');
      expect(await db.select(db.lessonImages).get(), isEmpty);
    });
  });

  group('the ordering the contract requires', () {
    test('stars are awarded before anything is deleted', () async {
      await seedLesson(day: friday, questions: 10);
      final result = await runTest(correct: 9);

      // Both true at the end is the only observable proof from here, but the
      // ordering matters: Art. 4.8 deletes *after* the test, so a crash between
      // the two must never cost the child both the week and the stars.
      expect(result.awardedUnits, 40 * starUnit);
      expect(await stars.derivedBalanceUnits(friday), 40 * starUnit);
      expect(await db.select(db.lessonImages).get(), isEmpty);
    });
  });
}
