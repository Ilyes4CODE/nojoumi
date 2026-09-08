import 'package:lunio_stars/lunio_stars.dart';

/// How stars and play time are written, everywhere.
///
/// One place, because the same two numbers appear on the child's screen, in the
/// setup wizard, on the parent's dashboard and in the session summary — and the
/// first version of this app already managed to print "10" in one place and
/// "10.0" in another for the same balance.
class Fmt {
  const Fmt._();

  /// Half stars are real (Art. 5), so `3.5` must be representable. A whole
  /// number must **not** be written `4.0`: a decimal point on an exact value
  /// reads as an approximation of something, and a star count is exact.
  static String stars(int units) {
    final remainder = units % starUnit;
    if (remainder == 0) return '${units ~/ starUnit}';
    return (units / starUnit).toStringAsFixed(1);
  }

  /// `mm:ss`, because the star value may be half a minute (appendix §5) and so
  /// half a star is thirty seconds. Rounding that to "1 minute" would be a lie
  /// the child can measure with the clock on the wall.
  static String duration(int seconds) {
    if (seconds < 0) seconds = 0;
    // Hours appear only when there are any. `MM:SS` alone was fine while play
    // time came from stars — the daily ceiling puts it under an hour — but a
    // parent handing over two hours of free play would have read `120:00`,
    // which is a number nobody parses as two hours.
    final h = seconds ~/ 3600;
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  /// A signed amount, for the parent's ledger: `+3`, `−2.5`.
  ///
  /// Uses U+2212 MINUS SIGN rather than a hyphen: in a right-to-left line a
  /// hyphen next to Arabic digits is ambiguous, and the minus sign is not.
  static String signedStars(int units) {
    if (units < 0) return '−${stars(-units)}';
    return '+${stars(units)}';
  }
}
