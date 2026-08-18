import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nojoumi_sm2/nojoumi_sm2.dart';
import 'package:nojoumi_stars/nojoumi_stars.dart';
import 'package:nojoumi_time/nojoumi_time.dart';

import '../local/database.dart';
import '../local/tables.dart';
import 'star_repository.dart';

/// One thing to answer, ready for the screen.
///
/// Cards and questions differ in every way that matters to the widget and in
/// almost none that matter to Article 6, so they are one sealed type: the
/// session screen switches on it once, and the star engine never sees the
/// difference at all.
sealed class SessionTask {
  const SessionTask({required this.taskId, required this.targetId});

  /// Row id in `task_instances` — the day's presentation, not the content.
  final int taskId;

  /// Row id of the card or question. This is what Article 6.2 dedupes on.
  final int targetId;
}

class CardTask extends SessionTask {
  const CardTask({
    required super.taskId,
    required super.targetId,
    required this.front,
    required this.back,
    required this.isFirstEncounter,
  });

  final String front;
  final String back;

  /// Article 5 pays 1 star for a card answered correctly **the first time** and
  /// 0.5 for one in a later review. This is that distinction, decided from the
  /// card's own history rather than from the session it appears in.
  final bool isFirstEncounter;

  EarnKind get earnKind => isFirstEncounter
      ? EarnKind.memorizeCardFirstTime
      : EarnKind.cardInLaterReview;
}

