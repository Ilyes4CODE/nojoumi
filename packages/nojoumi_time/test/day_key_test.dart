import 'package:nojoumi_time/nojoumi_time.dart';
import 'package:test/test.dart';

const dz = DayKey.algeriaUtcOffsetMinutes; // UTC+1

int utc(int y, int m, int d, [int h = 0, int min = 0]) =>
    DateTime.utc(y, m, d, h, min).millisecondsSinceEpoch;

void main() {
  group('DayKey', () {
    test('the epoch day is day zero at UTC', () {
      expect(DayKey.fromEpochMs(0, utcOffsetMinutes: 0).daysSinceEpoch, 0);
    });

    test('Algeria is one hour ahead, so 23:30 UTC is already tomorrow locally',
        () {
      final beforeMidnightUtc = utc(2026, 8, 14, 23, 30);
      expect(
        DayKey.fromEpochMs(beforeMidnightUtc, utcOffsetMinutes: dz).iso,
        '2026-08-15',
      );
      expect(
        DayKey.fromEpochMs(beforeMidnightUtc, utcOffsetMinutes: 0).iso,
        '2026-08-14',
      );
    });

    test('local midnight starts the day, one millisecond earlier is yesterday',
        () {
      final day = DayKey.fromEpochMs(utc(2026, 8, 14, 12), utcOffsetMinutes: dz);
      final start = day.startEpochMs(utcOffsetMinutes: dz);
      expect(DayKey.fromEpochMs(start, utcOffsetMinutes: dz), day);
      expect(
        DayKey.fromEpochMs(start - 1, utcOffsetMinutes: dz),
        day.previous,
      );
    });

    test('end of day is exclusive and equals the next day start (Art. 6 expiry)',
        () {
      final day = DayKey.fromEpochMs(utc(2026, 8, 14, 12), utcOffsetMinutes: dz);
      expect(
        day.endEpochMsExclusive(utcOffsetMinutes: dz),
        day.next.startEpochMs(utcOffsetMinutes: dz),
      );
      expect(
        DayKey.fromEpochMs(
          day.endEpochMsExclusive(utcOffsetMinutes: dz),
          utcOffsetMinutes: dz,
        ),
        day.next,
      );
    });

    test('difference is plain integer day arithmetic, across a month boundary',
        () {
      final aug31 = DayKey.fromEpochMs(utc(2026, 8, 31, 10), utcOffsetMinutes: dz);
      final sep01 = DayKey.fromEpochMs(utc(2026, 9, 1, 10), utcOffsetMinutes: dz);
      expect(sep01.difference(aug31), 1);
      expect(aug31.next, sep01);
    });

    test('difference works across a leap day', () {
      final feb28 = DayKey.fromEpochMs(utc(2028, 2, 28, 10), utcOffsetMinutes: dz);
      final mar01 = DayKey.fromEpochMs(utc(2028, 3, 1, 10), utcOffsetMinutes: dz);
      expect(mar01.difference(feb28), 2, reason: '2028 is a leap year');
    });

    test('pre-epoch dates floor correctly rather than truncating toward zero',
        () {
      expect(DayKey.fromEpochMs(-1, utcOffsetMinutes: 0).daysSinceEpoch, -1);
      expect(
        DayKey.fromEpochMs(-86400000, utcOffsetMinutes: 0).daysSinceEpoch,
        -1,
      );
    });

    test('equality and ordering are by day, not by instant', () {
      final morning =
          DayKey.fromEpochMs(utc(2026, 8, 14, 6), utcOffsetMinutes: dz);
      final evening =
          DayKey.fromEpochMs(utc(2026, 8, 14, 20), utcOffsetMinutes: dz);
      expect(morning, evening);
      expect(morning < evening.next, isTrue);
      expect({morning, evening}.length, 1);
    });
  });
}
