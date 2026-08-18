import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojoumi_stars/nojoumi_stars.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
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
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

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
              padding: NojoumiSpacing.page,
              child: Text('$error', textAlign: TextAlign.center),
            ),
          ),
          data: (session) => _SessionBody(session: session),
        ),
      ),
    );
  }
}

class _SessionBody extends ConsumerWidget {
  const _SessionBody({required this.session});

  final DailySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    final task = session.next;

    if (task == null) {
      return _SessionFinished(session: session);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: NojoumiSpacing.m,
            vertical: NojoumiSpacing.s,
          ),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: session.total == 0 ? 0 : session.answered / session.total,
                minHeight: 8,
                borderRadius: BorderRadius.circular(NojoumiRadius.button),
              ),
              const SizedBox(height: NojoumiSpacing.xs),
              Text(
                l10n.tasksRemaining('${session.total - session.answered}'),
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
            CardTask() => _CardView(key: ValueKey(task.taskId), task: task),
            QuestionTask() =>
              _QuestionView(key: ValueKey(task.taskId), task: task),
          },
        ),
      ],
    );
  }
}

/// A memorization card.
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
class _CardView extends ConsumerStatefulWidget {
  const _CardView({super.key, required this.task});

  final CardTask task;

  @override
  ConsumerState<_CardView> createState() => _CardViewState();
}

class _CardViewState extends ConsumerState<_CardView> {
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

    return Padding(
      padding: NojoumiSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      widget.task.front,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    if (_answered) ...[
                      const Divider(height: NojoumiSpacing.xl),
                      Text(
                        widget.task.back,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: NojoumiSpacing.m),
                      Text(
                        _claimedCorrect
                            ? l10n.answerCorrect
                            : l10n.answerWrong,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (!_answered) ...[
            FilledButton(
              onPressed: () => _choose(correct: true, revealed: false),
              child: Text(l10n.cardIKnewIt),
            ),
            const SizedBox(height: NojoumiSpacing.s),
            OutlinedButton(
              onPressed: () => _choose(correct: false, revealed: false),
              child: Text(l10n.cardIDidNot),
            ),
            const SizedBox(height: NojoumiSpacing.s),
            TextButton(
              onPressed: () => _choose(correct: false, revealed: true),
              child: Text(l10n.cardShowAnswer),
            ),
          ] else
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(l10n.continueAction),
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
    await ref.read(sessionControllerProvider.notifier).answer(
          task: widget.task,
          correct: _claimedCorrect,
          msOnTarget: _msAtChoice,
          solutionRevealed: _revealed,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: NojoumiSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.task.prompt,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: NojoumiSpacing.l),
          Expanded(
            child: ListView.separated(
              itemCount: widget.task.choices.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: NojoumiSpacing.s),
              itemBuilder: (context, index) {
                final selected = _chosen == index;
                return OutlinedButton(
                  onPressed: _submitting ? null : () => _choose(index),
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        selected ? theme.colorScheme.primaryContainer : null,
                  ),
                  child: Text(widget.task.choices[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _choose(int index) async {
    setState(() {
      _chosen = index;
      _submitting = true;
    });
    _onTask.stop();
    await ref.read(sessionControllerProvider.notifier).answer(
          task: widget.task,
          correct: index == widget.task.correctIndex,
          msOnTarget: _onTask.elapsedMilliseconds,
        );
  }
}

class _SessionFinished extends ConsumerWidget {
  const _SessionFinished({required this.session});

  final DailySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    final earned = ref.watch(todayProgressProvider).value?.balanceUnits ?? 0;

    return Padding(
      padding: NojoumiSpacing.page,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, size: 72, color: NojoumiTheme.star),
          const SizedBox(height: NojoumiSpacing.m),
          Text(
            session.total == 0 ? l10n.noTasksYet : l10n.sessionComplete,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          if (session.total > 0) ...[
            const SizedBox(height: NojoumiSpacing.s),
            Text(
              '${l10n.starsBalance}: ${unitsToStars(earned)}',
              style: theme.textTheme.titleMedium,
            ),
          ],
          const SizedBox(height: NojoumiSpacing.xl),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(l10n.continueAction),
          ),
        ],
      ),
    );
  }
}
