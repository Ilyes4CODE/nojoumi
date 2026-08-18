import 'package:nojoumi_time/nojoumi_time.dart';

import 'attempt.dart';
import 'day_progress.dart';
import 'star_rules.dart';

/// Result of consuming play time.
class PlayConsumption {
  const PlayConsumption({
    required this.day,
    required this.secondsConsumed,
    required this.remainingSeconds,
  });

  final DayProgress day;
  final int secondsConsumed;
  final int remainingSeconds;

  /// Article 4.7 / appendix §2: at zero, blocking returns immediately.
  bool get blockingShouldReturn => remainingSeconds == 0;
}

/// The star engine.
///
/// Pure. No clock reads, no IO, no mutable state, no Flutter. Every method takes
/// the rules, the day, and a [TrustedInstant], and returns a decision. That
/// shape is deliberate: Articles 5 and 6 are the most precisely specified and
/// least device-dependent part of the contract, so they are made provable by
/// `dart test` with no hardware attached.
class StarEngine {
  const StarEngine();

  /// Evaluate one answer against every condition in Article 6.
  ///
  /// The conditions are joint, so the first failure decides. The order below is
  /// the order of Article 6's own bullets, with the clock check hoisted to the
  /// front because an untrustworthy day key would invalidate the same-day and
  /// ceiling checks that follow it.
  StarDecision evaluate({
    required StarRules rules,
    required DayProgress day,
    required Attempt attempt,
    required TrustedInstant now,
  }) {
    // Art. 6.8 — "تغيير تاريخ أو ساعة الجهاز لا يُنتج رصيداً جديداً".
    if (!now.isTrustworthy) {
      return const StarDecision.rejected(Rejection.untrustedClock);
    }

    // Art. 6.1 — correct, on the first attempt, without revealing the answer.
    if (!attempt.correct) {
      return const StarDecision.rejected(Rejection.wrongAnswer);
    }
    if (attempt.solutionRevealed) {
      return const StarDecision.rejected(Rejection.solutionRevealed);
    }
    if (attempt.attemptNumber != 1) {
      return const StarDecision.rejected(Rejection.notFirstAttempt);
    }

    // Art. 6.2 — not already counted the same day.
    if (day.countedTargetIds.contains(attempt.targetId)) {
      return const StarDecision.rejected(Rejection.alreadyCountedToday);
    }

    // Art. 6.3 — must *exceed* the minimum time; rapid tapping earns nothing.
    if (attempt.msOnTarget <= rules.minimumTimeOnTargetMs) {
      return const StarDecision.rejected(Rejection.belowMinimumTime);
    }

    // Art. 6.4 — the daily ceiling.
    final remaining = day.remainingCeilingUnits(rules);
    if (remaining == 0) {
      return const StarDecision.rejected(Rejection.dailyCeilingReached);
    }

    final base = attempt.kind.baseUnits;
    if (base > remaining) {
      // Land exactly on the ceiling rather than forfeit the whole award: the
      // ceiling is a cap on earning, not a penalty. See docs/decisions.md.
      return StarDecision.awarded(remaining, cappedByCeiling: true);
    }
    return StarDecision.awarded(base);
  }

  /// Apply a granted decision to the day. Callers persist both the returned day
  /// and a ledger row; this function does not decide, it only folds.
  DayProgress applyEarned(DayProgress day, Attempt attempt, StarDecision d) {
    if (!d.granted) return day;
    return day.copyWith(
      earnedUnits: day.earnedUnits + d.awardedUnits,
      countedTargetIds: {...day.countedTargetIds, attempt.targetId},
    );
  }

  /// Article 5's "+5 مكافأة" for a complete daily session, gated by Article 6.5
  /// ("100% من مهام اليوم").
  StarDecision sessionBonus({
    required DayProgress day,
    required TrustedInstant now,
  }) {
    if (!now.isTrustworthy) {
      return const StarDecision.rejected(Rejection.untrustedClock);
    }
    if (day.sessionBonusAwarded) {
      return const StarDecision.rejected(Rejection.alreadyAwardedToday);
    }
    if (!day.sessionComplete) {
      return const StarDecision.rejected(Rejection.sessionIncomplete);
    }
    return const StarDecision.awarded(Article5.fullSessionBonus);
  }

  /// Article 5's "+3" attendance bonus, on a run of at least two consecutive
  /// days. Article 6.6 resets the run on any missed day, which [StreakState]
  /// enforces.
  StarDecision streakBonus({
    required DayProgress day,
    required StreakState streak,
    required TrustedInstant now,
  }) {
    if (!now.isTrustworthy) {
      return const StarDecision.rejected(Rejection.untrustedClock);
    }
    if (day.streakBonusAwarded) {
      return const StarDecision.rejected(Rejection.alreadyAwardedToday);
    }
    if (streak.consecutiveDays < Article5.streakMinimumDays) {
      return const StarDecision.rejected(Rejection.streakTooShort);
    }
    return const StarDecision.awarded(Article5.streakBonus);
  }

