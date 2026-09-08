import 'package:flutter/foundation.dart';

/// What the parent has decided on the protection step, as a value.
///
/// Three booleans that used to live as three `setState` fields in the wizard,
/// pulled out here for one reason: **the rules between them are the part that
/// can be wrong, and widgets are the hardest place to test.** The wizard's
/// state is private, `SetupWizard` reaches the database through providers, and
/// the widget harness refuses database access by design (D-33) — so as long as
/// these rules lived inside the wizard, nothing could assert them.
///
/// The rules, all of which have a reason:
///
///  * **Consent carries both switches with it.** Asked for by the client on
///    2026-08-28. A parent who has just read the disclosure and ticked "I
///    consent as a parent" has said what they want; making them find two more
///    switches to get it is a step that only loses people.
///  * **Withdrawing consent clears both**, because a switch that stayed on after
///    the consent behind it was withdrawn is a permission we would be claiming
///    without a basis for it.
///  * **[declined] ignores the switches entirely.** This is Article 15.2's
///    escape hatch and it must mean what the button says, whatever state the
///    parent left the switches in on the way to tapping it.
///
/// None of this weakens Article 15.2 or Play's disclosure requirement: consent
/// still starts [none] on every launch, still needs a deliberate tap, and both
/// switches stay individually adjustable afterwards. What changed is the default
/// *after* an explicit yes — not whether the yes is required.
@immutable
class ProtectionChoice {
  const ProtectionChoice({
    required this.consented,
    required this.blocking,
    required this.launcher,
  });

  /// The state every launch starts in. Consent that is pre-granted is not
  /// consent, and Play reviews this exact interaction.
  static const ProtectionChoice none = ProtectionChoice(
    consented: false,
    blocking: false,
    launcher: false,
  );

  /// The parent read the disclosure and accepted it.
  final bool consented;

  /// Article 15.2 — game blocking, opt-in.
  final bool blocking;

  /// Article 15.2 — Lunio as the home screen, opt-in.
  final bool launcher;

  /// Ticking or clearing the consent box.
  ProtectionChoice withConsent(bool value) =>
      ProtectionChoice(consented: value, blocking: value, launcher: value);

  /// The switches stay adjustable after consent — turning one off is a normal
  /// thing for a parent to want and must not silently withdraw the consent.
  ProtectionChoice withBlocking(bool value) {
    if (!consented) return this;
    return ProtectionChoice(
      consented: consented,
      blocking: value,
      launcher: launcher,
    );
  }

  ProtectionChoice withLauncher(bool value) {
    if (!consented) return this;
    return ProtectionChoice(
      consented: consented,
      blocking: blocking,
      launcher: value,
    );
  }

  /// "أكمل بدون حجب" — finish with both features off, whatever the switches say.
  ///
  /// Before consent turned the switches on, the decline button was safe by
  /// accident: both defaulted to off, so declining and finishing did the same
  /// thing and shared one callback. The moment consent started turning them on,
  /// that shared callback would have finished setup **with blocking enabled** —
  /// the exact opposite of what the button says, on the one path the twelve Play
  /// testers of Article 15.2 depend on.
  ProtectionChoice declined() => none;

  @override
  bool operator ==(Object other) =>
      other is ProtectionChoice &&
      other.consented == consented &&
      other.blocking == blocking &&
      other.launcher == launcher;

  @override
  int get hashCode => Object.hash(consented, blocking, launcher);

  @override
  String toString() =>
      'ProtectionChoice(consented: $consented, blocking: $blocking, '
      'launcher: $launcher)';
}
