import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/illustrations.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/repositories/weekly_test_repository.dart';
import '../../l10n/app_localizations.dart';

/// The weekly test — Article 4.8 and Article 5's 10–40 scale.
///
/// Deliberately calmer than the daily session. No mascot beside the question, no
/// confetti between answers, no running score: this is the one moment in the app
/// where the child is being measured rather than encouraged, and dressing it up
/// would make the measurement feel like a game they can lose.
///
/// What follows it is not optional. Article 14 deletes the week's images and
/// exercises immediately afterwards, and the screen says so — the deletion is a
/// promise the client will be asked about, and one nobody can see being kept is
/// worth less than one they can.
class WeeklyTestScreen extends ConsumerStatefulWidget {
  const WeeklyTestScreen({super.key});

  @override
  ConsumerState<WeeklyTestScreen> createState() => _WeeklyTestScreenState();
}

class _WeeklyTestScreenState extends ConsumerState<WeeklyTestScreen> {
  List<WeeklyQuestion>? _questions;
  int? _testId;
  int _index = 0;
  WeeklyTestResult? _result;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  Future<void> _begin() async {
    final day = ref.read(todayProvider).value;
    if (day == null) return;

    final repository = ref.read(weeklyTestRepositoryProvider);
    final questions = await repository.buildTest(today: day);
    if (questions.isEmpty || !mounted) {
      if (mounted) setState(() => _questions = const []);
      return;
    }

    final now = await ref.read(trustedNowProvider.notifier).refresh();
    final id = await repository.start(today: day, now: now);
    if (!mounted) return;
    setState(() {
      _questions = questions;
      _testId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final questions = _questions;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weeklyTest),
        automaticallyImplyLeading: _result != null,
      ),
      body: SafeArea(
        child: switch (null) {
          _ when _result != null => _Result(result: _result!),
          _ when questions == null => const Center(
            child: CircularProgressIndicator(),
          ),
          _ when questions.isEmpty => _Empty(message: l10n.lessonsEmpty),
          _ => _Question(
            key: ValueKey(_index),
            question: questions[_index],
            position: _index + 1,
            total: questions.length,
            enabled: !_busy,
            onAnswer: _answer,
          ),
        },
      ),
    );
  }

  Future<void> _answer(bool correct) async {
    final questions = _questions;
    final testId = _testId;
    final day = ref.read(todayProvider).value;
    if (questions == null || testId == null || day == null) return;

    setState(() => _busy = true);
    final repository = ref.read(weeklyTestRepositoryProvider);
    final now = await ref.read(trustedNowProvider.notifier).refresh();

    await repository.recordAnswer(
      testId: testId,
      question: questions[_index],
      correct: correct,
      now: now,
    );
    if (_index + 1 < questions.length) {
      if (mounted) {
        setState(() {
          _index++;
          _busy = false;
        });
      }
      return;
    }

    // The last answer closes the test, pays the scale and runs the purge, in that
    // order — see WeeklyTestRepository.finish for why the order is the contract's.
    final result = await repository.finish(
      testId: testId,
      today: day,
      now: now,
    );
    if (mounted) {
      setState(() {
        _result = result;
        _busy = false;
      });
    }
  }
}

class _Question extends StatefulWidget {
  const _Question({
    super.key,
    required this.question,
    required this.position,
    required this.total,
    required this.enabled,
    required this.onAnswer,
  });

  final WeeklyQuestion question;
  final int position;
  final int total;
  final bool enabled;
  final ValueChanged<bool> onAnswer;

  @override
  State<_Question> createState() => _QuestionState();
}

class _QuestionState extends State<_Question> {
  int? _chosen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: LunioSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: widget.position / widget.total,
            minHeight: 8,
            borderRadius: BorderRadius.circular(LunioRadius.button),
          ),
          const SizedBox(height: LunioSpacing.xs),
          Text(
            '${widget.position} / ${widget.total}',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: LunioSpacing.xl),
          Text(
            widget.question.prompt,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: LunioSpacing.xl),
          Expanded(
            child: ListView.separated(
              itemCount: widget.question.choices.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: LunioSpacing.s),
              itemBuilder: (context, index) {
                final selected = _chosen == index;
                return OutlinedButton(
                  onPressed: widget.enabled
                      ? () {
                          setState(() => _chosen = index);
                          widget.onAnswer(
                            index == widget.question.correctIndex,
                          );
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected ? LunioTheme.tintLavender : null,
                  ),
                  child: Text(widget.question.choices[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The score, the stars, and what was deleted.
class _Result extends StatelessWidget {
  const _Result({required this.result});

  final WeeklyTestResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      padding: LunioSpacing.page,
      children: [
        Center(child: Illustration.starBig.show(size: 140)),
        const SizedBox(height: LunioSpacing.l),
        Text(
          l10n.weeklyTestResult(result.percent.toStringAsFixed(0)),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: LunioSpacing.s),
        Text(
          '${result.correct} / ${result.total}',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: LunioTheme.ink.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: LunioSpacing.l),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.star_rounded,
              color: LunioTheme.star,
              size: 34,
            ),
            title: Text(
              '${Fmt.stars(result.awardedUnits)} ${l10n.starsUnit}',
              style: theme.textTheme.titleLarge,
            ),
          ),
        ),
        const SizedBox(height: LunioSpacing.l),

        // Article 14's deletion, said out loud.
        Card(
          color: LunioTheme.tintLavender,
          child: Padding(
            padding: const EdgeInsets.all(LunioSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_delete_outlined),
                    const SizedBox(width: LunioSpacing.s),
                    Expanded(
                      child: Text(
                        l10n.purgeDoneTitle,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LunioSpacing.s),
                Text(l10n.purgeDoneBody, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),

        const SizedBox(height: LunioSpacing.xl),
        FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l10n.continueAction),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: LunioSpacing.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Illustration.astronaut.show(size: 140),
            const SizedBox(height: LunioSpacing.l),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
