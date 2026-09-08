/// Build-time configuration.
///
/// Everything here arrives through `--dart-define`, never through a file in the
/// repository, because the one thing that varies between the developer's machine,
/// a tester's phone and the client's server is where the server *is* — and a URL
/// hardcoded in Dart is a URL that ships wrong.
///
/// ```
/// flutter run --dart-define=LUNIO_API_BASE=http://10.0.2.2:8000
/// flutter build appbundle --dart-define=LUNIO_API_BASE=https://api.example.dz
/// ```
///
/// **There is no API key here and there never will be.** Article 7.7 and docs/CONVENTIONS.md
/// both say it plainly: no AI key, no payment key, nothing secret in `app/`. The
/// app talks only to our own server, and the server holds every credential.
class AppConfig {
  const AppConfig._();

  /// Where the Django server lives.
  ///
  /// The default is the Android emulator's alias for the host machine's
  /// localhost, which is the only value that is right by default for anybody.
  /// A real device on the same network needs the machine's LAN address; the
  /// client's VPS is open question Q19.
  static const String apiBase = String.fromEnvironment(
    'LUNIO_API_BASE',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// The Ed25519 public key that verifies the subscription snapshot (Art. 7.6).
  ///
  /// **The matching private key exists only in the server's environment**, which
  /// is what makes the signature mean anything: a child who edits the local
  /// database produces a snapshot that fails verification, and an unverified
  /// snapshot is treated as no subscription — free mode, where blocking and stars
  /// keep working (Art. 7.1). Tampering costs nothing and gains nothing.
  ///
  /// Generate the pair with `python manage.py generate_signing_key`; the private
  /// half goes in `server/.env`, the public half here.
  ///
  /// ```
  /// flutter build appbundle
  ///   --dart-define=LUNIO_API_BASE=https://api.example.dz
  ///   --dart-define=LUNIO_SNAPSHOT_PUBLIC_KEY=<64 hex characters>
  /// ```
  ///
  /// This is a **public** key, so it is not a secret and shipping it in the
  /// binary is the point. It is a `--dart-define` rather than a constant only
  /// because it changes between the developer's server and the client's.
  static const String snapshotPublicKey = String.fromEnvironment(
    'LUNIO_SNAPSHOT_PUBLIC_KEY',
  );

  /// Where the payment page lives.
  ///
  /// A separate define from [apiBase] because the two genuinely separate in
  /// production: the API is an origin the app talks to, while this is a page a
  /// **parent reads in a browser**, and the client may host it on the marketing
  /// domain rather than on the API host. Defaults to `/pay/` on the API origin,
  /// which is where the server serves it in development.
  ///
  /// **Its existence is a deliberate departure from Article 7.2**, made at the
  /// client's direction on 2026-08-29 — see `features/parent/subscription_screen.dart`.
  static String get payUrl {
    const configured = String.fromEnvironment('LUNIO_PAY_URL');
    if (configured.trim().isNotEmpty) return configured;
    final base = apiBase.trim();
    if (base.isEmpty) return '';
    return '${base.endsWith('/') ? base.substring(0, base.length - 1) : base}/pay/';
  }

  /// Whether a server has been configured at all.
  ///
  /// Checked before any network feature is offered, so the app can say "no server
  /// configured" instead of failing with a connection error that reads like a bug.
  static bool get hasApi => apiBase.trim().isNotEmpty;

  /// Generous, because the lesson endpoint waits on a vision model. Measured at
  /// roughly two seconds per page against Groq (decisions.md D-28), but a slow
  /// Algerian mobile connection uploading a photo is the real constraint.
  static const Duration lessonTimeout = Duration(seconds: 90);

  /// Ordinary calls: authentication, subscription status.
  static const Duration apiTimeout = Duration(seconds: 20);
}
