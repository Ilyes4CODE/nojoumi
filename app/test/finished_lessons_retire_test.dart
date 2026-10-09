import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/data/repositories/session_repository.dart';
import 'package:lunio/data/repositories/star_repository.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

import 'support/test_db.dart';

/// A test finished today does not come back tomorrow.
///
/// Client report, 2026-10-09: "today's lesson comes back tomorrow as a new
/// test". With the memorization cards switched off (D-85) the day builder had no
/// cards to anchor on, so every morning it fell through to "any live question,
/// newest lesson first" and served the same lesson again, however completely
/// the child had answered it the day before.
void main() {
  late LunioDatabase db;
  late SessionRepository sessions;

  final rules = StarRules();
  const today = DayKey(20500);
  const tomorrow = DayKey(20501);
  const now = TrustedInstant(
    epochMs: 1788000000000,
    level: TrustLevel.serverAnchored,
  );

  setUp(() async {
    db = await freshDatabase();
    sessions = SessionRepository(db, StarRepository(db));
  });

  tearDown(() => db.close());

  Future<int> seedLesson(String name, {int questions = 3}) async {
    final lessonId = await db
        .into(db.lessons)
        .insert(
          LessonsCompanion.insert(
            summary: name,
            createdAtMs: now.epochMs,
            weekKey: 1,
          ),
        );
    for (var i = 0; i < questions; i++) {
      await db
          .into(db.questions)
          .insert(
            QuestionsCompanion.insert(
              lessonId: lessonId,
              prompt: '$name — سؤال $i',
              choicesJson: jsonEncode(['أ', 'ب', 'ج', 'د']),
              correctIndex: 1,
            ),
          );
    }
    return lessonId;
  }

  Future<void> answerEverything(DayKey day) async {
    var session = await sessions.sessionFor(day: day, rules: rules);
    while (!session.isComplete) {
      final task = session.tasks.firstWhere(
        (t) => !session.answeredTaskIds.contains(t.taskId),
      );
      await sessions.submitAnswer(
        day: day,
        rules: rules,
        now: now,
        task: task,
        correct: true,
        attemptNumber: 1,
        msOnTarget: 5000,
      );
      session = await sessions.sessionFor(day: day, rules: rules);
    }
  }

  Set<String> prompts(DailySession session) => {
    for (final task in session.tasks)
      if (task is QuestionTask) task.prompt,
  };

  test('a lesson finished today is not tomorrow\'s test', () async {
    await seedLesson('الحج');
    await answerEverything(today);

    final next = await sessions.sessionFor(day: tomorrow, rules: rules);

    expect(prompts(next), isEmpty,
        reason: 'every question was answered yesterday; nothing is left to ask');
  });

  test('a lesson added since then is what tomorrow brings', () async {
    await seedLesson('الحج');
    await answerEverything(today);
    await seedLesson('الصلاة');

    final next = await sessions.sessionFor(day: tomorrow, rules: rules);

    expect(prompts(next), isNotEmpty);
    expect(prompts(next).every((p) => p.startsWith('الصلاة')), isTrue,
        reason: 'only the new lesson — not a replay of the finished one');
  });

  test('a test left unfinished today carries over to tomorrow', () async {
    // Shown is not finished. A child who stopped halfway still owes the rest,
    // and dropping it would lose the lesson as surely as replaying it annoys.
    await seedLesson('الحج', questions: 3);
    final session = await sessions.sessionFor(day: today, rules: rules);
    final first = session.tasks.first;
    await sessions.submitAnswer(
      day: today,
      rules: rules,
      now: now,
      task: first,
      correct: true,
      attemptNumber: 1,
      msOnTarget: 5000,
    );

    final next = await sessions.sessionFor(day: tomorrow, rules: rules);
    final carried = prompts(next);

    expect(carried, isNot(contains((first as QuestionTask).prompt)),
        reason: 'the one answered yesterday is done');
    expect(carried, isNotEmpty, reason: 'the two not reached are still owed');
  });

  test('a question missed and then answered is still finished', () async {
    // The wrong-answer retry re-asks within the same day. Once the child gets
    // it right, the question is done like any other.
    await seedLesson('الحج', questions: 1);
    var session = await sessions.sessionFor(day: today, rules: rules);
    await sessions.submitAnswer(
      day: today,
      rules: rules,
      now: now,
      task: session.tasks.single,
      correct: false,
      attemptNumber: 1,
      msOnTarget: 5000,
    );
    await answerEverything(today);

    final next = await sessions.sessionFor(day: tomorrow, rules: rules);
    expect(prompts(next), isEmpty);
  });
}
