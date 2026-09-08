import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

import '../local/database.dart';
import 'star_repository.dart';

/// One question in the weekly test, ready for the screen.
class WeeklyQuestion {
  const WeeklyQuestion({
    required this.questionId,
    required this.prompt,
    required this.choices,
    required this.correctIndex,
  });

  final int questionId;
  final String prompt;
  final List<String> choices;
  final int correctIndex;
}

/// How the week ended.
class WeeklyTestResult {
  const WeeklyTestResult({
    required this.correct,
    required this.total,
    required this.awardedUnits,
    required this.purgedImages,
    required this.purgedQuestions,
  });

  final int correct;
  final int total;
  final int awardedUnits;

  /// What the automatic deletion actually removed. Surfaced so the screen can
  /// tell the parent, rather than doing it silently — Article 14 is a promise the
  /// client will be asked about, and a promise nobody can see being kept is worth
  /// less than one they can.
  final int purgedImages;
  final int purgedQuestions;

  int get percentBasisPoints => total == 0 ? 0 : (correct * 10000) ~/ total;
  double get percent => percentBasisPoints / 100;
}

/// Article 4.8, Article 5's weekly scale, and Article 14's automatic deletion.
///
/// The three are one mechanism, not three features: the test ends the week, the
/// scale pays for it, and the deletion is what the week costs. Splitting them
/// would let a build ship where the test runs and the purge does not, which is
/// exactly the failure acceptance criterion 11.6 exists to catch.
class WeeklyTestRepository {
  WeeklyTestRepository(
    this._db,
    this._stars, {
    StarEngine engine = const StarEngine(),
  }) : _engine = engine;

  final LunioDatabase _db;
  final StarRepository _stars;
  final StarEngine _engine;

  /// Article 5 needs a test worth grading. D-13 sets the floor at five cards:
  /// a test on two would hand out 10–40 stars for nothing, and would trigger the
  /// purge on a week that barely happened.
  static const int minimumCardsForTest = 5;

  /// Whether today is the day, and whether there is anything to test.
  ///
  /// Three conditions, all of which must hold. The weekday is the parent's
  /// (D-13, default Friday) because a fixed day is predictable for a family and
  /// makes the purge auditable, where "seven days from the first lesson" drifts
  /// and lands differently for every child.
  Future<bool> isDue({
    required DayKey today,
    required int expiryWeekday,
  }) async {
    if (_weekdayOf(today) != expiryWeekday) return false;
    if (await _testFor(_weekKeyOf(today)) != null) return false;
    return (await _cardsThisWeek(today)).length >= minimumCardsForTest;
  }

  /// Build this week's test from the week's own questions.
  ///
  /// Purged questions are excluded, which matters more than it looks: a question
  /// that survived a previous purge would put last week's material in this week's
  /// test and make the result meaningless.
  Future<List<WeeklyQuestion>> buildTest({required DayKey today}) async {
    final lessons = await _lessonsThisWeek(today);
    if (lessons.isEmpty) return const [];

    final rows =
        await (_db.select(_db.questions)
              ..where((t) => t.lessonId.isIn(lessons.map((l) => l.id)))
              ..where((t) => t.purgedAtMs.isNull()))
            .get();

    return [
      for (final row in rows)
        WeeklyQuestion(
          questionId: row.id,
          prompt: row.prompt,
          choices: (jsonDecode(row.choicesJson) as List<dynamic>)
              .map((e) => '$e')
              .toList(),
          correctIndex: row.correctIndex,
        ),
    ];
  }

  Future<int> start({
    required DayKey today,
    required TrustedInstant now,
  }) async {
    return _db
        .into(_db.weeklyTests)
        .insert(
          WeeklyTestsCompanion.insert(
            weekKey: _weekKeyOf(today),
            startedAtMs: now.epochMs,
          ),
        );
  }

  /// Record one answer.
  ///
  /// The prompt is **snapshotted**, not referenced. The question itself is deleted
  /// minutes later by the purge, and a result nobody can explain afterwards is a
  /// result the client is entitled to dispute.
  Future<void> recordAnswer({
    required int testId,
    required WeeklyQuestion question,
    required bool correct,
    required TrustedInstant now,
  }) async {
    await _db
        .into(_db.weeklyTestItems)
        .insert(
          WeeklyTestItemsCompanion.insert(
            testId: testId,
            promptSnapshot: question.prompt,
            correct: correct,
            answeredAtMs: now.epochMs,
          ),
        );
  }

  /// Close the test: score it, pay Article 5's scale, then purge the week.
  ///
  /// The order is the contract's. Article 4.8 deletes the images and exercises
  /// **after** the test, so scoring must be complete and the stars awarded before
  /// anything is removed — otherwise a crash mid-purge would cost the child a
  /// week's work and a week's stars at once.
  Future<WeeklyTestResult> finish({
    required int testId,
    required DayKey today,
    required TrustedInstant now,
  }) async {
    final items = await (_db.select(
      _db.weeklyTestItems,
    )..where((t) => t.testId.equals(testId))).get();

    final total = items.length;
    final correct = items.where((i) => i.correct).length;
    final basisPoints = total == 0 ? 0 : (correct * 10000) ~/ total;

    // Article 5's scale lives in the pure engine, which has table-driven tests on
    // the 49/50/74/75/89/90 boundaries. Not re-derived here.
    final awarded = total == 0
        ? 0
        : await _stars.awardWeeklyTest(
            day: today,
            correct: correct,
            total: total,
            now: now,
            sourceRef: testId,
          );

    await (_db.update(
      _db.weeklyTests,
    )..where((t) => t.id.equals(testId))).write(
      WeeklyTestsCompanion(
        finishedAtMs: Value(now.epochMs),
        totalQuestions: Value(total),
        correctAnswers: Value(correct),
        percentBasisPoints: Value(basisPoints),
        awardedUnits: Value(awarded),
      ),
    );

    final purged = await purgeWeek(today: today, now: now);

    await (_db.update(_db.weeklyTests)..where((t) => t.id.equals(testId)))
        .write(WeeklyTestsCompanion(purgeDoneAtMs: Value(now.epochMs)));

    return WeeklyTestResult(
      correct: correct,
      total: total,
      awardedUnits: awarded,
      purgedImages: purged.images,
      purgedQuestions: purged.questions,
    );
  }

