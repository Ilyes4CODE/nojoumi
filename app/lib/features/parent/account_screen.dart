import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/illustrations.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../auth/account_form.dart';

/// The parent's account — the only account this app has.
///
/// **The child never signs in and never sees this screen.** Article 14 keeps every
/// byte about the child on the device and AD-6 keeps the server free of it, so the
/// account exists for exactly two things: generating new lessons, and the
/// subscription.
///
/// Which means the screen has to say, plainly, what happens without it. A parent
/// who reads "sign in" on a parental-control app assumes the whole thing stops
/// working, and Article 7.1 is emphatic that it does not.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    final signedIn = ref.watch(isSignedInProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: SafeArea(
        child: ListView(
          padding: LunioSpacing.page,
          children: [
            Center(child: Illustration.shield.show(size: 96)),
            const SizedBox(height: LunioSpacing.m),
            Text(
              l10n.accountWhy,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: LunioTheme.ink.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: LunioSpacing.l),
            if (!AppConfig.hasApi)
              _Notice(message: l10n.serverNotConfigured)
            else if (signedIn)
              _SignedIn(onSignOut: _signOut)
            else
              // The same form the setup wizard shows. See `AccountForm` for why
              // it is shared rather than duplicated.
              const AccountForm(),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() => ref.read(authRepositoryProvider).signOut();
}

class _SignedIn extends ConsumerWidget {
  const _SignedIn({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    final email = ref.watch(authRepositoryProvider).watch();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreamBuilder(
          stream: email,
          builder: (context, snapshot) {
            final address = snapshot.data?.email ?? '';
            return Card(
              child: ListTile(
                leading: const TintedIcon(Icons.verified_user_outlined),
                title: Text(l10n.signedInAs(address)),
              ),
            );
          },
        ),
        const SizedBox(height: LunioSpacing.l),
        OutlinedButton(onPressed: onSignOut, child: Text(l10n.signOut)),
      ],
    );
  }
}

/// A calm informational card. Deliberately not an error colour: a build without a
/// server address is a configuration fact, not the parent's mistake.
class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.m),
        child: Row(
          children: [
            const TintedIcon(Icons.info_outline),
            const SizedBox(width: LunioSpacing.m),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
