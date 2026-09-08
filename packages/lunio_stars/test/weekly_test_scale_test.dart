import 'package:lunio_stars/lunio_stars.dart';
import 'package:test/test.dart';

/// Article 5, "سلّم نجوم الاختبار الأسبوعي":
///   أقل من 50%      -> 10
///   50% – 74%       -> 20
///   75% – 89%       -> 30
///   90% فما فوق      -> 40
void main() {
  const engine = StarEngine();

  double stars(int correct, int total) =>
      unitsToStars(engine.weeklyTestUnits(correct: correct, total: total));

  group('the published bands, on a 100-question test', () {
    final expected = <int, double>{
      0: 10,
      1: 10,
      49: 10,
      50: 20,
      60: 20,
      74: 20,
      75: 30,
      80: 30,
      89: 30,
      90: 40,
      99: 40,
      100: 40,
    };

    expected.forEach((correct, want) {
      test('$correct% -> $want stars', () => expect(stars(correct, 100), want));
    });
  });

  group('the boundaries are exact, with no floating point in the way', () {
    test('49% is below the first band, 50% is on it', () {
      expect(stars(49, 100), 10);
      expect(stars(50, 100), 20);
    });

    test('74% stays in band two, 75% moves to band three', () {
      expect(stars(74, 100), 20);
      expect(stars(75, 100), 30);
    });

    test('89% stays in band three, 90% reaches the top', () {
      expect(stars(89, 100), 30);
      expect(stars(90, 100), 40);
    });

    test('exactly 75% on a 4-question test scores band three', () {
      expect(stars(3, 4), 30);
    });

    test('exactly 50% on a 2-question test scores band two', () {
      expect(stars(1, 2), 20);
    });

    test('a fraction between two bands falls to the lower band', () {
      // 7/8 = 87.5% -> band three; 74.5% cannot occur on 8 questions, so use 200.
      expect(stars(7, 8), 30);
      expect(stars(149, 200), 20, reason: '74.5% -> the 50–74 band');
      expect(stars(179, 200), 30, reason: '89.5% -> the 75–89 band');
    });

    test('a 13-question test, every possible score', () {
      // 13 questions makes every percentage fractional, which is the case most
      // likely to break a float-based implementation.
      const want = <double>[
        10, 10, 10, 10, 10, 10, 10, // 0..6  -> up to 46.1%
        20, 20, 20, // 7..9  -> 53.8%, 61.5%, 69.2%
        30, 30, // 10..11 -> 76.9%, 84.6%
        40, 40, // 12..13 -> 92.3%, 100%
      ];
      for (var correct = 0; correct <= 13; correct++) {
        expect(stars(correct, 13), want[correct],
            reason: '$correct of 13 = ${(correct / 13 * 100).toStringAsFixed(1)}%');
      }
    });
  });

  group('degenerate input cannot award stars by accident', () {
    test('a test with no questions awards nothing', () {
      expect(engine.weeklyTestUnits(correct: 0, total: 0), 0);
      expect(engine.weeklyTestUnits(correct: 5, total: 0), 0);
    });

    test('negative or impossible scores are clamped, not trusted', () {
      expect(stars(-5, 20), 10);
      expect(stars(999, 20), 40);
    });
  });

  test(
      'zero correct still awards 10 stars, exactly as Article 5 is written '
      '(flagged for the client — decisions.md D-14)', () {
    expect(stars(0, 20), 10);
  });
}
