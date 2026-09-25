import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/illustrations.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/remote/api_client.dart';
import '../../l10n/app_localizations.dart';
import 'password_field.dart';

/// Getting back into the parent account: address, code, new password.
///
/// **One screen with four steps, not four screens.** The illustration changes
/// and the card underneath it slides, so the parent can see they are moving
/// through one errand rather than being handed between pages. It also means the
/// address is typed once and carried, which matters because the code is only
/// valid for the address it was sent to and a parent who retypes it on a second
/// screen will eventually retype it wrong.
///
/// **A six-digit code, not a link.** The app has no deep links, so a link would
/// open a browser and the reset would finish somewhere this app cannot see. The
/// code is the same errand as the activation code of Article 7.3 — read a short
/// string in one place, type it in another — and the parent has already done
/// that once.
///
/// **It says when an address has no account** — the client's choice on
/// 2026-09-25, reversing the original design, so a parent who mistyped learns it
/// on the spot instead of waiting for a message that will never come. The words
/// are the server's, passed through as the field's error; the app does not
/// decide what counts as "no account", so it does not word it either. D-97
/// records what that trades.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.email = ''});

  /// Prefilled from the sign-in form, so a parent who typed their address and
  /// then remembered they had forgotten the password does not type it twice.
  final String email;

  /// Mirrors the server's own cooldown, so the resend button is not offered a
  /// second before it would work. The server drops a second request inside the
  /// window and tells nobody — a resend that quietly does nothing is worse than
  /// a disabled button with a number on it.
  ///
  /// Public so a test can name it rather than hard-code sixty.
  static const Duration resendCooldown = Duration(seconds: 60);

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

