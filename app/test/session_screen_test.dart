import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/core/providers.dart';
import 'package:lunio/data/repositories/session_repository.dart';
import 'package:lunio/domain/card_choices.dart';
import 'package:lunio/features/session/session_controller.dart';
import 'package:lunio/features/session/session_screen.dart';
import 'package:lunio_stars/lunio_stars.dart';
import 'package:lunio_time/lunio_time.dart';

import 'support/widget_harness.dart';

/// The session screen, against a scripted session.
///
/// The interaction being guarded here is not cosmetic. The obvious flashcard
/// flow — reveal the answer, then say whether you knew it — makes Article 6.1's
/// "and none after the solution was revealed" unenforceable, because every card
/// would be revealed before it was answered. These tests pin the flow that keeps
/// the clause real: **commit first, reveal at a cost.**
void main() {
  final day = DayKey(20500);

  const card = CardTask(
    taskId: 1,
    targetId: 10,
    lessonId: 1,
    front: 'ما عاصمة الجزائر؟',
    back: 'الجزائر العاصمة',
    isFirstEncounter: true,
  );

  const question = QuestionTask(
    taskId: 2,
    targetId: 20,
    lessonId: 1,
    prompt: 'كم عدد ولايات الجزائر؟',
    choices: ['48', '58', '40'],
    correctIndex: 1,
  );

  /// A card the device could build options for. Same lesson as [card] so the
  /// two can share an intro in the tests below.
  const choiceCard = CardTask(
    taskId: 3,
    targetId: 30,
    lessonId: 1,
    front: 'ما عاصمة الجزائر؟',
    back: 'الجزائر العاصمة',
    isFirstEncounter: true,
    options: CardChoiceSet(
      choices: ['وهران', 'الجزائر العاصمة', 'قسنطينة'],
      correctIndex: 1,
    ),
  );


  /// A controller that records what the screen asked for and never touches a
  /// database, so the test asserts the *intent* the widget dispatches.
  late _RecordingController controller;

  Future<void> pumpSession(
    WidgetTester tester, {
    required List<SessionTask> tasks,
    Set<int> answered = const {},
    Map<int, LessonBrief> lessons = const {},
  }) async {
    controller = _RecordingController(
      DailySession(
        day: day,
        tasks: tasks,
        answeredTaskIds: answered,
        backlogCount: 0,
        lessons: lessons,
      ),
    );
    await pumpScreen(
      tester,
      const SessionScreen(),
      overrides: [
        sessionControllerProvider.overrideWith(() => controller),
        // The finished-session view reads the day's balance, so the test must
        // supply it too — the harness refuses to open a real database.
        todayProgressProvider.overrideWith(
          (ref) => Stream<DayProgress>.value(DayProgress(dayKey: day)),
        ),
      ],
    );
    await tester.pump();
  }

  group('a memorization card', () {
    testWidgets('offers the commitment before the answer', (tester) async {
      await pumpSession(tester, tasks: const [card]);

      expect(find.text('ما عاصمة الجزائر؟'), findsOneWidget);
      expect(find.text('الجزائر العاصمة'), findsNothing,
          reason: 'the back must not be visible before the child commits');
      expect(find.text('أعرفها'), findsOneWidget);
      expect(find.text('لم أعرفها'), findsOneWidget);
      expect(find.text('أظهر الجواب'), findsOneWidget);
    });

    testWidgets('"أعرفها" submits a correct, unrevealed first attempt',
        (tester) async {
      await pumpSession(tester, tasks: const [card]);

      await tester.tap(find.text('أعرفها'));
      await tester.pump();
      // The back is shown so the child can check — this is the learning moment.
      expect(find.text('الجزائر العاصمة'), findsOneWidget);
      expect(controller.calls, isEmpty,
          reason: 'nothing is submitted until the child moves on, so reading '
              'the answer is never counted as thinking about the question');

      await tester.pump(cardDwell);
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(controller.calls, hasLength(1));
      expect(controller.calls.single.correct, isTrue);
      expect(controller.calls.single.solutionRevealed, isFalse);
    });

    testWidgets('Article 6.1 — "أظهر الجواب" submits as revealed',
        (tester) async {
      await pumpSession(tester, tasks: const [card]);

      await tester.tap(find.text('أظهر الجواب'));
      await tester.pump();
      await tester.pump(cardDwell);
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(controller.calls.single.solutionRevealed, isTrue,
          reason: 'this is the reveal Article 6.1 names, and it must reach the '
              'engine as such — otherwise the clause is unenforceable');
      expect(controller.calls.single.correct, isFalse);
    });

    testWidgets('"لم أعرفها" is wrong but not a reveal', (tester) async {
      await pumpSession(tester, tasks: const [card]);

      await tester.tap(find.text('لم أعرفها'));
      await tester.pump();
      await tester.pump(cardDwell);
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(controller.calls.single.correct, isFalse);
      expect(controller.calls.single.solutionRevealed, isFalse,
          reason: 'an honest "I did not know" and a peek are different acts, '
              'and SM-2 grades them differently (D-22)');
    });

    testWidgets('Article 6.3 — the time reported is time before the choice',
        (tester) async {
      await pumpSession(tester, tasks: const [card]);

      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('أعرفها'));
      await tester.pump();
      // A long pause reading the answer must not inflate the measurement.
      await tester.pump(const Duration(seconds: 30));
      await tester.pump(cardDwell);
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(controller.calls.single.msOnTarget, lessThan(30000),
          reason: 'time on the card is time before answering; counting the '
              'feedback would let a child idle past the minimum');
    });
  });

  group('a review question', () {
    testWidgets('the answer is shown before anything is submitted',
        (tester) async {
      // Changed 2026-08-29: tapping used to submit and advance in one motion, so
      // a child who answered wrongly learned nothing — the question simply
      // vanished. Article 2 calls this the review step, and a review that never
      // shows the answer is a scoreboard.
      await pumpSession(tester, tasks: const [question]);

      await tester.tap(find.text('48'));
      await tester.pump();

      expect(
        controller.calls,
        isEmpty,
        reason: 'nothing is recorded until the child has seen the answer',
      );
      expect(find.textContaining('الإجابة الصحيحة'), findsOneWidget);
    });

    testWidgets('submits the chosen index as correct or not', (tester) async {
      await pumpSession(tester, tasks: const [question]);

      expect(find.text('كم عدد ولايات الجزائر؟'), findsOneWidget);
      await tester.tap(find.text('58'));
      await tester.pump();
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(controller.calls.single.correct, isTrue);
    });

    testWidgets('a wrong choice is reported as wrong', (tester) async {
      await pumpSession(tester, tasks: const [question]);

      await tester.tap(find.text('48'));
      await tester.pump();
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(controller.calls.single.correct, isFalse);
    });

    testWidgets('a right answer says so plainly', (tester) async {
      await pumpSession(tester, tasks: const [question]);

      await tester.tap(find.text('58'));
      await tester.pump();

      expect(find.text('إجابة صحيحة'), findsOneWidget);
    });

    testWidgets('the choices lock once answered', (tester) async {
      // A second tap would either change a recorded result or do nothing
      // visible. Both are worse than a button that has plainly stopped.
      await pumpSession(tester, tasks: const [question]);

      await tester.tap(find.text('48'));
      await tester.pump();
      await tester.tap(find.text('58'));
      await tester.pump();

      expect(controller.calls, isEmpty);
    });
  });

  group('a memorization card is recall, never a verdict', () {
    testWidgets('"not yet" is never called a wrong answer', (tester) async {
      // The child was asked whether they remembered and answered honestly.
      // Calling that wrong teaches them to press «تذكّرتها» to avoid the word —
      // and SM-2 fed on flattering answers stops scheduling anything useful,
      // which quietly breaks Article 2's mechanism.
      await pumpSession(tester, tasks: const [card]);

      await tester.tap(find.text('لم أعرفها'));
      await tester.pump();

      expect(find.textContaining('خاطئ'), findsNothing);
      expect(find.text('لا بأس — ستعود إليك قريبًا'), findsOneWidget);
    });

    testWidgets('remembering it is praised', (tester) async {
      await pumpSession(tester, tasks: const [card]);

      await tester.tap(find.text('أعرفها'));
      await tester.pump();

      expect(find.text('أحسنت، تذكّرتها'), findsOneWidget);
    });
  });

  group('a memorization card answered by choosing', () {
    // Asked for by the client on 2026-08-30. It makes Article 6 stricter, not
    // looser: the recall card asks the child to grade themselves, and tapping
    // «أعرفها» on every card earns every star in the table without reading a
    // word. Article 6.1 pays for an answer, and a claim is not one.

    testWidgets('offers the options instead of a self-report', (tester) async {
      await pumpSession(tester, tasks: const [choiceCard]);

      expect(find.text('وهران'), findsOneWidget);
      expect(find.text('قسنطينة'), findsOneWidget);
      expect(find.text('أعرفها'), findsNothing);
      expect(find.text('أظهر الجواب'), findsNothing);
    });

    testWidgets('the right choice is recorded as correct', (tester) async {
      await pumpSession(tester, tasks: const [choiceCard]);

      await tester.tap(find.text('الجزائر العاصمة'));
      await tester.pump();
      await tester.pump(cardDwell);
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(controller.calls.single.correct, isTrue);
      expect(
        controller.calls.single.solutionRevealed,
        isFalse,
        reason: 'there is no reveal button on this card, so Article 6.1 must '
            'never see one reported',
      );
    });

    testWidgets('a missed card is recorded as not correct', (tester) async {
      await pumpSession(tester, tasks: const [choiceCard]);

      await tester.tap(find.text('وهران'));
      await tester.pump();
      await tester.pump(cardDwell);
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(controller.calls.single.correct, isFalse);
      expect(controller.calls.single.solutionRevealed, isFalse);
    });

    testWidgets('a missed card is still never called wrong', (tester) async {
      // The client's instruction of 2026-08-29 survives the redesign: this is
      // the memorize step, not the exam.
      await pumpSession(tester, tasks: const [choiceCard]);

      await tester.tap(find.text('وهران'));
      await tester.pump();

      expect(find.textContaining('خاطئ'), findsNothing);
      expect(find.text('لا بأس — ستعود إليك قريبًا'), findsOneWidget);
      expect(
        find.byIcon(Icons.cancel_outlined),
        findsNothing,
        reason: 'the right answer is marked; the child\'s pick is not crossed '
            'out. A red cross here tells them nothing they do not know and '
            'teaches them to dread the screen.',
      );
    });

    testWidgets('nothing is submitted before the child moves on',
        (tester) async {
      await pumpSession(tester, tasks: const [choiceCard]);

      await tester.tap(find.text('وهران'));
      await tester.pump();

      expect(controller.calls, isEmpty);
    });

    testWidgets('Article 6.3 — the time reported stops at the tap',
        (tester) async {
      await pumpSession(tester, tasks: const [choiceCard]);

      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('الجزائر العاصمة'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      await tester.pump(cardDwell);
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(controller.calls.single.msOnTarget, lessThan(30000));
    });
  });

  group('a card cannot be rushed', () {
    // Asked for by the client on 2026-08-30: «لا يستطيع الطفل أن يتجاوز... يقضي
    // دقيقة واحدة حتى يستوعبها». The minute runs from the card appearing, so a
    // child who thinks before answering is not made to wait the full minute
    // again afterwards.

    testWidgets('the way out is shut until the minute is up', (tester) async {
      await pumpSession(tester, tasks: const [choiceCard]);

      await tester.tap(find.text('الجزائر العاصمة'));
      await tester.pump();

      expect(find.text('متابعة'), findsNothing);
      expect(find.textContaining('تأمّلها'), findsOneWidget);

      await tester.tap(find.textContaining('تأمّلها'));
      await tester.pump();
      expect(
        controller.calls,
        isEmpty,
        reason: 'tapping the countdown must not submit',
      );

      await tester.pump(cardDwell);

      expect(find.text('متابعة'), findsOneWidget);
      await tester.tap(find.text('متابعة'));
      await tester.pump();
      expect(controller.calls, hasLength(1));
    });

    testWidgets('the recall card is paced too', (tester) async {
      await pumpSession(tester, tasks: const [card]);

      await tester.tap(find.text('أعرفها'));
      await tester.pump();

      expect(find.text('متابعة'), findsNothing);

      await tester.pump(cardDwell);
      expect(find.text('متابعة'), findsOneWidget);
    });

    testWidgets('Article 6.3 — the minute is not counted as thinking time',
        (tester) async {
      // The line this must not cross. The dwell is pacing; the measurement
      // Article 6.3 uses is time spent *deciding*. If the wait leaked into
      // msOnTarget, every card would clear the minimum by standing still and
      // the clause would stop refusing anything.
      await pumpSession(tester, tasks: const [choiceCard]);

      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('وهران'));
      await tester.pump();
      await tester.pump(cardDwell);
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(controller.calls.single.msOnTarget, lessThan(10000));
    });

    testWidgets('a review question is not paced', (tester) async {
      // Only the memorization cards were asked for, and rightly: a question is
      // answered from what you already know, and holding a child in front of
      // one teaches nothing.
      await pumpSession(tester, tasks: const [question]);

      await tester.tap(find.text('58'));
      await tester.pump();

      expect(find.text('متابعة'), findsOneWidget);
    });
  });

  group('the minute is spent on the card, not on a list', () {
    testWidgets('the card is shown whole once the answer is known',
        (tester) async {
      // A choice list with one row turned green is feedback; it is not
      // something anybody memorises. The minute the client asked for is spent
      // on the card itself — the front, and the answer under it, alone.
      await pumpSession(tester, tasks: const [choiceCard]);

      await tester.tap(find.text('وهران'));
      await tester.pump();

      expect(find.text('ما عاصمة الجزائر؟'), findsOneWidget);
      expect(find.text('الجزائر العاصمة'), findsOneWidget);
      expect(
        find.text('قسنطينة'),
        findsNothing,
        reason: 'the options are gone once there is nothing left to choose',
      );

      await tester.pump(cardDwell);
    });

    testWidgets('the answer is never shown before the attempt', (tester) async {
      // The constraint that fixes the order. Article 6.1 grants nothing after
      // the solution was revealed, so a card that showed its answer first could
      // never earn — the whole star economy of Articles 5 and 6 would go to
      // zero without a single test failing.
      await pumpSession(tester, tasks: const [choiceCard]);

      expect(find.text('الجزائر العاصمة'), findsOneWidget,
          reason: 'only as one option among the choices');
      expect(find.text('وهران'), findsOneWidget);
      expect(find.text('قسنطينة'), findsOneWidget);
    });
  });

  group('the session as a whole', () {
    testWidgets('shows how many tasks are left', (tester) async {
      await pumpSession(tester, tasks: const [card, question]);
      expect(find.textContaining('بقيت 2'), findsOneWidget);
    });

    testWidgets('a finished session shows the completion message',
        (tester) async {
      await pumpSession(
        tester,
        tasks: const [card, question],
        answered: const {1, 2},
      );
      expect(find.text('أنهيتَ مهام اليوم كلها'), findsOneWidget);
    });

    testWidgets('an empty day says so instead of showing a blank screen',
        (tester) async {
      await pumpSession(tester, tasks: const []);
      expect(find.textContaining('لا توجد مهام بعد'), findsOneWidget);
    });
  });
}

class _RecordedAnswer {
  const _RecordedAnswer({
    required this.correct,
    required this.msOnTarget,
    required this.solutionRevealed,
  });

  final bool correct;
  final int msOnTarget;
  final bool solutionRevealed;
}

class _RecordingController extends SessionController {
  _RecordingController(this._session);

  final DailySession _session;
  final List<_RecordedAnswer> calls = [];

  @override
  Future<DailySession> build() async => _session;

  @override
  Future<AnswerOutcome?> answer({
    required SessionTask task,
    required bool correct,
    required int msOnTarget,
    int attemptNumber = 1,
    bool solutionRevealed = false,
  }) async {
    calls.add(
      _RecordedAnswer(
        correct: correct,
        msOnTarget: msOnTarget,
        solutionRevealed: solutionRevealed,
      ),
    );
    return null;
  }
}
