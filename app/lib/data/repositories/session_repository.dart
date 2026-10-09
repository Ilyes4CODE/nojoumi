import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:lunio_sm2/lunio_sm2.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

import '../../domain/answer_order.dart';
import '../../domain/card_choices.dart';
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
  const SessionTask({
    required this.taskId,
    required this.targetId,
    required this.lessonId,
  });

  /// Row id in `task_instances` — the day's presentation, not the content.
  final int taskId;

  /// Row id of the card or question. This is what Article 6.2 dedupes on.
  final int targetId;

  /// The lesson this came from.
  ///
  /// Carried on the task so the screen can tell when the day moves from one
  /// lesson to the next and show its summary first. `_buildSession` already
  /// orders the day lesson by lesson; this is what makes that ordering visible
  /// to the child instead of merely tidy in the database.
  final int lessonId;
}

class CardTask extends SessionTask {
  const CardTask({
    required super.taskId,
    required super.targetId,
    required super.lessonId,
    required this.front,
    required this.back,
    required this.isFirstEncounter,
    this.options = CardChoiceSet.none,
  });

  final String front;
  final String back;

  /// The answer options, when the device holds enough material to build them.
  ///
  /// Defaults to [CardChoiceSet.none] so a caller that does not care — the
  /// widget tests, mainly — still gets a valid card. When it is not usable the
  /// screen falls back to the recall card, which is the only honest thing to
  /// show: see [CardChoiceSet.isUsable].
  final CardChoiceSet options;

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
    required super.lessonId,
    required this.prompt,
    required this.choices,
    required this.correctIndex,
    this.attempt = 1,
  });

  final String prompt;
  final List<String> choices;
  final int correctIndex;

  /// Which time round this is, counting from 1.
  ///
  /// A question the child missed comes back at the end of the section, and from
  /// the child's side that is just another question — reported on 2026-08-31 as
  /// the missed question never coming back at all, when it had. So the screen
  /// says so. **It is not a scold**: it is the difference between a section
  /// that grew for a reason and one that appears to have miscounted.
  ///
  /// It is also the honest place to explain a star that did not arrive. Article
  /// 6.1 pays only for a first attempt, so this one earns nothing however well
  /// it is answered, and a child owed no explanation for that will conclude the
  /// stars are arbitrary.
  final int attempt;

  bool get isRepeat => attempt > 1;

  EarnKind get earnKind => EarnKind.reviewQuestion;
}

/// The two halves of a lesson, as the child picks between them.
///
/// Article 4.3 orders the day memorize → review, which is why these are ordered
/// and why [SessionSection.review] is held shut until the cards are done rather
/// than merely listed second.
enum SessionSection { memorize, review }

/// One lesson's share of today, ready for the picker and the two section cards.
class LessonSlice {
  const LessonSlice({
    required this.lessonId,
    required this.brief,
    required this.cards,
    required this.questions,
    required this.answeredTaskIds,
  });

  final int lessonId;
  final LessonBrief brief;
  final List<CardTask> cards;
  final List<QuestionTask> questions;
  final Set<int> answeredTaskIds;

  int get total => cards.length + questions.length;
  int get answered => answeredTaskIds.length;
  bool get isComplete => total > 0 && answered >= total;

  int get cardsAnswered =>
      cards.where((c) => answeredTaskIds.contains(c.taskId)).length;
  int get questionsAnswered =>
      questions.where((q) => answeredTaskIds.contains(q.taskId)).length;

  bool get cardsDone => cardsAnswered >= cards.length;

  /// Article 4.3 — the review follows the material just memorised.
  ///
  /// A child who can answer the questions first is being examined on a page
  /// they have not studied, which is the wrong way round and also feeds SM-2 a
  /// grade that means nothing. A lesson with no cards at all opens its
  /// questions immediately; there is nothing to do first.
  bool get questionsUnlocked => cardsDone;

  List<SessionTask> tasksIn(SessionSection section) => switch (section) {
    SessionSection.memorize => cards,
    SessionSection.review => questions,
  };

  SessionTask? nextIn(SessionSection section) {
    for (final task in tasksIn(section)) {
      if (!answeredTaskIds.contains(task.taskId)) return task;
    }
    return null;
  }
}

