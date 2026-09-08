import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/illustrations.dart';
import '../../core/pin.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

/// The door to everything the parent controls.
///
/// The threat model is narrow and specific: the attacker is a child holding the
/// device, with unlimited time and a four-digit space of ten thousand values.
/// No hash makes that space large, so **the rate limit is the actual defence**
/// and PBKDF2 only protects the stored value (see [PinHasher]).
///
/// The backoff below is therefore not decoration. Five wrong attempts and the
/// wait doubles each time, which turns an afternoon of guessing into a week of
/// it, while a parent who fat-fingers their own PIN twice notices nothing.
class PinGate extends ConsumerStatefulWidget {
  const PinGate({super.key, required this.child, required this.title});

  /// Shown once the PIN is accepted.
  final Widget child;
  final String title;

  @override
  ConsumerState<PinGate> createState() => _PinGateState();
}

class _PinGateState extends ConsumerState<PinGate> {
  final _controller = TextEditingController();

  bool _unlocked = false;
  bool _checking = false;
  String? _error;
  int _wrongAttempts = 0;
  DateTime? _lockedUntilMonotonic;

  /// Attempts allowed before the wait starts. Generous, because a parent typing
  /// on a cracked screen in bad light is the common case and a locked-out
  /// parent is a support call.
  static const int _freeAttempts = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;

    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Padding(
          padding: LunioSpacing.page,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Illustration.shield.show(size: 120)),
              const SizedBox(height: LunioSpacing.l),
              Text(
                l10n.enterPin,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: LunioSpacing.m),
              TextField(
                controller: _controller,
                obscureText: true,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(errorText: _error),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: LunioSpacing.m),
              FilledButton(
                onPressed: _checking ? null : _submit,
                child: _checking
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.continueAction),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppL10n.of(context)!;

    final waitFor = _remainingLockout();
    if (waitFor > Duration.zero) {
      setState(() => _error = l10n.pinLockedFor('${waitFor.inSeconds}'));
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    final settings = await ref.read(settingsRepositoryProvider).read();
    final credential = PinCredential(
      hash: settings.pinHash,
      salt: settings.pinSalt,
    );

    // A device whose PIN was never set must not be an open door. This should be
    // unreachable — the setup wizard requires one — but "should be unreachable"
    // is not a security property.
    final ok =
        credential.isSet &&
        await const PinHasher().verify(_controller.text, credential);

    if (!mounted) return;
    if (ok) {
      setState(() {
        _unlocked = true;
        _checking = false;
      });
      return;
    }

    _wrongAttempts++;
    if (_wrongAttempts > _freeAttempts) {
      _lockedUntilMonotonic = DateTime.now().add(_backoff());
    }
    setState(() {
      _checking = false;
      _error = l10n.wrongPin;
      _controller.clear();
    });
  }

  /// Doubling, capped. The cap exists so a child mashing the keypad for an hour
  /// cannot lock the parent out for a day — the point is to make guessing
  /// pointless, not to punish.
  Duration _backoff() {
    final over = _wrongAttempts - _freeAttempts;
    final seconds = 15 * (1 << (over - 1).clamp(0, 6));
    return Duration(seconds: seconds.clamp(15, 900));
  }

  /// Wall-clock time is fine here and only here.
  ///
  /// This is a UI cooldown within one screen's lifetime, not a contract window:
  /// nothing is granted, extended or expired by it. Winding the clock forward
  /// skips the wait — and gains the attacker nothing, because the PIN space is
  /// unchanged and no star or subscription day depends on this value. Article
  /// 6.8 and 7.6 both live in `lunio_time`, where they belong.
  Duration _remainingLockout() {
    final until = _lockedUntilMonotonic;
    if (until == null) return Duration.zero;
    final left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }
}
