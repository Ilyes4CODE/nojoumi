import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nojoumi/data/local/database.dart';
import 'package:nojoumi/data/repositories/session_repository.dart';
import 'package:nojoumi/data/repositories/star_repository.dart';
import 'package:nojoumi_stars/nojoumi_stars.dart';
import 'package:nojoumi_time/nojoumi_time.dart';

import 'support/test_db.dart';

/// Article 4's daily cycle, end to end, with no phone and no AI.
///
/// This is the closest a machine with no device can get to acceptance criterion
/// 11.4 — "a full cycle with no manual intervention". What it cannot prove is
/// the half that lives on hardware: the camera, the blocking, and whether a
/// child can actually work the screens.
void main() {
  late NojoumiDatabase db;
  late StarRepository stars;
  late SessionRepository sessions;

  final rules = StarRules();
  final today = DayKey(20500);

  const trusted = TrustedInstant(
    epochMs: 1772000000000,
    level: TrustLevel.serverAnchored,
  );

  /// A lesson with [cardCount] cards and [questionCount] questions, as the AI
  /// proxy would have produced it.
  Future<int> seedLesson({int cardCount = 3, int questionCount = 2}) async {
    final lessonId = await db.into(db.lessons).insert(
          LessonsCompanion.insert(
            summary: 'ملخّص الدرس',
            createdAtMs: trusted.epochMs,
            weekKey: 1,
          ),
        );
    for (var i = 0; i < cardCount; i++) {
      await db.into(db.cards).insert(
            CardsCompanion.insert(
              lessonId: lessonId,
              front: 'وجه $i',
              back: 'ظهر $i',
            ),
          );
    }
    for (var i = 0; i < questionCount; i++) {
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              lessonId: lessonId,
              prompt: 'سؤال $i',
              choicesJson: jsonEncode(['أ', 'ب', 'ج']),
              correctIndex: 1,
            ),
          );
    }
    return lessonId;
  }

  /// Answer every task correctly, with enough time on each to satisfy Art. 6.3.
  Future<List<AnswerOutcome>> answerWholeSession() async {
    final outcomes = <AnswerOutcome>[];
    var session = await sessions.sessionFor(day: today, rules: rules);
    while (session.next != null) {
      outcomes.add(
        await sessions.submitAnswer(
          day: today,
          rules: rules,
          now: trusted,
          task: session.next!,
          correct: true,
          attemptNumber: 1,
          msOnTarget: 4000,
        ),
      );
      session = await sessions.sessionFor(day: today, rules: rules);
    }
    return outcomes;
  }

  setUp(() async {
    db = await freshDatabase();
    stars = StarRepository(db);
    sessions = SessionRepository(db, stars);
  });

  tearDown(() async => db.close());

  group('building the day', () {
    test('an empty library produces an empty session', () async {
      final session = await sessions.sessionFor(day: today, rules: rules);
      expect(session.total, 0);
      expect(session.isComplete, isFalse,
          reason: 'a day with no tasks is not a completed day — otherwise the '
              'session bonus would be free');
    });

    test('cards come before questions (Art. 4.3)', () async {
      await seedLesson(cardCount: 3, questionCount: 2);
      final session = await sessions.sessionFor(day: today, rules: rules);

      expect(session.total, 5);
      expect(session.tasks.take(3), everyElement(isA<CardTask>()));
      expect(session.tasks.skip(3), everyElement(isA<QuestionTask>()));
    });

    test('the session is built once and then read back unchanged', () async {
      await seedLesson(cardCount: 4);
      final first = await sessions.sessionFor(day: today, rules: rules);
      final second = await sessions.sessionFor(day: today, rules: rules);

      expect(
        second.tasks.map((t) => t.taskId),
        first.tasks.map((t) => t.taskId),
        reason: 'reopening the app mid-session must not reshuffle the day or '
            'move the target Art. 6.5 measures completion against',
      );
    });

    test('the session never exceeds the parent session size (appendix §5)',
        () async {
      await seedLesson(cardCount: 40, questionCount: 0);
      final small = StarRules(dailySessionCards: 5, dailyQuestionCount: 0);
      final session = await sessions.sessionFor(day: today, rules: small);

      expect(session.total, 5,
          reason: 'a capped session is what keeps the +5 bonus reachable on a '
              'day when the backlog is enormous');
    });

    test('review questions still appear on a day with no cards due', () async {
      // The first version of this repository drew questions only from the
      // lessons today's cards came from, so a day where every card was
      // scheduled ahead presented no questions at all — quietly shortening the
      // session and removing 2-star earnings that Article 5 grants independently
      // of any card.
      await seedLesson(cardCount: 1, questionCount: 2);
      await db.customStatement(
        'UPDATE cards SET repetitions = 3, due_day = ?, last_reviewed_day = ?',
        [today.daysSinceEpoch + 30, today.daysSinceEpoch - 1],
      );

      final session = await sessions.sessionFor(day: today, rules: rules);
      expect(session.tasks.whereType<CardTask>(), isEmpty);
      expect(session.tasks.whereType<QuestionTask>(), hasLength(2));
    });

    test('purged questions are never presented (Art. 14)', () async {
      await seedLesson(cardCount: 1, questionCount: 2);
      await db.customStatement('UPDATE questions SET purged_at_ms = 1');

      final session = await sessions.sessionFor(day: today, rules: rules);
      expect(session.tasks.whereType<QuestionTask>(), isEmpty,
          reason: 'a purged row is a tombstone, not content');
    });

    test('the question count follows its own setting (D-15)', () async {
      await seedLesson(cardCount: 2, questionCount: 6);
      final custom = StarRules(dailySessionCards: 5, dailyQuestionCount: 3);
      final session = await sessions.sessionFor(day: today, rules: custom);

      expect(session.tasks.whereType<QuestionTask>().length, 3);
    });
  });

  group('Article 5 — what one answer is worth', () {
    test('a card seen for the first time pays 1 star, a later review 0.5',
        () async {
      await seedLesson(cardCount: 1, questionCount: 0);

      final first = await sessions.sessionFor(day: today, rules: rules);
      final card = first.tasks.single as CardTask;
      expect(card.isFirstEncounter, isTrue);

      final outcome = await sessions.submitAnswer(
        day: today,
        rules: rules,
        now: trusted,
        task: card,
        correct: true,
        attemptNumber: 1,
        msOnTarget: 4000,
      );
      expect(outcome.decision.awardedUnits, Article5.memorizeCardFirstTime);

      // The same card on a later day is a review, and pays half.
      final tomorrow = DayKey(today.daysSinceEpoch + 1);
      final second = await sessions.sessionFor(day: tomorrow, rules: rules);
      final again = second.tasks.single as CardTask;
      expect(again.isFirstEncounter, isFalse,
          reason: 'the distinction comes from the card history, not from which '
              'session it appears in');

      final secondOutcome = await sessions.submitAnswer(
        day: tomorrow,
        rules: rules,
        now: trusted,
        task: again,
        correct: true,
        attemptNumber: 1,
        msOnTarget: 4000,
      );
      expect(secondOutcome.decision.awardedUnits, Article5.cardInLaterReview);
    });

    test('a review question pays 2 stars', () async {
      await seedLesson(cardCount: 0, questionCount: 1);
      final session = await sessions.sessionFor(day: today, rules: rules);
      final question = session.tasks.single as QuestionTask;

      final outcome = await sessions.submitAnswer(
        day: today,
        rules: rules,
        now: trusted,
        task: question,
        correct: true,
        attemptNumber: 1,
        msOnTarget: 4000,
      );
      expect(outcome.decision.awardedUnits, Article5.reviewQuestion);
    });
  });

  group('Article 6.5 / D-5 — completing the session', () {
    test('the +5 bonus fires on the last answer, not before', () async {
      await seedLesson(cardCount: 2, questionCount: 1);
      final outcomes = await answerWholeSession();

      expect(outcomes, hasLength(3));
      expect(outcomes.take(2).every((o) => o.sessionComplete), isFalse);
      expect(outcomes.last.sessionComplete, isTrue);
      expect(
        outcomes.last.sessionBonus?.awardedUnits,
        Article5.fullSessionBonus,
      );
    });

    test('a wrong answer still completes the session (D-5)', () async {
      await seedLesson(cardCount: 2, questionCount: 0);

      var session = await sessions.sessionFor(day: today, rules: rules);
      await sessions.submitAnswer(
        day: today,
        rules: rules,
        now: trusted,
        task: session.next!,
        correct: false,
        attemptNumber: 1,
        msOnTarget: 4000,
      );
      session = await sessions.sessionFor(day: today, rules: rules);
      final last = await sessions.submitAnswer(
        day: today,
        rules: rules,
        now: trusted,
        task: session.next!,
        correct: true,
        attemptNumber: 1,
        msOnTarget: 4000,
      );

      expect(last.sessionBonus?.awardedUnits, Article5.fullSessionBonus,
          reason: 'the appendix worked example grants the bonus to a child who '
              'got 10 of 12 — completing means answered, not correct');
      // 1 star for the correct card, 0 for the wrong one, +5 for the session.
      expect(await stars.derivedBalanceUnits(today), 6 * starUnit);
    });

    test('the attendance bonus follows a completed second day (Art. 6.6)',
        () async {
      await seedLesson(cardCount: 1, questionCount: 0);

      // Yesterday counts as an active day.
      await stars.markDayActive(DayKey(today.daysSinceEpoch - 1));
      final outcomes = await answerWholeSession();

      expect(outcomes.last.streakBonus?.awardedUnits, Article5.streakBonus);
      expect((await stars.streak()).consecutiveDays, 2);
    });

    test('a first-ever day earns no attendance bonus', () async {
      await seedLesson(cardCount: 1, questionCount: 0);
      final outcomes = await answerWholeSession();

      expect(outcomes.last.streakBonus?.granted, isFalse);
      expect(outcomes.last.streakBonus?.rejection, Rejection.streakTooShort);
    });
  });

  group('Article 2 / D-22 — the card is rescheduled from what we observed', () {
    test('a correct fast first answer schedules the card forward', () async {
      await seedLesson(cardCount: 1, questionCount: 0);
      final session = await sessions.sessionFor(day: today, rules: rules);

      await sessions.submitAnswer(
        day: today,
        rules: rules,
        now: trusted,
        task: session.next!,
        correct: true,
        attemptNumber: 1,
        msOnTarget: 2000,
      );

      final card = await db.select(db.cards).getSingle();
      expect(card.repetitions, 1);
      expect(card.dueDay, today.daysSinceEpoch + 1);
      expect(card.easePermille, greaterThan(2500),
          reason: 'a fast first-attempt recall is SM-2 quality 5');
      expect(card.lapses, 0);
    });

    test('a wrong answer counts a lapse and brings the card back tomorrow',
        () async {
      await seedLesson(cardCount: 1, questionCount: 0);
      final session = await sessions.sessionFor(day: today, rules: rules);

      await sessions.submitAnswer(
        day: today,
        rules: rules,
        now: trusted,
        task: session.next!,
        correct: false,
        attemptNumber: 1,
        msOnTarget: 4000,
      );

      final card = await db.select(db.cards).getSingle();
      expect(card.lapses, 1);
      expect(card.repetitions, 0);
      expect(card.dueDay, today.daysSinceEpoch + 1,
          reason: 'the appendix promises the card comes back in a later review');
      expect(card.firstCorrectAtMs, isNull);
    });

    test('revealing the solution earns nothing and cannot count as a recall',
        () async {
      await seedLesson(cardCount: 1, questionCount: 0);
      final session = await sessions.sessionFor(day: today, rules: rules);

      final outcome = await sessions.submitAnswer(
        day: today,
        rules: rules,
        now: trusted,
        task: session.next!,
        correct: true,
        attemptNumber: 1,
        msOnTarget: 4000,
        solutionRevealed: true,
      );

      expect(outcome.decision.rejection, Rejection.solutionRevealed);
      final card = await db.select(db.cards).getSingle();
      expect(card.repetitions, 0,
          reason: 'Art. 6.1 says a revealed answer earns nothing, and the '
              'scheduler must agree with the ledger');
      expect(card.lapses, 1);
    });
  });

  group('Article 6.8 — an untrusted clock', () {
    test('lets the session proceed but grants nothing at all', () async {
      await seedLesson(cardCount: 1, questionCount: 0);
      const untrusted = TrustedInstant(
        epochMs: 1772000000000,
        level: TrustLevel.untrusted,
      );

      final session = await sessions.sessionFor(day: today, rules: rules);
      final outcome = await sessions.submitAnswer(
        day: today,
        rules: rules,
        now: untrusted,
        task: session.next!,
        correct: true,
        attemptNumber: 1,
        msOnTarget: 4000,
      );

      expect(outcome.decision.rejection, Rejection.untrustedClock);
      expect(outcome.sessionComplete, isTrue,
          reason: 'the child is not locked out of studying — only out of '
              'earning');
      expect(outcome.sessionBonus?.rejection, Rejection.untrustedClock);
      expect(await stars.derivedBalanceUnits(today), 0);
    });
  });
}
