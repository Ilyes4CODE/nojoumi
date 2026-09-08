import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/core/providers.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/data/remote/api_client.dart';
import 'package:lunio/features/session/session_controller.dart';
import 'package:lunio_time/lunio_time.dart';

import 'support/test_db.dart';

/// The composition root, resolved for real.
///
/// **Why this file exists.** On 2026-08-29 every authenticated call in the app —
/// register, sign-in, the trial, the lesson endpoint, the subscription status —
/// failed on hardware before a single byte reached the network. Riverpod threw
/// `CircularDependencyError` from inside `ApiClient._send`: `apiClientProvider`
/// read `authRepositoryProvider` for the token, and `AuthRepository` was built
/// from `apiClientProvider`. The health probe was the only thing that worked,
/// because it calls `dio.get` directly and never asks for a token.
///
/// It reached a phone because **nothing had ever built the real provider graph
/// and made a call through it**. `flutter analyze` is happy with a cycle written
/// through closures; the widget tests override the providers they use, which is
/// exactly what hides this; and the server tests never see Dart. The gap was not
/// a missing assertion, it was a missing *shape* of test.
///
/// So these tests take the real container, with only the database swapped for an
/// in-memory one, and exercise the paths that construct and use the graph. They
/// need no phone and no server.
void main() {
  late LunioDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = await freshDatabase();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        // Port 1 on loopback refuses instantly. The graph is otherwise entirely
        // real — this changes where the socket points, not how it is built,
        // which is the part under test. Without it each call waits out the
        // twenty-second connect timeout.
        apiBaseProvider.overrideWithValue('http://127.0.0.1:1'),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('every provider in the composition root can be constructed', () async {
    // Construction alone would not have caught the 2026-08-29 cycle — it was a
    // read that happened at call time, not at build time — but it catches the
    // cheaper mistakes, and it is the natural first line of this file.
    expect(container.read(databaseProvider), isNotNull);
    expect(container.read(tokenStoreProvider), isNotNull);
    expect(container.read(apiClientProvider), isNotNull);
    expect(container.read(authRepositoryProvider), isNotNull);
    expect(container.read(settingsRepositoryProvider), isNotNull);
    expect(container.read(starRepositoryProvider), isNotNull);
    expect(container.read(sessionRepositoryProvider), isNotNull);
    expect(container.read(lessonRepositoryProvider), isNotNull);
    expect(container.read(subscriptionRepositoryProvider), isNotNull);
    expect(container.read(weeklyTestRepositoryProvider), isNotNull);
    expect(container.read(blockingRepositoryProvider), isNotNull);
    expect(container.read(clockRepositoryProvider), isNotNull);
  });

  group('the token path is reachable — the 2026-08-29 regression', () {
    /// Fails with a **network** error, never a dependency error.
    ///
    /// `AppConfig.apiBase` in a test run is the emulator alias, which nothing is
    /// listening on, so every call below is expected to fail. The point is
    /// *which* failure: an `ApiFailure` means the request was assembled, the
    /// token was read, and the client got as far as the socket.
    /// `CircularDependencyError` means it never got that far.
    Future<void> expectsNetworkFailureNotACycle(
      Future<void> Function() call,
    ) async {
      try {
        await call();
        // A response would mean something really is listening on the test
        // address. Still not a cycle, so the test has done its job.
      } on ApiFailure {
        // The expected outcome.
      } catch (error) {
        fail(
          'expected a network ApiFailure, got ${error.runtimeType}: $error\n'
          'A CircularDependencyError here means apiClientProvider and '
          'authRepositoryProvider depend on each other again — see '
          'data/repositories/token_store.dart.',
        );
      }
    }

    const now = TrustedInstant(
      epochMs: 1787000000000,
      level: TrustLevel.monotonic,
    );

    test('register reaches the network', () async {
      await expectsNetworkFailureNotACycle(
        () => container.read(authRepositoryProvider).register(
              email: 'parent@lunio.test',
              password: 'Lunio-test-2026',
              now: now,
            ),
      );
    });

    test('sign-in reaches the network', () async {
      await expectsNetworkFailureNotACycle(
        () => container.read(authRepositoryProvider).signIn(
              email: 'parent@lunio.test',
              password: 'Lunio-test-2026',
              now: now,
            ),
      );
    });

    test('starting the trial reaches the network', () async {
      await expectsNetworkFailureNotACycle(
        () => container.read(subscriptionRepositoryProvider).startTrial(now),
      );
    });

    test('redeeming an activation code reaches the network', () async {
      await expectsNetworkFailureNotACycle(
        () => container
            .read(subscriptionRepositoryProvider)
            .activate('ABCDE-12345', now),
      );
    });

    test('the subscription refresh reaches the network', () async {
      await expectsNetworkFailureNotACycle(
        () => container.read(subscriptionRepositoryProvider).refresh(now),
      );
    });
  });

  group('the install id, which every one of those calls carries', () {
    test('is minted once and then stable', () async {
      final settings = container.read(settingsRepositoryProvider);
      final first = await settings.installId();
      final second = await settings.installId();

      expect(first, isNotEmpty);
      expect(second, first, reason: 'a second id would claim a second device');
    });

    test('looks like a v4 UUID', () async {
      // The server field is a UUIDField; anything else is a 400 that would only
      // show up as "register does not work".
      final id = await container.read(settingsRepositoryProvider).installId();
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
            r'[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('is sent with every authenticated call', () async {
      final fields = await container.read(authRepositoryProvider).deviceFields();
      expect(fields.keys, contains('install_id'));
      expect(fields['install_id'], isNotEmpty);
    });
  });
}
