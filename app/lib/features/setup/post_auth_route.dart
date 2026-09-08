/// Where the parent goes after the server accepts them.
///
/// Client request, 2026-08-29: branch on the case — a sign-in should not walk a
/// returning parent through onboarding again.
enum PostAuthRoute {
  /// On to the school level, the PIN, and the protection step.
  continueSetup,

  /// Nothing left to ask on this device. Mark setup complete and hand over.
  straightToApp,
}

/// The rule, as a function, because getting it wrong locks a parent out.
///
/// A device may skip the rest of setup only when **all three** hold:
///
///  * it was a **sign-in**, not a registration — a new account has never
///    configured anything anywhere;
///  * this phone already has a **school level**;
///  * this phone already has a **parent PIN**.
///
/// ### Why the last two cannot be relaxed
///
/// The grade and the PIN are never sent to the server. Article 14 keeps every
/// byte about the child on the device, and AD-6 keeps the server's tables free
/// of it, so there is nothing to restore them from. A sign-in on a fresh phone
/// therefore has no way to inherit them, however much one would like it to.
///
/// And skipping anyway is worse than tedious, in two specific ways that are easy
/// to miss when the rule looks like a convenience:
///
///  * `PinGate` refuses to unlock when no PIN is set — deliberately, because "no
///    PIN" must not be an open door. So a parent dropped into the app without
///    one is **locked out of their own settings permanently**: the app picker,
///    the star adjustments, the subscription screen, all unreachable, with no
///    way back other than clearing the app's data.
///  * the lesson endpoint requires a grade. An empty one is a 400 that surfaces
///    as "capture does not work".
///
/// So the interesting case this rule really serves is the parent who signed out
/// from the dashboard and back in, or whose wizard was interrupted after the PIN
/// step. For them the skip is right and the setup would be pure repetition.
PostAuthRoute routeAfterAuth({
  required bool registered,
  required bool deviceHasGrade,
  required bool deviceHasPin,
}) {
  if (registered) return PostAuthRoute.continueSetup;
  if (deviceHasGrade && deviceHasPin) return PostAuthRoute.straightToApp;
  return PostAuthRoute.continueSetup;
}
