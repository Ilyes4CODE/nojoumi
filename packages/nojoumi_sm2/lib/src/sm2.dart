import 'package:nojoumi_time/nojoumi_time.dart';

/// SM-2 quality, 0–5, as the original algorithm defines it.
///
/// A child cannot self-rate the way an adult SuperMemo user does, and Article 6
/// forbids counting an answer at all once the solution was revealed. So the app
/// never asks — it *derives* the grade from what it already observed for the
/// star engine: correctness, attempt number, whether the solution was revealed,
/// and time on the card. See [Sm2Grade.fromObservation] and decisions.md D-22.
enum Sm2Grade {
  blackout(0),
  wrongButFamiliar(1),
  wrongAlmost(2),
  correctHard(3),
  correctHesitant(4),
  correctEasy(5);

  const Sm2Grade(this.value);

  final int value;

  /// SM-2's threshold: 3 and above counts as recalled.
  bool get recalled => value >= 3;

  /// Derive the grade from the same observation the star engine sees.
  ///
  /// Deliberately conservative at the top: [correctEasy] needs a *fast* first
  /// attempt, because an easy card that took twenty seconds is not easy. The
  /// fast threshold is injected rather than fixed — a 7-year-old reading Arabic
  /// is not a 12-year-old, and the parent already tunes the minimum card time.
  static Sm2Grade fromObservation({
    required bool correct,
    required int attemptNumber,
    required bool solutionRevealed,
    required int msOnTarget,
    int fastMs = 6000,
  }) {
    if (solutionRevealed) return Sm2Grade.wrongAlmost;
    if (!correct) {
      // One honest wrong attempt is a lapse; several is a card not learned.
      return attemptNumber <= 1 ? Sm2Grade.wrongButFamiliar : Sm2Grade.blackout;
    }
    if (attemptNumber > 1) return Sm2Grade.correctHard;
    return msOnTarget <= fastMs ? Sm2Grade.correctEasy : Sm2Grade.correctHesitant;
  }
}

/// The scheduling state of one memorization card.
///
/// Ease is stored in **permille** (2500 = 2.5), not as a double. Article 5's
/// ledger is integer for the same reason: a card reviewed weekly for a school
/// year goes through dozens of updates, and float error compounds. Every SM-2
/// ease adjustment happens to be an exact multiple of 0.01, so permille is
/// lossless — this is not a rounding trick, it is the natural unit.
class CardSchedule {
  const CardSchedule({
    required this.cardId,
    this.repetitions = 0,
    this.intervalDays = 0,
    this.easePermille = defaultEasePermille,
    this.lapses = 0,
    this.dueDay,
    this.lastReviewedDay,
  });

  /// SuperMemo's initial EF of 2.5.
  static const int defaultEasePermille = 2500;

  /// SuperMemo's floor of 1.3. Below this a card cycles forever.
  static const int minimumEasePermille = 1300;

  final String cardId;

  /// Consecutive successful recalls. Reset to 0 by any lapse.
  final int repetitions;

  /// Current interval in whole days. 0 means never scheduled.
  final int intervalDays;

  final int easePermille;

  /// How many times this card has been forgotten. Not used by SM-2 itself —
  /// it is what the parent dashboard means by "البطاقات الضعيفة".
  final int lapses;

  final DayKey? dueDay;
  final DayKey? lastReviewedDay;

  bool get isNew => repetitions == 0 && lastReviewedDay == null;

  double get ease => easePermille / 1000;

  bool isDue(DayKey today) => dueDay == null || dueDay! <= today;

  /// Days past due. Negative when not yet due; 0 when due exactly today.
  int overdueBy(DayKey today) =>
      dueDay == null ? 0 : today.difference(dueDay!);

  CardSchedule copyWith({
    int? repetitions,
    int? intervalDays,
    int? easePermille,
    int? lapses,
    DayKey? dueDay,
    DayKey? lastReviewedDay,
  }) {
    return CardSchedule(
      cardId: cardId,
      repetitions: repetitions ?? this.repetitions,
      intervalDays: intervalDays ?? this.intervalDays,
      easePermille: easePermille ?? this.easePermille,
      lapses: lapses ?? this.lapses,
      dueDay: dueDay ?? this.dueDay,
      lastReviewedDay: lastReviewedDay ?? this.lastReviewedDay,
    );
  }

  @override
  String toString() => 'CardSchedule($cardId, n=$repetitions, '
      'I=${intervalDays}d, EF=$ease, lapses=$lapses, due=$dueDay)';
}

/// The SM-2 scheduler.
///
/// Pure: it takes a schedule, a grade and today's [DayKey], and returns the next
/// schedule. It reads no clock and stores nothing.
class Sm2Scheduler {
  const Sm2Scheduler({
    this.firstIntervalDays = 1,
    this.secondIntervalDays = 6,
    this.maximumIntervalDays = 365,
  });

  /// SM-2's I(1).
  final int firstIntervalDays;

  /// SM-2's I(2).
  final int secondIntervalDays;

  /// A cap the original algorithm lacks. Without it a strong card can be
  /// scheduled years out, which is meaningless for a school year and looks like
  /// a bug to a parent reading the dashboard.
  final int maximumIntervalDays;

  /// Apply one review.
  CardSchedule review({
    required CardSchedule card,
    required Sm2Grade grade,
    required DayKey today,
  }) {
    final ease = _nextEase(card.easePermille, grade);

    if (!grade.recalled) {
      // SM-2: a failed card restarts the repetition count and comes back
      // tomorrow. The appendix says the same in plain words —
      // "البطاقة التي يخطئ فيها تعود تلقائيا في مراجعة لاحقة".
      return card.copyWith(
        repetitions: 0,
        intervalDays: firstIntervalDays,
        easePermille: ease,
        lapses: card.lapses + 1,
        dueDay: DayKey(today.daysSinceEpoch + firstIntervalDays),
        lastReviewedDay: today,
      );
    }

    final repetitions = card.repetitions + 1;
    final interval = switch (repetitions) {
      1 => firstIntervalDays,
      2 => secondIntervalDays,
      _ => _scaled(card.intervalDays, ease),
    };
    final capped = interval > maximumIntervalDays ? maximumIntervalDays : interval;

    return card.copyWith(
      repetitions: repetitions,
      intervalDays: capped,
      easePermille: ease,
      dueDay: DayKey(today.daysSinceEpoch + capped),
      lastReviewedDay: today,
    );
  }

  /// EF' = EF + (0.1 − (5−q) × (0.08 + (5−q) × 0.02)), floored at 1.3.
  ///
  /// In permille every term is an exact integer, so this is the original
  /// formula with no approximation: q=5 → +100, q=4 → 0, q=3 → −140,
  /// q=2 → −320, q=1 → −540, q=0 → −800.
  static int _nextEase(int easePermille, Sm2Grade grade) {
    final d = 5 - grade.value;
    final delta = 100 - d * (80 + d * 20);
    final next = easePermille + delta;
    return next < CardSchedule.minimumEasePermille
        ? CardSchedule.minimumEasePermille
        : next;
  }

  /// I' = round(I × EF), in integer arithmetic.
  static int _scaled(int intervalDays, int easePermille) {
    final base = intervalDays <= 0 ? 1 : intervalDays;
    final scaled = (base * easePermille + 500) ~/ 1000;
    return scaled <= base ? base + 1 : scaled;
  }
}
