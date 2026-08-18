/// Spaced repetition for Nojoumi.
///
/// Contract basis:
///  * Article 2 — "نظام مراجعة متباعدة يعيد عرض البطاقات الضعيفة تلقائياً".
///  * Article 4.3 — the daily session is memorize, then review, then exercise.
///  * Appendix §5 — "حجم الجلسة اليومية": 12 cards by default, range 5–30.
///
/// The contract does not name an algorithm, so SM-2 is our choice (see
/// decisions.md D-22) and every parameter is injectable. Arithmetic is integer
/// throughout — ease is held in permille — for the same reason the star ledger
/// is: a card reviewed across a school year accumulates dozens of updates.
library;

export 'src/session_builder.dart';
export 'src/sm2.dart';
