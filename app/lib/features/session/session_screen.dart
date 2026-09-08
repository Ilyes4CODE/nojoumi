import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/illustrations.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/card_choices.dart';
import '../../l10n/app_localizations.dart';
import 'session_controller.dart';

/// The daily session — the screen where stars are actually earned.
///
/// Two things here are contract mechanisms, not interaction design:
///
///  * **Time on the task is measured, not estimated.** Article 6.3 grants
///    nothing unless the child spent longer than the minimum on the card, and
///    the appendix's reason is explicit: rapid random tapping must earn nothing.
///    The stopwatch starts when a task is first painted and stops when the
///    answer is submitted, so what the engine receives is the interval the child
///    actually had the task in front of them.
///  * **Revealing the answer is a first-class action with a consequence.**
///    Article 6.1 says a revealed solution earns nothing, so the button is
///    present, honest, and irreversible for that task.
/// How long a memorization card stays in front of the child.
///
/// Requested by the client on 2026-08-30: the child must not be able to rush
/// past a card, «حتى يستوعبها».
///
/// **It is counted from the card appearing, not from the answer.** A child who
/// thinks for forty seconds and then answers waits twenty more; a child who
/// taps instantly spends almost the whole minute with the right answer in front
/// of them. Either way the card lasts a minute, which is what was asked for —
/// and the child who was actually thinking is not punished for it.
///
/// **It does not touch Article 6.3.** The stopwatch that feeds the star engine
/// still stops at the moment of the answer, so the seconds spent reading the
/// solution afterwards are never counted as time spent deciding. What this
/// changes is the pace of the session, not what is earned in it.
///
/// It deliberately does **not** show the answer first. Doing that would make
/// every card a revealed one, and Article 6.1 grants nothing after a reveal —
/// the whole star economy would quietly go to zero. If the client wants a
/// study-then-test card instead, that is a contract question, not a layout one.
const Duration cardDwell = Duration(seconds: 60);

/// The countdown shared by both kinds of memorization card.
mixin _CardDwell<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Timer? _dwellTimer;
  int _dwellLeft = cardDwell.inSeconds;

  int get dwellLeft => _dwellLeft;
  bool get dwellSpent => _dwellLeft <= 0;

  @override
  void initState() {
    super.initState();
    _dwellTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _dwellLeft -= 1);
      // Cancelled the moment it is spent, so no timer outlives the card — and
      // so a widget test can settle.
      if (_dwellLeft <= 0) {
        timer.cancel();
        _dwellTimer = null;
      }
    });
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    super.dispose();
  }
}

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, this.lessonId, this.section});

  /// The lesson to work through, or null for the whole day in one queue.
  ///
  /// **A filter over the day, never a separate day.** Article 6.5 pays the +5
  /// bonus for finishing *the day's* tasks, and `submitAnswer` still evaluates
  /// completion across every lesson at once — a child working lesson by lesson
  /// is taking a different route through the same list.
  final int? lessonId;

  /// Which half of the lesson. Ignored unless [lessonId] is set.
  final SessionSection? section;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final state = ref.watch(sessionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.todayTasks)),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: LunioSpacing.page,
              child: Text('$error', textAlign: TextAlign.center),
            ),
          ),
          data: (session) => _SessionBody(
            session: session,
            lessonId: widget.lessonId,
            section: widget.section,
          ),
        ),
      ),
    );
  }
}

/// The day's work, one task at a time — optionally narrowed to one half of one
/// lesson.
class _SessionBody extends ConsumerWidget {
  const _SessionBody({
    required this.session,
    required this.lessonId,
    required this.section,
  });

  final DailySession session;
  final int? lessonId;
  final SessionSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonId = this.lessonId;
    final section = this.section;

    final slice = lessonId == null ? null : session.sliceOf(lessonId);
    final scoped = slice != null && section != null;