enum _Step { ask, code, choose, done }

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  _Step _step = _Step.ask;
  bool _busy = false;
  String? _error;

  Timer? _ticker;
  int _resendIn = 0;

  @override
  void initState() {
    super.initState();
    _email.text = widget.email.trim();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: LunioSpacing.page,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: LunioSpacing.s),
                  _Hero(step: _step),
                  const SizedBox(height: LunioSpacing.l),
                  // Keyed so the switcher sees a different child per step and
                  // actually animates; without it the fields are reused and the
                  // transition never plays.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _card(l10n),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(AppL10n l10n) => switch (_step) {
    _Step.ask => _ask(l10n),
    _Step.code => _codeStep(l10n),
    _Step.choose => _choose(l10n),
    _Step.done => _done(l10n),
  };

  // --- step 1: the address --------------------------------------------------

  Widget _ask(AppL10n l10n) {
    return _Panel(
      title: l10n.forgotAskTitle,
      body: l10n.forgotAskBody,
      children: [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          // An email typed on an Arabic keyboard is a Latin string in an RTL
          // field; forcing LTR stops the cursor and the @ from jumping around.
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: l10n.emailLabel,
            errorText: _error,
          ),
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: LunioSpacing.l),
        _Action(busy: _busy, label: l10n.forgotAskAction, onPressed: _send),
      ],
    );
  }

  // --- step 2: the code -----------------------------------------------------

  Widget _codeStep(AppL10n l10n) {
    return _Panel(
      title: l10n.forgotCodeTitle,
      body: l10n.forgotCodeBody(_email.text.trim()),
      children: [
        TextField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLength: 6,
          // Six digits typed by someone reading them off another screen. Wide
          // tracking makes a transcription error visible before it is submitted.
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            letterSpacing: 12,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            hintText: '------',
            errorText: _error,
          ),
          onChanged: (value) {
            // Submitting on the sixth digit saves a tap, and every one of the
            // five attempts is precious — so it only fires once the field is
            // exactly full, never on a paste that overshoots.
            if (value.length == 6 && !_busy) _checkCode();
          },
        ),
        const SizedBox(height: LunioSpacing.m),
        _Action(
          busy: _busy,
          label: l10n.forgotCodeAction,
          onPressed: _checkCode,
        ),
        const SizedBox(height: LunioSpacing.xs),
        TextButton(
          onPressed: _busy || _resendIn > 0 ? null : _send,
          child: Text(
            _resendIn > 0
                ? l10n.forgotCodeResendIn('$_resendIn')
                : l10n.forgotCodeResend,
          ),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                  _step = _Step.ask;
                  _code.clear();
                  _error = null;
                }),
          child: Text(l10n.forgotCodeWrongEmail),
        ),
      ],
    );
  }

  // --- step 3: the new password --------------------------------------------

  Widget _choose(AppL10n l10n) {
    return _Panel(
      title: l10n.forgotNewTitle,
      // Article 7.1 in one sentence. A parent told that "other sessions will
      // end" on a parental-control app assumes the controls end with them.
      body: l10n.forgotNewBody,
      children: [
        PasswordField(
          controller: _password,
          label: l10n.forgotNewLabel,
          autofocus: true,
        ),
        const SizedBox(height: LunioSpacing.m),
        PasswordField(
          controller: _confirm,
          label: l10n.forgotNewConfirmLabel,
          errorText: _error,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: LunioSpacing.l),
        _Action(busy: _busy, label: l10n.forgotNewAction, onPressed: _save),
      ],
    );
  }

  // --- step 4: done ---------------------------------------------------------

  Widget _done(AppL10n l10n) {
    return _Panel(
      title: l10n.forgotDoneTitle,
      body: l10n.forgotDoneBody,
      children: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.forgotDoneAction),
        ),
      ],
    );
  }

  // --- the work -------------------------------------------------------------

  /// Runs [action], holding the button and surfacing a failure as field text.
  Future<void> _guard(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _guard(() async {
    final auth = ref.read(authRepositoryProvider);
    await auth.requestPasswordReset(email: _email.text);

    if (!mounted) return;
    setState(() {
      _step = _Step.code;
      _code.clear();
    });
    _startCooldown();
  });

  Future<void> _checkCode() => _guard(() async {
    final auth = ref.read(authRepositoryProvider);
    await auth.verifyResetCode(email: _email.text, code: _code.text);

    if (!mounted) return;
    setState(() => _step = _Step.choose);
  });

  Future<void> _save() async {
    final l10n = AppL10n.of(context)!;

    // Checked here rather than on the server: the server never sees the second
    // field, and a mismatch is a typing slip, not a failed request. Sending it
    // would spend one of the five code attempts on a mistake the app can see.
    if (_password.text != _confirm.text) {
      setState(() => _error = l10n.forgotNewMismatch);
      return;
    }

    await _guard(() async {
      final auth = ref.read(authRepositoryProvider);
      final now = await ref.read(trustedNowProvider.notifier).refresh();

      await auth.confirmPasswordReset(
        email: _email.text,
        code: _code.text,
        password: _password.text,
        now: now,
      );

      if (!mounted) return;
      // Cleared the moment they are no longer needed. The screen stays alive
      // behind the success panel until the parent taps through it.
      _password.clear();
      _confirm.clear();
      _code.clear();
      setState(() => _step = _Step.done);
    });
  }

  void _startCooldown() {
    _ticker?.cancel();
    setState(() => _resendIn = ForgotPasswordScreen.resendCooldown.inSeconds);

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendIn -= 1);
      if (_resendIn <= 0) timer.cancel();
    });
  }
}

/// The drawing above the card, one per step.
///
/// Inside a fixed-height box so the card below it does not jump when the
/// artwork changes — and so a missing asset leaves the layout where it was
/// rather than collapsing it.
class _Hero extends StatelessWidget {
  const _Hero({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final illustration = switch (step) {
      _Step.ask => Illustration.keyFriendly,
      _Step.code => Illustration.mailSent,
      _Step.choose => Illustration.shield,
      _Step.done => Illustration.starBig,
    };

    return SizedBox(
      height: 132,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: KeyedSubtree(
            key: ValueKey(illustration),
            child: illustration.show(size: 128),
          ),
        ),
      ),
    );
  }
}

/// A titled card: heading, one explaining sentence, then the fields.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.body,
    required this.children,
  });

  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: LunioSpacing.s),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: LunioTheme.ink.withValues(alpha: 0.7),
                height: 1.7,
              ),
            ),
            const SizedBox(height: LunioSpacing.l),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// The step's main button, with the spinner in place of its label.
///
/// The spinner replaces the text rather than sitting beside it so the button
/// keeps its width — a button that shrinks under a thumb is a button that gets
/// tapped twice.
class _Action extends StatelessWidget {
  const _Action({
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
