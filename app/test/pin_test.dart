import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/core/pin.dart';

/// D-10 — the PIN is stored as a salted hash and is never recoverable.
///
/// Iterations are lowered here so the suite stays fast; the production value
/// lives in [PinHasher] and still has to be measured on the reference device.
void main() {
  const hasher = PinHasher(iterations: 1000);

  test('the stored credential contains no trace of the PIN', () async {
    final credential = await hasher.hash('482913');
    expect(credential.hash.contains('482913'), isFalse);
    expect(credential.salt.contains('482913'), isFalse);
    expect(credential.isSet, isTrue);
  });

  test('the right PIN verifies and a wrong one does not', () async {
    final credential = await hasher.hash('1234');
    expect(await hasher.verify('1234', credential), isTrue);
    expect(await hasher.verify('1235', credential), isFalse);
    expect(await hasher.verify('', credential), isFalse);
  });

  test('the same PIN hashes differently every time', () async {
    final a = await hasher.hash('1234');
    final b = await hasher.hash('1234');
    expect(a.hash, isNot(b.hash),
        reason: 'a per-credential salt is what stops one leaked hash from '
            'unlocking every install');
    expect(a.salt, isNot(b.salt));
  });

  test('a credential from another PIN never verifies', () async {
    final credential = await hasher.hash('9999');
    expect(await hasher.verify('1111', credential), isFalse);
  });

  test('what may be set as a PIN', () {
    expect(PinHasher.isAcceptable('1234'), isTrue);
    expect(PinHasher.isAcceptable('123456'), isTrue);
    expect(PinHasher.isAcceptable('123'), isFalse, reason: 'four digits min');
    expect(PinHasher.isAcceptable('12a4'), isFalse, reason: 'digits only');
    expect(PinHasher.isAcceptable(''), isFalse);
  });
}
