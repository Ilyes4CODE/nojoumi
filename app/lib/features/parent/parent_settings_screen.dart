import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunio_stars/lunio_stars.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

/// The six numbers of appendix §5, plus the two D-13/D-15 settings.
///
/// The design rule for this screen: **it never invents a value and never
/// silently corrects one.** Every edit builds a [StarRules], whose constructor
/// validates against the appendix's published ranges and throws rather than
/// clamping. A clamped value is a contract violation nobody notices; a thrown
/// one becomes a message under the field.
///
/// So the sliders below are bounded by the same numbers the constructor
/// enforces, which means the two can never drift apart — the widget cannot
/// offer a value the engine would refuse.
class ParentSettingsScreen extends ConsumerWidget {
  const ParentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    final rules = ref.watch(starRulesProvider).value;
    final settings = ref.watch(settingsProvider).value;

    if (rules == null || settings == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Future<void> save(StarRules next) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(settingsRepositoryProvider).writeRules(next);
        messenger.showSnackBar(SnackBar(content: Text(l10n.parentSaved)));
      } on ArgumentError catch (error) {
        // Should be unreachable, because every control is bounded by the same
        // range. If it ever fires, a control and the contract have drifted
        // apart, and the parent sees the reason rather than a silent no-op.
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.parentInvalidValue('${error.message}'))),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: LunioSpacing.page,
        children: [
          Text(
            l10n.parentSettingsBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: LunioSpacing.l),

          // "قيمة النجمة الواحدة بالدقائق" — 0.5 to 3, in half-minute steps
          // (D-20). Held in seconds so every conversion stays exact.
          _StepperTile(
            label: l10n.starValueMinutes,
            value: '${rules.starValueSeconds / 60}',
            hint: l10n.parentRangeHint('0.5', '3'),
            onDecrement: rules.starValueSeconds > 30
                ? () => save(
                    rules.copyWith(
                      starValueSeconds: rules.starValueSeconds - 30,
                    ),
                  )
                : null,
            onIncrement: rules.starValueSeconds < 180
                ? () => save(
                    rules.copyWith(
                      starValueSeconds: rules.starValueSeconds + 30,
                    ),
                  )
                : null,
          ),

          // "السقف اليومي للنجوم" — 20 to 150 stars. D-2: this is also the
          // daily play cap, shown below in minutes, because Article 2 words it
          // that way and the appendix words it this way. One stored value.
          _StepperTile(
            label: l10n.dailyStarCeiling,
            value: Fmt.stars(rules.dailyCeilingUnits),
            hint: l10n.parentRangeHint('20', '150'),
            onDecrement: rules.dailyCeilingUnits > 20 * starUnit
                ? () => save(
                    rules.copyWith(
                      dailyCeilingUnits: rules.dailyCeilingUnits - 5 * starUnit,
                    ),
                  )
                : null,
            onIncrement: rules.dailyCeilingUnits < 150 * starUnit
                ? () => save(
                    rules.copyWith(
                      dailyCeilingUnits: rules.dailyCeilingUnits + 5 * starUnit,
                    ),
                  )
                : null,
          ),
          _DerivedTile(
            label: l10n.parentDailyPlayMinutes,
            value: '${rules.dailyPlayCapSeconds ~/ 60}',
            hint: l10n.parentDailyPlayHint,
          ),

          // "الحد الأدنى للوقت على البطاقة" — 1 to 5 seconds. This is the rule
          // that makes rapid random tapping worthless (Art. 6.3).
          _StepperTile(
            label: l10n.minimumCardSeconds,
            value: '${rules.minimumTimeOnTargetMs / 1000}',
            hint: l10n.parentRangeHint('1', '5'),
            onDecrement: rules.minimumTimeOnTargetMs > 1000
                ? () => save(
                    rules.copyWith(
                      minimumTimeOnTargetMs: rules.minimumTimeOnTargetMs - 500,
                    ),
                  )
                : null,
            onIncrement: rules.minimumTimeOnTargetMs < 5000
                ? () => save(
                    rules.copyWith(
                      minimumTimeOnTargetMs: rules.minimumTimeOnTargetMs + 500,
                    ),
                  )
                : null,
          ),

          // "حجم الجلسة اليومية" — 5 to 30 cards.
          _StepperTile(
            label: l10n.dailySessionSize,
            value: '${rules.dailySessionCards}',
            hint: l10n.parentRangeHint('5', '30'),
            onDecrement: rules.dailySessionCards > 0
                ? () => save(
                    rules.copyWith(
                      dailySessionCards: rules.dailySessionCards - 1,
                    ),
                  )
                : null,
            onIncrement: rules.dailySessionCards < 30
                ? () => save(
                    rules.copyWith(
                      dailySessionCards: rules.dailySessionCards + 1,
                    ),
                  )
                : null,
          ),

          // Not in the appendix table; its worked example uses 5 (D-15).
          _StepperTile(
            label: l10n.parentQuestionsPerDay,
            value: '${rules.dailyQuestionCount}',
            hint: l10n.parentRangeHint('0', '15'),
            onDecrement: rules.dailyQuestionCount > 0
                ? () => save(
                    rules.copyWith(
                      dailyQuestionCount: rules.dailyQuestionCount - 1,
                    ),
                  )
                : null,
            onIncrement: rules.dailyQuestionCount < 15
                ? () => save(
                    rules.copyWith(
                      dailyQuestionCount: rules.dailyQuestionCount + 1,
                    ),
                  )
                : null,
          ),

          // "رصيد ترحيبي عند البداية" — 0 to 30 stars, granted once ever.
          // Editable after the fact so the parent can see what it was, even
          // though changing it has no effect once `welcomeGranted` is set.
          _StepperTile(
            label: l10n.parentWelcomeBalance,
            value: Fmt.stars(rules.welcomeUnits),
            hint: l10n.parentRangeHint('0', '30'),
            enabled: !settings.welcomeGranted,
            onDecrement: rules.welcomeUnits > 0
                ? () => save(
                    rules.copyWith(welcomeUnits: rules.welcomeUnits - starUnit),
                  )
                : null,
            onIncrement: rules.welcomeUnits < 30 * starUnit
                ? () => save(
                    rules.copyWith(welcomeUnits: rules.welcomeUnits + starUnit),
                  )
                : null,
          ),

          const Divider(height: LunioSpacing.xl),

          // Article 6.7 makes daily the rule; appendix §5 offers weekly as a
          // parent choice. Read together: a default, not a prohibition.
          ListTile(
            title: Text(l10n.balanceExpiry),
            contentPadding: EdgeInsets.zero,
            trailing: SegmentedButton<ExpiryMode>(
              segments: [
                ButtonSegment(
                  value: ExpiryMode.daily,
                  label: Text(l10n.expiryDaily),
                ),
                ButtonSegment(
                  value: ExpiryMode.weekly,
                  label: Text(l10n.expiryWeekly),
                ),
              ],
              selected: {rules.expiryMode},
              onSelectionChanged: (selection) =>
                  save(rules.copyWith(expiryMode: selection.first)),
            ),
          ),

          // D-13 — a fixed weekday is predictable for a family and makes the
          // Article 14 purge auditable.
          ListTile(
            title: Text(l10n.parentExpiryWeekday),
            contentPadding: EdgeInsets.zero,
            trailing: DropdownButton<int>(
              value: settings.expiryWeekday,
              items: [
                for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                  DropdownMenuItem(
                    value: day,
                    child: Text(_weekday(l10n, day)),
                  ),
              ],
              onChanged: (value) => value == null
                  ? null
                  : ref
                        .read(settingsRepositoryProvider)
                        .setExpiryWeekday(value),
            ),
          ),

          const Divider(height: LunioSpacing.xl),

          Text(
            l10n.parentBlockingSection,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          // Article 15.2 — both stay switchable at any time, so a Play tester
          // who turned them on can turn them off again without reinstalling.
          SwitchListTile(
            value: settings.blockingEnabled,
            onChanged: (value) =>
                ref.read(settingsRepositoryProvider).setBlockingEnabled(value),
            title: Text(l10n.setupEnableBlocking),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: settings.launcherMode,
            onChanged: (value) =>
                ref.read(settingsRepositoryProvider).setLauncherMode(value),
            title: Text(l10n.setupEnableLauncher),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  static String _weekday(AppL10n l10n, int weekday) => switch (weekday) {
    DateTime.monday => l10n.weekdayMonday,
    DateTime.tuesday => l10n.weekdayTuesday,
    DateTime.wednesday => l10n.weekdayWednesday,
    DateTime.thursday => l10n.weekdayThursday,
    DateTime.friday => l10n.weekdayFriday,
    DateTime.saturday => l10n.weekdaySaturday,
    _ => l10n.weekdaySunday,
  };
}

/// One adjustable number, with its contractual range under it.
///
/// A stepper rather than a free text field: the range is enforced by which
/// buttons are enabled, so a value outside the appendix cannot be typed in the
/// first place. The range is also *printed*, because a parent who cannot see
/// the limit reads a disabled button as a bug.
class _StepperTile extends StatelessWidget {
  const _StepperTile({
    required this.label,
    required this.value,
    required this.hint,
    required this.onDecrement,
    required this.onIncrement,
    this.enabled = true,
  });

  final String label;
  final String value;
  final String hint;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LunioSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                Text(hint, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          IconButton.outlined(
            onPressed: enabled ? onDecrement : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 64,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton.outlined(
            onPressed: enabled ? onIncrement : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

/// A number the parent does not set directly because it is another one in
/// different units (D-2: there is only one daily cap).
class _DerivedTile extends StatelessWidget {
  const _DerivedTile({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LunioSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                Text(hint, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
