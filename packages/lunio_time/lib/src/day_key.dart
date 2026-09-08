/// A civil day in the child's local timezone, as an integer number of days
/// since the Unix epoch.
///
/// Why an int and not a `DateTime`: day identity is the key that Article 6
/// hangs three separate rules on — "not already counted **the same day**",
/// "the **daily** ceiling", and "unused balance expires **at end of day**".
/// Comparing and subtracting day keys must be exact and cheap, and streak
/// arithmetic (Article 5, "two consecutive days") is then plain integer
/// subtraction with no calendar edge cases.
///
/// The UTC offset is injected, never read from the platform. Algeria is UTC+1
/// with no daylight saving, so [algeriaUtcOffsetMinutes] is the production
/// value, but tests pin it explicitly.
class DayKey implements Comparable<DayKey> {
  const DayKey(this.daysSinceEpoch);

  /// Algeria: UTC+01:00, no DST.
  static const int algeriaUtcOffsetMinutes = 60;

  static const int _msPerDay = 86400000;

  final int daysSinceEpoch;

  /// The civil day containing [epochMs] at [utcOffsetMinutes].
  factory DayKey.fromEpochMs(int epochMs, {required int utcOffsetMinutes}) {
    final local = epochMs + utcOffsetMinutes * 60000;
    return DayKey(_floorDiv(local, _msPerDay));
  }

  /// Epoch milliseconds of the first instant of this day.
  int startEpochMs({required int utcOffsetMinutes}) =>
      daysSinceEpoch * _msPerDay - utcOffsetMinutes * 60000;

  /// Epoch milliseconds of the first instant of the next day — the moment
  /// unused balance expires under Article 6.
  int endEpochMsExclusive({required int utcOffsetMinutes}) =>
      next.startEpochMs(utcOffsetMinutes: utcOffsetMinutes);

  DayKey get next => DayKey(daysSinceEpoch + 1);
  DayKey get previous => DayKey(daysSinceEpoch - 1);

  /// Days from [other] to this. Positive when this is later.
  int difference(DayKey other) => daysSinceEpoch - other.daysSinceEpoch;

  bool get isEpochDay => daysSinceEpoch == 0;

  /// `Dart`'s `~/` truncates toward zero, which is wrong for pre-1970 values.
  static int _floorDiv(int a, int b) => (a - a % b) ~/ b;

  @override
  int compareTo(DayKey other) => daysSinceEpoch.compareTo(other.daysSinceEpoch);

  bool operator <(DayKey other) => daysSinceEpoch < other.daysSinceEpoch;
  bool operator <=(DayKey other) => daysSinceEpoch <= other.daysSinceEpoch;
  bool operator >(DayKey other) => daysSinceEpoch > other.daysSinceEpoch;
  bool operator >=(DayKey other) => daysSinceEpoch >= other.daysSinceEpoch;

  @override
  bool operator ==(Object other) =>
      other is DayKey && other.daysSinceEpoch == daysSinceEpoch;

  @override
  int get hashCode => daysSinceEpoch.hashCode;

  /// `YYYY-MM-DD`, for logs and for the local database's day column.
  String get iso {
    final d = DateTime.fromMillisecondsSinceEpoch(
      daysSinceEpoch * _msPerDay,
      isUtc: true,
    );
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  String toString() => 'DayKey($iso)';
}
