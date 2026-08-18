/// Trusted time for Nojoumi.
///
/// Contract basis:
///  * Article 6.8 — "تغيير تاريخ أو ساعة الجهاز لا يُنتج رصيداً جديداً؛ يعتمد
///    النظام على مرجع زمني محمي." (changing the device date or time produces no
///    new balance; the system relies on a protected time reference)
///  * Article 7.6 — "تغيير تاريخ أو ساعة الجهاز لا يمدّد الاشتراك."
///  * Article 12, scenario 12 — changing the date or time to earn balance must
///    yield no extra balance.
///
/// Nothing here reads a clock. The platform supplies [ClockReading]s and the
/// app persists [ClockState]; everything else is a pure function, so the three
/// obligations above are provable by `dart test` with no device attached.
library;

export 'src/clock.dart';
export 'src/day_key.dart';
