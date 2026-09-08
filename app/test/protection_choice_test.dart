import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/features/setup/protection_choice.dart';

/// The setup wizard's protection step, as rules rather than as a screen.
///
/// These four booleans decide whether a phone ends up blocking games and acting
/// as a home screen, and they are set once, on a screen a parent sees once. That
/// combination — high consequence, single exposure — is exactly the kind that
/// hardware testing tends to skip, because it only appears on a fresh install.
void main() {
  group('Play disclosure — consent is deliberate and starts clear', () {
    test('nothing is on before the parent has consented', () {
      expect(ProtectionChoice.none.consented, isFalse);
      expect(ProtectionChoice.none.blocking, isFalse);
      expect(ProtectionChoice.none.launcher, isFalse);
    });

    test('the switches cannot be turned on without consent', () {
      // Not reachable through the UI — the switches are disabled until the box
      // is ticked — but the rule belongs in the value, not only in a widget's
      // `onChanged: consented ? ... : null`. A permission granted without the
      // disclosure that precedes it is the one thing Play checks by hand.
      final forced = ProtectionChoice.none.withBlocking(true).withLauncher(true);
      expect(forced, ProtectionChoice.none);
    });
  });

  group('client request 2026-08-28 — consent turns both on', () {
    test('ticking consent enables blocking and launcher mode', () {
      final choice = ProtectionChoice.none.withConsent(true);
      expect(choice.consented, isTrue);
      expect(choice.blocking, isTrue);
      expect(choice.launcher, isTrue);
    });

    test('withdrawing consent clears both again', () {
      final choice = ProtectionChoice.none.withConsent(true).withConsent(false);
      expect(choice, ProtectionChoice.none);
    });

    test('either switch can still be turned off afterwards', () {
      // The client asked for a default, not a lock. A parent who wants blocking
      // but not a replaced home screen must be able to say so, and doing it must
      // not silently withdraw the consent underneath.
      final choice =
          ProtectionChoice.none.withConsent(true).withLauncher(false);
      expect(choice.consented, isTrue);
      expect(choice.blocking, isTrue);
      expect(choice.launcher, isFalse);
    });
  });

  group('Article 15.2 — the app must be fully usable with both off', () {
    test('declining after consenting leaves both off', () {
      // The regression this exists for. While both switches defaulted to off,
      // "finish" and "finish without blocking" did the same thing and shared one
      // callback. The moment consent started turning them on, that shared
      // callback would have finished setup with blocking enabled — the opposite
      // of what the button says, on the path the twelve Play testers need.
      final declined = ProtectionChoice.none.withConsent(true).declined();
      expect(declined.blocking, isFalse);
      expect(declined.launcher, isFalse);
      expect(declined.consented, isFalse);
    });

    test('declining is idempotent and safe from any state', () {
      for (final start in [
        ProtectionChoice.none,
        ProtectionChoice.none.withConsent(true),
        ProtectionChoice.none.withConsent(true).withBlocking(false),
        const ProtectionChoice(consented: true, blocking: true, launcher: false),
      ]) {
        expect(start.declined(), ProtectionChoice.none, reason: '$start');
      }
    });
  });
}
