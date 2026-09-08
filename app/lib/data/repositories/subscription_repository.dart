import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:lunio_subscription/lunio_subscription.dart';
import 'package:lunio_time/lunio_time.dart';

import '../../core/config.dart';
import '../local/database.dart';
import '../local/tables.dart';
import '../remote/api_client.dart';
import 'auth_repository.dart';

/// Article 7.6 — the server decides, the device verifies.
///
/// > "المرجع الأساسي لحالة الاشتراك هو الخادم، وليس الجهاز، منعاً للتلاعب."
///
/// The device keeps a **signed** copy so it can work offline for seven days, and
/// the signature is the whole point: a child who edits the local database
/// produces a snapshot that fails verification, and an unverified snapshot is
/// treated as no subscription at all — which means free mode, which means
/// blocking and stars keep working (Art. 7.1). Tampering costs the child nothing
/// and gains them nothing.
///
/// **The public key is embedded in the app, never taken from the response.** The
/// server does return one, and using it would be circular: anything able to
/// substitute the snapshot could substitute the key beside it and sign its own
/// payload. The embedded key is the only thing that makes the signature mean
/// anything.
class SubscriptionRepository {
  SubscriptionRepository(
    this._db,
    this._api,
    this._auth, {
    SubscriptionMachine machine = const SubscriptionMachine(),
  }) : _machine = machine;

  final LunioDatabase _db;
  final ApiClient _api;
  final AuthRepository _auth;
  final SubscriptionMachine _machine;

  static const int _singletonId = 1;

  Stream<SubscriptionCacheRow> watch() => (_db.select(
    _db.subscriptionCaches,
  )..where((t) => t.id.equals(_singletonId))).watchSingle();

  Future<SubscriptionCacheRow> _row() => (_db.select(
    _db.subscriptionCaches,
  )..where((t) => t.id.equals(_singletonId))).getSingle();

  /// The cache as the pure state machine wants it.
  Future<SubscriptionCache> cache() async {
    final row = await _row();
    if (row.payloadJson.isEmpty) return const SubscriptionCache();

    final payload = jsonDecode(row.payloadJson);
    if (payload is! Map<String, dynamic>) return const SubscriptionCache();

    final verified = await _verify(row.payloadJson, row.signatureHex);
    return SubscriptionCache(
      snapshot: SubscriptionSnapshot(
        state: _stateFrom('${payload['state']}'),
        plan: _planFrom('${payload['plan']}'),
        startedAtMs: _int(payload['started_at_ms']),
        endsAtMs: _int(payload['ends_at_ms']),
        issuedAtMs: _int(payload['issued_at_ms']),
        signatureValid: verified,
      ),
      fetchedAtMs: row.fetchedAtMs,
    );
  }

  /// What the app may currently do, decided by the pure machine.
  Future<Capabilities> capabilities(TrustedInstant now) async =>
      _machine.capabilities(await cache(), now);

  /// Article 7.4's in-app reminder, 7 days then 2 days before expiry.
  Future<ExpiryReminder?> dueReminder(TrustedInstant now) async =>
      _machine.dueReminder(await cache(), now);

  /// Whether the 24-hour revalidation is due (Art. 7.6).
  ///
  /// Deliberately separate from the seven-day offline window: the app should
  /// *try* after 24 hours, but nothing bad happens until day seven. Conflating
  /// the two would break a family whose internet is intermittent, which is most
  /// of them.
  Future<bool> needsRevalidation(TrustedInstant now) async =>
      _machine.needsRevalidation(await cache(), now);

  /// Fetch and cache a fresh snapshot.
  ///
  /// Returns false when the server could not be reached or the signature did not
  /// verify. **A snapshot that fails verification is never written**: keeping it
  /// would mean the next offline read finds a payload the app already knows is
  /// worthless, and the honest state is "we still have the last good one".
  Future<bool> refresh(TrustedInstant now) async {
    if (!AppConfig.hasApi) return false;

    final response = await _api.get('/api/subscriptions/status/');
    if (response.statusCode != 200) return false;

    final data = response.data;
    if (data is! Map) return false;

    final payload = data['payload'];
    final signature = data['signature'];
    if (payload is! Map || signature is! String) return false;

    // Re-serialised with the server's canonicalisation — sorted keys, no
    // whitespace, UTF-8, no ASCII escaping — because Dio has already decoded the
    // body and the original bytes are gone. Any disagreement here reads as a bad
    // signature, which is why `signing.py` calls this rule a protocol contract
    // and versions the payload rather than editing it.
    final canonical = _canonical(Map<String, dynamic>.from(payload));
    if (!await _verify(canonical, signature)) return false;

    // Art. 7.6 — `fetchedAtMs` anchors the offline window, so storing an
    // untrusted timestamp here would hand a child a way to extend it by moving
    // the clock.
    if (!now.isTrustworthy) return false;

    await (_db.update(
      _db.subscriptionCaches,
    )..where((t) => t.id.equals(_singletonId))).write(
      SubscriptionCachesCompanion(
        payloadJson: Value(canonical),
        signatureHex: Value(signature),
        fetchedAtMs: Value(now.epochMs),
        state: Value(_stateRowFrom('${payload['state']}')),
        plan: Value('${payload['plan']}'),
        endsAtMs: Value(_int(payload['ends_at_ms'])),
        graceEndsAtMs: Value(_int(payload['grace_ends_at_ms'])),
      ),
    );
    return true;
  }

