import 'star_rules.dart';

/// What the child just answered. Article 5 pays each of these differently.
enum EarnKind {
  /// "بطاقة حفظ صحيحة (أول مرة)" — 1 star.
  memorizeCardFirstTime,

  /// "بطاقة في مراجعة لاحقة" — 0.5 stars.
  cardInLaterReview,

  /// "سؤال مراجعة صحيح" — 2 stars.
  reviewQuestion;

  int get baseUnits => switch (this) {
        EarnKind.memorizeCardFirstTime => Article5.memorizeCardFirstTime,
        EarnKind.cardInLaterReview => Article5.cardInLaterReview,
        EarnKind.reviewQuestion => Article5.reviewQuestion,
      };
}

/// Why an attempt earned nothing.
///
/// Article 6 lists conditions that must hold **jointly**, so a rejected attempt
/// always has exactly one first cause. Recording it is what lets the parent
/// dashboard answer "why didn't I get a star?" from data instead of a guess,
/// and it is why every one of these has its own test.
enum Rejection {
  /// Art. 6.8 / Art. 12 scenario 12 — the clock cannot be trusted, so nothing
  /// may be earned. Checked first: an untrustworthy day key would poison every
  /// other check below it.
  untrustedClock,

  /// Art. 6.1 — "لا نجوم على الإجابة الخاطئة".
  wrongAnswer,

  /// Art. 6.1 — "ولا بعد كشف الحل".
  solutionRevealed,

  /// Art. 6.1 — "الإجابة صحيحة من المحاولة الأولى".
  notFirstAttempt,

  /// Art. 6.2 — "ألّا تكون البطاقة أو السؤال قد احتُسب في اليوم ذاته".
  alreadyCountedToday,

  /// Art. 6.3 — "تجاوز الحد الأدنى للوقت على البطاقة … الضغط العشوائي السريع
  /// لا يُحتسب".
  belowMinimumTime,

  /// Art. 6.4 — "عدم استنفاد السقف اليومي للنجوم".
  dailyCeilingReached,

  /// The session bonus is once per day (Art. 5), the streak bonus once per day.
  alreadyAwardedToday,

  /// Art. 6.5 — the session bonus needs 100% of the day's tasks.
  sessionIncomplete,

  /// Art. 5 — the streak bonus needs at least two consecutive days.
  streakTooShort,
}

/// One answer, as the UI observed it.
class Attempt {
  const Attempt({
    required this.targetId,
    required this.kind,
    required this.attemptNumber,
    required this.correct,
    required this.msOnTarget,
    this.solutionRevealed = false,
  });

  /// Stable id of the card or question. Used for the same-day dedupe of
  /// Article 6.2, so it must identify the *content*, not the presentation.
  final String targetId;

  final EarnKind kind;

  /// 1 for the first attempt. Article 6.1 pays only on 1.
  final int attemptNumber;

  final bool correct;

  /// Milliseconds the target was actually on screen and interactive.
  final int msOnTarget;

  /// True if the child asked to see the answer before responding.
  final bool solutionRevealed;
}

/// The engine's answer: how much was earned, and if nothing, why.
class StarDecision {
  const StarDecision._(this.awardedUnits, this.rejection, this.cappedByCeiling);

  const StarDecision.awarded(int units, {bool cappedByCeiling = false})
      : this._(units, null, cappedByCeiling);

  const StarDecision.rejected(Rejection reason) : this._(0, reason, false);

  final int awardedUnits;
  final Rejection? rejection;

  /// True when the award was trimmed to land exactly on the daily ceiling.
  final bool cappedByCeiling;

  bool get granted => awardedUnits > 0;
  double get awardedStars => unitsToStars(awardedUnits);

  @override
  String toString() => granted
      ? 'StarDecision(+$awardedStars★${cappedByCeiling ? ' capped' : ''})'
      : 'StarDecision(rejected: ${rejection!.name})';
}
