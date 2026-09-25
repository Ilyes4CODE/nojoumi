import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A password field with an eye to show what was typed.
///
/// Client request, 2026-09-25. One widget rather than a toggle added to each of
/// the three password fields, because the three would drift: one would forget
/// the LTR direction, another the tooltip, and the parent would meet slightly
/// different fields on screens that should feel like one flow.
///
/// **Not used for the PIN.** The parent's PIN gate is typed on the phone the
/// child uses, often with the child beside it, and a reveal button on it is a
/// way for the child to read the four digits over a shoulder. A password is
/// typed once, at setup or recovery, where that risk is small and the cost of a
/// typo — being locked out of the account — is large.
///
/// Starts hidden, every time. A field that remembered being revealed would
/// eventually show a password on a screen somebody else was looking at.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;

    return TextField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      obscureText: !_visible,
      // Suggestions and autocorrect on a password field are how a password ends
      // up in the keyboard's learned-words list.
      enableSuggestions: false,
      autocorrect: false,
      // A password is a Latin string even in an RTL layout; without this the
      // cursor and the characters jump around as it is typed.
      textDirection: TextDirection.ltr,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          icon: Icon(
            _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          // Read aloud by a screen reader, and shown on long-press. Our own
          // strings: Material has no password-visibility label, and its nearest
          // neighbour — `showAccountsLabel` — would announce "show accounts" on a
          // password field, which is worse for a blind parent than no label.
          tooltip: _visible ? l10n.passwordHide : l10n.passwordShow,
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}
