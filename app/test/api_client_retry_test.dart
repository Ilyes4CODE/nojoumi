import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/data/remote/api_client.dart';

/// The retry that runs after a token expires must be able to send the request
/// **again**, and a multipart body cannot be sent twice.
///
/// **The bug this exists for.** `_send` re-invoked the caller's closure on a 401,
/// and the lesson upload's closure captured one already-built `FormData`. Dio
/// finalizes a `FormData` into a stream as it sends it and refuses to finalize
/// the same one a second time, so the retry threw a `StateError` from inside
/// Dio, which Dio reported as `DioExceptionType.unknown`, which `_networkFailure`
/// turned into «تعذّر الوصول إلى الخادم» — *the server is unreachable*.
///
/// It was the opposite of unreachable. The server had answered 401 promptly and
/// the refresh had succeeded. Nothing about the network was wrong.
///
/// Why it hit **every** lesson upload rather than an unlucky few: SimpleJWT's
/// default access-token lifetime is five minutes, and the path from signing up to
/// photographing a page — grade, PIN, the accessibility disclosure, the
/// dashboard — takes longer than that. So the 401 was not an edge case, it was
/// the normal case, and the one request that had to survive it was the only
/// request in the app that could not.
///
/// Reported by the client as "the AI is not working", the same words as the
/// missing-Pillow fault it was hiding behind.
void main() {
  late Directory temporary;
  late File photograph;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('lunio_retry');
    photograph = File('${temporary.path}/page.jpg')
      ..writeAsBytesSync(List<int>.filled(2048, 7));
  });

  tearDown(() => temporary.delete(recursive: true));

  ApiClient clientFor(_ExpiredTokenAdapter adapter) {
    var access = 'stale';
    return ApiClient(
      dio: Dio()..httpClientAdapter = adapter,
      baseUrl: 'https://example.test',
      readToken: () async => access,
      readRefreshToken: () async => 'refresh',
      writeAccessToken: (fresh) async => access = fresh,
    );
  }

  test('a multipart upload survives an expired access token', () async {
    final adapter = _ExpiredTokenAdapter();
    final client = clientFor(adapter);

    final response = await client.post(
      '/api/lessons/process/',
      form: () async => FormData.fromMap({
        'image': await MultipartFile.fromFile(photograph.path),
        'grade': 'السنة الخامسة ابتدائي',
      }),
    );

    expect(response.statusCode, 200);
    expect(adapter.uploads, 2, reason: 'once rejected, once retried');
    expect(
      adapter.tokens,
      ['Bearer stale', 'Bearer fresh'],
      reason: 'the retry must carry the renewed token, not the expired one',
    );
  });

  test('the retried body still carries the photograph', () async {
    // A retry that rebuilds the form but forgets the file would pass the test
    // above and fail on the server with a validation error about a missing
    // image — which reads to a parent as the photograph being rejected.
    final adapter = _ExpiredTokenAdapter();
    final client = clientFor(adapter);

    await client.post(
      '/api/lessons/process/',
      form: () async => FormData.fromMap({
        'image': await MultipartFile.fromFile(photograph.path),
        'grade': 'السنة الخامسة ابتدائي',
      }),
    );

    expect(adapter.uploadedBytes.last, greaterThan(2048));
  });

  test('a JSON body is retried too, and is not sent twice on success', () async {
    final adapter = _ExpiredTokenAdapter();
    final client = clientFor(adapter);

    final response = await client.post(
      '/api/lessons/process/',
      body: {'grade': 'السنة الخامسة ابتدائي'},
    );

    expect(response.statusCode, 200);
    expect(adapter.uploads, 2);
  });
}

/// Answers the first upload with 401 and every later one with 200, exactly as a
/// server does to a token that expired while the parent was reading a screen.
class _ExpiredTokenAdapter implements HttpClientAdapter {
  int uploads = 0;
  final List<String> tokens = <String>[];
  final List<int> uploadedBytes = <int>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('token/refresh')) {
      return ResponseBody.fromString(
        jsonEncode({'access': 'fresh'}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    uploads += 1;
    tokens.add('${options.headers['Authorization']}');

    // Draining the stream is what a real adapter does, and it is the only way
    // the test can see whether the body was rebuilt or arrived empty.
    var bytes = 0;
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes += chunk.length;
      }
    }
    uploadedBytes.add(bytes);

    return ResponseBody.fromString(
      jsonEncode(uploads == 1 ? {'detail': 'expired'} : {'summary': 'ملخّص'}),
      uploads == 1 ? 401 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
