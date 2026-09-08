import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/local/tables.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/blocking_channel.dart';

/// Where the parent says which apps are games.
///
/// The list comes from a `MAIN`/`LAUNCHER` query, not from `QUERY_ALL_PACKAGES` —
/// that permission is among the most rejection-prone on Play, and we would be
/// asking for it to enumerate icons the parent can already see on their own home
/// screen. Anything a child can open is launchable by definition, so the narrow
/// query is not a compromise.
///
/// **Nothing here can unprotect a protected app.** Settings, the dialer, the
/// keyboard and Lunio itself are refused inside `BlockPolicy`, before the parent's
/// list is consulted at all (D-9), so no row this screen writes can brick the
/// phone. The note at the bottom says so, because a parent who cannot find
/// Settings in the list should know why rather than assume the list is broken.
///
/// **UNVERIFIED-ON-HARDWARE.**
class AppPickerScreen extends ConsumerStatefulWidget {
  const AppPickerScreen({super.key});

  @override
  ConsumerState<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<AppPickerScreen> {
  late Future<List<InstalledApp>> _apps;
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Loaded once and held. Sixty icons is a few hundred kilobytes over the
    // channel, and reloading them on every keystroke of the search field would
    // make the screen stutter on the 2 GB device of Article 13.
    _apps = ref.read(blockingRepositoryProvider).installedApps();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    final managed = ref.watch(managedAppsProvider).value ?? const [];
    final blocked = {
      for (final row in managed)
        if (row.policy == AppPolicy.blockedGame) row.packageName,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockingApps)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LunioSpacing.l,
                LunioSpacing.m,
                LunioSpacing.l,
                LunioSpacing.s,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.blockingAppsHint, style: theme.textTheme.bodySmall),
                  const SizedBox(height: LunioSpacing.m),
                  TextField(
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: l10n.blockingAppsSearch,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<InstalledApp>>(
                future: _apps,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: LunioSpacing.m),
                          Text(
                            l10n.blockingAppsLoading,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  final apps = snapshot.data!
                      .where(
                        (app) =>
                            _query.isEmpty ||
                            app.label.toLowerCase().contains(_query) ||
                            app.packageName.toLowerCase().contains(_query),
                      )
                      .toList(growable: false);

                  if (apps.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.blockingAppsEmpty,
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return CheckboxListTile(
                        value: blocked.contains(app.packageName),
                        onChanged: (value) => _toggle(app, value ?? false),
                        title: Text(app.label),
                        subtitle: Text(
                          app.packageName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: LunioTheme.ink.withValues(alpha: 0.45),
                          ),
                        ),
                        secondary: app.icon == null
                            ? const Icon(Icons.android)
                            : Image.memory(
                                app.icon!,
                                width: 40,
                                height: 40,
                                // A malformed icon from one odd app must not take
                                // the whole list down with it.
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.android),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: LunioSpacing.page,
              child: Text(
                l10n.blockingProtectedNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: LunioTheme.ink.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(InstalledApp app, bool blocked) async {
    final now = ref.read(trustedNowProvider).value;
    await ref
        .read(blockingRepositoryProvider)
        .setPolicy(
          packageName: app.packageName,
          label: app.label,
          policy: blocked ? AppPolicy.blockedGame : AppPolicy.allowed,
          // Bookkeeping only — nothing decides anything on this timestamp, so an
          // unresolved clock costs nothing here.
          nowMs: now?.epochMs ?? 0,
        );
  }
}
