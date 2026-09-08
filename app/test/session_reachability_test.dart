import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/data/local/tables.dart';
import 'package:lunio/data/repositories/session_repository.dart';
import 'package:lunio/data/repositories/star_repository.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

import 'support/test_db.dart';

/// Can the child actually reach the lessons the parent captured?
///
/// **Why this file exists.** Reported from the device on 2026-08-29: two lessons
/// photographed, both saved correctly, and the child's home screen said
/// «لا توجد مهام بعد» for ever.
///
/// The cause was a circle, not a missing row. The day's tasks are created by
/// `sessionFor`, which ran only when the *session screen* opened — and the button
/// that opens the session screen was disabled until `tasksTotal > 0`, which only
/// `sessionFor` could set. Every piece worked: the cards were in the database,
/// the builder selected new cards correctly, the star engine was fine. There was
/// simply no path from the home screen into the day.
///
/// Every existing test passed throughout, because each tested a piece. Nothing
/// asked the question this file asks: **starting from a fresh install and a
/// captured lesson, does the child end up with something to do?**
void main() {
  late LunioDatabase db;
  late SessionRepository sessions;
  late StarRepository stars;

  // Cards are off by default since 2026-08-31 (D-85), and this file is where
  // the card machinery is proved to still work — so it asks for them by name.
  // If the client reverses the amendment, these are the tests that already say
  // whether Article 5's first two rows still pay.
  final rules = StarRules(dailySessionCards: 12);
  const day = DayKey(20694);

  setUp(() async {
    db = await freshDatabase();
    stars = StarRepository(db);
    sessions = SessionRepository(db, stars);
  });

  tearDown(() => db.close());

  Future<int> captureLesson({int cards = 3, int questions = 2}) async {
    final lessonId = await db
        .into(db.lessons)
        .insert(
          LessonsCompanion.insert(
            summary: 'فضل العلم',
            createdAtMs: 1787000000000,
            weekKey: 2904,
          ),
        );
    for (var i = 0; i < cards; i++) {
      await db.into(db.cards).insert(
            CardsCompanion.insert(
              lessonId: lessonId,
              front: 'سؤال $i',
              back: 'جواب $i',
            ),
          );
    }
    for (var i = 0; i < questions; i++) {
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              lessonId: lessonId,
              prompt: 'مراجعة $i',
              choicesJson: '["أ","ب","ج","د"]',
              correctIndex: 0,
            ),
          );
    }
    return lessonId;
  }

  test('a captured lesson gives the child something to do', () async {
    await captureLesson();
    final session = await sessions.sessionFor(day: day, rules: rules);

    expect(session.total, greaterThan(0), reason: 'the day must not be empty');
    expect(session.next, isNotNull, reason: 'there must be a first task');
  });

  test('the progress row the home screen reads is written by the build', () async {
    // The specific link that was broken. `_TasksCard` renders from
    // `DayProgress.tasksTotal`; if building the session does not write it, the
    // child sees "no tasks yet" beside a session that exists.
    await captureLesson();
    expect((await stars.dayProgress(day)).tasksTotal, 0);

    await sessions.sessionFor(day: day, rules: rules);

    expect((await stars.dayProgress(day)).tasksTotal, greaterThan(0));
  });

  test('a day with no lessons stays empty and does not crash', () async {
    final session = await sessions.sessionFor(day: day, rules: rules);
    expect(session.total, 0);
    expect(session.next, isNull);
  });

  group('a lesson captured after the session was built', () {
    const now = TrustedInstant(
      epochMs: 1787000000000,
      level: TrustLevel.serverAnchored,
    );

    Future<void> answerEverything() async {
      var session = await sessions.sessionFor(day: day, rules: rules);
      while (session.next != null) {
        await sessions.submitAnswer(
          day: day,
          rules: rules,
          now: now,
          task: session.next!,
          correct: true,
          attemptNumber: 1,
          msOnTarget: 3000,
        );
        session = await sessions.sessionFor(day: day, rules: rules);
      }
    }

    test('joins today while nothing has been answered', () async {
      await sessions.sessionFor(day: day, rules: rules);
      expect((await stars.dayProgress(day)).tasksTotal, 0);

      final lessonId = await captureLesson();
      final inToday = await sessions.absorbLesson(
        day: day,
        rules: rules,
        lessonId: lessonId,
      );

      expect(inToday, greaterThan(0));
      final session = await sessions.sessionFor(day: day, rules: rules);
      expect(session.total, greaterThan(0));
    });

    test('joins today even after the child has started', () async {
      // The 2026-08-30 report. This used to refuse: a parent who photographed a
      // page after the child had begun got nothing, silently, which from the
      // outside is indistinguishable from the capture having failed.
      await captureLesson(cards: 2, questions: 0);
      final session = await sessions.sessionFor(day: day, rules: rules);
      expect(session.total, 2);

      await sessions.submitAnswer(
        day: day,
        rules: rules,
        now: now,
        task: session.tasks.first,
        correct: true,
        attemptNumber: 1,
        msOnTarget: 3000,
      );

      final second = await captureLesson(cards: 5, questions: 0);
      final added = await sessions.absorbLesson(
        day: day,
        rules: rules,
        lessonId: second,
      );

      expect(added, 5, reason: 'all five of the new lesson\'s cards');
      final after = await sessions.sessionFor(day: day, rules: rules);
      expect(after.total, 7);
      expect(
        after.answeredTaskIds,
        hasLength(1),
        reason: 'appending must not disturb what was already answered',
      );
      expect((await stars.dayProgress(day)).tasksTotal, 7);
    });

    test('Article 6.5 — the +5 bonus is still paid only once', () async {
      // This is what made appending safe to do at all. The guard is
      // `sessionBonusAwarded` on the day, not the length of the list — so a day
      // that grows after being completed cannot pay a second time.
      await captureLesson(cards: 2, questions: 0);
      await answerEverything();
      expect((await stars.dayProgress(day)).sessionBonusAwarded, isTrue);

      final second = await captureLesson(cards: 3, questions: 0);
      await sessions.absorbLesson(day: day, rules: rules, lessonId: second);
      await answerEverything();

      final bonuses = await (db.select(
        db.starLedger,
      )..where((t) => t.kind.equalsValue(LedgerKind.sessionBonus))).get();
      expect(
        bonuses,
        hasLength(1),
        reason: 'a day completed twice is still one completed day',
      );
    });

    test('absorbing the same lesson twice adds nothing the second time', () async {
      // Article 6.2 would refuse to pay for the duplicate anyway, which would
      // leave the child a task that can never earn — visible work, no reward.
      final lessonId = await captureLesson(cards: 3, questions: 1);
      await sessions.sessionFor(day: day, rules: rules);

      final first = await sessions.absorbLesson(
        day: day,
        rules: rules,
        lessonId: lessonId,
      );
      final again = await sessions.absorbLesson(
        day: day,
        rules: rules,
        lessonId: lessonId,
      );

      expect(again, first, reason: 'the lesson does not grow on a second pass');
      final session = await sessions.sessionFor(day: day, rules: rules);
      // Keyed by kind *and* target: card ids and question ids both start at
      // 1, so a bare target id collides across the two kinds and would make
      // this assertion fail on a perfectly good day.
      expect(
        session.tasks.map((t) => '${t.runtimeType}:${t.targetId}').toSet(),
        hasLength(session.total),
        reason: 'no card or question appears twice in the day',
      );
    });

    test('a lesson stranded outside the day is picked up on the next read', () async {
      // The 2026-08-30 device measurement, reproduced. Two lessons of twelve
      // cards; the day was built from the first and filled by it, and not one
      // card of the second had ever been presented on any day. `absorbLesson`
      // could not help — it runs at capture time, and this lesson was captured
      // before that code existed. Without reconciliation the child had no route
      // to it, ever.
      await captureLesson(cards: 12, questions: 5);
      final stranded = await captureLesson(cards: 12, questions: 5);

      // Build the day the way the device did, then strand the second lesson:
      // remove every trace of it from the day's list, leaving it captured,
      // intact, and unreachable.
      await sessions.sessionFor(day: day, rules: rules);
      final strandedCards =
          await (db.select(db.cards)
                ..where((c) => c.lessonId.equals(stranded)))
              .get();
      final strandedIds = strandedCards.map((c) => c.id).toList();
      await (db.delete(db.taskInstances)
            ..where((t) => t.targetId.isIn(strandedIds))
            ..where((t) => t.kind.equalsValue(TaskKind.memorize)))
          .go();

      final before = await sessions.sessionFor(day: day, rules: rules);
      expect(
        before.lessonSlices.where((s) => s.lessonId == stranded),
        isNotEmpty,
        reason: 'reading the day again must find the stranded lesson',
      );
      expect(
        before.lessonSlices
            .firstWhere((s) => s.lessonId == stranded)
            .cards,
        isNotEmpty,
      );
    });

    test('a lesson being paced by SM-2 is not dragged back in', () async {
      // The line the reconciliation must not cross. "Orphaned" means never
      // presented, not merely absent today — a lesson whose cards the scheduler
      // has spread over the coming week is being paced, and pulling it back
      // every morning would undo spaced repetition entirely.
      final lessonId = await captureLesson(cards: 12, questions: 0);
      final first = await sessions.sessionFor(day: day, rules: rules);
      final presented = first.total;

      // Some of its cards are in today; the rest are not. Reading again must
      // not add the remainder.
      final again = await sessions.sessionFor(day: day, rules: rules);

      expect(again.total, presented);
      expect(again.lessonSlices.single.lessonId, lessonId);
    });

    test('the new lesson arrives as its own slice for the picker', () async {
      final first = await captureLesson(cards: 2, questions: 1);
      await sessions.sessionFor(day: day, rules: rules);
      final second = await captureLesson(cards: 3, questions: 1);
      await sessions.absorbLesson(day: day, rules: rules, lessonId: second);

      final slices = (await sessions.sessionFor(
        day: day,
        rules: rules,
      )).lessonSlices;

      expect(slices.map((s) => s.lessonId), containsAll([first, second]));
      final added = slices.firstWhere((s) => s.lessonId == second);
      expect(added.cards, hasLength(3));
      expect(added.questions, hasLength(1));
      expect(added.brief.summary, 'فضل العلم');
    });
  });
}