/// A lesson's title and summary, for the page shown before its cards.
///
/// Only these two fields, deliberately. The intro exists to put the material
/// back in front of the child before they are asked about it; anything else on
/// that page is something to look at instead of reading.
class LessonBrief {
  const LessonBrief({required this.title, required this.summary});

  final String title;
  final String summary;
}

/// Today's session as the screen consumes it.
class DailySession {
  const DailySession({
    required this.day,
    required this.tasks,
    required this.answeredTaskIds,
    required this.backlogCount,
    this.lessons = const {},
  });

  final DayKey day;
  final List<SessionTask> tasks;
  final Set<int> answeredTaskIds;

  /// Due cards that did not fit today. Shown to the parent, never to the child:
  /// a child cannot act on a backlog, and telling them about one only makes the
  /// session feel unfinishable.
  final int backlogCount;

  /// The lessons today's tasks came from, by id.
  ///
  /// Empty is a legitimate state and the screen must treat it as one: a lesson
  /// with no summary gets no intro page rather than a blank one.
  final Map<int, LessonBrief> lessons;

  int get total => tasks.length;
  int get answered => answeredTaskIds.length;
  bool get isComplete => tasks.isNotEmpty && answered >= total;

  SessionTask? get next {
    for (final task in tasks) {
      if (!answeredTaskIds.contains(task.taskId)) return task;
    }
    return null;
  }

  /// Today's work grouped by lesson, in the order the day presents it.
  ///
  /// **A view, never a division of the data.** Article 6.5 pays the +5 bonus
  /// for finishing *the day's* tasks, so completion is still counted across
  /// every lesson at once — the child choosing which lesson to open changes the
  /// route through the day, not the day.
  List<LessonSlice> get lessonSlices {
    final order = <int>[];
    final cards = <int, List<CardTask>>{};
    final questions = <int, List<QuestionTask>>{};

    for (final task in tasks) {
      if (!order.contains(task.lessonId)) order.add(task.lessonId);
      switch (task) {
        case CardTask():
          (cards[task.lessonId] ??= []).add(task);
        case QuestionTask():
          (questions[task.lessonId] ??= []).add(task);
      }
    }

    return [
      for (final lessonId in order)
        LessonSlice(
          lessonId: lessonId,
          brief:
              lessons[lessonId] ??
              const LessonBrief(title: '', summary: ''),
          cards: cards[lessonId] ?? const [],
          questions: questions[lessonId] ?? const [],
          answeredTaskIds: {
            for (final task in [
              ...?cards[lessonId],
              ...?questions[lessonId],
            ])
              if (answeredTaskIds.contains(task.taskId)) task.taskId,
          },
        ),
    ];
  }

