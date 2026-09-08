import 'package:dio/dio.dart';

import '../../core/config.dart';

/// What went wrong, in a form a screen can show a parent.
///
/// Dio's own errors are useful to a developer and useless to a parent standing in
/// a kitchen with a schoolbook. Every failure is folded into one of these, and
/// [message] is written to be displayed as-is.
class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode, this.retryable = false});

  final String message;
  final int? statusCode;

  /// Whether trying again could plausibly work. Drives whether the screen offers
  /// a retry button or asks the parent to change something.
  final bool retryable;

  bool get isUnauthorised => statusCode == 401;

  @override
  String toString() => 'ApiFailure($statusCode): $message';
}

/// What a reachability probe found.
///
/// Carries the base URL it tried, because the single most common cause of "it
/// does not connect" is a build launched without `--dart-define` and therefore
/// pointing at the emulator alias `10.0.2.2` from a real phone. A screen that
/// prints the address turns a mystery into a one-look diagnosis.
class ServerHealth {
  const ServerHealth({
    required this.baseUrl,
    required this.reachable,
    this.databaseOk = false,
    this.serverTimeMs,
    this.detail = '',
  });

  final String baseUrl;
  final bool reachable;

  /// The server answered but reported its own database as down. A different
  /// instruction to the developer than "unreachable", so it is a separate field
  /// rather than folded into [reachable].
  final bool databaseOk;

  /// The server's clock, for `TrustedClock` to anchor on (AD-2). Available
  /// before the parent has an account, which is what lets a fresh install
  /// establish trusted time on its first screen.
  final int? serverTimeMs;

  final String detail;

  bool get healthy => reachable && databaseOk;
}

/// Supplies the current access token, or null when signed out.
typedef TokenReader = Future<String?> Function();

/// Supplies the refresh token, or null when there is no session to renew.
typedef RefreshTokenReader = Future<String?> Function();

/// Stores a freshly minted access token.
typedef AccessTokenWriter = Future<void> Function(String access);

/// Called when a refresh is refused and the session is genuinely over.
typedef SessionEnder = Future<void> Function();

/// The one HTTP client.
///
/// It talks to our Django server and to nothing else. Article 7.7 and docs/CONVENTIONS.md
/// are the reason: the AI provider and the payment gateway are reached only from
/// the server, so the app holds no key of any kind and there is no second base URL
/// to get wrong.
class ApiClient {
  ApiClient({
    Dio? dio,
    String? baseUrl,
    required TokenReader readToken,
    RefreshTokenReader? readRefreshToken,
    AccessTokenWriter? writeAccessToken,
    SessionEnder? endSession,
  }) : _baseUrl = baseUrl ?? AppConfig.apiBase,
       _readToken = readToken,
       _readRefreshToken = readRefreshToken,
       _writeAccessToken = writeAccessToken,
       _endSession = endSession,
       dio = dio ?? Dio() {
    this.dio.options
      ..baseUrl = _baseUrl
      ..connectTimeout = AppConfig.apiTimeout
      ..receiveTimeout = AppConfig.apiTimeout
      // Statuses are handled by us, not thrown by Dio, so a 422 carrying a
      // readable Arabic message reaches the screen instead of a stack trace.
      ..validateStatus = (_) => true;
  }

  final Dio dio;

  /// Where the server is, as an instance field rather than a global read.
  ///
  /// It comes from `AppConfig.apiBase` in the app. It is a parameter so that a
  /// test can point the **real** provider graph at an address that refuses
  /// instantly instead of waiting out a twenty-second connect timeout — five
  /// tests at twenty seconds is a suite nobody runs, and a suite nobody runs is
  /// the reason the provider cycle reached a phone in the first place.
  final String _baseUrl;

  final TokenReader _readToken;
  final RefreshTokenReader? _readRefreshToken;
  final AccessTokenWriter? _writeAccessToken;
  final SessionEnder? _endSession;

  /// Ask the server whether it is there. Never throws.
  ///
  /// Unauthenticated and outside the token interceptor on purpose: it is called
  /// on the setup screen, before an account exists, which is exactly where a
  /// wrong address shows up. A short timeout because a parent staring at a
  /// spinner learns nothing that twenty seconds would add.
  Future<ServerHealth> health() async {
    final base = _baseUrl;
    if (base.trim().isEmpty) {
      return ServerHealth(
        baseUrl: base,
        reachable: false,
        detail: 'لم يُضبط عنوان الخادم في هذه النسخة.',
      );
    }

    // Two attempts, not one.
    //
    // The first probe runs while the setup wizard is still opening, and on the
    // Article 13 reference class of device that is a slow moment: the Oppo A15
    // logged `Displayed MainActivity: +9s794ms` on a debug build, with Wi-Fi
    // still associating behind it. A single attempt that lands in that window
    // reports "cannot reach the server" about a server that is answering
    // perfectly — and the parent then goes looking for a fault that is not
    // there. One retry costs a second and removes the whole class of false
    // alarm.
    final first = await _probe(base);
    if (first.reachable) return first;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return _probe(base);
  }

