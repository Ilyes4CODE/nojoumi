import 'package:lunio_time/lunio_time.dart';

import '../local/database.dart';
import '../remote/api_client.dart';
import 'settings_repository.dart';
import 'token_store.dart';

/// The parent's account.
///
/// **The child never has one.** Article 14 keeps every byte about the child on the
/// device, and AD-6 says the server holds a parent account, a subscription and
/// transactions — nothing else. So this repository exists for exactly one reason:
/// the lesson endpoint and the subscription endpoint are authenticated, and
/// somebody has to hold the token.
///
/// The account is email plus password (D-25). No SMS gateway, no phone
/// verification, no social sign-in — none of which is in scope, and a Google
/// sign-in button on a child's phone would drag the app into Designed for Families
/// scrutiny for nothing.
class AuthRepository {
  AuthRepository(this._tokens, this._api, this._settings);

  final TokenStore _tokens;
  final ApiClient _api;
  final SettingsRepository _settings;

  /// The device fields sent with register and sign-in.
  ///
  /// The install UUID anchors two rules the contract puts on the **device**
  /// rather than the account: Article 7.1's once-per-device trial, and the
  /// one-account-per-phone rule of 2026-08-28. Without it the server had nothing
  /// to key either rule on — and `startTrial` was posting an empty body against
  /// an endpoint whose `install_id` is required, so the trial could never have
  /// started at all.
  ///
  /// Optional on the wire, so a failure to read it degrades to "no device rule"
  /// rather than to "cannot sign in".
  Future<Map<String, Object?>> deviceFields() async {
    final id = await _settings.installId();
    return {'install_id': id};
  }

  Stream<AuthTokenRow> watch() => _tokens.watch();

  Future<bool> get isSignedIn => _tokens.isSignedIn;

  /// Create the parent account, then sign in with the same credentials.
  ///
  /// Registration does not return tokens — `RegisterView` creates the account and
  /// nothing more — so the sign-in is a second call rather than an oversight.
  Future<void> register({
    required String email,
    required String password,
    String phone = '',
    required TrustedInstant now,
  }) async {
    final response = await _api.post(
      '/api/accounts/register/',
      body: {
        'email': email.trim(),
        'password': password,
        if (phone.trim().isNotEmpty) 'phone': phone.trim(),
        ...await deviceFields(),
      },
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiFailure(
        // 409 is the one-account-per-phone rule, and the server's Arabic message
        // already says what to do about it, so it is passed through rather than
        // replaced by a generic line.
        ApiClient.messageFrom(response, 'تعذّر إنشاء الحساب.'),
        statusCode: response.statusCode,
      );
    }
    await signIn(email: email, password: password, now: now);
  }

  Future<void> signIn({
    required String email,
    required String password,
    required TrustedInstant now,
  }) async {
    final response = await _api.post(
      '/api/accounts/token/',
      body: {
        'email': email.trim(),
        'password': password,
        ...await deviceFields(),
      },
    );

    if (response.statusCode != 200) {
      throw ApiFailure(
        // 401 here means the pair was wrong, which is the common case and worth
        // saying plainly rather than echoing the server's generic wording.
        response.statusCode == 401
            ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
            // 400 carries the device rule's own message; anything else gets the
            // generic line.
            : ApiClient.messageFrom(response, 'تعذّر تسجيل الدخول.'),
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is! Map || data['access'] is! String) {
      throw const ApiFailure('ردّ الخادم غير مفهوم.');
    }

    await _write(
      access: data['access'] as String,
      refresh: data['refresh'] is String ? data['refresh'] as String : '',
      email: email.trim(),
      // Untrusted time is stored as-is here on purpose: this is a display value
      // for the parent, not a contract window. Nothing is granted or extended by
      // it, so Article 7.6 is not in play.
      atMs: now.epochMs,
    );
  }

  /// Forget the tokens.
  ///
  /// Signing out takes nothing away from the child: Article 7.1 keeps blocking,
  /// stars and saved lessons working, and all of them are local. What stops is
  /// generating new lessons, which needs the server.
  Future<void> signOut() => _tokens.clear();

  Future<void> _write({
    required String access,
    required String refresh,
    required String email,
    required int? atMs,
  }) =>
      _tokens.write(access: access, refresh: refresh, email: email, atMs: atMs);
}