class QuestionTask extends SessionTask {
  const QuestionTask({
    required super.taskId,
    required super.targetId,
    required this.prompt,
    required this.choices,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> choices;
  final int correctIndex;

  EarnKind get earnKind => EarnKind.reviewQuestion;
}

/// Today's session as the screen consumes it.
class DailySession {
  const DailySession({
    required this.day,
    required this.tasks,
    required this.answeredTaskIds,
    required this.backlogCount,
  });

  final DayKey day;
  final List<SessionTask> tasks;
  final Set<int> answeredTaskIds;

  /// Due cards that did not fit today. Shown to the parent, never to the child:
  /// a child cannot act on a backlog, and telling them about one only makes the
  /// session feel unfinishable.
  final int backlogCount;

  int get total => tasks.length;
  int get answered => answeredTaskIds.length;
  bool get isComplete => tasks.isNotEmpty && answered >= total;

  SessionTask? get next {
    for (final task in tasks) {
      if (!answeredTaskIds.contains(task.taskId)) return task;
    }
    return null;
  }
}

/// What happened when an answer was submitted.
class AnswerOutcome {
  const AnswerOutcome({
    required this.decision,
    required this.sessionComplete,
    this.sessionBonus,
    this.streakBonus,
  });

  final StarDecision decision;

  /// True when this answer finished the day's tasks.
  final bool sessionComplete;

  /// Set only on the answer that completed the session.
  final StarDecision? sessionBonus;
  final StarDecision? streakBonus;

  int get totalAwardedUnits =>
      decision.awardedUnits +
      (sessionBonus?.awardedUnits ?? 0) +
      (streakBonus?.awardedUnits ?? 0);
}

/// Builds the day's session and records its answers.
///
/// This is the seam where Article 4's daily cycle, Article 5's award table and
/// SM-2's scheduling meet. Each of the three is owned elsewhere and none of the
/// rules are re-implemented here: [SessionBuilder] chooses the cards,
/// [StarRepository] applies Article 6, and [Sm2Scheduler] moves the card on.
/// What this class owns is the *order*, and one contractual consequence of it —
/// that finishing the last task is what triggers the session and attendance
/// bonuses, in that order, inside the same call.
class SessionRepository {
  SessionRepository(
    this._db,
    this._stars, {
    SessionBuilder builder = const SessionBuilder(),
    Sm2Scheduler scheduler = const Sm2Scheduler(),
  })  : _builder = builder,
        _scheduler = scheduler;

  final NojoumiDatabase _db;
  final StarRepository _stars;
  final SessionBuilder _builder;
  final Sm2Scheduler _scheduler;

  /// Load today's session, building it on first call of the day.
  ///
  /// Idempotent: the task list for a day is written once and then read back, so
  /// closing and reopening the app mid-session does not reshuffle the cards or
  /// reset the count Article 6.5 measures completion against.
  Future<DailySession> sessionFor({
    required DayKey day,
    required StarRules rules,
  }) async {
    final existing = await _tasksFor(day);
    if (existing.isEmpty) {
      await _buildSession(day: day, rules: rules);
      return _readSession(day);
    }
    return _readSession(day);
  }

  /// Submit one answer.
  ///
  /// Everything that follows from an answer happens here and in this order,
  /// because each step depends on the one before it:
  ///  1. Article 6 decides whether a star is earned, and records the attempt;
  ///  2. the task is marked answered, which is what Article 6.5 counts;
  ///  3. SM-2 reschedules the card, using a grade derived from the same
  ///     observation — never from a self-rating a child cannot give (D-22);
  ///  4. if that was the last task, the session and attendance bonuses fire.
  Future<AnswerOutcome> submitAnswer({
    required DayKey day,
    required StarRules rules,
    required TrustedInstant now,
    required SessionTask task,
    required bool correct,
    required int attemptNumber,
    required int msOnTarget,
    bool solutionRevealed = false,
  }) async {
    final earnKind = switch (task) {
      CardTask() => task.earnKind,
      QuestionTask() => task.earnKind,
    };

    final recorded = await _stars.recordAttempt(
      rules: rules,
      attempt: Attempt(
        targetId: StarRepository.targetKeyFor(earnKind, task.targetId),
        kind: earnKind,
        attemptNumber: attemptNumber,
        correct: correct,
        msOnTarget: msOnTarget,
        solutionRevealed: solutionRevealed,
      ),
      now: now,
      day: day,
    );

    await _markAnswered(task.taskId, now);

    if (task is CardTask) {
      await _reschedule(
        cardId: task.targetId,
        day: day,
        correct: correct,
        attemptNumber: attemptNumber,
        msOnTarget: msOnTarget,
        solutionRevealed: solutionRevealed,
        firstCorrectAtMs: correct && task.isFirstEncounter ? now.epochMs : null,
      );
    }

    final session = await _readSession(day);
    await _stars.setTaskCounts(
      day: day,
      total: session.total,
      answered: session.answered,
    );

    if (!session.isComplete) {
      return AnswerOutcome(decision: recorded.decision, sessionComplete: false);
    }

    // The order matters: the attendance run must include today before the
    // streak bonus is evaluated, and "an active day" means a completed session
    // (D-19, consistent with D-5).
    final sessionBonus = await _stars.awardSessionBonus(now: now, day: day);
    await _stars.markDayActive(day);
    final streakBonus = await _stars.awardStreakBonus(now: now, day: day);

    return AnswerOutcome(
      decision: recorded.decision,
      sessionComplete: true,
      sessionBonus: sessionBonus,
      streakBonus: streakBonus,
    );
  }

  // ------------------------------------------------------------- internals

  Future<void> _buildSession({
    required DayKey day,
    required StarRules rules,
  }) async {
    final cardRows = await _db.select(_db.cards).get();
    final selection = _builder.build(
      allCards: cardRows.map(_scheduleOf).toList(),
      today: day,
      sessionSize: rules.dailySessionCards,
    );

    final questionRows = await _pickQuestions(
      selection: selection,
      cardRows: cardRows,
      limit: rules.dailyQuestionCount,
    );

    await _db.transaction(() async {
      var position = 0;
      for (final card in selection.cards) {
        await _db.into(_db.taskInstances).insert(
              TaskInstancesCompanion.insert(
                dayKey: day.daysSinceEpoch,
                kind: TaskKind.memorize,
                targetId: int.parse(card.cardId),
                position: position++,
              ),
            );
      }
      for (final question in questionRows) {
        await _db.into(_db.taskInstances).insert(
              TaskInstancesCompanion.insert(
                dayKey: day.daysSinceEpoch,
                kind: TaskKind.review,
                targetId: question.id,
                position: position++,
              ),
            );
      }
    });

    await _stars.setTaskCounts(
      day: day,
      total: selection.cards.length + questionRows.length,
      answered: 0,
    );
  }

  /// Choose today's review questions.
  ///
  /// Article 4.3 orders the day memorize → review, so the review should follow
  /// the material just seen: questions from the lessons today's cards came from
  /// are taken first.
  ///
  /// But they cannot be the *only* source. A day where every card is scheduled
  /// far ahead would otherwise present no questions at all, and Article 5 pays
  /// for a correct review question (2 stars) independently of any card — so an
  /// empty review would quietly cut the day's earning ceiling and, worse, make
  /// the session shorter than the parent configured. The remainder is therefore
  /// filled from the newest unpurged lessons.
  ///
  /// Purged questions are excluded everywhere: Article 14 deletes the exercises
  /// after the weekly test, and a purged row is a tombstone, not content.
  Future<List<QuestionRow>> _pickQuestions({
    required DailySelection selection,
    required List<CardRow> cardRows,
    required int limit,
  }) async {
    if (limit <= 0) return const [];

    final selectedIds = selection.cards.map((c) => c.cardId).toSet();
    final preferredLessons = <int>{
      for (final card in cardRows)
        if (selectedIds.contains('${card.id}')) card.lessonId,
    };

    final picked = <QuestionRow>[];
    if (preferredLessons.isNotEmpty) {
      picked.addAll(
        await (_db.select(_db.questions)
              ..where((t) => t.lessonId.isIn(preferredLessons))
              ..where((t) => t.purgedAtMs.isNull())
              ..limit(limit))
            .get(),
      );
    }
    if (picked.length >= limit) return picked;

    final taken = picked.map((q) => q.id).toSet();
    final filler = await (_db.select(_db.questions)
          ..where((t) => t.purgedAtMs.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.lessonId)])
          ..limit(limit))
        .get();
    for (final question in filler) {
      if (picked.length >= limit) break;
      if (taken.add(question.id)) picked.add(question);
    }
    return picked;
  }