  /// Article 14's automatic deletion.
  ///
  /// > "تُحذف الصور والتمارين من الجهاز بعد الاختبار الأسبوعي، ويبقى الملخّص والنتائج"
  ///
  /// **Images:** the file is deleted from disk and the row with it. A database row
  /// pointing at a path that no longer exists is not a deletion, and neither is a
  /// file left behind because only the row was removed.
  ///
  /// **Exercises:** the question's content is erased and the row is tombstoned.
  /// Erasing rather than dropping keeps the id from ever being reused and keeps
  /// "how many exercises were purged" answerable — but the prompt, the choices and
  /// the answer are genuinely gone, because a row that still reads back the
  /// exercise has not been deleted in any sense the client would accept.
  ///
  /// **Kept:** the lesson row, its summary, the memorization cards (D-6 — deleting
  /// those would make spaced repetition weekly-only and empty a headline feature
  /// of Article 2), and every weekly-test result.
  Future<({int images, int questions})> purgeWeek({
    required DayKey today,
    required TrustedInstant now,
  }) async {
    final lessons = await _lessonsThisWeek(today);
    if (lessons.isEmpty) return (images: 0, questions: 0);
    final lessonIds = lessons.map((l) => l.id).toList();

    final images =
        await (_db.select(_db.lessonImages)
              ..where((t) => t.lessonId.isIn(lessonIds))
              ..where((t) => t.deletedAtMs.isNull()))
            .get();

    // The files go first, outside the transaction. A file deletion cannot be
    // rolled back, so doing it inside one would let the database disagree with
    // the disk in the one direction that matters — rows saying the image exists
    // when it does not.
    var deletedFiles = 0;
    for (final image in images) {
      final file = File(image.filePath);
      if (file.existsSync()) {
        try {
          file.deleteSync();
          deletedFiles++;
        } on FileSystemException {
          // Left on disk. The row stays too, so the next purge retries it rather
          // than recording a deletion that did not happen.
          continue;
        }
      } else {
        deletedFiles++;
      }
    }

    return _db.transaction(() async {
      await (_db.delete(
        _db.lessonImages,
      )..where((t) => t.lessonId.isIn(lessonIds))).go();

      final questions =
          await (_db.select(_db.questions)
                ..where((t) => t.lessonId.isIn(lessonIds))
                ..where((t) => t.purgedAtMs.isNull()))
              .get();

      for (final question in questions) {
        await (_db.update(
          _db.questions,
        )..where((t) => t.id.equals(question.id))).write(
          QuestionsCompanion(
            prompt: const Value(''),
            choicesJson: const Value('[]'),
            correctIndex: const Value(0),
            purgedAtMs: Value(now.epochMs),
          ),
        );
      }

      await (_db.update(_db.lessons)..where((t) => t.id.isIn(lessonIds))).write(
        LessonsCompanion(purgedAtMs: Value(now.epochMs)),
      );

      return (images: deletedFiles, questions: questions.length);
    });
  }

  Future<WeeklyTestRow?> _testFor(int weekKey) {
    return (_db.select(_db.weeklyTests)
          ..where((t) => t.weekKey.equals(weekKey))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<LessonRow>> _lessonsThisWeek(DayKey today) {
    return (_db.select(
      _db.lessons,
    )..where((t) => t.weekKey.equals(_weekKeyOf(today)))).get();
  }

  Future<List<CardRow>> _cardsThisWeek(DayKey today) async {
    final lessons = await _lessonsThisWeek(today);
    if (lessons.isEmpty) return const [];
    return (_db.select(
      _db.cards,
    )..where((t) => t.lessonId.isIn(lessons.map((l) => l.id)))).get();
  }

  /// Whole weeks since the epoch. 1970-01-01 was a Thursday, so the +3 aligns the
  /// boundary; the same expression is used when a lesson is saved, and the two
  /// must never diverge or a lesson would be tested in a week it does not belong
  /// to.
  static int _weekKeyOf(DayKey day) => (day.daysSinceEpoch + 3) ~/ 7;

  /// `DateTime`'s Monday=1..Sunday=7, derived from the day key rather than from a
  /// `DateTime`, because AD-2 forbids reading the platform clock anywhere.
  static int _weekdayOf(DayKey day) => ((day.daysSinceEpoch + 3) % 7) + 1;

  /// Exposed for the engine's own scale, so a caller can preview what a score is
  /// worth without starting a test.
  int previewUnits({required int correct, required int total}) =>
      _engine.weeklyTestUnits(correct: correct, total: total);
}
