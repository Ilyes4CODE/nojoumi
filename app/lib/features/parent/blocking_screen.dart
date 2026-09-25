import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/local/tables.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/blocking_channel.dart';
import 'app_picker_screen.dart';

/// Where the parent arms the blocking engine — Article 15.2's opt-in, made
/// explicit.
///
/// The screen is built around one refusal: **it never claims blocking is on when
/// it is not.** Three separate system grants stand between the switch and a game
/// actually being stopped, every one of them lives on a Settings screen we cannot
/// automate, and any of them can be revoked later by the parent or by an OEM
/// cleanup without telling us. So the state is read back from the system each time
/// this screen appears, and each grant is shown on its own line with its own
/// consequence spelled out.
///
/// A parental-control app that believes it is guarding when it is not is worse
/// than one that is honestly off: the parent stops watching.
///
/// **UNVERIFIED-ON-HARDWARE.**
class BlockingScreen extends ConsumerStatefulWidget {
  const BlockingScreen({super.key});

  @override
  ConsumerState<BlockingScreen> createState() => _BlockingScreenState();
}

class _BlockingScreenState extends ConsumerState<BlockingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The whole screen turns on this. Every button here sends the parent out to a
    // system Settings screen, and the only moment we can learn what they did is
    // when they come back — there is no callback, no broadcast and no permission
    // result. An answer cached from before they left is the one answer that is
    // certainly stale.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(blockingStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).value;
    final status = ref.watch(blockingStatusProvider).value;
    final managed = ref.watch(managedAppsProvider).value ?? const [];

    // Reading the sync provider is what subscribes this screen's lifetime to the
    // push. It is a Provider<void> whose only job is its side effect.
    ref.watch(blockingSyncProvider);

    final blockedCount = managed
        .where((app) => app.policy == AppPolicy.blockedGame)
        .length;
    final enabled = settings?.blockingEnabled ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockingTitle)),
      body: SafeArea(
        child: ListView(
          padding: LunioSpacing.page,
          children: [
            Text(
              l10n.blockingIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: LunioTheme.ink.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: LunioSpacing.l),

            if (status != null && !status.available)
              _Notice(text: l10n.blockingUnavailable)
            else ...[
              _StateCard(enabled: enabled, status: status),
              const SizedBox(height: LunioSpacing.m),

              Card(
                child: SwitchListTile(
                  value: enabled,
                  onChanged: (value) => ref
                      .read(settingsRepositoryProvider)
                      .setBlockingEnabled(value),
                  title: Text(l10n.blockingEnableSwitch),
                  secondary: Icon(
                    enabled ? Icons.shield : Icons.shield_outlined,
                  ),
                ),
              ),

              if (enabled) ...[
                const SizedBox(height: LunioSpacing.m),

                _Permission(
                  title: l10n.permAccessibility,
                  body: l10n.permAccessibilityBody,
                  granted: status?.accessibilityEnabled ?? false,
                  icon: Icons.accessibility_new,
                  action: () async {
                    await ref
                        .read(blockingChannelProvider)
                        .openAccessibilitySettings();
                  },
                ),
                _Permission(
                  title: l10n.permOverlay,
                  body: l10n.permOverlayBody,
                  granted: status?.overlayGranted ?? false,
                  icon: Icons.layers_outlined,
                  action: () async {
                    await ref
                        .read(blockingChannelProvider)
                        .openOverlaySettings();
                  },
                ),
                // Placed above notifications because it matters more: without
                // it the countdown freezes mid-game and the eviction is late,
                // which is the difference between blocking working and blocking
                // appearing to work.
                _Permission(
                  title: l10n.permBattery,
                  body: l10n.permBatteryBody,
                  granted: status?.batteryUnrestricted ?? false,
                  icon: Icons.battery_saver,
                  action: () async {
                    await ref
                        .read(blockingChannelProvider)
                        .requestBatteryExemption();
                  },
                ),
                _Permission(
                  title: l10n.permNotifications,
                  body: l10n.permNotificationsBody,
                  granted: status?.notificationsGranted ?? false,
                  icon: Icons.notifications_outlined,
                  action: () async {
                    await ref
                        .read(blockingChannelProvider)
                        .openBatterySettings();
                  },
                ),

                // Shown only where a screen was actually found. Article 12
                // scenario 11 is won or lost here on ColorOS, One UI and MIUI,
                // and the activity names are undocumented — so the button appears
                // when one resolved and stays away when none did, rather than
                // sending the parent to a dead end.
                if (status?.autostartScreenAvailable ?? false)
                  _Permission(
                    title: l10n.permAutostart,
                    body: l10n.permAutostartBody(status?.manufacturer ?? ''),
                    granted: false,
                    showState: false,
                    icon: Icons.restart_alt,
                    action: () async {
                      await ref
                          .read(blockingChannelProvider)
                          .openAutostartSettings();
                    },
                  ),

                const SizedBox(height: LunioSpacing.m),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.videogame_asset_outlined),
                    title: Text(l10n.blockingApps),
                    subtitle: Text(
                      blockedCount == 0
                          ? l10n.blockingAppsEmpty
                          : l10n.blockingAppsCount('$blockedCount'),
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AppPickerScreen(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: LunioSpacing.m),
                _Notice(text: l10n.blockingProtectedNote),
              ],

              if (status != null && status.sdkInt > 0) ...[
                const SizedBox(height: LunioSpacing.l),
                Text(
                  l10n.blockingDeviceLine(
                    status.manufacturer,
                    '${status.sdkInt}',
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: LunioTheme.ink.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// The one-line answer: is anything actually being blocked right now?
class _StateCard extends StatelessWidget {
  const _StateCard({required this.enabled, required this.status});

  final bool enabled;
  final BlockingStatus? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    final ready = enabled && (status?.ready ?? false);
    final (label, tint, icon) = switch ((enabled, ready)) {
      (false, _) => (
        l10n.blockingOff,
        LunioTheme.tintLavender,
        Icons.shield_outlined,
      ),
      (true, true) => (
        l10n.blockingReady,
        LunioTheme.tintMint,
        Icons.verified_user,
      ),
      // Enabled but incomplete is the dangerous state, and the only one worth a
      // warning colour: the parent has been told blocking is on and it is not.
      (true, false) => (
        l10n.blockingIncomplete,
        LunioTheme.tintPeach,
        Icons.warning_amber,
      ),
    };

    return Card(
      color: tint,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: LunioSpacing.m),
            Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
          ],
        ),
      ),
    );
  }
}

class _Permission extends StatelessWidget {
  const _Permission({
    required this.title,
    required this.body,
    required this.granted,
    required this.icon,
    required this.action,
    this.showState = true,
  });

  final String title;
  final String body;
  final bool granted;
  final bool showState;
  final IconData icon;
  final Future<void> Function() action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: showState && granted ? LunioTheme.play : null,
        ),
        title: Text(title),
        subtitle: Text(body, style: theme.textTheme.bodySmall),
        trailing: showState && granted
            ? Chip(
                label: Text(l10n.permGranted),
                backgroundColor: LunioTheme.tintMint,
                side: BorderSide.none,
              )
            : TextButton(
                onPressed: action,
                child: Text(showState ? l10n.permMissing : l10n.permOpen),
              ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(LunioSpacing.m),
      decoration: BoxDecoration(
        color: LunioTheme.tintLavender,
        borderRadius: BorderRadius.circular(LunioRadius.card),
      ),
      child: Text(text, style: theme.textTheme.bodySmall),
    );
  }
}
