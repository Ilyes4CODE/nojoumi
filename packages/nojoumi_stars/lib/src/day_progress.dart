import 'package:nojoumi_time/nojoumi_time.dart';

import 'star_rules.dart';

/// Everything about one child-day that the engine needs, as an immutable value.
///
/// Two separate balances, because Article 6 treats them differently: the daily
/// ceiling constrains what the child *earns*, while the parent's authority is
/// "فوق النظام" (above the system) and is not subject to it.
class DayProgress {
  const DayProgress({
    required this.dayKey,
    this.earnedUnits = 0,
    this.grantedUnits = 0,
    this.usedPlaySeconds = 0,
    this.countedTargetIds = const <String>{},
    this.tasksTotal = 0,
    this.tasksAnswered = 0,
    this.sessionBonusAwarded = false,
    this.streakBonusAwarded = false,
  });

  final DayKey dayKey;

  /// Earned by the child today. Counts against the daily ceiling.
  final int earnedUnits;

  /// Parent grants, the welcome balance, and weekly-test awards. Does not count
  /// against the daily ceiling.
  final int grantedUnits;

  /// Seconds of real play already consumed. Play never rounds a balance away:
  /// awards only ever change [earnedUnits]/[grantedUnits], consumption only
  /// ever changes this, so no conversion error can accumulate.
  final int usedPlaySeconds;

  /// Targets already paid today — Article 6.2.
  final Set<String> countedTargetIds;

  /// Size of today's session (cards + questions), and how many have been
  /// answered. Article 6.5's bonus needs these equal.
  final int tasksTotal;
  final int tasksAnswered;

  final bool sessionBonusAwarded;
  final bool streakBonusAwarded;

  /// Total balance available to spend on play.
  int get balanceUnits => earnedUnits + grantedUnits;

  /// Whether the day's tasks are all done. Note "answered", not "correct" —
  /// see docs/decisions.md D-5, forced by the appendix's own worked example
  /// where a child with 10/12 cards and 4/5 questions still receives the bonus.
  bool get sessionComplete => tasksTotal > 0 && tasksAnswered >= tasksTotal;

  int remainingCeilingUnits(StarRules rules) {
    final left = rules.dailyCeilingUnits - earnedUnits;
    return left > 0 ? left : 0;
  }

  /// Seconds of play still available right now.
  int remainingPlaySeconds(StarRules rules) {
    final left = rules.playableSecondsFor(balanceUnits) - usedPlaySeconds;
    return left > 0 ? left : 0;
  }

  /// Article 4.7: when the balance runs out, blocking returns.
  bool playExhausted(StarRules rules) => remainingPlaySeconds(rules) == 0;

  DayProgress copyWith({
    DayKey? dayKey,
    int? earnedUnits,
    int? grantedUnits,
    int? usedPlaySeconds,
    Set<String>? countedTargetIds,
    int? tasksTotal,
    int? tasksAnswered,
    bool? sessionBonusAwarded,
    bool? streakBonusAwarded,
  }) {
    return DayProgress(
      dayKey: dayKey ?? this.dayKey,
      earnedUnits: earnedUnits ?? this.earnedUnits,
      grantedUnits: grantedUnits ?? this.grantedUnits,
      usedPlaySeconds: usedPlaySeconds ?? this.usedPlaySeconds,
      countedTargetIds: countedTargetIds ?? this.countedTargetIds,
      tasksTotal: tasksTotal ?? this.tasksTotal,
      tasksAnswered: tasksAnswered ?? this.tasksAnswered,
      sessionBonusAwarded: sessionBonusAwarded ?? this.sessionBonusAwarded,
      streakBonusAwarded: streakBonusAwarded ?? this.streakBonusAwarded,
    );
  }
}

/// Attendance state for Article 5's "يومان متتاليان دون انقطاع (مواظبة)".
class StreakState {
  const StreakState({this.lastActiveDay, this.consecutiveDays = 0, this.best = 0});

  /// The last day the child completed a session. An "active day" is a completed
  /// session, consistent with how the session bonus is defined — see D-5.
  final DayKey? lastActiveDay;

  final int consecutiveDays;
  final int best;

  /// Fold a newly completed day in. Article 6.6: counted on actual consecutive
  /// days, and the counter resets on any missed day.
  StreakState withActiveDay(DayKey day) {
    if (lastActiveDay == null) {
      return StreakState(lastActiveDay: day, consecutiveDays: 1, best: _max(best, 1));
    }
    if (day == lastActiveDay) return this;
    if (day.difference(lastActiveDay!) == 1) {
      final next = consecutiveDays + 1;
      return StreakState(
        lastActiveDay: day,
        consecutiveDays: next,
        best: _max(best, next),
      );
    }
    // Any gap at all resets to a run of one.
    return StreakState(lastActiveDay: day, consecutiveDays: 1, best: _max(best, 1));
  }

  /// Whether a day with no completed session breaks the run.
  StreakState brokenBy(DayKey missedDay) {
    if (lastActiveDay == null) return this;
    if (missedDay.difference(lastActiveDay!) >= 1) {
      return StreakState(lastActiveDay: lastActiveDay, consecutiveDays: 0, best: best);
    }
    return this;
  }

  static int _max(int a, int b) => a > b ? a : b;
}
