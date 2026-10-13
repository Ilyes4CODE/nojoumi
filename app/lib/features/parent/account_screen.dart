import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/illustrations.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../data/remote/api_client.dart';
import '../auth/account_form.dart';
import '../auth/password_field.dart';

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
              _SignedIn(onSignOut: _signOut, onDelete: _delete)
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

  Future<void> _delete() async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (deleted != true || !mounted) return;
    final l10n = AppL10n.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
  }
}

/// Google Play requires account deletion inside the app (2026-10-13).
///
/// Asks for the password, not just a tap: this screen sits behind the parent
/// PIN, but the PIN is four digits typed beside the child, and deleting the
/// account loses whatever is left of a paid subscription. Says so before the
/// button, in the same words as the web page at /account/delete/.
///
/// Pops `true` only once the server has confirmed. On a wrong password the
/// dialog stays open with the server's message under the field.
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_password.text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .deleteAccount(password: _password.text);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = failure.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final danger = Theme.of(context).colorScheme.error;

    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.deleteAccountBody),
            const SizedBox(height: LunioSpacing.m),
            PasswordField(
              controller: _password,
              label: l10n.deleteAccountPasswordHint,
              errorText: _error,
              onSubmitted: (_) => _confirm(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: danger),
          onPressed: _busy ? null : _confirm,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.deleteAccountConfirm),
        ),
      ],
    );
  }
}

class _SignedIn extends ConsumerWidget {
  const _SignedIn({required this.onSignOut, required this.onDelete});

  final Future<void> Function() onSignOut;
  final Future<void> Function() onDelete;

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
        const SizedBox(height: LunioSpacing.l),
        TextButton.icon(
          onPressed: onDelete,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.delete_forever_outlined),
          label: Text(l10n.deleteAccount),
        ),
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
