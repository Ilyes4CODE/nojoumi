import 'package:drift/drift.dart';

import '../local/database.dart';

/// Where the parent's tokens live, and **nothing else**.
///
/// Split out of `AuthRepository` on 2026-08-29 to break a provider cycle that
/// made every authenticated call in the app fail before it reached the network.
///
/// The cycle: `apiClientProvider` needed a way to read the access token and to
/// refresh it, so it reached for `authRepositoryProvider`; `AuthRepository`
/// needed an `ApiClient` to make requests. Written as closures it looked lazy
/// enough to be safe, and it compiled. On a device, the first call through
/// `ApiClient._send` threw `CircularDependencyError` from inside Riverpod —
/// **before the HTTP request was made**, so nothing reached the server and
/// nothing appeared in its log. Only the health probe worked, because it calls
/// `dio.get` directly and never asks for a token. That asymmetry was the clue.
///
/// The fix is structural rather than a suppression: **a token is data**, and the
/// thing that reads it for an Authorization header has no business also being
/// the thing that performs HTTP. This class depends on the database and on
/// nothing else, so both sides can depend on it and neither depends on the
/// other.
class TokenStore {
  TokenStore(this._db);

  final LunioDatabase _db;

  static const int _singletonId = 1;

  Future<AuthTokenRow> row() => (_db.select(
    _db.authTokens,
  )..where((t) => t.id.equals(_singletonId))).getSingle();

  Stream<AuthTokenRow> watch() => (_db.select(
    _db.authTokens,
  )..where((t) => t.id.equals(_singletonId))).watchSingle();

  Future<String?> accessToken() async {
    final token = (await row()).accessToken;
    return token.isEmpty ? null : token;
  }

  Future<String?> refreshToken() async {
    final token = (await row()).refreshToken;
    return token.isEmpty ? null : token;
  }

  Future<bool> get isSignedIn async => (await row()).accessToken.isNotEmpty;

  Future<void> write({
    required String access,
    required String refresh,
    required String email,
    required int? atMs,
  }) async {
    await (_db.update(
      _db.authTokens,
    )..where((t) => t.id.equals(_singletonId))).write(
      AuthTokensCompanion(
        accessToken: Value(access),
        refreshToken: Value(refresh),
        email: Value(email),
        signedInAtMs: Value(atMs),
      ),
    );
  }

  /// Replace only the access token, after a refresh. The refresh token and the
  /// email are untouched — a refresh is not a new session.
  Future<void> writeAccess(String access) async {
    await (_db.update(_db.authTokens)..where((t) => t.id.equals(_singletonId)))
        .write(AuthTokensCompanion(accessToken: Value(access)));
  }

  /// Forget everything.
  ///
  /// Signing out takes nothing away from the child: Article 7.1 keeps blocking,
  /// stars and saved lessons working, and all of them are local. What stops is
  /// generating new lessons, which needs the server.
  Future<void> clear() => write(access: '', refresh: '', email: '', atMs: null);
}