  Future<ServerHealth> _probe(String base) async {
    try {
      final response = await dio.get<dynamic>(
        '/api/health/',
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
        ),
      );
      final data = response.data;
      if (response.statusCode != 200 || data is! Map) {
        return ServerHealth(
          baseUrl: base,
          reachable: false,
          detail: 'الخادم ردّ بحالة ${response.statusCode}.',
        );
      }
      return ServerHealth(
        baseUrl: base,
        reachable: true,
        databaseOk: data['database'] == true,
        serverTimeMs: data['server_time_ms'] is int
            ? data['server_time_ms'] as int
            : null,
      );
    } on DioException catch (error) {
      return ServerHealth(
        baseUrl: base,
        reachable: false,
        detail: _reason(error),
      );
    } catch (_) {
      return ServerHealth(baseUrl: base, reachable: false);
    }
  }

  static String _reason(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => 'انتهت مهلة الاتصال بالخادم.',
    DioExceptionType.connectionError =>
      'لا يمكن الوصول إلى الخادم. تحقّق من أنّ الهاتف والحاسوب على نفس الشبكة.',
    _ => 'تعذّر الاتصال بالخادم.',
  };

  Future<Response<dynamic>> get(String path) => _send(
    (headers) => dio.get<dynamic>(path, options: Options(headers: headers)),
  );

  Future<Response<dynamic>> post(
    String path, {
    Object? body,
    FormData? form,
    Duration? timeout,
  }) {
    return _send(
      (headers) => dio.post<dynamic>(
        path,
        data: form ?? body,
        options: Options(
          headers: headers,
          receiveTimeout: timeout ?? AppConfig.apiTimeout,
          sendTimeout: timeout ?? AppConfig.apiTimeout,
        ),
      ),
    );
  }

  /// Sends with the bearer token attached, and retries **once** after refreshing
  /// if the server says the token expired.
  ///
  /// Once, deliberately. A refresh loop against an expired refresh token is an
  /// app that hammers the server and never tells the parent to sign in again.
  Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function(Map<String, String>) call,
  ) async {
    if (_baseUrl.trim().isEmpty) {
      throw const ApiFailure('لم يُضبط عنوان الخادم بعد.');
    }

    Map<String, String> headers = {};
    final token = await _readToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    Response<dynamic> response;
    try {
      response = await call(headers);
    } on DioException catch (error) {
      throw _networkFailure(error);
    }

    if (response.statusCode == 401 && _readRefreshToken != null) {
      final refreshed = await _refreshAccessToken();
      if (refreshed != null && refreshed.isNotEmpty) {
        try {
          response = await call({'Authorization': 'Bearer $refreshed'});
        } on DioException catch (error) {
          throw _networkFailure(error);
        }
      }
    }
    return response;
  }

  /// Renew the access token, here rather than in a repository.
  ///
  /// It used to live in `AuthRepository`, which is what created the provider
  /// cycle described in `token_store.dart`: the client reached for the
  /// repository to refresh, and the repository reached for the client to send.
  ///
  /// It belongs here on its own merits, not only to break the cycle. The refresh
  /// endpoint is **unauthenticated** — it carries the refresh token in the body
  /// and takes no Authorization header — so it is the one call that must not go
  /// through the token path, and putting it behind the same interceptor that
  /// triggers it was always circular in spirit as well as in wiring.
  Future<String?> _refreshAccessToken() async {
    final read = _readRefreshToken;
    if (read == null) return null;

    final token = await read();
    if (token == null || token.isEmpty) return null;

    Response<dynamic> response;
    try {
      response = await dio.post<dynamic>(
        '/api/accounts/token/refresh/',
        data: {'refresh': token},
      );
    } on DioException {
      // A network failure is not an invalid session. Ending it here would sign
      // the parent out every time the Wi-Fi drops.
      return null;
    }

    final data = response.data;
    final access = data is Map ? data['access'] : null;
    if (response.statusCode != 200 || access is! String || access.isEmpty) {
      await _endSession?.call();
      return null;
    }

    await _writeAccessToken?.call(access);
    return access;
  }

  /// Turn a transport error into something a parent can act on.
  ///
  /// The distinction that matters is **no connection** versus **the server is
  /// unreachable**: the first is the parent's to fix, the second is ours, and a
  /// single "something went wrong" hides which.
  static ApiFailure _networkFailure(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const ApiFailure(
        'انتهت مهلة الاتصال. حاول مرة أخرى.',
        retryable: true,
      ),
      DioExceptionType.connectionError => const ApiFailure(
        'لا يوجد اتصال بالإنترنت',
        retryable: true,
      ),
      _ => const ApiFailure('تعذّر الوصول إلى الخادم.', retryable: true),
    };
  }

  /// Pull a readable message out of a DRF error body.
  ///
  /// Django REST Framework answers with `{"detail": "..."}` for most errors and
  /// with `{"field": ["..."]}` for validation. Both carry Arabic written by us on
  /// the server, so surfacing them beats inventing a message here.
  static String messageFrom(Response<dynamic> response, String fallback) {
    final data = response.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) return '${value.first}';
        if (value is String && value.isNotEmpty) return value;
      }
    }
    return fallback;
  }
}