  /// Article 7.1 — the seven-day trial, once per device.
  Future<bool> startTrial(TrustedInstant now) async {
    // `install_id` is **required** by the endpoint, and sending it was missing
    // until 2026-08-28 — the call posted an empty body, so the trial could never
    // have started at all. Article 7.1 puts the trial on the device, not the
    // account: «مرة واحدة لكل جهاز», so a new email address does not reset it.
    final response = await _api.post(
      '/api/subscriptions/trial/',
      body: await _auth.deviceFields(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiFailure(
        ApiClient.messageFrom(response, 'تعذّر بدء الفترة التجريبية.'),
        statusCode: response.statusCode,
      );
    }
    return refresh(now);
  }

  /// Article 7.3 step 5 — the parent types the code from the payment page.
  ///
  /// The code is the only thing that crosses from the web page into the app.
  /// **No card detail ever does** (Art. 7.7), and there is no field anywhere in
  /// this codebase that could hold one.
  Future<bool> activate(String code, TrustedInstant now) async {
    final response = await _api.post(
      '/api/subscriptions/activate/',
      body: {'code': code.trim(), ...await _auth.deviceFields()},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiFailure(
        ApiClient.messageFrom(response, 'رمز التفعيل غير صحيح.'),
        statusCode: response.statusCode,
      );
    }
    return refresh(now);
  }

  // ------------------------------------------------------------- internals

  /// Byte-for-byte what `signing.py:canonical_bytes` produces.
  static String _canonical(Map<String, dynamic> payload) {
    final keys = payload.keys.toList()..sort();
    final buffer = StringBuffer('{');
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) buffer.write(',');
      buffer
        ..write(jsonEncode(keys[i]))
        ..write(':')
        ..write(jsonEncode(payload[keys[i]]));
    }
    buffer.write('}');
    return buffer.toString();
  }

  Future<bool> _verify(String canonicalPayload, String signatureHex) async {
    final publicKeyHex = AppConfig.snapshotPublicKey.trim();
    // No key embedded means nothing can be verified, and Article 7.6 says an
    // unverified snapshot proves nothing. Refusing is the only safe answer: the
    // alternative is a build that trusts anything.
    if (publicKeyHex.isEmpty) return false;

    try {
      final algorithm = Ed25519();
      final signature = Signature(
        _hexToBytes(signatureHex),
        publicKey: SimplePublicKey(
          _hexToBytes(publicKeyHex),
          type: KeyPairType.ed25519,
        ),
      );
      return algorithm.verify(
        utf8.encode(canonicalPayload),
        signature: signature,
      );
    } on FormatException {
      return false;
    } on ArgumentError {
      return false;
    }
  }

  static List<int> _hexToBytes(String hex) {
    if (hex.length.isOdd) throw const FormatException('odd-length hex');
    return [
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ];
  }

  static int _int(Object? value) => value is int ? value : 0;

  static SubscriptionState _stateFrom(String raw) => switch (raw) {
    'trial' => SubscriptionState.trial,
    'active' => SubscriptionState.active,
    'grace' => SubscriptionState.grace,
    'refunded' => SubscriptionState.refunded,
    // Anything unrecognised is treated as expired, which is free mode. A new
    // state string from a newer server must never be read as more access
    // than the app understands.
    _ => SubscriptionState.expired,
  };

  static SubscriptionStateRow _stateRowFrom(String raw) => switch (raw) {
    'trial' => SubscriptionStateRow.trial,
    'active' => SubscriptionStateRow.active,
    'grace' => SubscriptionStateRow.grace,
    'refunded' => SubscriptionStateRow.refunded,
    _ => SubscriptionStateRow.expired,
  };

  static SubscriptionPlan _planFrom(String raw) => switch (raw) {
    'monthly' => SubscriptionPlan.monthly,
    'annual' => SubscriptionPlan.annual,
    _ => SubscriptionPlan.trial,
  };
}
