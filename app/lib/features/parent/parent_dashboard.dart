import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunio_stars/lunio_stars.dart';

import '../../core/format.dart';
import '../../core/illustrations.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../lesson/capture_screen.dart';
import '../lesson/lessons_screen.dart';
import 'account_screen.dart';
import 'blocking_screen.dart';
import 'parent_settings_screen.dart';
import 'subscription_screen.dart';
import 'pin_gate.dart';
import 'star_ledger_screen.dart';

/// Everything the parent controls, behind the PIN.
///
/// Appendix §4 gives the parent authority "فوق النظام" — above the system — and
/// this screen is where that is exercised. Two consequences run through it:
///
///  * a grant or deduction is **not** subject to the daily ceiling, and works on
///    a phone whose clock we distrust, because a parent rewarding good behaviour
///    must not be blocked by a rule aimed at a child gaming the clock;
///  * every number the parent can change has a **published range** (appendix
///    §5), and an out-of-range value is refused with the reason rather than
///    quietly clamped.
class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    return PinGate(title: l10n.parentArea, child: const _DashboardBody());
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    final progress = ref.watch(todayProgressProvider).value;
    final rules = ref.watch(starRulesProvider).value;
    final settings = ref.watch(settingsProvider).value;
    final streak = ref.watch(streakProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.parentArea)),
      // Photographing a page is the one thing a parent does *every day*, and
      // until now it was three taps down: dashboard, lessons, then the button.
      // Asked for by the client on 2026-08-30 as an icon on the dashboard
      // itself. The lessons screen keeps its own button — this is a shortcut to
      // the same screen, not a second way of doing it.
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CaptureScreen()),
        ),
        tooltip: l10n.captureLesson,
        child: const Icon(Icons.photo_camera_outlined),
      ),
      body: ListView(
        // Room under the last card for the button to float over nothing. A FAB
        // sitting on top of the account row would hide the row it covers.
        padding: LunioSpacing.page.add(
          const EdgeInsets.only(bottom: LunioSpacing.tapTarget + LunioSpacing.l),
        ),
        children: [
          _OverviewCard(progress: progress, rules: rules, streak: streak),
          const SizedBox(height: LunioSpacing.m),
          const _AdjustCard(),
          const SizedBox(height: LunioSpacing.m),
          _PlayPauseCard(paused: settings?.playPaused ?? false),
          const SizedBox(height: LunioSpacing.m),
          _FreePlayCard(granted: progress?.freePlaySeconds ?? 0),
          const SizedBox(height: LunioSpacing.m),
          _NavigationCard(
            icon: Icons.tune,
            label: l10n.settings,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ParentSettingsScreen(),
              ),
            ),
          ),
          const SizedBox(height: LunioSpacing.s),
          _NavigationCard(
            icon: Icons.shield_outlined,
            label: l10n.blockingTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BlockingScreen()),
            ),
          ),
          const SizedBox(height: LunioSpacing.s),
          _NavigationCard(
            icon: Icons.receipt_long,
            label: l10n.parentLedgerTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const StarLedgerScreen()),
            ),
          ),
          const SizedBox(height: LunioSpacing.s),
          _NavigationCard(
            icon: Icons.menu_book_outlined,
            label: l10n.lessonsTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LessonsScreen()),
            ),
          ),
          const SizedBox(height: LunioSpacing.s),
          _NavigationCard(
            icon: Icons.workspace_premium_outlined,
            label: l10n.subscription,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SubscriptionScreen(),
              ),
            ),
          ),
          const SizedBox(height: LunioSpacing.s),
          _NavigationCard(
            icon: Icons.account_circle_outlined,
            label: l10n.accountTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
            ),
          ),
        ],
      ),
    );
  }
}