  /// Article 5's weekly-test scale.
  ///
  /// Compared with integers so no floating point can land a child on the wrong
  /// side of a boundary. The published bands are "<50", "50–74", "75–89",
  /// "90 and above"; a fractional percentage between two bands (74.5%) falls to
  /// the lower band, since the bands are plainly meant to be contiguous.
  int weeklyTestUnits({required int correct, required int total}) {
    if (total <= 0) return 0;
    if (correct < 0) correct = 0;
    if (correct > total) correct = total;

    final scaled = correct * 100; // avoids division entirely
    if (scaled < 50 * total) return Article5.weeklyTestBelow50;
    if (scaled < 75 * total) return Article5.weeklyTest50to74;
    if (scaled < 90 * total) return Article5.weeklyTest75to89;
    return Article5.weeklyTest90plus;
  }

  /// The parent's authority, "فوق النظام" (appendix §4).
  ///
  /// Not subject to the daily ceiling and not subject to the clock: a parent
  /// rewarding good behaviour must work on a phone whose clock we distrust.
  /// Deductions may not push the balance below zero.
  DayProgress parentAdjust(DayProgress day, int deltaUnits) {
    var granted = day.grantedUnits + deltaUnits;
    if (day.earnedUnits + granted < 0) granted = -day.earnedUnits;
    return day.copyWith(grantedUnits: granted);
  }

  /// The one-time welcome balance of appendix §5. The caller is responsible for
  /// the "one time" part (a flag in settings); this only folds it in.
  DayProgress grantWelcome(DayProgress day, StarRules rules) =>
      day.copyWith(grantedUnits: day.grantedUnits + rules.welcomeUnits);

  /// Consume real play time. Never consumes more than remains.
  ///
  /// Appendix §2: the counter measures actual play only, stops on screen-off or
  /// leaving the game, and resumes on return. That behaviour lives in the
  /// platform layer, which reports elapsed foreground seconds; the engine only
  /// debits them, so there is no threshold here to get wrong.
  PlayConsumption consumePlay({
    required StarRules rules,
    required DayProgress day,
    required int seconds,
  }) {
    if (seconds < 0) seconds = 0;
    final available = day.remainingPlaySeconds(rules);
    final consumed = seconds > available ? available : seconds;
    final next = day.copyWith(usedPlaySeconds: day.usedPlaySeconds + consumed);
    return PlayConsumption(
      day: next,
      secondsConsumed: consumed,
      remainingSeconds: next.remainingPlaySeconds(rules),
    );
  }

  /// Whether the balance expires when moving from [from] to [to].
  ///
  /// Article 6.7 is "الرصيد غير المستعمل ينتهي في نهاية اليوم"; appendix §5
  /// makes that the default and offers a weekly option.
  bool balanceExpires({
    required DayKey from,
    required DayKey to,
    required StarRules rules,
    int expiryWeekday = DateTime.friday,
  }) {
    if (to <= from) return false;
    return switch (rules.expiryMode) {
      ExpiryMode.daily => true,
      ExpiryMode.weekly =>
        _weekStart(from, expiryWeekday) != _weekStart(to, expiryWeekday),
    };
  }

  /// Move to a new day, expiring the balance if the rules say so.
  ///
  /// Counted targets and the per-day bonus flags always reset — Article 6.2 is
  /// explicitly a same-day rule, and the ceiling is explicitly daily, even when
  /// the *balance* is configured to survive the night.
  DayProgress rollOver({
    required DayProgress day,
    required DayKey to,
    required StarRules rules,
    int expiryWeekday = DateTime.friday,
  }) {
    final expires = balanceExpires(
      from: day.dayKey,
      to: to,
      rules: rules,
      expiryWeekday: expiryWeekday,
    );
    if (!expires) {
      return DayProgress(
        dayKey: to,
        // Carried balance moves into the granted bucket: it must remain
        // spendable without consuming tomorrow's earning ceiling.
        grantedUnits: day.balanceUnits,
        usedPlaySeconds: day.usedPlaySeconds,
      );
    }
    return DayProgress(dayKey: to);
  }

  /// 1970-01-01 was a Thursday, so this maps a day key to `DateTime`'s
  /// Monday=1..Sunday=7 weekday numbering.
  static int weekdayOf(DayKey day) => ((day.daysSinceEpoch + 3) % 7) + 1;

  static int _weekStart(DayKey day, int expiryWeekday) {
    final shift = (weekdayOf(day) - expiryWeekday + 7) % 7;
    return day.daysSinceEpoch - shift;
  }
}
