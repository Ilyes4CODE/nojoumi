import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojoumi_stars/nojoumi_stars.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../session/session_screen.dart';

/// What the child sees.
///
/// The whole contract is a motivation instrument (Art. 1), and this is the
/// instrument's face. Three things are on it and nothing else: **how many stars
/// I have**, **how much play time that buys**, and **what I can do right now to
/// get more**. Everything a parent needs lives behind a PIN on another screen.
///
/// Deliberately absent, and each absence is a contract requirement:
///
///  * no price, no buy button, no payment link anywhere (Art. 7.2);
///  * no punishment surface — a locked game shows what it costs, never a scold,
///    because the appendix's stated principle is that the system withholds a
///    reward rather than inflicting a penalty;
///  * nothing about the subscription, which is the parent's business and must
///    never reach the child (Art. 7.1).
class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    final progress = ref.watch(todayProgressProvider);
    final rules = ref.watch(starRulesProvider);
    final clockOk = ref.watch(clockIsTrustworthyProvider);
    final paused = ref.watch(settingsProvider).value?.playPaused ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(trustedNowProvider.notifier).refresh(),
        child: ListView(
          padding: NojoumiSpacing.page,
          children: [
            if (!clockOk) const _ClockUntrustedCard(),
            _BalanceCard(
              progress: progress.value,
              rules: rules.value,
              paused: paused,
            ),
            const SizedBox(height: NojoumiSpacing.l),
            _TasksCard(progress: progress.value),
          ],
        ),
      ),
    );
  }
}

/// Article 6.8 made visible.
///
/// Without this the app looks broken: the child answers correctly and nothing
/// happens. Saying why, in the child's language, and saying plainly that the
/// stars already earned are safe, is the difference between a rule and a bug.
class _ClockUntrustedCard extends StatelessWidget {
  const _ClockUntrustedCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      margin: const EdgeInsets.only(bottom: NojoumiSpacing.m),
      child: Padding(
        padding: const EdgeInsets.all(NojoumiSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: scheme.onErrorContainer),
                const SizedBox(width: NojoumiSpacing.s),
                Expanded(
                  child: Text(
                    l10n.clockUntrustedTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: NojoumiSpacing.s),
            Text(
              l10n.clockUntrustedBody,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}

/// The balance and what it buys.
///
/// Play time is shown as `mm:ss` rather than rounded minutes because the star
/// value may be half a minute (appendix §5), so half a star is thirty seconds
/// and rounding it to "1 minute" would be a lie the child can measure.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.progress,
    required this.rules,
    required this.paused,
  });

  final DayProgress? progress;
  final StarRules? rules;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    final units = progress?.balanceUnits ?? 0;
    final seconds =
        (rules == null || progress == null) ? 0 : progress!.remainingPlaySeconds(rules!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(NojoumiSpacing.l),
        child: Column(
          children: [
            Text(l10n.starsBalance, style: theme.textTheme.titleMedium),
            const SizedBox(height: NojoumiSpacing.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded,
                    color: NojoumiTheme.star, size: 44),
                const SizedBox(width: NojoumiSpacing.s),
                Text(
                  _formatStars(units),
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: NojoumiSpacing.xl),
            Text(l10n.playTimeRemaining, style: theme.textTheme.titleSmall),
            const SizedBox(height: NojoumiSpacing.xs),
            Text(
              _formatDuration(seconds),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: seconds > 0 ? NojoumiTheme.play : NojoumiTheme.blocked,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (paused) ...[
              const SizedBox(height: NojoumiSpacing.s),
              Text(
                l10n.playPausedByParent,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Half stars are real (Art. 5), so "3.5" must be representable — but "4.0"
  /// must not be, because a whole number written with a decimal point reads as
  /// an approximation of something.
  static String _formatStars(int units) {
    final whole = units ~/ starUnit;
    final remainder = units % starUnit;
    if (remainder == 0) return '$whole';
    return (units / starUnit).toStringAsFixed(1);
  }

  static String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Today's session, and the way into it.
class _TasksCard extends StatelessWidget {
  const _TasksCard({required this.progress});

  final DayProgress? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    final total = progress?.tasksTotal ?? 0;
    final answered = progress?.tasksAnswered ?? 0;
    final remaining = total - answered;

    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(NojoumiSpacing.l),
          child: Column(
            children: [
              const Icon(Icons.menu_book_outlined, size: 40),
              const SizedBox(height: NojoumiSpacing.s),
              Text(
                l10n.noTasksYet,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(NojoumiSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.todayTasks, style: theme.textTheme.titleMedium),
            const SizedBox(height: NojoumiSpacing.m),
            LinearProgressIndicator(
              value: total == 0 ? 0 : answered / total,
              minHeight: 10,
              borderRadius: BorderRadius.circular(NojoumiRadius.button),
            ),
            const SizedBox(height: NojoumiSpacing.m),
            Text(
              remaining > 0
                  ? l10n.tasksRemaining('$remaining')
                  : l10n.sessionComplete,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: NojoumiSpacing.m),
            FilledButton(
              onPressed: remaining > 0
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SessionScreen(),
                        ),
                      )
                  : null,
              child: Text(l10n.startSession),
            ),
          ],
        ),
      ),
    );
  }
}
