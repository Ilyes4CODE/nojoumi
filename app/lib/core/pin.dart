import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Hashing for the parent's PIN.
///
/// D-10: the PIN is stored as a salted hash and is **never recoverable**. Reset
/// goes through the parent's authenticated server account, because a
/// locally-resettable PIN is not a PIN — the child holds the phone.
///
/// The threat model is specific and worth stating, because it decides the cost
/// parameter: the attacker is a child with the device, unlimited attempts, and a
/// four-digit space of 10 000 values. No hash makes that space large. What
/// PBKDF2 buys is that the stored value cannot be *read off* and reused, and
/// that a brute-force costs real time per guess rather than none. The rate limit
/// on the entry screen is what actually defends the PIN; this defends the file.
class PinHasher {
  const PinHasher({this.iterations = 120000});

  /// Deliberately high for a value that is verified once in a while by a parent,
  /// on the low-end Article 13 device. Measure this on the reference phone: if a
  /// single verification exceeds roughly a quarter of a second there, lower it —
  /// a parent who waits for the settings screen stops opening the settings.
  ///
  /// **UNVERIFIED-ON-HARDWARE.**
  final int iterations;

  static const int minimumDigits = 4;

  /// Whether a candidate PIN is even allowed to be set.
  static bool isAcceptable(String pin) =>
      pin.length >= minimumDigits && RegExp(r'^\d+$').hasMatch(pin);

  Future<PinCredential> hash(String pin) async {
    final salt = _randomSalt();
    final key = await _derive(pin, salt);
    return PinCredential(hash: base64Encode(key), salt: base64Encode(salt));
  }

  /// Constant-time comparison, so a wrong PIN cannot be narrowed down by timing
  /// the response. Cheap to do, and the alternative is a subtle hole.
  Future<bool> verify(String pin, PinCredential credential) async {
    final salt = base64Decode(credential.salt);
    final expected = base64Decode(credential.hash);
    final actual = await _derive(pin, salt);
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }

  Future<List<int>> _derive(String pin, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    return key.extractBytes();
  }

  static List<int> _randomSalt([int length = 16]) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}

/// What gets stored. The PIN itself appears nowhere in this type.
class PinCredential {
  const PinCredential({required this.hash, required this.salt});

  final String hash;
  final String salt;

  bool get isSet => hash.isNotEmpty && salt.isNotEmpty;
}
