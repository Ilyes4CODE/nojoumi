import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/features/setup/post_auth_route.dart';

/// Where a parent lands after signing in, as a rule rather than as a screen.
///
/// It is worth a file of its own because getting it wrong does not look like a
/// bug — it looks like a smooth, fast onboarding that has quietly locked the
/// parent out of their own settings. `PinGate` refuses to unlock when no PIN is
/// set, so a device that skips the PIN step has no way back into the parent area
/// short of clearing the app's data.
void main() {
  group('a new account always walks the whole setup', () {
    test('registration never skips, even on a configured device', () {
      // Reachable: a parent whose account was refused by the one-per-device rule
      // clears app data, then registers a second account on a phone whose grade
      // and PIN were restored some other way. Rare, and it must still be safe.
      expect(
        routeAfterAuth(
          registered: true,
          deviceHasGrade: true,
          deviceHasPin: true,
        ),
        PostAuthRoute.continueSetup,
      );
    });
  });

  group('a sign-in skips only when the device is genuinely ready', () {
    test('grade and PIN present — straight into the app', () {
      expect(
        routeAfterAuth(
          registered: false,
          deviceHasGrade: true,
          deviceHasPin: true,
        ),
        PostAuthRoute.straightToApp,
      );
    });

    test('no PIN — never skips, or the parent is locked out for good', () {
      expect(
        routeAfterAuth(
          registered: false,
          deviceHasGrade: true,
          deviceHasPin: false,
        ),
        PostAuthRoute.continueSetup,
      );
    });

    test('no grade — never skips, or lesson capture fails with a 400', () {
      expect(
        routeAfterAuth(
          registered: false,
          deviceHasGrade: false,
          deviceHasPin: true,
        ),
        PostAuthRoute.continueSetup,
      );
    });

    test('a bare phone runs the full setup', () {
      // The common case: a parent with an existing account installing Lunio on a
      // new phone. Nothing about the child ever reaches the server (Art. 14,
      // AD-6), so there is nothing to restore and the setup is not repetition.
      expect(
        routeAfterAuth(
          registered: false,
          deviceHasGrade: false,
          deviceHasPin: false,
        ),
        PostAuthRoute.continueSetup,
      );
    });
  });
}
