import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/data/repositories/session_repository.dart';
import 'package:lunio/data/repositories/star_repository.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

import 'support/test_db.dart';

/// The day as the client asked for it on 2026-08-31: questions only, and a
/// missed question comes back.
///
/// Two changes with very different weights. Removing the cards is a **contract
/// amendment** — Article 5's first two rows stop being earnable because nothing
/// presents them (D-85). Re-asking a missed question is not: Articles 6.1 and
/// 6.2 already refuse to pay for a second attempt, so the repeat is practice
/// and the star table is untouched. This file pins both.
void main() {
  late LunioDatabase db;
  late StarRepository stars;
  late SessionRepository sessions;

  /// The shipped defaults — cards off.
  final rules = StarRules();
  const day = DayKey(20500);
  const now = TrustedInstant(
    epochMs: 1788000000000,
    level: TrustLevel.serverAnchored,
  );

  setUp(() async {
    db = await freshDatabase();
    stars = StarRepository(db);
    sessions = SessionRepository(db, stars);
  });

  tearDown(() => db.close());

  Future<int> seedLesson({int cards = 6, int questions = 3}) async {
    final lessonId = await db
        .into(db.lessons)
        .insert(
          LessonsCompanion.insert(
            summary: 'ملخّص',
            createdAtMs: now.epochMs,
            weekKey: 1,
          ),
        );
    for (var i = 0; i < cards; i++) {
      await db
          .into(db.cards)
          .insert(
            CardsCompanion.insert(
              lessonId: lessonId,
              front: 'وجه $i',
              back: 'ظهر $i',
            ),
          );
    }
    for (var i = 0; i < questions; i++) {
      await db
          .into(db.questions)
          .insert(
            QuestionsCompanion.insert(
              lessonId: lessonId,
              prompt: 'سؤال $i',
              choicesJson: jsonEncode(['أ', 'ب', 'ج', 'د']),
              correctIndex: 1,
            ),
          );
    }
    return lessonId;
  }

  group('the day is questions only', () {
    test('no memorization card is presented, however many exist', () async {
      await seedLesson(cards: 12, questions: 3);

      final session = await sessions.sessionFor(day: day, rules: rules);

      expect(session.tasks.whereType<CardTask>(), isEmpty);
      expect(session.tasks.whereType<QuestionTask>(), hasLength(3));
    });

    test('a captured lesson still reaches the child', () async {
      // The reachability guarantee of D-78/D-81 must survive the amendment: a
      // lesson with no presented cards is still a lesson the child can open.
      final lessonId = await seedLesson(cards: 12, questions: 2);
      final session = await sessions.sessionFor(day: day, rules: rules);

      final slice = session.sliceOf(lessonId);
      expect(slice, isNotNull);
      expect(slice!.cards, isEmpty);
      expect(slice.questions, hasLength(2));
      expect(
        slice.questionsUnlocked,
        isTrue,
        reason: 'Article 4.3 orders memorize before review, and with no cards '
            'there is nothing to do first',
      );
    });

    test('the cards are not deleted, only unasked', () async {
      // The amendment is one number. If the client reverses it the material is
      // still there — this is the assertion that says so.
      await seedLesson(cards: 12, questions: 1);

      expect(await db.select(db.cards).get(), hasLength(12));

      final restored = await sessions.sessionFor(
        day: const DayKey(20501),
        rules: StarRules(dailySessionCards: 12),
      );
      expect(restored.tasks.whereType<CardTask>(), isNotEmpty);
    });
  });

  group('a missed question comes back', () {
    Future<SessionTask> nextTask() async =>
        (await sessions.sessionFor(day: day, rules: rules)).next!;

    Future<AnswerOutcome> answer(SessionTask task, {required bool correct}) =>
        sessions.submitAnswer(
          day: day,
          rules: rules,
          now: now,
          task: task,
          correct: correct,
          attemptNumber: 1,
          msOnTarget: 4000,
        );

    test('answering wrongly puts it back at the end of the day', () async {
      await seedLesson(cards: 0, questions: 1);
      final first = await nextTask();
      expect((await sessions.sessionFor(day: day, rules: rules)).total, 1);

      await answer(first, correct: false);

      final after = await sessions.sessionFor(day: day, rules: rules);
      expect(after.total, 2);
      expect(after.next, isNotNull);
      expect(after.next!.targetId, first.targetId);
    });

    test('answering correctly does not', () async {
      await seedLesson(cards: 0, questions: 1);

      await answer(await nextTask(), correct: true);

      final after = await sessions.sessionFor(day: day, rules: rules);
      expect(after.total, 1);
      expect(after.next, isNull);
    });

    test('it is asked a different way the second time', () async {
      // Re-asked in the order the child just saw, it is a memory test on a
      // screen they were looking at ten seconds ago.
      await seedLesson(cards: 0, questions: 1);

      final first = await nextTask() as QuestionTask;
      await answer(first, correct: false);
      final second = await nextTask() as QuestionTask;

      expect(second.taskId, isNot(first.taskId));
      expect(
        second.choices[second.correctIndex],
        first.choices[first.correctIndex],
        reason: 'however the options move, the right one is still the right one',
      );
      expect(second.choices.toSet(), first.choices.toSet());
    });

    test('the repeat says it is a repeat', () async {
      // Reported 2026-08-31 as the missed question never coming back. It had:
      // it went to the end of the section and looked like any other question,
      // so the section simply grew by one and nobody could tell why. A repeat
      // that does not announce itself is indistinguishable from a miscount.
      await seedLesson(cards: 0, questions: 2);

      final first = await nextTask() as QuestionTask;
      expect(first.attempt, 1);
      expect(first.isRepeat, isFalse);

      await answer(first, correct: false);

      final session = await sessions.sessionFor(day: day, rules: rules);
      final again = session.tasks
          .whereType<QuestionTask>()
          .lastWhere((q) => q.targetId == first.targetId);

      expect(again.attempt, 2);
      expect(again.isRepeat, isTrue);
    });

    test('Article 6.1 — the second attempt earns nothing', () async {
      await seedLesson(cards: 0, questions: 1);

      await answer(await nextTask(), correct: false);
      final retry = await answer(await nextTask(), correct: true);

      expect(
        retry.decision.awardedUnits,
        0,
        reason: 'a star is for an answer correct on the first attempt; the '
            'repeat is practice, and the engine already refuses it without '
            'being told about any of this',
      );
    });

    test('it stops after three attempts rather than for ever', () async {
      // An unbounded retry is a day that can never be finished, which would put
      // Article 6.5's +5 permanently out of reach for the child having the
      // hardest time.
      await seedLesson(cards: 0, questions: 1);

      for (var i = 0; i < maxQuestionAttempts; i++) {
        final task = (await sessions.sessionFor(
          day: day,
          rules: rules,
        )).next;
        expect(task, isNotNull, reason: 'attempt ${i + 1} should exist');
        await answer(task!, correct: false);
      }

      final after = await sessions.sessionFor(day: day, rules: rules);
      expect(after.total, maxQuestionAttempts);
      expect(after.next, isNull, reason: 'the day ends even unanswered');
      expect(after.isComplete, isTrue);
    });

    test('Article 6.5 — a day of retries still completes and pays once', () async {
      await seedLesson(cards: 0, questions: 2);

      var session = await sessions.sessionFor(day: day, rules: rules);
      var outcomes = <AnswerOutcome>[];
      // Miss the first question once, then answer everything.
      var missedOnce = false;
      while (session.next != null) {
        final correct = missedOnce;
        missedOnce = true;
        outcomes.add(await answer(session.next!, correct: correct));
        session = await sessions.sessionFor(day: day, rules: rules);
      }

      expect(session.isComplete, isTrue);
      final bonuses = outcomes.where((o) => o.sessionBonus != null);
      expect(bonuses, hasLength(1), reason: 'one completed day, one +5');
    });
  });
}
