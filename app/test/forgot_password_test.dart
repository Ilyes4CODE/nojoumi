import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/core/providers.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/data/remote/api_client.dart';
import 'package:lunio/data/repositories/auth_repository.dart';
import 'package:lunio/data/repositories/settings_repository.dart';
import 'package:lunio/data/repositories/token_store.dart';
import 'package:lunio/features/auth/forgot_password_screen.dart';
import 'package:lunio_time/lunio_time.dart';

import 'support/test_db.dart';
import 'support/widget_harness.dart';

/// Getting back into the parent account.
///
/// **Split deliberately in two.** The repository group runs in plain `test()`
/// bodies with a real in-memory database, because the interesting claim there —
/// *confirming a reset leaves the parent signed in* — is a database write. The
/// widget group runs under `pumpScreen`, where D-33 forbids the database: its
/// client is given a token reader that returns nothing, so no step it exercises
/// touches Drift, and the one step that would (confirm, which signs in) is
/// proven in the first group instead.
///
/// Neither group proves the *server* behaves as staged.
/// `server/apps/accounts/tests/test_password_reset.py` does that, and the two
/// files describe the same flow from opposite ends.
void main() {
  const now = TrustedInstant(
    epochMs: 1773133200000,
    level: TrustLevel.serverAnchored,
  );

  group('the repository', () {
    late LunioDatabase db;
    late _ResetAdapter adapter;
    late AuthRepository auth;

    setUp(() async {
      db = await freshDatabase();
      adapter = _ResetAdapter();
      final tokens = TokenStore(db);
      auth = AuthRepository(
        tokens,
        ApiClient(
          dio: Dio()..httpClientAdapter = adapter,
          baseUrl: 'https://example.test',
          readToken: tokens.accessToken,
        ),
        SettingsRepository(db),
      );
    });

    tearDown(() => db.close());

    test("asking for a code returns the server's own sentence", () async {
      adapter.stage('/password/reset/', 200, {
        'detail': 'إذا كان هذا البريد مسجَّلاً لدينا، فقد أرسلنا إليه رمزاً.',
      });

      final said = await auth.requestPasswordReset(email: ' wali@bayt.dz ');

      expect(said, contains('إذا كان'));
      // Trimmed on the way out: a keyboard that adds a space after an address
      // must not produce a different account.
      expect(adapter.sent['/password/reset/']?['email'], 'wali@bayt.dz');
    });

    test("a wrong code raises with the server's message", () async {
      adapter.stage('/password/reset/verify/', 400, {
        'detail': 'الرمز غير صحيح أو انتهت صلاحيته. اطلب رمزاً جديداً.',
      });

      await expectLater(
        auth.verifyResetCode(email: 'wali@bayt.dz', code: '000000'),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.message,
            'message',
            contains('اطلب رمزاً جديداً'),
          ),
        ),
      );
    });

    test('confirming signs the parent in with the new password', () async {
      adapter.stage('/password/reset/confirm/', 200, {'detail': 'تم'});
      adapter.stage('/accounts/token/', 200, {
        'access': 'fresh-access',
        'refresh': 'fresh-refresh',
      });

      await auth.confirmPasswordReset(
        email: 'wali@bayt.dz',
        code: '123456',
        password: 'K8-Masaa-Noor-2026',
        now: now,
      );

      // The reset ends every session this account had, **including this
      // device's** — the server binds a hash of the password into every token.
      // Without the sign-in the app would be holding credentials the server has
      // already stopped honouring, and the parent would find out at the next
      // lesson upload rather than here.
      expect(await auth.isSignedIn, isTrue);
      expect(
        adapter.sent['/accounts/token/']?['password'],
        'K8-Masaa-Noor-2026',
      );
    });

    test('a refused confirmation leaves the parent signed out', () async {
      adapter.stage('/password/reset/confirm/', 400, {
        'detail': 'الرمز غير صحيح أو انتهت صلاحيته. اطلب رمزاً جديداً.',
      });

      await expectLater(
        auth.confirmPasswordReset(
          email: 'wali@bayt.dz',
          code: '000000',
          password: 'K8-Masaa-Noor-2026',
          now: now,
        ),
        throwsA(isA<ApiFailure>()),
      );

      expect(await auth.isSignedIn, isFalse);
      expect(adapter.sent.containsKey('/accounts/token/'), isFalse);
    });
  });

  group('the screen', () {
    late _ResetAdapter adapter;

    /// A repository whose client never asks for a token, so nothing it does
    /// reaches the database. See the note at the top of the file.
    List<Override> overrides(LunioDatabase db) => [
      authRepositoryProvider.overrideWith(
        (ref) => AuthRepository(
          TokenStore(db),
          ApiClient(
            dio: Dio()..httpClientAdapter = adapter,
            baseUrl: 'https://example.test',
            readToken: () async => null,
          ),
          SettingsRepository(db),
        ),
      ),
    ];

    late LunioDatabase db;

    setUp(() {
      adapter = _ResetAdapter();
      db = openTestDatabase();
    });

    tearDown(() => db.close());

    Future<void> open(WidgetTester tester) => pumpScreen(
      tester,
      const ForgotPasswordScreen(email: 'wali@bayt.dz'),
      overrides: overrides(db),
    );

    testWidgets('the address step leads to the code step', (tester) async {
      adapter.stage('/password/reset/', 200, {'detail': 'أرسلنا إليه رمزاً'});

      await open(tester);
      await tester.tap(find.text('أرسل الرمز'));
      await tester.pumpAndSettle();

      expect(find.text('تفقّد بريدك'), findsOneWidget);
      // The one instruction that actually rescues this flow: a transactional
      // message from a new domain lands in spam often enough that a screen
      // which does not mention it is a support call.
      expect(find.textContaining('غير المرغوبة'), findsOneWidget);

      await tester.pump(ForgotPasswordScreen.resendCooldown);
    });

    testWidgets('six digits submit on their own and unlock the password step', (
      tester,
    ) async {
      adapter.stage('/password/reset/', 200, {'detail': 'sent'});
      adapter.stage('/password/reset/verify/', 200, {'detail': 'الرمز صحيح.'});

      await open(tester);
      await tester.tap(find.text('أرسل الرمز'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();

      expect(find.text('اختر كلمة مرور جديدة'), findsOneWidget);
      // Article 7.1, said before the parent can worry about it: a parent told
      // that "other sessions will end" on a parental-control app assumes the
      // controls end with them.
      expect(find.textContaining('على هذا الهاتف'), findsOneWidget);

      await tester.pump(ForgotPasswordScreen.resendCooldown);
    });

    testWidgets('a wrong code stays on the code step and says why', (
      tester,
    ) async {
      adapter.stage('/password/reset/', 200, {'detail': 'sent'});
      adapter.stage('/password/reset/verify/', 400, {
        'detail': 'الرمز غير صحيح أو انتهت صلاحيته. اطلب رمزاً جديداً.',
      });

      await open(tester);
      await tester.tap(find.text('أرسل الرمز'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '000000');
      await tester.pumpAndSettle();

      expect(find.textContaining('اطلب رمزاً جديداً'), findsOneWidget);
      expect(find.text('اختر كلمة مرور جديدة'), findsNothing);

      await tester.pump(ForgotPasswordScreen.resendCooldown);
    });

    testWidgets('two different passwords never reach the server', (
      tester,
    ) async {
      adapter.stage('/password/reset/', 200, {'detail': 'sent'});
      adapter.stage('/password/reset/verify/', 200, {'detail': 'ok'});

      await open(tester);
      await tester.tap(find.text('أرسل الرمز'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'K8-Masaa-Noor-2026');
      await tester.enterText(fields.at(1), 'K8-Masaa-Noor-2025');
      await tester.tap(find.text('حفظ كلمة المرور'));
      await tester.pumpAndSettle();

      expect(find.text('الكلمتان غير متطابقتين.'), findsOneWidget);
      // A typing slip must not spend one of the five code attempts.
      expect(adapter.sent.containsKey('/password/reset/confirm/'), isFalse);

      await tester.pump(ForgotPasswordScreen.resendCooldown);
    });

    testWidgets("resending waits out the server's own cooldown", (
      tester,
    ) async {
      adapter.stage('/password/reset/', 200, {'detail': 'sent'});

      await open(tester);
      await tester.tap(find.text('أرسل الرمز'));
      await tester.pumpAndSettle();

      // The server drops a second request inside a minute and tells nobody. A
      // resend button that quietly does nothing is worse than a disabled one
      // with a number counting down on it.
      final held = tester.widget<TextButton>(
        find.ancestor(
          of: find.textContaining('يمكنك إعادة الإرسال'),
          matching: find.byType(TextButton),
        ),
      );
      expect(held.onPressed, isNull);

      await tester.pump(ForgotPasswordScreen.resendCooldown);
      await tester.pumpAndSettle();
      expect(find.text('لم يصلك شيء؟ أعد الإرسال'), findsOneWidget);
    });
  });

  testWidgets('an unknown address is told so and stays on the address step', (
    tester,
  ) async {
    // The client reversed the original design on 2026-09-25: a parent who
    // mistyped their address should learn it now, not wait for a message that
    // will never come. The test that used to stand here asserted the opposite —
    // that no string on this screen could reveal whether an address exists.
    //
    // The message is the server's own, passed through: the app does not decide
    // what counts as "no account", so it does not word it either.
    final adapter = _ResetAdapter()
      ..stage('/password/reset/', 404, {
        'detail': 'لا يوجد حساب بهذا البريد الإلكتروني. تحقّق من كتابته.',
      });
    final db = openTestDatabase();
    addTearDown(db.close);

    await pumpScreen(
      tester,
      const ForgotPasswordScreen(email: 'mistyped@bayt.dz'),
      overrides: [
        authRepositoryProvider.overrideWith(
          (ref) => AuthRepository(
            TokenStore(db),
            ApiClient(
              dio: Dio()..httpClientAdapter = adapter,
              baseUrl: 'https://example.test',
              readToken: () async => null,
            ),
            SettingsRepository(db),
          ),
        ),
      ],
    );
    await tester.tap(find.text('أرسل الرمز'));
    await tester.pumpAndSettle();

    expect(find.textContaining('لا يوجد حساب'), findsOneWidget);
    // Still asking for the address, so the parent can correct it in place.
    expect(find.text('أرسل الرمز'), findsOneWidget);
    expect(find.text('تفقّد بريدك'), findsNothing);
  });

  testWidgets('a mail failure is shown rather than hidden', (tester) async {
    // Before 2026-09-25 a send failure was swallowed so it could not reveal a
    // real address. That hid a real outage for a day. Once existence is
    // answered openly there is nothing left for silence to protect.
    final adapter = _ResetAdapter()
      ..stage('/password/reset/', 503, {
        'detail': 'تعذّر إرسال البريد الآن. حاول مرة أخرى بعد قليل.',
      });
    final db = openTestDatabase();
    addTearDown(db.close);

    await pumpScreen(
      tester,
      const ForgotPasswordScreen(email: 'wali@bayt.dz'),
      overrides: [
        authRepositoryProvider.overrideWith(
          (ref) => AuthRepository(
            TokenStore(db),
            ApiClient(
              dio: Dio()..httpClientAdapter = adapter,
              baseUrl: 'https://example.test',
              readToken: () async => null,
            ),
            SettingsRepository(db),
          ),
        ),
      ],
    );
    await tester.tap(find.text('أرسل الرمز'));
    await tester.pumpAndSettle();

    expect(find.textContaining('تعذّر إرسال البريد'), findsOneWidget);
    expect(find.text('تفقّد بريدك'), findsNothing);
  });

  test('the spam-folder instruction is still there', () {
    // The sentence that carries the parent through the commonest real failure:
    // the message arriving, in a folder they did not think to open.
    final arb = File('lib/l10n/app_ar.arb').readAsStringSync();
    expect(arb.contains('غير المرغوبة'), isTrue);
  });
}

/// Answers a staged body per path suffix, and remembers what was posted.
class _ResetAdapter implements HttpClientAdapter {
  final Map<String, (int, Object)> _staged = {};

  /// The JSON body of the last request to each path, so a test can assert on
  /// what the app actually sent rather than on what it meant to.
  final Map<String, Map<String, dynamic>> sent = {};

  /// Matched with `endsWith`, never `contains`: `/password/reset/verify/`
  /// contains `/password/reset/`, and a looser match answers the verify call
  /// with the request call's stage — which is a test that passes while proving
  /// nothing.
  void stage(String pathSuffix, int status, Object body) {
    _staged[pathSuffix] = (status, body);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    for (final entry in _staged.entries) {
      if (!options.path.endsWith(entry.key)) continue;

      final data = options.data;
      if (data is Map) {
        sent[entry.key] = Map<String, dynamic>.from(data);
      }

      final (status, body) = entry.value;
      return ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'detail': 'not staged: ${options.path}'}),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
