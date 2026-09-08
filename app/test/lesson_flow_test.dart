import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/data/repositories/session_repository.dart';
import 'package:lunio/domain/card_choices.dart';
import 'package:lunio/features/session/lesson_hub_screen.dart';
import 'package:lunio/features/session/lesson_picker_screen.dart';
import 'package:lunio_time/lunio_time.dart';

import 'support/widget_harness.dart';

/// The child's route into the day: a shelf of lessons, then one lesson's two
/// halves.
///
/// Asked for by the client on 2026-08-30. The day used to be a single queue
/// running from the first card of the first lesson to the last question of the
/// last, and a child could not see what they were working on or that a lesson
/// had been added.
///
/// **What must not move while the route changes.** Article 6.5 pays the +5 bonus
/// for finishing *the day's* tasks, so the grouping is a view over one list, not
/// a division of it — and Article 4.3 orders the day memorize → review, which is
/// why the questions are held shut rather than merely listed second.
void main() {
  const day = DayKey(20500);

  CardTask cardIn(int lesson, int id, {int correct = 0}) => CardTask(
    taskId: id,
    targetId: id,
    lessonId: lesson,
    front: 'وجه $id',
    back: 'ظهر $id',
    isFirstEncounter: true,
    options: CardChoiceSet(
      choices: ['ظهر $id', 'خيار آخر'],
      correctIndex: correct,
    ),
  );

  QuestionTask questionIn(int lesson, int id) => QuestionTask(
    taskId: id,
    targetId: id,
    lessonId: lesson,
    prompt: 'سؤال $id',
    choices: const ['أ', 'ب'],
    correctIndex: 0,
  );

  DailySession sessionOf({
    required List<SessionTask> tasks,
    Set<int> answered = const {},
    Map<int, LessonBrief> lessons = const {
      1: LessonBrief(title: 'فضل العلم', summary: 'ملخّص الدرس الأوّل هنا.'),
      2: LessonBrief(title: 'الكسور', summary: 'ملخّص الدرس الثاني هنا.'),
    },
  }) => DailySession(
    day: day,
    tasks: tasks,
    answeredTaskIds: answered,
    backlogCount: 0,
    lessons: lessons,
  );

  group('the shelf', () {
    testWidgets('shows one tile per lesson with its own progress',
        (tester) async {
      await pumpScreen(
        tester,
        const LessonPickerScreen(),
        overrides: [
          fakeSession(
            session: sessionOf(
              tasks: [
                cardIn(1, 1),
                cardIn(1, 2),
                cardIn(2, 3),
                questionIn(2, 4),
              ],
              answered: const {1},
            ),
          ),
        ],
      );
      await tester.pump();

      expect(find.text('فضل العلم'), findsOneWidget);
      expect(find.text('الكسور'), findsOneWidget);
      expect(find.text('1 من 2'), findsOneWidget);
      expect(find.text('0 من 2'), findsOneWidget);
    });

    testWidgets('a finished lesson says so and still opens', (tester) async {
      // A tick means "nothing owed here", never "closed". A child who wants to
      // look at a lesson again should be able to.
      await pumpScreen(
        tester,
        const LessonPickerScreen(),
        overrides: [
          fakeSession(
            session: sessionOf(
              tasks: [cardIn(1, 1)],
              answered: const {1},
              lessons: const {
                1: LessonBrief(title: 'فضل العلم', summary: 'ملخّص'),
              },
            ),
          ),
        ],
      );
      await tester.pump();

      expect(find.text('أنهيتَه'), findsOneWidget);
    });

    testWidgets('an empty day says so instead of showing a blank shelf',
        (tester) async {
      await pumpScreen(
        tester,
        const LessonPickerScreen(),
        overrides: [fakeSession(session: sessionOf(tasks: const []))],
      );
      await tester.pump();

      expect(find.textContaining('لا توجد مهام بعد'), findsOneWidget);
    });
  });

  group('one lesson', () {
    Future<void> pumpHub(
      WidgetTester tester, {
      required List<SessionTask> tasks,
      Set<int> answered = const {},
    }) async {
      await pumpScreen(
        tester,
        const LessonHubScreen(lessonId: 1),
        overrides: [
          fakeSession(session: sessionOf(tasks: tasks, answered: answered)),
        ],
      );
      await tester.pump();
    }

    testWidgets('the summary is on the page, above both halves',
        (tester) async {
      await pumpHub(tester, tasks: [cardIn(1, 1), questionIn(1, 2)]);

      expect(find.textContaining('ملخّص الدرس الأوّل'), findsOneWidget);
      expect(find.text('بطاقات الحفظ'), findsOneWidget);
      expect(find.text('أسئلة المراجعة'), findsOneWidget);

      // Spend the gate so no periodic timer outlives the test.
      await tester.pump(lessonSummaryGate);
    });

    testWidgets('the cards are shut for a minute while the summary is read',
        (tester) async {
      await pumpHub(tester, tasks: [cardIn(1, 1)]);

      expect(find.textContaining('يمكنك المتابعة بعد'), findsOneWidget);

      await tester.pump(lessonSummaryGate);

      expect(find.textContaining('يمكنك المتابعة بعد'), findsNothing);
    });

    testWidgets('a lesson already started skips the minute', (tester) async {
      // The across-restarts half of the rule, and the reason it needs no new
      // column: a lesson with an answered card has had its summary read. A
      // child who studies two cards and comes back is not made to sit through
      // it again.
      await pumpHub(
        tester,
        tasks: [cardIn(1, 1), cardIn(1, 2)],
        answered: const {1},
      );

      expect(find.textContaining('يمكنك المتابعة بعد'), findsNothing);
    });

    testWidgets('Article 4.3 — the questions wait for the cards',
        (tester) async {
      // A child answering questions about a page they have not studied is being
      // examined rather than taught, and the grade SM-2 gets out of it means
      // nothing.
      await pumpHub(tester, tasks: [cardIn(1, 1), questionIn(1, 2)]);

      expect(find.text('أنهِ بطاقات الحفظ أوّلًا'), findsOneWidget);

      await tester.pump(lessonSummaryGate);
    });

    testWidgets('the questions open once the cards are done', (tester) async {
      await pumpHub(
        tester,
        tasks: [cardIn(1, 1), questionIn(1, 2)],
        answered: const {1},
      );

      expect(find.text('أنهِ بطاقات الحفظ أوّلًا'), findsNothing);
    });
  });
}