  LessonSlice? sliceOf(int lessonId) {
    for (final slice in lessonSlices) {
      if (slice.lessonId == lessonId) return slice;
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
/// How many times one question may be asked in a day, counting the first.
///
/// Three, not "until correct". A child who has missed the same question twice
/// is not helped by a third identical screen, and an unbounded retry makes the
/// day unfinishable — which would deny Article 6.5's +5 to the child who needed
/// it most.
const int maxQuestionAttempts = 3;

class SessionRepository {
  SessionRepository(
    this._db,
    this._stars, {
    SessionBuilder builder = const SessionBuilder(),
    Sm2Scheduler scheduler = const Sm2Scheduler(),
  }) : _builder = builder,
       _scheduler = scheduler;

  final LunioDatabase _db;
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
    if ((await _tasksFor(day)).isEmpty) {
      await _buildSession(day: day, rules: rules);
    }
    await _absorbUnseenLessons(day: day, rules: rules);

    final session = await _readSession(day);

    // The counts on the day row are what the child's home screen reads and what
    // Article 6.5 measures completion against, and they are written by whoever
    // last changed the list. Anything that changes it behind their back — a
    // migration removing cards, a purge, a row deleted by hand — would leave
    // the home screen advertising tasks that no longer exist. Re-derived here,
    // and written only when they actually disagree, so the ordinary read stays
    // a read.
    final progress = await _stars.dayProgress(day);
    if (progress.tasksTotal != session.total ||
        progress.tasksAnswered != session.answered) {
      await _stars.setTaskCounts(
        day: day,
        total: session.total,
        answered: session.answered,
      );
    }
    return session;
  }

  /// Pull in any lesson the day never got to see.
  ///
  /// ### The hole this closes
  ///
  /// `absorbLesson` puts a lesson into today **at the moment it is captured**.
  /// That leaves a lesson captured at any other moment — before the app knew how
  /// to do this, while the day had not been built, or through any path that did
  /// not reach the capture screen — with no way back in **ever**, because
  /// `sessionFor` is idempotent and the builder only ever looks at cards, never
  /// at lessons.
  ///
  /// Measured on the device on 2026-08-30: two lessons of twelve cards each, and
  /// not one card of the second had been presented on any day. The parent could
  /// see the lesson in their own list; the child had no route to it and never
  /// would have.
  ///
  /// **Orphaned means never presented, not merely absent today.** A lesson whose
  /// cards are in the day partly, or whose cards SM-2 has scheduled for next
  /// week, is being paced — that is the scheduler working, and dragging it back
  /// in every morning would undo spaced repetition entirely. The condition is
  /// the narrow one: *not one* of this lesson's cards or questions appears in
  /// any day's task list.
  ///
  /// Runs on every read of the day, which is what makes it self-healing: the
  /// lesson stranded before this code existed is picked up the next time the
  /// child opens their work, with no migration and nothing for the parent to do.
  Future<int> _absorbUnseenLessons({
    required DayKey day,
    required StarRules rules,
  }) async {
    final presentedCards = <int>{};
    final presentedQuestions = <int>{};
    for (final row in await _db.select(_db.taskInstances).get()) {
      if (row.kind == TaskKind.memorize) {
        presentedCards.add(row.targetId);
      } else {
        presentedQuestions.add(row.targetId);
      }
    }

    final seen = <int>{};
    for (final card in await _db.select(_db.cards).get()) {
      if (presentedCards.contains(card.id)) seen.add(card.lessonId);
    }
    for (final question in await _db.select(_db.questions).get()) {
      if (presentedQuestions.contains(question.id)) seen.add(question.lessonId);
    }

    var added = 0;
    for (final lesson in await _db.select(_db.lessons).get()) {
      if (seen.contains(lesson.id)) continue;
      added += await _appendLesson(day: day, rules: rules, lessonId: lesson.id);
    }
    if (added > 0) await _syncCounts(day);
    return added;
  }

  /// Put a lesson captured today into today's session, now.
  ///
  /// ### Why this replaced `rebuildIfUntouched`
  ///
  /// It used to rebuild the day, and only **while nothing had been answered**.
  /// The reasoning was sound and the result was wrong: a parent who
  /// photographed a page after the child had started got nothing, with no
  /// message and no way to tell. Reported on 2026-08-30 as a lesson that simply
  /// never appeared — which from the outside is indistinguishable from the
  /// capture having failed.
  ///
  /// The fear was Article 6.5: the +5 bonus is paid for finishing *the day's*
  /// tasks, and a list that grows underneath a child turns a finished session
  /// back into an unfinished one, or pays the bonus twice. Both are handled
  /// without refusing the parent:
  ///
  ///  * **appending, not rebuilding.** Nothing already in the day moves, no
  ///    answered task is touched, and no card is reshuffled — so the count
  ///    Article 6.5 measures against only ever grows at the end.
  ///  * **the bonus is already once-per-day.** `DayProgress.sessionBonusAwarded`
  ///    is what stops a second payment, not the size of the list, and it is
  ///    asserted in a test rather than assumed here.
  ///
  /// A day that was never built today is simply built, which picks the new
  /// lesson up on the ordinary path.
  ///
  /// Returns **how many tasks this lesson has in today's list afterwards** —
  /// not how many rows were inserted. The two differ in the ordinary case of a
  /// day that had not been built yet: the build itself picks the new lesson up,
  /// nothing is appended, and a caller reading an insert count would conclude
  /// the lesson had not made it and skip refreshing the screen.
  Future<int> absorbLesson({
    required DayKey day,
    required StarRules rules,
    required int lessonId,
  }) async {
    if ((await _tasksFor(day)).isEmpty) {
      await _buildSession(day: day, rules: rules);
    }
    final appended = await _appendLesson(
      day: day,
      rules: rules,
      lessonId: lessonId,
    );
    if (appended > 0) await _syncCounts(day);

    final slice = (await _readSession(day)).sliceOf(lessonId);
    return slice?.total ?? 0;
  }

  /// Append one lesson's tasks to the end of the day. Returns how many.
  ///
  /// Shared by [absorbLesson] and [_absorbUnseenLessons] so there is exactly one
  /// piece of code that can lengthen a day, and one place where the dedupe and
  /// the cap live.
  Future<int> _appendLesson({
    required DayKey day,
    required StarRules rules,
    required int lessonId,
  }) async {
    // Deduped by target so capturing the same page twice, or absorbing a lesson
    // the builder had already chosen from, cannot put a card in the day twice —
    // Article 6.2 would refuse to pay for the second copy anyway, leaving the
    // child a task that can never earn.
    final seenCards = <int>{};
    final seenQuestions = <int>{};
    var position = 0;
    for (final row in await _tasksFor(day)) {
      if (row.position >= position) position = row.position + 1;
      if (row.kind == TaskKind.memorize) {
        seenCards.add(row.targetId);
      } else {
        seenQuestions.add(row.targetId);
      }
    }

    final cards =
        await (_db.select(_db.cards)
              ..where((t) => t.lessonId.equals(lessonId))
              // Capped by the parent's own session size rather than unbounded:
              // one very long lesson must not make the day unfinishable, which
              // would put Article 6.5's bonus out of reach.
              ..limit(rules.dailySessionCards))
            .get();
    final questions =
        await (_db.select(_db.questions)
              ..where((t) => t.lessonId.equals(lessonId))
              ..where((t) => t.purgedAtMs.isNull())
              ..limit(rules.dailyQuestionCount))
            .get();

    var added = 0;
    await _db.transaction(() async {
      for (final card in cards) {
        if (!seenCards.add(card.id)) continue;
        await _db
            .into(_db.taskInstances)
            .insert(
              TaskInstancesCompanion.insert(
                dayKey: day.daysSinceEpoch,
                kind: TaskKind.memorize,
                targetId: card.id,
                position: position++,
              ),
            );
        added++;
      }
      for (final question in questions) {
        if (!seenQuestions.add(question.id)) continue;
        await _db
            .into(_db.taskInstances)
            .insert(
              TaskInstancesCompanion.insert(
                dayKey: day.daysSinceEpoch,
                kind: TaskKind.review,
                targetId: question.id,
                position: position++,
              ),
            );
        added++;
      }
    });
    return added;
  }

  /// Re-derive the day's totals after its list changed.
  Future<void> _syncCounts(DayKey day) async {
    final session = await _readSession(day);
    await _stars.setTaskCounts(
      day: day,
      total: session.total,
      answered: session.answered,
    );
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

    // **Which attempt this really is, counted rather than claimed.**
    //
    // The screen builds a fresh widget for every task and has no idea the same
    // question was asked earlier today, so it always says "1". That was
    // harmless while nothing was ever re-asked. The moment a missed question
    // started coming back (2026-08-31) it became a hole big enough to drive the
    // whole star table through: answer wrongly, read the right answer off the
    // screen, answer again — and the engine, told this was a first attempt,
    // paid the full two stars.
    //
    // Article 6.2's dedupe does not close it, because that records targets that
    // were *awarded*, and a wrong answer awards nothing — so the second pass
    // looked untouched. Article 6.1 is the clause that refuses it, and it can
    // only do that if it is told the truth about the attempt number.
    //
    // The caller's value is kept as a floor rather than discarded: a caller
    // that knows it is on attempt three is not overruled by a count that has
    // not caught up.
    final counted = await _attemptNumberFor(day: day, task: task);
    final attempt = counted > attemptNumber ? counted : attemptNumber;

    final recorded = await _stars.recordAttempt(
      rules: rules,
      attempt: Attempt(
        targetId: StarRepository.targetKeyFor(earnKind, task.targetId),
        kind: earnKind,
        attemptNumber: attempt,
        correct: correct,
        msOnTarget: msOnTarget,
        solutionRevealed: solutionRevealed,
      ),
      now: now,
      day: day,
    );

    await _markAnswered(task.taskId, now);

    if (task is QuestionTask && !correct) {
      await _askAgain(day: day, task: task);
    }

    if (task is CardTask) {
      await _reschedule(
        cardId: task.targetId,
        day: day,
        correct: correct,
        attemptNumber: attempt,
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
      day: day,
      selection: selection,
      cardRows: cardRows,
      limit: rules.dailyQuestionCount,
    );

    // --- ordering: one lesson at a time -----------------------------------
    //
    // SM-2 chooses *which* cards are due, and it is right to choose them across
    // every lesson at once — forgetting does not respect chapter boundaries. But
    // it returns them sorted by how overdue they are, which interleaves lessons:
    // a card about الكسور, then one about فضل العلم, then الكسور again. A child
    // working through that is switching subject every fifteen seconds.
    //
    // So the *selection* stays exactly as the scheduler made it and only the
    // *order* changes: each lesson's cards together, its questions immediately
    // after them, then the next lesson. Article 4.3's memorize-then-review holds
    // inside each block rather than across the whole day, which is the more
    // useful reading of it — the review follows the material just seen.
    //
    // Lessons appear in the order their first due card did, so the most urgent
    // material still comes first.
    final lessonOfCard = {
      for (final row in cardRows) '${row.id}': row.lessonId,
    };

    final lessonOrder = <int>[];
    final cardsByLesson = <int, List<String>>{};
    for (final card in selection.cards) {
      final lessonId = lessonOfCard[card.cardId] ?? -1;
      if (!cardsByLesson.containsKey(lessonId)) {
        cardsByLesson[lessonId] = [];
        lessonOrder.add(lessonId);
      }
      cardsByLesson[lessonId]!.add(card.cardId);
    }

    final questionsByLesson = <int, List<QuestionRow>>{};
    for (final question in questionRows) {
      (questionsByLesson[question.lessonId] ??= []).add(question);
    }
    // A lesson whose questions were picked but whose cards were not still has to
    // appear — `_pickQuestions` deliberately reaches beyond today's cards so the
    // day is never review-less (Art. 5 pays for a review question on its own).
    for (final lessonId in questionsByLesson.keys) {
      if (!lessonOrder.contains(lessonId)) lessonOrder.add(lessonId);
    }

    await _db.transaction(() async {
      var position = 0;
      for (final lessonId in lessonOrder) {
        for (final cardId in cardsByLesson[lessonId] ?? const <String>[]) {
          await _db
              .into(_db.taskInstances)
              .insert(
                TaskInstancesCompanion.insert(
                  dayKey: day.daysSinceEpoch,
                  kind: TaskKind.memorize,
                  targetId: int.parse(cardId),
                  position: position++,
                ),
              );
        }
        for (final question
            in questionsByLesson[lessonId] ?? const <QuestionRow>[]) {
          await _db
              .into(_db.taskInstances)
              .insert(
                TaskInstancesCompanion.insert(
                  dayKey: day.daysSinceEpoch,
                  kind: TaskKind.review,
                  targetId: question.id,
                  position: position++,
                ),
              );
        }
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
    required DayKey day,
    required DailySelection selection,
    required List<CardRow> cardRows,
    required int limit,
  }) async {
    if (limit <= 0) return const [];

    // **A question finished on an earlier day is done.** Client report,
    // 2026-10-09: "today's lesson comes back tomorrow as a new test". Once the
    // memorization cards were switched off (D-85) the selection below has no
    // cards to anchor on, so every morning fell through to the filler — *any*
    // live question, newest lesson first — and served the same lesson again,
    // however completely the child had answered it the day before.
    //
    // Answered, not merely shown: a question that was on yesterday's list but
    // never reached — the child stopped halfway — is unfinished work and carries
    // over. The wrong-answer retry (`_askAgain`) only ever re-asks within the
    // same day, so an answered row from a past day is a finished question.
    final retired = await _questionsFinishedBefore(day);

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
              ..where((t) => t.id.isNotIn(retired))
              ..limit(limit))
            .get(),
      );
    }
    if (picked.length >= limit) return picked;

    final taken = picked.map((q) => q.id).toSet();
    final filler =
        await (_db.select(_db.questions)
              ..where((t) => t.purgedAtMs.isNull())
              ..where((t) => t.id.isNotIn(retired))
              ..orderBy([(t) => OrderingTerm.desc(t.lessonId)])
              ..limit(limit))
            .get();
    for (final question in filler) {
      if (picked.length >= limit) break;
      if (taken.add(question.id)) picked.add(question);
    }
    return picked;
  }

  /// Ids of every question answered on a day before [day].
  ///
  /// One indexed query over the task list, returning only ids. The set is
  /// small — a child answers a handful of questions a day — and passed to
  /// `isNotIn`, so the database does the exclusion rather than Dart filtering a
  /// whole table.
  Future<Set<int>> _questionsFinishedBefore(DayKey day) async {
    final rows =
        await (_db.selectOnly(_db.taskInstances, distinct: true)
              ..addColumns([_db.taskInstances.targetId])
              ..where(
                _db.taskInstances.kind.equalsValue(TaskKind.review) &
                    _db.taskInstances.state.equalsValue(TaskState.answered) &
                    _db.taskInstances.dayKey.isSmallerThanValue(
                      day.daysSinceEpoch,
                    ),
              ))
            .get();
    return {for (final row in rows) row.read(_db.taskInstances.targetId)!};
  }

  Future<List<TaskInstanceRow>> _tasksFor(DayKey day) {
    return (_db.select(_db.taskInstances)
          ..where((t) => t.dayKey.equals(day.daysSinceEpoch))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
  }

  Future<DailySession> _readSession(DayKey day) async {
    final rows = await _tasksFor(day);
    if (rows.isEmpty) {
      return DailySession(
        day: day,
        tasks: const [],
        answeredTaskIds: const {},
        backlogCount: 0,
      );
    }

    // Whole tables rather than a SELECT per task. The card table has to be read
    // in full anyway — [_choicesFor] draws each card's wrong answers out of it —
    // and issuing one query per row of the day's list to get there would be the
    // same work done a dozen times.
    final cardRows = await _db.select(_db.cards).get();
    final questionRows = await _db.select(_db.questions).get();
    final cardsById = {for (final row in cardRows) row.id: row};
    final questionsById = {for (final row in questionRows) row.id: row};

    final tasks = <SessionTask>[];
    final answered = <int>{};
    final lessonIds = <int>{};

    // How many times each question has appeared so far, walking the day in
    // presentation order. Counted here rather than stored, because the rows
    // already say it and a second copy could disagree with them.
    final timesAsked = <int, int>{};

    for (final row in rows) {
      if (row.state != TaskState.pending) answered.add(row.id);

      switch (row.kind) {
        case TaskKind.memorize:
          final card = cardsById[row.targetId];
          if (card == null) continue;
          lessonIds.add(card.lessonId);
          tasks.add(
            CardTask(
              taskId: row.id,
              targetId: card.id,
              lessonId: card.lessonId,
              front: card.front,
              back: card.back,
              isFirstEncounter: card.firstCorrectAtMs == null,
              options: _choicesFor(card: card, pool: cardRows, day: day),
            ),
          );
        case TaskKind.review:
        case TaskKind.exercise:
          final question = questionsById[row.targetId];
          if (question == null) continue;
          lessonIds.add(question.lessonId);
          // Re-ordered per presentation, so a question that comes back after
          // a wrong answer does not come back with the answer in the same
          // place. Seeded by the task row, so re-reading the day is stable.
          final asked = AnswerOrder.reorder(
            choices: (jsonDecode(question.choicesJson) as List<dynamic>)
                .map((e) => '$e')
                .toList(),
            correctIndex: question.correctIndex,
            seed: row.id,
          );
          final round = (timesAsked[question.id] ?? 0) + 1;
          timesAsked[question.id] = round;
          tasks.add(
            QuestionTask(
              taskId: row.id,
              targetId: question.id,
              lessonId: question.lessonId,
              prompt: question.prompt,
              choices: asked.choices,
              correctIndex: asked.correctIndex,
              attempt: round,
            ),
          );
      }
    }

    final lessonRows = lessonIds.isEmpty
        ? const <LessonRow>[]
        : await (_db.select(
            _db.lessons,
          )..where((t) => t.id.isIn(lessonIds.toList()))).get();

    return DailySession(
      day: day,
      tasks: tasks,
      answeredTaskIds: answered,
      backlogCount: 0,
      lessons: {
        for (final lesson in lessonRows)
          lesson.id: LessonBrief(title: lesson.title, summary: lesson.summary),
      },
    );
  }

  /// How many times this target has been put in front of the child today,
  /// counting the one being answered now.
  ///
  /// Presentations that are still pending are not counted — only the ones
  /// already answered — so the task being submitted is the `+ 1`.
  Future<int> _attemptNumberFor({
    required DayKey day,
    required SessionTask task,
  }) async {
    final memorize = task is CardTask;
    var answered = 0;
    for (final row in await _tasksFor(day)) {
      if (row.targetId != task.targetId) continue;
      if ((row.kind == TaskKind.memorize) != memorize) continue;
      if (row.state != TaskState.pending) answered++;
    }
    return answered + 1;
  }

  /// Put a missed question back at the end of the day.
  ///
  /// Asked for by the client on 2026-08-31: a question the child got wrong
  /// comes round again, with the answer in a different place. The re-ordering
  /// is not part of this method — it happens in [_readSession] for every
  /// presentation, so the new row is asked differently by construction rather
  /// than by remembering to do it here.
  ///
  /// **It cannot earn.** Article 6.1 pays only for an answer correct on the
  /// *first* attempt, and Article 6.2 refuses anything already counted today —
  /// so a second pass is practice, and the engine already treats it as such
  /// without being told. Nothing about the star table changes.
  ///
  /// **Capped at [maxQuestionAttempts].** Repeating until correct sounds right
  /// and is a trap: a child who does not know the answer is not taught it by a
  /// fourth identical question, and an unbounded list is a day that can never be
  /// finished — which would put Article 6.5's +5 permanently out of reach for
  /// exactly the child having the hardest time.
  Future<void> _askAgain({
    required DayKey day,
    required QuestionTask task,
  }) async {
    final rows = await _tasksFor(day);

    var asked = 0;
    var position = 0;
    for (final row in rows) {
      if (row.position >= position) position = row.position + 1;
      if (row.kind != TaskKind.memorize && row.targetId == task.targetId) {
        asked++;
      }
    }
    if (asked >= maxQuestionAttempts) return;

    await _db
        .into(_db.taskInstances)
        .insert(
          TaskInstancesCompanion.insert(
            dayKey: day.daysSinceEpoch,
            kind: TaskKind.review,
            targetId: task.targetId,
            position: position,
          ),
        );
  }

  /// The options for one card, drawn from the answers of the others.
  ///
  /// Same-lesson answers are offered to the builder first because they are the
  /// distractors that test anything — see [CardChoices]. The card's own row is
  /// excluded by id rather than by text, so a lesson that legitimately repeats
  /// an answer still gets a full set.
  CardChoiceSet _choicesFor({
    required CardRow card,
    required List<CardRow> pool,
    required DayKey day,
  }) {
    final sameLesson = <String>[];
    final otherLessons = <String>[];
    for (final other in pool) {
      if (other.id == card.id) continue;
      if (other.lessonId == card.lessonId) {
        sameLesson.add(other.back);
      } else {
        otherLessons.add(other.back);
      }
    }

    return CardChoices.build(
      cardId: card.id,
      back: card.back,
      sameLessonBacks: sameLesson,
      otherLessonBacks: otherLessons,
      // The day is half the seed, so a card that comes round again on a later
      // review is not asked with the same four options in the same order.
      daySeed: day.daysSinceEpoch,
    );
  }

  Future<void> _markAnswered(int taskId, TrustedInstant now) async {
    await (_db.update(
      _db.taskInstances,
    )..where((t) => t.id.equals(taskId))).write(
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
    final row = await (_db.select(
      _db.cards,
    )..where((t) => t.id.equals(cardId))).getSingleOrNull();
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
        firstCorrectAtMs:
            row.firstCorrectAtMs == null && firstCorrectAtMs != null
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
    lastReviewedDay: row.lastReviewedDay == null
        ? null
        : DayKey(row.lastReviewedDay!),
  );
}
