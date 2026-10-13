import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/data/remote/api_client.dart';
import 'package:lunio/data/repositories/auth_repository.dart';
import 'package:lunio/data/repositories/settings_repository.dart';
import 'package:lunio/data/repositories/token_store.dart';

import 'support/test_db.dart';

/// Deleting the parent account from inside the app.
///
/// Google Play requires it for any app that creates accounts (added 2026-10-13,
/// during the first submission). The server half — what is deleted, what is
/// kept, the throttle — is `server/apps/accounts/tests/test_account_deletion.py`.
/// This half is what the phone does with the answer.
void main() {
  late LunioDatabase db;
  late _Adapter adapter;
  late TokenStore tokens;
  late AuthRepository auth;

  setUp(() async {
    db = await freshDatabase();
    adapter = _Adapter();
    tokens = TokenStore(db);
    await tokens.write(
      access: 'access-token',
      refresh: 'refresh-token',
      email: 'wali@bayt.dz',
      atMs: 0,
    );
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

  test('a deleted account leaves the phone signed out', () async {
    adapter.answer(204, null);

    await auth.deleteAccount(password: 'n7-Sabah-Khayr-2026');

    expect(await auth.isSignedIn, isFalse);
    expect(adapter.sent?['password'], 'n7-Sabah-Khayr-2026');
  });

  test('a wrong password says so and keeps the session', () async {
    adapter.answer(403, {'detail': 'كلمة المرور غير صحيحة.'});

    await expectLater(
      auth.deleteAccount(password: 'not-it'),
      throwsA(
        isA<ApiFailure>().having((f) => f.message, 'message', contains('كلمة المرور')),
      ),
    );
    expect(await auth.isSignedIn, isTrue,
        reason: 'a typo must not cost the parent their session');
  });

  test('a server failure deletes nothing locally either', () async {
    adapter.answer(500, {'detail': 'boom'});

    await expectLater(
      auth.deleteAccount(password: 'n7-Sabah-Khayr-2026'),
      throwsA(isA<ApiFailure>()),
    );
    expect(await auth.isSignedIn, isTrue);
  });
}

class _Adapter implements HttpClientAdapter {
  int _status = 404;
  Object? _body;
  Map<String, dynamic>? sent;

  void answer(int status, Object? body) {
    _status = status;
    _body = body;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!options.path.endsWith('/api/accounts/delete/')) {
      return ResponseBody.fromString('{}', 404);
    }
    final data = options.data;
    if (data is Map) sent = Map<String, dynamic>.from(data);
    return ResponseBody.fromString(
      _body == null ? '' : jsonEncode(_body),
      _status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