    final task = scoped ? slice.nextIn(section) : session.next;
    final total = scoped ? slice.tasksIn(section).length : session.total;
    final answered = scoped
        ? slice.tasksIn(section).where(
            (t) => slice.answeredTaskIds.contains(t.taskId),
          ).length
        : session.answered;

    if (task == null) {
      // The whole day being finished is a different event from one section
      // being finished, and the child is told which. Saying «أنهيتَ مهام اليوم
      // كلها» after five cards out of thirty is a lie the child can check.
      return _SessionFinished(
        empty: total == 0,
        dayComplete: session.isComplete,
      );
    }

    return Stack(
      children: [
        const Positioned.fill(child: _SessionBackdrop()),
        _SessionColumn(total: total, answered: answered, task: task),
      ],
    );
  }
}

/// The faint pattern behind the day's work.
///
/// Low opacity on purpose, and it is the number that matters rather than the
/// drawing: Arabic sentences are laid over this, and a pattern strong enough to
/// notice is a pattern competing with the words. A child who already reads
/// slowly will stop trying rather than squint. **If you can see it, it is too
/// strong.**
///
/// `IgnorePointer` because it is decoration and must never take a tap meant for
/// an answer.
class _SessionBackdrop extends StatelessWidget {
  const _SessionBackdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Opacity(
        // 0.4, tuned by rendering the screen and looking at it. At 0.5 the
        // scattered stars were noticeable in the empty half of the card view —
        // and the empty half is exactly where the eye goes when there is nothing
        // else to read.
        opacity: 0.4,
        child: Image(
          image: AssetImage('assets/illustrations/session_bg.webp'),
          fit: BoxFit.cover,
          // A pattern that fails to load must leave a clean canvas, not a broken
          // image in front of a child mid-session.
          errorBuilder: _noBackdrop,
        ),
      ),
    );
  }

  static Widget _noBackdrop(
    BuildContext context,
    Object error,
    StackTrace? stack,
  ) => const SizedBox.shrink();
}

class _SessionColumn extends StatelessWidget {
  const _SessionColumn({
    required this.total,
    required this.answered,
    required this.task,
  });

  /// Counted over whatever the screen is showing — one section, or the day.
  final int total;
  final int answered;

  final SessionTask task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    // Copied to a local so the switch below can promote it. Dart does not
    // promote fields, and the exhaustive match on CardTask/QuestionTask is the
    // thing that makes adding a third task kind a compile error rather than a
    // silent gap.
    final task = this.task;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LunioSpacing.m,
            vertical: LunioSpacing.s,
          ),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: total == 0 ? 0 : answered / total,
                minHeight: 8,
                borderRadius: BorderRadius.circular(LunioRadius.button),
              ),
              const SizedBox(height: LunioSpacing.xs),
              Text(
                l10n.tasksRemaining('${total - answered}'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
        Expanded(
          // The key is the task id, so moving to the next task rebuilds the
          // widget from scratch — which resets the stopwatch and the revealed
          // flag. Reusing the widget would carry the previous task's elapsed
          // time into this one and hand out stars for time never spent.
          child: switch (task) {
            // A card the device could build options for is the multiple-choice
            // card the client asked for; one it could not falls back to recall.
            // The fallback is not a nicety — see CardChoiceSet.isUsable, which
            // refuses to paint a question with a single answer.
            CardTask() when task.options.isUsable => _CardChoiceView(
              key: ValueKey(task.taskId),
              task: task,
            ),
            CardTask() => _CardRecallView(
              key: ValueKey(task.taskId),
              task: task,
            ),
            QuestionTask() => _QuestionView(
              key: ValueKey(task.taskId),
              task: task,
            ),
          },
        ),
      ],
    );
  }
}

