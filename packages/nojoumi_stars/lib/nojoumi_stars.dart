/// The Nojoumi star engine.
///
/// Contract basis:
///  * Article 5 — "نظام احتساب النجوم": the award table and the weekly-test scale.
///  * Article 6 — "شروط الحصول على النجوم": nine conditions that must hold
///    jointly, plus the parent's authority above the system.
///  * Appendix «آلية النجوم ووقت اللعب» — the parent-adjustable defaults and
///    ranges (§5), how the balance is spent (§2), and the worked example (§3)
///    which is encoded verbatim as a test.
///
/// Pure Dart on purpose: no Flutter, no platform channels, no `DateTime.now()`.
/// Time arrives as a [TrustedInstant] from `nojoumi_time`, which is what makes
/// Article 6.8 (device clock tampering) verifiable without a device.
library;

export 'src/attempt.dart';
export 'src/day_progress.dart';
export 'src/star_engine.dart';
export 'src/star_rules.dart';