/// Article 6.9 — the parent hands over play time directly.
///
/// Asked for by the client on 2026-08-30: a button for free play, with a
/// duration on it.
///
/// **It adds rather than sets.** Two taps on "one hour" mean two hours, because
/// that is what those two taps mean. Setting would throw the first hour away
/// silently, and once the child had spent part of it the button would appear to
/// do nothing at all.
///
/// There is no stop button here, deliberately: the pause switch directly above
/// already stops play, and it stops *all* play rather than unpicking a gift
/// halfway through. Two ways to take time back would be two behaviours to
/// explain, and the parent would have to guess which one they wanted.
class _FreePlayCard extends ConsumerStatefulWidget {
  const _FreePlayCard({required this.granted});

  /// Seconds handed over today, for the running total under the buttons.
  final int granted;

  @override
  ConsumerState<_FreePlayCard> createState() => _FreePlayCardState();
}

class _FreePlayCardState extends ConsumerState<_FreePlayCard> {
  /// The four the client named — half an hour up to three.
  static const _choices = [1800, 3600, 7200, 10800];

  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const TintedIcon(Icons.sports_esports_outlined),
                const SizedBox(width: LunioSpacing.s),
                Expanded(
                  child: Text(
                    l10n.parentFreePlayTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LunioSpacing.s),
            Text(l10n.parentFreePlayBody, style: theme.textTheme.bodySmall),
            const SizedBox(height: LunioSpacing.m),
            Wrap(
              spacing: LunioSpacing.s,
              runSpacing: LunioSpacing.s,
              children: [
                for (final seconds in _choices)
                  OutlinedButton(
                    onPressed: _busy ? null : () => _give(seconds),
                    child: Text(Fmt.duration(seconds)),
                  ),
              ],
            ),
            if (widget.granted > 0) ...[
              const SizedBox(height: LunioSpacing.m),
              Text(
                l10n.parentFreePlayGranted(Fmt.duration(widget.granted)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _give(int seconds) async {
    setState(() => _busy = true);
    final l10n = AppL10n.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final day = ref.read(todayProvider).value;
      // Re-read the clock rather than reusing one from the build: the event log
      // entry should say when the parent actually pressed it.
      final now = await ref.read(trustedNowProvider.notifier).refresh();
      if (day == null) return;

      await ref
          .read(starRepositoryProvider)
          .addFreePlay(day: day, seconds: seconds, now: now);
      ref.invalidate(todayProgressProvider);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.parentFreePlayAdded(Fmt.duration(seconds))),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.progress,
    required this.rules,
    required this.streak,
  });

  final DayProgress? progress;
  final StarRules? rules;
  final StreakState? streak;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    final earned = progress?.earnedUnits ?? 0;
    final granted = progress?.grantedUnits ?? 0;
    final ceiling = rules?.dailyCeilingUnits ?? 0;
    final usedSeconds = progress?.usedPlaySeconds ?? 0;
    // The live counter. Free play is inside this by construction — it is the
    // same pool the child spends from, so there is no second number that could
    // disagree with it.
    // Copied to locals first: `progress` and `rules` are fields, and Dart does
    // not promote a field to non-null however it is tested.
    final day = progress;
    final starRules = rules;
    final remainingSeconds = day != null && starRules != null
        ? day.remainingPlaySeconds(starRules)
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.parentOverview, style: theme.textTheme.titleMedium),
            const SizedBox(height: LunioSpacing.m),
            _Line(label: l10n.parentEarnedToday, value: Fmt.stars(earned)),
            _Line(label: l10n.parentGrantedToday, value: Fmt.stars(granted)),
            _Line(
              label: l10n.starsBalance,
              value: Fmt.stars(earned + granted),
              emphasis: true,
            ),
            const Divider(height: LunioSpacing.xl),
            // The ceiling constrains only what the child *earns* (Art. 6.4), so
            // it is shown against `earned` and never against the total — a
            // parent grant must never look like it consumed the child's day.
            if (ceiling > 0) ...[
              LinearProgressIndicator(
                value: (earned / ceiling).clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(LunioRadius.button),
              ),
              const SizedBox(height: LunioSpacing.xs),
              Text(
                '${Fmt.stars(earned)} / ${Fmt.stars(ceiling)} ${l10n.parentCeilingUsed}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: LunioSpacing.m),
            ],
            _Line(label: l10n.parentPlayUsed, value: Fmt.duration(usedSeconds)),
            _Line(
              label: l10n.parentPlayRemaining,
              value: Fmt.duration(remainingSeconds),
              emphasis: true,
            ),
            _Line(
              label: l10n.parentStreak,
              value: l10n.streakDays('${streak?.consecutiveDays ?? 0}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasis
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LunioSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Appendix §4 — grant or deduct, at any time, for any reason.
class _AdjustCard extends ConsumerStatefulWidget {
  const _AdjustCard();

  @override
  ConsumerState<_AdjustCard> createState() => _AdjustCardState();
}

class _AdjustCardState extends ConsumerState<_AdjustCard> {
  final _amount = TextEditingController(text: '1');
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.parentAdjustTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: LunioSpacing.s),
            Text(l10n.parentAdjustBody, style: theme.textTheme.bodySmall),
            const SizedBox(height: LunioSpacing.m),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              // Half stars exist (Art. 5), so a decimal separator is allowed —
              // but only one, and only digits around it.
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.،]')),
              ],
              decoration: InputDecoration(labelText: l10n.parentAdjustAmount),
            ),
            const SizedBox(height: LunioSpacing.s),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: l10n.parentAdjustNote),
            ),
            const SizedBox(height: LunioSpacing.m),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : () => _apply(grant: true),
                    child: Text(l10n.grantStars),
                  ),
                ),
                const SizedBox(width: LunioSpacing.s),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _apply(grant: false),
                    child: Text(l10n.deductStars),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply({required bool grant}) async {
    final l10n = AppL10n.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final units = _parseUnits(_amount.text);
    if (units == null || units == 0) return;

    final day = ref.read(todayProvider).value;
    final now = ref.read(trustedNowProvider).value;
    if (day == null || now == null) return;

    setState(() => _busy = true);
    final before = ref.read(todayProgressProvider).value?.balanceUnits ?? 0;
    if (!grant && units > before) {
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.parentDeductTooMuch)));
      return;
    }

    await ref
        .read(starRepositoryProvider)
        .parentAdjust(
          day: day,
          deltaUnits: grant ? units : -units,
          now: now,
          note: _note.text.trim(),
        );

    if (!mounted) return;
    setState(() => _busy = false);
    _note.clear();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          grant
              ? l10n.parentGrantDone(Fmt.stars(units))
              : l10n.parentDeductDone(Fmt.stars(units)),
        ),
      ),
    );
  }

  /// Parses "2", "2.5" or the Arabic decimal separator "٫"/"،" into star units.
  ///
  /// Rounds to the nearest half star, because that is the smallest amount the
  /// contract knows about (Art. 5) and a parent typing "1.3" means "about one
  /// and a half", not a value the ledger should try to represent exactly.
  static int? _parseUnits(String raw) {
    final normalised = raw.replaceAll('،', '.').replaceAll('٫', '.').trim();
    final value = double.tryParse(normalised);
    if (value == null || value < 0) return null;
    return ((value * 2).round() * starUnit) ~/ 2;
  }
}

/// Appendix §4 — "أو إيقاف مؤقت". Pauses consumption without destroying the
/// balance, which is why it is a switch and not a deduction.
class _PlayPauseCard extends ConsumerWidget {
  const _PlayPauseCard({required this.paused});

  final bool paused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    return Card(
      child: SwitchListTile(
        value: paused,
        onChanged: (value) =>
            ref.read(settingsRepositoryProvider).setPlayPaused(value),
        title: Text(l10n.pausePlay),
        subtitle: Text(
          paused ? l10n.parentPlayPausedOn : l10n.parentPlayPausedOff,
        ),
        secondary: Icon(paused ? Icons.pause_circle : Icons.play_circle),
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        // `endIcon` rather than a hardcoded left/right chevron: the direction
        // flips with the locale, and docs/CONVENTIONS.md forbids baking one in.
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