/// The minute after the answer: the card, whole, to be memorised.
///
/// ### Why this exists and why it comes *after* the answer
///
/// The client asked on 2026-08-30 that the child not be able to rush a card,
/// «حتى يستوعبها». A choice list with one option turned green is feedback; it is
/// not something to memorise. This is: the front, and the answer under it,
/// large, alone on the screen, for as long as [cardDwell] lasts.
///
/// **The order is a contract constraint, not a layout preference.** Showing the
/// answer *before* the attempt is the better lesson and it is not ours to
/// choose: Article 6.1 grants nothing "after the solution was revealed", so a
/// card that reveals first is a card that can never earn, and the whole star
/// economy of Articles 5 and 6 would quietly go to zero. Answer first, study
/// second, keeps both the clause and the minute.
///
/// The stopwatch feeding the star engine has already stopped by the time this
/// is on screen, so none of this minute is counted as time spent deciding
/// (Article 6.3).
class _StudyBeat extends StatelessWidget {
  const _StudyBeat({
    required this.front,
    required this.back,
    required this.note,
    required this.positive,
    required this.dwellLeft,
    required this.dwellSpent,
    required this.submitting,
    required this.onContinue,
  });

  final String front;
  final String back;

  /// What to say about how it went. **Never the word "wrong"** on a
  /// memorization card — the client's instruction of 2026-08-29, and the reason
  /// holds: this is the memorize step, not the exam.
  final String note;
  final bool positive;

  final int dwellLeft;
  final bool dwellSpent;
  final bool submitting;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(LunioSpacing.l),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LunioRadius.card),
                ),
                child: Column(
                  children: [
                    Text(
                      front,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                    const Divider(height: LunioSpacing.xl),
                    // The thing being learned, and the largest thing on screen.
                    Text(
                      back,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: LunioSpacing.m),
        Container(
          padding: const EdgeInsets.all(LunioSpacing.m),
          decoration: BoxDecoration(
            color: positive ? LunioTheme.tintMint : LunioTheme.tintLavender,
            borderRadius: BorderRadius.circular(LunioRadius.card),
          ),
          child: Row(
            children: [
              Icon(
                positive ? Icons.check_circle : Icons.lightbulb_outline,
                color: positive
                    ? LunioTheme.play
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: LunioSpacing.s),
              Expanded(
                child: Text(note, style: theme.textTheme.bodyLarge),
              ),
            ],
          ),
        ),
        const SizedBox(height: LunioSpacing.m),
        FilledButton(
          onPressed: (submitting || !dwellSpent) ? null : onContinue,
          child: Text(
            dwellSpent ? l10n.continueAction : l10n.cardStayWith('$dwellLeft'),
          ),
        ),
      ],
    );
  }
}

/// A memorization card with no options to offer — the fallback path.
///
/// Reached only when the device holds too few distinct answers to build a
/// choice from, which in practice means the very first lesson on a fresh
/// install. It is kept because the alternative is worse in both directions: a
/// one-option question awards a star for a single tap, and showing nothing at
/// all loses the card.
///
/// **The order of the buttons is a contract mechanism.** The obvious flashcard
/// flow — reveal, then self-report — would make Article 6.1's "and none after
/// the solution was revealed" dead text, because every card would be revealed
/// before it was answered and therefore no card could ever earn.
///
/// So the child commits *first*, from the front of the card:
///
///  * **أعرفها** — a first-attempt claim. Earns 1 star (or 0.5 on review).
///  * **لم أعرفها** — wrong. Earns nothing, and SM-2 brings the card back.
///  * **أظهر الجواب** — this is the reveal Article 6.1 names. Earns nothing,
///    and it is offered plainly rather than hidden, because a child who is
///    stuck must have a way out that is not a lie.
///
/// The back of the card is shown after any of the three, because the point of
/// the exercise is to learn it. The stopwatch stops at the moment of choice, so
/// time spent reading the answer afterwards never counts toward Article 6.3.
class _CardRecallView extends ConsumerStatefulWidget {
  const _CardRecallView({super.key, required this.task});

  final CardTask task;

  @override
  ConsumerState<_CardRecallView> createState() => _CardRecallViewState();
}

