import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/data/remote/api_client.dart';

/// A parent signs in once, not once a day.
///
/// Reported 2026-11-25: "each day he should log in to the app". The server half
/// is `server/apps/accounts/tests/test_session_lifetime.py` — the refresh token
/// lived one day. This half is what the phone does with a renewal:
///
///  * **it keeps the new refresh token.** The server now rotates them, and a
///    client that kept using the first one would be back on a fixed lifetime;
///  * **only a refused token ends the session.** The client used to sign the
///    parent out on *any* answer but 200 — a 503 while the server restarted
///    after a deployment was enough.
void main() {
  late _Session session;
  late _RefreshAdapter adapter;
  late ApiClient client;

  setUp(() {
    session = _Session();
    adapter = _RefreshAdapter();
    client = ApiClient(
      dio: Dio()..httpClientAdapter = adapter,
      baseUrl: 'https://example.test',
      readToken: () async => session.access,
      readRefreshToken: () async => session.refresh,
      writeAccessToken: (fresh) async => session.access = fresh,
      writeRefreshToken: (fresh) async => session.refresh = fresh,
      endSession: () async => session.ended = true,
    );
  });

  test('a renewal keeps the rotated refresh token', () async {
    adapter.refreshAnswer = (200, {'access': 'fresh', 'refresh': 'rotated'});

    final response = await client.get('/api/accounts/me/');

    expect(response.statusCode, 200);
    expect(session.access, 'fresh');
    expect(session.refresh, 'rotated',
        reason: 'the next renewal must present the token the server just issued');
    expect(session.ended, isFalse);
  });

  test('a server without rotation leaves the refresh token alone', () async {
    adapter.refreshAnswer = (200, {'access': 'fresh'});

    await client.get('/api/accounts/me/');

    expect(session.refresh, 'first');
  });

  test('a refused refresh token ends the session', () async {
    adapter.refreshAnswer = (401, {'detail': 'Token is invalid or expired'});

    await client.get('/api/accounts/me/');

    expect(session.ended, isTrue);
  });

  for (final status in [500, 502, 503]) {
    test('a $status while renewing does not sign the parent out', () async {
      // A deployment restarts the server; for a few seconds it answers 503.
      // That is not the parent's session being over.
      adapter.refreshAnswer = (status, {'detail': 'unavailable'});

      await client.get('/api/accounts/me/');

      expect(session.ended, isFalse);
      expect(session.refresh, 'first');
    });
  }
}

class _Session {
  String access = 'stale';
  String refresh = 'first';
  bool ended = false;
}

/// Answers any call made with the stale token with 401, any call made with a
/// fresh one with 200, and the refresh endpoint with whatever the test stages.
class _RefreshAdapter implements HttpClientAdapter {
  (int, Map<String, Object?>) refreshAnswer = (200, {'access': 'fresh'});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final headers = {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };
    if (options.path.contains('token/refresh')) {
      final (status, body) = refreshAnswer;
      return ResponseBody.fromString(jsonEncode(body), status, headers: headers);
    }
    final fresh = options.headers['Authorization'] == 'Bearer fresh';
    return ResponseBody.fromString(
      jsonEncode({'detail': fresh ? 'ok' : 'expired'}),
      fresh ? 200 : 401,
      headers: headers,
    );
  }

  @override
  void close({bool force = false}) {}
}
