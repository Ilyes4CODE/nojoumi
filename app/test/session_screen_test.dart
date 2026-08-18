import 'package:flutter_test/flutter_test.dart';
import 'package:nojoumi/core/providers.dart';
import 'package:nojoumi/data/repositories/session_repository.dart';
import 'package:nojoumi/features/session/session_controller.dart';
import 'package:nojoumi/features/session/session_screen.dart';
import 'package:nojoumi_stars/nojoumi_stars.dart';
import 'package:nojoumi_time/nojoumi_time.dart';

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
    front: 'ما عاصمة الجزائر؟',
    back: 'الجزائر العاصمة',
    isFirstEncounter: true,
  );

  const question = QuestionTask(
    taskId: 2,
    targetId: 20,
    prompt: 'كم عدد ولايات الجزائر؟',
    choices: ['48', '58', '40'],
    correctIndex: 1,
  );

  /// A controller that records what the screen asked for and never touches a
  /// database, so the test asserts the *intent* the widget dispatches.
  late _RecordingController controller;

  Future<void> pumpSession(
    WidgetTester tester, {
    required List<SessionTask> tasks,
    Set<int> answered = const {},
  }) async {
    controller = _RecordingController(
      DailySession(
        day: day,
        tasks: tasks,
        answeredTaskIds: answered,
        backlogCount: 0,
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
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(controller.calls.single.msOnTarget, lessThan(30000),
          reason: 'time on the card is time before answering; counting the '
              'feedback would let a child idle past the minimum');
    });
  });

  group('a review question', () {
    testWidgets('submits the chosen index as correct or not', (tester) async {
      await pumpSession(tester, tasks: const [question]);

      expect(find.text('كم عدد ولايات الجزائر؟'), findsOneWidget);
      await tester.tap(find.text('58'));
      await tester.pump();

      expect(controller.calls.single.correct, isTrue);
    });

    testWidgets('a wrong choice is reported as wrong', (tester) async {
      await pumpSession(tester, tasks: const [question]);

      await tester.tap(find.text('48'));
      await tester.pump();

      expect(controller.calls.single.correct, isFalse);
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