class _CardRecallViewState extends ConsumerState<_CardRecallView>
    with _CardDwell<_CardRecallView> {
  final _onTask = Stopwatch()..start();

  bool _answered = false;
  bool _claimedCorrect = false;
  bool _revealed = false;
  int _msAtChoice = 0;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    if (_answered) {
      return Padding(
        padding: LunioSpacing.page,
        child: _StudyBeat(
          front: widget.task.front,
          back: widget.task.back,
          // Article 6.1 still governs the star here — a revealed card earns
          // nothing — but what is *said* about it stays kind.
          note: switch ((_claimedCorrect, _revealed)) {
            (true, _) => l10n.cardRemembered,
            (false, true) => l10n.cardRevealedNote,
            (false, false) => l10n.cardNotYet,
          },
          positive: _claimedCorrect,
          dwellLeft: dwellLeft,
          dwellSpent: dwellSpent,
          submitting: _submitting,
          onContinue: _submit,
        ),
      );
    }

    return Padding(
      padding: LunioSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Illustration.cardBook.show(size: 110),
                    const SizedBox(height: LunioSpacing.m),
                    Text(
                      widget.task.front,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => _choose(correct: true, revealed: false),
            child: Text(l10n.cardIKnewIt),
          ),
          const SizedBox(height: LunioSpacing.s),
          OutlinedButton(
            onPressed: () => _choose(correct: false, revealed: false),
            child: Text(l10n.cardIDidNot),
          ),
          const SizedBox(height: LunioSpacing.s),
          TextButton(
            onPressed: () => _choose(correct: false, revealed: true),
            child: Text(l10n.cardShowAnswer),
          ),
        ],
      ),
    );
  }

  /// The choice is recorded and the clock stops here, but nothing is submitted
  /// until the child has seen the answer and moved on — so reading the back is
  /// never mistaken for thinking about the front.
  void _choose({required bool correct, required bool revealed}) {
    _onTask.stop();
    setState(() {
      _answered = true;
      _claimedCorrect = correct;
      _revealed = revealed;
      _msAtChoice = _onTask.elapsedMilliseconds;
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await ref
        .read(sessionControllerProvider.notifier)
        .answer(
          task: widget.task,
          correct: _claimedCorrect,
          msOnTarget: _msAtChoice,
          solutionRevealed: _revealed,
        );
  }
}

/// A memorization card, answered by choosing.
///
/// Requested by the client on 2026-08-30 — «و تكون البطاقات فقط خيارات» — and
/// it makes Article 6 stricter rather than looser. The recall card above asks
/// the child to grade themselves, and a self-report is fully exploitable: tap
/// «أعرفها» on every card and every star in the table is earned without reading
/// anything. Article 6.1 pays for an answer "correct on the first attempt", and
/// a claim is not an answer. See [CardChoices] for the rest of the reasoning
/// and for where the wrong options come from.
///
/// **Nothing here calls the child wrong.** The client asked for that on
/// 2026-08-29 and the reason holds just as well now that there is a right and
/// a wrong button to press: this is the memorize step, not the exam. A card the
/// child missed shows the right answer in green, says «لا بأس», and comes back
/// sooner — the star is withheld by the engine, silently, exactly as Article
/// 6.1 requires. The child's own wrong pick is left unmarked; marking it with a
/// red cross would tell them something they already know in the one place the
/// app is supposed to be teaching.
class _CardChoiceView extends ConsumerStatefulWidget {
  const _CardChoiceView({super.key, required this.task});

  final CardTask task;

  @override
  ConsumerState<_CardChoiceView> createState() => _CardChoiceViewState();
}

class _CardChoiceViewState extends ConsumerState<_CardChoiceView>
    with _CardDwell<_CardChoiceView> {
  final _onTask = Stopwatch()..start();

  int? _chosen;
  bool _submitting = false;

  bool get _answered => _chosen != null;
  bool get _wasRight => _chosen == widget.task.options.correctIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    final choices = widget.task.options.choices;

    if (_answered) {
      // The choice list is gone by now, deliberately. Once the answer is known
      // the child should be looking at the card, not at three options they are
      // no longer choosing between — and a list with one green row is feedback,
      // not something anybody memorises.
      return Padding(
        padding: LunioSpacing.page,
        child: _StudyBeat(
          front: widget.task.front,
          back: widget.task.back,
          // Never «إجابة خاطئة» on a memorisation card.
          note: _wasRight ? l10n.cardRemembered : l10n.cardNotYet,
          positive: _wasRight,
          dwellLeft: dwellLeft,
          dwellSpent: dwellSpent,
          submitting: _submitting,
          onContinue: _submit,
        ),
      );
    }

    return Padding(
      padding: LunioSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Illustration.cardBook.show(size: 86),
          const SizedBox(height: LunioSpacing.s),
          Text(
            widget.task.front,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: LunioSpacing.xs),
          Text(
            l10n.cardPickAnswer,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: LunioTheme.ink.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: LunioSpacing.m),
          Expanded(
            child: ListView.separated(
              itemCount: choices.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: LunioSpacing.s),
              itemBuilder: (context, index) => _Choice(
                text: choices[index],
                state: _ChoiceState.idle,
                onTap: () => _choose(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The clock stops at the tap. Article 6.3 measures the time spent deciding,
  /// and the seconds spent afterwards reading the right answer are not that.
  void _choose(int index) {
    _onTask.stop();
    setState(() => _chosen = index);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await ref
        .read(sessionControllerProvider.notifier)
        .answer(
          task: widget.task,
          correct: _wasRight,
          msOnTarget: _onTask.elapsedMilliseconds,
          // There is no reveal button on this card, so Article 6.1's "and none
          // after the solution was revealed" cannot be triggered here. The
          // clause still governs the recall card above.
          solutionRevealed: false,
        );
  }
}

/// A multiple-choice review question.
class _QuestionView extends ConsumerStatefulWidget {
  const _QuestionView({super.key, required this.task});

  final QuestionTask task;

  @override
  ConsumerState<_QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends ConsumerState<_QuestionView> {
  final _onTask = Stopwatch()..start();
  int? _chosen;
  bool _submitting = false;

  bool get _answered => _chosen != null;
  bool get _wasRight => _chosen == widget.task.correctIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: LunioSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_answered) ...[
            Illustration.cardQuestion.show(size: 86),
            const SizedBox(height: LunioSpacing.s),
          ],
          // A repeat announces itself. Without this the section simply grows by
          // one and the child — and the person testing — concludes the missed
          // question never came back. Reported exactly that way on 2026-08-31,
          // when it had come back and been answered.
          if (widget.task.isRepeat) ...[
            Align(
              alignment: AlignmentDirectional.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LunioSpacing.m,
                  vertical: LunioSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: LunioTheme.tintSky,
                  borderRadius: BorderRadius.circular(LunioRadius.button),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: LunioSpacing.xs),
                    Text(
                      l10n.questionAgain,
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: LunioSpacing.s),
          ],
          Text(
            widget.task.prompt,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: LunioSpacing.m),
          Expanded(
            child: ListView.separated(
              itemCount: widget.task.choices.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: LunioSpacing.s),
              itemBuilder: (context, index) => _Choice(
                text: widget.task.choices[index],
                state: _stateOf(index),
                // Locked once answered: the marking is the answer, and a second
                // tap would either change a recorded result or do nothing
                // visible. Both are worse than a disabled button.
                onTap: _answered ? null : () => _choose(index),
              ),
            ),
          ),

          // **The child is told what was right before moving on.**
          //
          // The screen used to submit on tap and advance immediately, so a wrong
          // answer taught nothing at all — the child saw only that the question
          // had gone. Article 2 calls this the review step; a review that never
          // shows the answer is just a scoreboard.
          if (_answered) ...[
            const SizedBox(height: LunioSpacing.m),
            Container(
              padding: const EdgeInsets.all(LunioSpacing.m),
              decoration: BoxDecoration(
                color: _wasRight ? LunioTheme.tintMint : LunioTheme.tintPeach,
                borderRadius: BorderRadius.circular(LunioRadius.card),
              ),
              child: Row(
                children: [
                  Icon(
                    _wasRight ? Icons.check_circle : Icons.lightbulb_outline,
                    color: _wasRight ? LunioTheme.play : LunioTheme.celebrate,
                  ),
                  const SizedBox(width: LunioSpacing.s),
                  Expanded(
                    child: Text(
                      _wasRight ? l10n.questionRight : l10n.questionShowsAnswer,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LunioSpacing.m),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(l10n.continueAction),
            ),
          ],
        ],
      ),
    );
  }

  _ChoiceState _stateOf(int index) {
    if (!_answered) return _ChoiceState.idle;
    if (index == widget.task.correctIndex) return _ChoiceState.correct;
    if (index == _chosen) return _ChoiceState.chosenWrong;
    return _ChoiceState.idle;
  }

  /// The clock stops at the tap, not at the submit.
  ///
  /// Article 6.3 measures time spent *on the question*, and the seconds a child
  /// spends reading why they were wrong are not thinking time. Recording them
  /// would let a slow reader clear the 1.5 s minimum without having engaged.
  void _choose(int index) {
    _onTask.stop();
    setState(() => _chosen = index);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await ref
        .read(sessionControllerProvider.notifier)
        .answer(
          task: widget.task,
          correct: _wasRight,
          msOnTarget: _onTask.elapsedMilliseconds,
        );
  }
}

enum _ChoiceState { idle, correct, chosenWrong }

/// One answer button, before and after the reveal.
///
/// Colour is never the only signal: each state carries an icon too. A child who
/// cannot separate the green from the orange still sees a tick and a dot, which
/// costs nothing and is the difference between usable and not.
class _Choice extends StatelessWidget {
  const _Choice({required this.text, required this.state, required this.onTap});

  final String text;
  final _ChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (background, border, icon, iconColour) = switch (state) {
      _ChoiceState.correct => (
        LunioTheme.tintMint,
        LunioTheme.play,
        Icons.check_circle,
        LunioTheme.play,
      ),
      _ChoiceState.chosenWrong => (
        LunioTheme.tintPeach,
        LunioTheme.celebrate,
        Icons.cancel_outlined,
        LunioTheme.celebrate,
      ),
      _ChoiceState.idle => (null, null, null, null),
    };

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: background,
        side: border == null ? null : BorderSide(color: border, width: 2),
        // Disabled buttons dim their label by default, which would grey out the
        // right answer at the exact moment it needs to be readable.
        disabledForegroundColor: LunioTheme.ink,
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
          if (icon != null) Icon(icon, color: iconColour, size: 22),
        ],
      ),
    );
  }
}

class _SessionFinished extends ConsumerWidget {
  const _SessionFinished({required this.empty, required this.dayComplete});

  /// There was nothing here in the first place — a different message from
  /// having finished something, and the one case where a balance would be
  /// meaningless.
  final bool empty;

  final bool dayComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    final earned = ref.watch(todayProgressProvider).value?.balanceUnits ?? 0;

    return Padding(
      padding: LunioSpacing.page,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Illustration.starBig.show(size: 140),
          const SizedBox(height: LunioSpacing.m),
          Text(
            switch ((empty, dayComplete)) {
              (true, _) => l10n.noTasksYet,
              (false, true) => l10n.sessionComplete,
              (false, false) => l10n.sectionComplete,
            },
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          if (!empty) ...[
            const SizedBox(height: LunioSpacing.s),
            Text(
              '${l10n.starsBalance}: ${Fmt.stars(earned)}',
              style: theme.textTheme.titleMedium,
            ),
          ],
          const SizedBox(height: LunioSpacing.xl),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(l10n.continueAction),
          ),
        ],
      ),
    );
  }
}
