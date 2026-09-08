import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunio_stars/lunio_stars.dart';

import '../../core/format.dart';
import '../../core/illustrations.dart';
import '../../core/providers.dart';
import '../../data/repositories/session_repository.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../parent/parent_dashboard.dart';
import 'balance_card.dart';
import '../session/session_controller.dart';
import '../session/lesson_picker_screen.dart';
import '../weekly/weekly_test_screen.dart';

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

    // **Watched here, and this is what makes the app work at all.**
    //
    // The day's tasks are created by `SessionRepository.sessionFor`, which runs
    // when this controller is first read. Until 2026-08-29 nothing on this
    // screen read it: the session was only built when the session *screen*
    // opened, and the button that opens it was disabled until the session had
    // been built. A parent could photograph two lessons and the child would be
    // told «لا توجد مهام بعد» for ever, with no way in — the cards were saved
    // correctly and simply unreachable.
    //
    // Reading it here breaks that circle: arriving at the home screen is what
    // creates the day.
    final session = ref.watch(sessionControllerProvider);
    final rules = ref.watch(starRulesProvider);
    final clockOk = ref.watch(clockIsTrustworthyProvider);
    final paused = ref.watch(settingsProvider).value?.playPaused ?? false;
    final weeklyDue = ref.watch(weeklyTestDueProvider).value ?? false;

    // Watching is what runs it. The welcome balance of appendix §5 is granted
    // on the first day the clock can be defended, not at the end of setup, so
    // this screen is where it lands — and the child is told, because ten stars
    // appearing with no explanation reads as a glitch.
    ref.listen<AsyncValue<int?>>(welcomeGrantProvider, (previous, next) {
      final units = next.value;
      if (units == null || units == 0) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.setupDoneBody(Fmt.stars(units)))),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          // The way in is deliberately plain and always visible. Hiding it
          // behind a long-press or a secret gesture would only mean the parent
          // cannot find it either — the PIN is the lock, not the doorway.
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: l10n.parentArea,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ParentDashboard()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(trustedNowProvider.notifier).refresh(),
        child: ListView(
          padding: LunioSpacing.page,
          children: [
            if (!clockOk) const _ClockUntrustedCard(),
            BalanceCard(
              progress: progress.value,
              rules: rules.value,
              paused: paused,
            ),
            const SizedBox(height: LunioSpacing.l),
            const _BlockingBrokenBanner(),
            _TasksCard(progress: progress.value, session: session.value),
            if (weeklyDue) ...[
              const SizedBox(height: LunioSpacing.l),
              _WeeklyTestCard(),
            ],
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
      margin: const EdgeInsets.only(bottom: LunioSpacing.m),
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: scheme.onErrorContainer),
                const SizedBox(width: LunioSpacing.s),
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
            const SizedBox(height: LunioSpacing.s),
            Text(
              l10n.clockUntrustedBody,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when blocking is switched on but is not actually running.
///
/// **The most dangerous state this app has**, and until 2026-08-30 it was also
/// the quietest. The parent turned blocking on, the switch says on, and nothing
/// is blocked and no play time is counted — because the accessibility service is
/// not bound. A parental-control app that believes it is guarding when it is not
/// is worse than one that is honestly off: the parent stops watching.
///
/// It is not a rare state. **Every app update clears the grant**, which during
/// development means every `flutter run`, and in production means every Play
/// update. Three separate rounds of "the counter does not work" turned out to
/// include this, and nothing on screen said so — the only place that showed it
/// was a row inside the parent's blocking screen, which nobody opens unless they
/// already suspect something.
///
/// So it is on the first screen, in a colour that is not the ordinary palette,
/// with the one action that fixes it.
class _BlockingBrokenBanner extends ConsumerWidget {
  const _BlockingBrokenBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    final settings = ref.watch(settingsProvider).value;
    final status = ref.watch(blockingStatusProvider).value;

    // Silent unless the parent asked for blocking *and* the engine is not there.
    // Blocking switched off is a legitimate state (Art. 15.2) and says nothing.
    final broken =
        (settings?.blockingEnabled ?? false) &&
        status != null &&
        status.available &&
        !status.accessibilityEnabled;
    if (!broken) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: LunioSpacing.m),
      child: Container(
        padding: const EdgeInsets.all(LunioSpacing.m),
        decoration: BoxDecoration(
          color: LunioTheme.tintPeach,
          borderRadius: BorderRadius.circular(LunioRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: LunioTheme.celebrate),
                const SizedBox(width: LunioSpacing.s),
                Expanded(
                  child: Text(
                    l10n.blockingNotRunningTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LunioSpacing.xs),
            Text(l10n.blockingNotRunningBody, style: theme.textTheme.bodySmall),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => ref
                    .read(blockingChannelProvider)
                    .openAccessibilitySettings(),
                child: Text(l10n.blockingNotRunningAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's session, and the way into it.
class _TasksCard extends StatelessWidget {
  const _TasksCard({required this.progress, required this.session});

  final DayProgress? progress;

  /// Today's task list, once built.
  ///
  /// Preferred over [progress] for the counts because it is the thing that was
  /// just created: `DayProgress` is updated by the same build, but through a
  /// separate stream, and on the first frame after a lesson is captured the
  /// session is right while the progress row is still catching up.
  final DailySession? session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    final total = session?.total ?? progress?.tasksTotal ?? 0;
    final answered = session?.answered ?? progress?.tasksAnswered ?? 0;
    final remaining = total - answered;

    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(LunioSpacing.l),
          child: Column(
            children: [
              Illustration.astronaut.show(size: 120),
              const SizedBox(height: LunioSpacing.s),
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
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.todayTasks, style: theme.textTheme.titleMedium),
            const SizedBox(height: LunioSpacing.m),
            LinearProgressIndicator(
              value: total == 0 ? 0 : answered / total,
              minHeight: 10,
              borderRadius: BorderRadius.circular(LunioRadius.button),
            ),
            const SizedBox(height: LunioSpacing.m),
            Text(
              remaining > 0
                  ? l10n.tasksRemaining('$remaining')
                  : l10n.sessionComplete,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: LunioSpacing.m),
            // The shelf, not the queue. Asked for by the client on
            // 2026-08-30: the child picks a lesson rather than being marched
            // through the day in one line. Article 6.5 still counts the day as
            // a whole — see LessonPickerScreen.
            FilledButton(
              onPressed: remaining > 0
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LessonPickerScreen(),
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

/// Article 4.8's moment, surfaced on the day it arrives.
///
/// Only on the parent's chosen weekday, only once a week, and only when the week
/// holds at least five cards (D-13). It appears below the day's tasks rather than
/// above them, because the daily session is still the thing that earns stars.
class _WeeklyTestCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return Card(
      color: LunioTheme.tintPeach,
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined, size: 32),
                const SizedBox(width: LunioSpacing.m),
                Expanded(
                  child: Text(
                    l10n.weeklyTestDue,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LunioSpacing.m),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WeeklyTestScreen(),
                ),
              ),
              child: Text(l10n.weeklyTestStart),
            ),
          ],
        ),
      ),
    );
  }
}
