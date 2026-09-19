import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/remote/api_client.dart';
import '../../l10n/app_localizations.dart';
import 'forgot_password_screen.dart';

/// Sign in, or create the parent account. One implementation, two callers.
///
/// It was written once inside `AccountScreen` and is now also the setup wizard's
/// second step (client request, 2026-08-28). Extracted rather than copied for a
/// specific reason: this form is where a password is typed, and a second copy is
/// a second place for the LTR field direction, the error handling and the
/// clear-on-success to drift out of step. Two login forms in one app is how one
/// of them ends up subtly worse.
///
/// **The child never sees this.** Article 14 keeps every byte about the child on
/// the device and AD-6 keeps the server free of it, so the account exists for
/// exactly two things: generating new lessons, and the subscription.
class AccountForm extends ConsumerStatefulWidget {
  const AccountForm({super.key, this.onSignedIn});

  /// Called after a successful sign-in or registration, with **which of the two
  /// it was**.
  ///
  /// The wizard branches on it: a parent who just created an account has a whole
  /// setup ahead of them, while one signing back in may have nothing left to do.
  /// The dashboard ignores the argument — it rebuilds from `isSignedInProvider`
  /// on its own.
  final void Function(bool registered)? onSignedIn;

  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  bool _registering = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          // An email typed on an Arabic keyboard is a Latin string in an RTL
          // field; forcing LTR stops the cursor and the @ from jumping around.
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(labelText: l10n.emailLabel),
        ),
        const SizedBox(height: LunioSpacing.m),
        TextField(
          controller: _password,
          obscureText: true,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: l10n.passwordLabel,
            errorText: _error,
          ),
        ),
        if (_registering) ...[
          const SizedBox(height: LunioSpacing.m),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            // Optional, and it stays optional: D-25 built the account on an
            // email precisely so no SMS gateway is needed. The field exists so
            // the client can switch the activation-code channel later without a
            // migration.
            decoration: InputDecoration(labelText: l10n.phoneOptional),
          ),
        ],
        const SizedBox(height: LunioSpacing.l),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_registering ? l10n.signUp : l10n.signIn),
        ),
        const SizedBox(height: LunioSpacing.s),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                  _registering = !_registering;
                  _error = null;
                }),
          child: Text(
            _registering ? l10n.haveAccountAlready : l10n.noAccountYet,
          ),
        ),
        // Only when signing in. On the registration side there is no password
        // to have forgotten yet, and the link would read as a suggestion that
        // something has already gone wrong.
        if (!_registering)
          TextButton(
            onPressed: _busy ? null : _forgot,
            child: Text(l10n.forgotPasswordLink),
          ),
      ],
    );
  }

  /// Open the reset flow, carrying whatever address is already typed.
  ///
  /// It returns true when the parent finished and was signed in, which is the
  /// same outcome as submitting this form — so the caller is told in the same
  /// way, as a sign-in rather than a registration.
  Future<void> _forgot() async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(email: _email.text),
      ),
    );

    if (done == true && mounted) {
      _password.clear();
      widget.onSignedIn?.call(false);
    }
  }

  Future<void> _submit() async {
    // Captured before the await: `_registering` is state, and the toggle is
    // still tappable while the request is in flight.
    final registering = _registering;

    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = ref.read(authRepositoryProvider);
    final now = await ref.read(trustedNowProvider.notifier).refresh();

    try {
      if (registering) {
        await auth.register(
          email: _email.text,
          password: _password.text,
          phone: _phone.text,
          now: now,
        );
      } else {
        await auth.signIn(
          email: _email.text,
          password: _password.text,
          now: now,
        );
      }
      // Cleared on success and never on failure — a parent who mistyped should
      // not have to retype the whole thing.
      _password.clear();
      if (mounted) widget.onSignedIn?.call(registering);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