  Future<List<TaskInstanceRow>> _tasksFor(DayKey day) {
    return (_db.select(_db.taskInstances)
          ..where((t) => t.dayKey.equals(day.daysSinceEpoch))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
  }

  Future<DailySession> _readSession(DayKey day) async {
    final rows = await _tasksFor(day);
    final tasks = <SessionTask>[];
    final answered = <int>{};

    for (final row in rows) {
      if (row.state != TaskState.pending) answered.add(row.id);

      switch (row.kind) {
        case TaskKind.memorize:
          final card = await (_db.select(_db.cards)
                ..where((t) => t.id.equals(row.targetId)))
              .getSingleOrNull();
          if (card == null) continue;
          tasks.add(
            CardTask(
              taskId: row.id,
              targetId: card.id,
              front: card.front,
              back: card.back,
              isFirstEncounter: card.firstCorrectAtMs == null,
            ),
          );
        case TaskKind.review:
        case TaskKind.exercise:
          final question = await (_db.select(_db.questions)
                ..where((t) => t.id.equals(row.targetId)))
              .getSingleOrNull();
          if (question == null) continue;
          tasks.add(
            QuestionTask(
              taskId: row.id,
              targetId: question.id,
              prompt: question.prompt,
              choices: (jsonDecode(question.choicesJson) as List<dynamic>)
                  .map((e) => '$e')
                  .toList(),
              correctIndex: question.correctIndex,
            ),
          );
      }
    }

    return DailySession(
      day: day,
      tasks: tasks,
      answeredTaskIds: answered,
      backlogCount: 0,
    );
  }

  Future<void> _markAnswered(int taskId, TrustedInstant now) async {
    await (_db.update(_db.taskInstances)..where((t) => t.id.equals(taskId)))
        .write(
      TaskInstancesCompanion(
        state: const Value(TaskState.answered),
        answeredAtMs: Value(now.epochMs),
      ),
    );
  }

  Future<void> _reschedule({
    required int cardId,
    required DayKey day,
    required bool correct,
    required int attemptNumber,
    required int msOnTarget,
    required bool solutionRevealed,
    int? firstCorrectAtMs,
  }) async {
    final row = await (_db.select(_db.cards)..where((t) => t.id.equals(cardId)))
        .getSingleOrNull();
    if (row == null) return;

    final grade = Sm2Grade.fromObservation(
      correct: correct,
      attemptNumber: attemptNumber,
      solutionRevealed: solutionRevealed,
      msOnTarget: msOnTarget,
    );
    final next = _scheduler.review(
      card: _scheduleOf(row),
      grade: grade,
      today: day,
    );

    await (_db.update(_db.cards)..where((t) => t.id.equals(cardId))).write(
      CardsCompanion(
        repetitions: Value(next.repetitions),
        intervalDays: Value(next.intervalDays),
        easePermille: Value(next.easePermille),
        lapses: Value(next.lapses),
        dueDay: Value(next.dueDay?.daysSinceEpoch),
        lastReviewedDay: Value(next.lastReviewedDay?.daysSinceEpoch),
        firstCorrectAtMs: row.firstCorrectAtMs == null && firstCorrectAtMs != null
            ? Value(firstCorrectAtMs)
            : const Value.absent(),
      ),
    );
  }

  static CardSchedule _scheduleOf(CardRow row) => CardSchedule(
        cardId: '${row.id}',
        repetitions: row.repetitions,
        intervalDays: row.intervalDays,
        easePermille: row.easePermille,
        lapses: row.lapses,
        dueDay: row.dueDay == null ? null : DayKey(row.dueDay!),
        lastReviewedDay:
            row.lastReviewedDay == null ? null : DayKey(row.lastReviewedDay!),
      );
}
