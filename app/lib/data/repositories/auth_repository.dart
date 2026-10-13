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

  // --- Forgotten password ---------------------------------------------------
  //
  // A six-digit code by email, not a link. The app has no deep links — no
  // intent filter, no App Links verification — so a link would open a browser,
  // which would need its own reset page and its own session handling, and the
  // parent would end up carrying a password between two places. The code stays
  // here, and it is the same errand as the activation code of Article 7.3: read
  // a short string on one screen, type it on another.
  //
  // **The three calls answer alike for an address that has an account and one
  // that does not.** That is the server's rule and the app must not undo it by
  // saying something more helpful — "no account with that email" on a parental
  // control app tells whoever is holding the phone which addresses exist.

  /// Ask the server to mail a code.
  ///
  /// Succeeds whether or not the address is registered, and whether or not a
  /// message was actually sent. The screen says "if this address is registered"
  /// for that reason rather than out of politeness.
  Future<String> requestPasswordReset({required String email}) async {
    const fallback = 'تحقّق من بريدك الإلكتروني.';
    final response = await _api.post(
      '/api/accounts/password/reset/',
      body: {'email': email.trim()},
    );

    if (response.statusCode != 200) {
      throw ApiFailure(
        ApiClient.messageFrom(response, 'تعذّر إرسال الرمز.'),
        statusCode: response.statusCode,
        retryable: (response.statusCode ?? 500) >= 500,
      );
    }
    return ApiClient.messageFrom(response, fallback);
  }

  /// Check a code before asking the parent to invent a password.
  ///
  /// Exists so nobody types a new password twice and is only then told the code
  /// expired. It spends one of the five attempts, the same budget the confirm
  /// call draws on, so it buys the parent kindness and an attacker nothing.
  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final response = await _api.post(
      '/api/accounts/password/reset/verify/',
      body: {'email': email.trim(), 'code': code.trim()},
    );
    if (response.statusCode != 200) {
      throw ApiFailure(
        ApiClient.messageFrom(response, 'الرمز غير صحيح أو انتهت صلاحيته.'),
        statusCode: response.statusCode,
      );
    }
  }

  /// Set the new password, then sign in with it.
  ///
  /// Signing in here rather than sending the parent back to a login form: they
  /// have just proved they own the address and chosen a password, and asking
  /// them to type it again immediately is a form with no question in it.
  ///
  /// The sign-in is also what replaces the tokens. The reset ends every session
  /// this account had, including this device's — the server binds a hash of the
  /// password into each token — so without this call the app would be holding
  /// credentials the server has already stopped honouring.
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String password,
    required TrustedInstant now,
  }) async {
    final response = await _api.post(
      '/api/accounts/password/reset/confirm/',
      body: {
        'email': email.trim(),
        'code': code.trim(),
        'password': password,
      },
    );

    if (response.statusCode != 200) {
      throw ApiFailure(
        ApiClient.messageFrom(response, 'تعذّر تغيير كلمة المرور.'),
        statusCode: response.statusCode,
      );
    }

    await signIn(email: email, password: password, now: now);
  }

  /// Forget the tokens.
  ///
  /// Signing out takes nothing away from the child: Article 7.1 keeps blocking,
  /// stars and saved lessons working, and all of them are local. What stops is
  /// generating new lessons, which needs the server.
  Future<void> signOut() => _tokens.clear();

  /// Delete the account on the server, then forget the tokens.
  ///
  /// Google Play requires this inside the app (2026-10-13). The password is asked
  /// again because the phone is the child's: being signed in on it proves
  /// nothing about who is tapping. The server answers a wrong one with 403, not
  /// 401, so the client's refresh-and-retry does not turn a typo into "signed
  /// out".
  ///
  /// The tokens are cleared only after the server confirms. A failure leaves the
  /// parent signed in to an account that still exists, which is the truth.
  Future<void> deleteAccount({required String password}) async {
    final response = await _api.post(
      '/api/accounts/delete/',
      body: {'password': password},
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiFailure(
        ApiClient.messageFrom(response, 'تعذّر حذف الحساب.'),
        statusCode: response.statusCode,
      );
    }
    await _tokens.clear();
  }

  Future<void> _write({
    required String access,
    required String refresh,
    required String email,
    required int? atMs,
  }) =>
      _tokens.write(access: access, refresh: refresh, email: email, atMs: atMs);
}
