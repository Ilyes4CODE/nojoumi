import 'package:drift/drift.dart';
import 'package:nojoumi_stars/nojoumi_stars.dart';
import 'package:nojoumi_time/nojoumi_time.dart';

import '../local/database.dart';
import '../local/tables.dart';

/// The result of recording one answer: what the engine decided, and the balance
/// the child now has.
class RecordedAttempt {
  const RecordedAttempt({
    required this.decision,
    required this.day,
    required this.balanceUnits,
  });

  final StarDecision decision;
  final DayProgress day;
  final int balanceUnits;
}

/// Everything that touches the star ledger.
///
/// Two rules from CLAUDE.md are structural here, not stylistic:
///
///  * **AD-4 — the ledger is append-only and rejections are recorded.** Every
///    evaluated attempt writes a row to `attempts`, awarded or not, with the
///    rejection reason. Every balance movement writes a row to `star_ledger`.
///    Nothing is ever updated in place, so "why did my child not get a star?"
///    is answered by a query.
///  * **AD-1 — no rule lives here.** This class loads state, hands it to
///    [StarEngine], and persists the answer. If a condition from Article 6 ever
///    appears as an `if` in this file, it is in the wrong place.
class StarRepository {
  StarRepository(this._db, {StarEngine engine = const StarEngine()})
      : _engine = engine;

  final NojoumiDatabase _db;
  final StarEngine _engine;

  // ---------------------------------------------------------------- reading

  /// Load one day, including the Article 6.2 set of already-counted targets.
  Future<DayProgress> dayProgress(DayKey day) async {
    final row = await (_db.select(_db.dayProgressRows)
          ..where((t) => t.dayKey.equals(day.daysSinceEpoch)))
        .getSingleOrNull();

    final counted = await (_db.select(_db.countedTargets)
          ..where((t) => t.dayKey.equals(day.daysSinceEpoch)))
        .get();

    if (row == null) return DayProgress(dayKey: day);

    return DayProgress(
      dayKey: day,
      earnedUnits: row.earnedUnits,
      grantedUnits: row.grantedUnits,
      usedPlaySeconds: row.usedPlaySeconds,
      countedTargetIds:
          counted.map((c) => _targetKey(c.kind, c.targetId)).toSet(),
      tasksTotal: row.tasksTotal,
      tasksAnswered: row.tasksAnswered,
      sessionBonusAwarded: row.sessionBonusAwarded,
      streakBonusAwarded: row.streakBonusAwarded,
    );
  }

  Stream<DayProgress> watchDay(DayKey day) {
    return (_db.select(_db.dayProgressRows)
          ..where((t) => t.dayKey.equals(day.daysSinceEpoch)))
        .watchSingleOrNull()
        .asyncMap((_) => dayProgress(day));
  }

  Future<StreakState> streak() async {
    final row =
        await (_db.select(_db.streakStates)..where((t) => t.id.equals(1)))
            .getSingle();
    return StreakState(
      lastActiveDay:
          row.lastActiveDay == null ? null : DayKey(row.lastActiveDay!),
      consecutiveDays: row.consecutiveDays,
      best: row.best,
    );
  }

  /// The balance recomputed from the ledger alone.
  ///
  /// AD-4 says the balance is *derived*, so this is the authority and the
  /// `day_progress_rows` columns are a cache of it. A test asserts the two agree
  /// after a long sequence of awards, deductions and expiries — if they ever
  /// drift, that test is where it surfaces, not the parent's screen.
  Future<int> derivedBalanceUnits(DayKey day) async {
    final rows = await (_db.select(_db.starLedger)
          ..where((t) => t.dayKey.equals(day.daysSinceEpoch)))
        .get();
    return rows.fold<int>(0, (sum, row) => sum + row.starUnits);
  }

  // ---------------------------------------------------------------- writing

  /// Evaluate and record one answer.
  ///
  /// The whole thing runs in one transaction, because a granted star that lost
  /// its `counted_targets` row would be earnable twice — Article 6.2 as a
  /// database property rather than a hope.
  Future<RecordedAttempt> recordAttempt({
    required StarRules rules,
    required Attempt attempt,
    required TrustedInstant now,
    required DayKey day,
  }) async {
    return _db.transaction(() async {
      final progress = await dayProgress(day);
      final decision = _engine.evaluate(
        rules: rules,
        day: progress,
        attempt: attempt,
        now: now,
      );

      final kind = _taskKindOf(attempt.kind);
      final targetId = int.parse(attempt.targetId.split(':').last);

      await _db.into(_db.attempts).insert(
            AttemptsCompanion.insert(
              dayKey: day.daysSinceEpoch,
              kind: kind,
              targetId: targetId,
              attemptNumber: attempt.attemptNumber,
              correct: attempt.correct,
              msOnTarget: attempt.msOnTarget,
              solutionRevealed: Value(attempt.solutionRevealed),
              awardedUnits: Value(decision.awardedUnits),
              rejection: Value(_rejectionRow(decision.rejection)),
              cappedByCeiling: Value(decision.cappedByCeiling),
              atMs: now.epochMs,
              trustLevel: _trustRow(now.level),
            ),
          );

      if (!decision.granted) {
        return RecordedAttempt(
          decision: decision,
          day: progress,
          balanceUnits: progress.balanceUnits,
        );
      }

      final next = _engine.applyEarned(progress, attempt, decision);

      await _db.into(_db.countedTargets).insert(
            CountedTargetsCompanion.insert(
              dayKey: day.daysSinceEpoch,
              kind: kind,
              targetId: targetId,
              atMs: now.epochMs,
            ),
            mode: InsertMode.insertOrIgnore,
          );

      await _upsertDay(next);
      await _appendLedger(
        day: day,
        kind: _ledgerKindOf(attempt.kind),
        units: decision.awardedUnits,
        balanceAfter: next.balanceUnits,
        sourceRef: targetId,
        now: now,
      );

      return RecordedAttempt(
        decision: decision,
        day: next,
        balanceUnits: next.balanceUnits,
      );
    });
  }

  /// Article 5's "+5" for a complete session (Art. 6.5: 100 % of the day's
  /// tasks). "Complete" means answered, not correct — see decisions.md D-5.
  Future<StarDecision> awardSessionBonus({
    required TrustedInstant now,
    required DayKey day,
  }) async {
    return _db.transaction(() async {
      final progress = await dayProgress(day);
      final decision = _engine.sessionBonus(day: progress, now: now);
      if (!decision.granted) return decision;

      final next = progress.copyWith(
        earnedUnits: progress.earnedUnits + decision.awardedUnits,
        sessionBonusAwarded: true,
      );
      await _upsertDay(next);
      await _appendLedger(
        day: day,
        kind: LedgerKind.sessionBonus,
        units: decision.awardedUnits,
        balanceAfter: next.balanceUnits,
        now: now,
      );
      return decision;
    });
  }

  /// Article 5's "+3" attendance bonus, on a run of two or more consecutive
  /// days. Article 6.6 resets the run on any missed day.
  Future<StarDecision> awardStreakBonus({
    required TrustedInstant now,
    required DayKey day,
  }) async {
    return _db.transaction(() async {
      final progress = await dayProgress(day);
      final decision = _engine.streakBonus(
        day: progress,
        streak: await streak(),
        now: now,
      );
      if (!decision.granted) return decision;

      final next = progress.copyWith(
        earnedUnits: progress.earnedUnits + decision.awardedUnits,
        streakBonusAwarded: true,
      );
      await _upsertDay(next);
      await _appendLedger(
        day: day,
        kind: LedgerKind.streakBonus,
        units: decision.awardedUnits,
        balanceAfter: next.balanceUnits,
        now: now,
      );
      return decision;
    });
  }

  /// Fold a completed day into the attendance run (Art. 5, Art. 6.6).
  Future<StreakState> markDayActive(DayKey day) async {
    final next = (await streak()).withActiveDay(day);
    await _writeStreak(next);
    return next;
  }

  /// A day with no completed session breaks the run (Art. 6.6).
  Future<StreakState> markDayMissed(DayKey day) async {
    final next = (await streak()).brokenBy(day);
    await _writeStreak(next);
    return next;
  }

  /// Appendix §4 — the parent's authority is above the system: not subject to
  /// the daily ceiling, and not subject to the clock, because a parent
  /// rewarding good behaviour must work on a phone whose clock we distrust.
  Future<DayProgress> parentAdjust({
    required DayKey day,
    required int deltaUnits,
    required TrustedInstant now,
    String note = '',
  }) async {
    return _db.transaction(() async {
      final progress = await dayProgress(day);
      final next = _engine.parentAdjust(progress, deltaUnits);
      final applied = next.grantedUnits - progress.grantedUnits;
      await _upsertDay(next);
      await _appendLedger(
        day: day,
        kind: applied >= 0 ? LedgerKind.parentGrant : LedgerKind.parentDeduct,
        units: applied,
        balanceAfter: next.balanceUnits,
        now: now,
        note: note,
      );
      return next;
    });
  }

  /// The one-time welcome balance of appendix §5.
  ///
  /// The "one time" is a flag on the settings row, checked and set inside the
  /// same transaction as the grant, so two callers racing at the end of the
  /// setup wizard cannot both succeed.
  Future<DayProgress?> grantWelcomeOnce({
    required StarRules rules,
    required DayKey day,
    required TrustedInstant now,
  }) async {
    return _db.transaction(() async {
      final settings =
          await (_db.select(_db.appSettings)..where((t) => t.id.equals(1)))
              .getSingle();
      if (settings.welcomeGranted || rules.welcomeUnits == 0) return null;

      final progress = await dayProgress(day);
      final next = _engine.grantWelcome(progress, rules);
      await _upsertDay(next);
      await _appendLedger(
        day: day,
        kind: LedgerKind.welcomeGrant,
        units: rules.welcomeUnits,
        balanceAfter: next.balanceUnits,
        now: now,
      );
      await (_db.update(_db.appSettings)..where((t) => t.id.equals(1)))
          .write(const AppSettingsCompanion(welcomeGranted: Value(true)));
      return next;
    });
  }

  /// Article 5's weekly-test award, 10–40 by result.
  Future<int> awardWeeklyTest({
    required DayKey day,
    required int correct,
    required int total,
    required TrustedInstant now,
    int? sourceRef,
  }) async {
    final units = _engine.weeklyTestUnits(correct: correct, total: total);
    if (units == 0) return 0;
    return _db.transaction(() async {
      final progress = await dayProgress(day);
      // The weekly test is not part of the daily session, so it lands in the
      // granted bucket and is not squeezed by the daily earning ceiling.
      final next =
          progress.copyWith(grantedUnits: progress.grantedUnits + units);
      await _upsertDay(next);
      await _appendLedger(
        day: day,
        kind: LedgerKind.weeklyTest,
        units: units,
        balanceAfter: next.balanceUnits,
        now: now,
        sourceRef: sourceRef,
      );
      return units;
    });
  }

  /// Debit real play time (appendix §2). The platform layer reports measured
  /// foreground seconds; nothing here runs a timer, so there is no threshold to
  /// get wrong and "الطفل لا يخسر دقائق وهو لا يلعب" is exact by construction.
  Future<PlayConsumption> consumePlay({
    required StarRules rules,
    required DayKey day,
    required int seconds,
  }) async {
    return _db.transaction(() async {
      final progress = await dayProgress(day);
      final result = _engine.consumePlay(
        rules: rules,
        day: progress,
        seconds: seconds,
      );
      await _upsertDay(result.day);
      return result;
    });
  }

  /// Move to [to], expiring the balance if the rules say so (Art. 6.7).
  ///
  /// The expiry is written to the ledger as a negative row rather than by
  /// resetting a column, so a parent asking "where did the 12 stars go?" gets an
  /// answer with a timestamp on it.
  Future<DayProgress> rollOverTo({
    required DayKey to,
    required StarRules rules,
    required TrustedInstant now,
    int expiryWeekday = DateTime.friday,
  }) async {
    return _db.transaction(() async {
      final lastRow = await (_db.select(_db.dayProgressRows)
            ..orderBy([(t) => OrderingTerm.desc(t.dayKey)])
            ..limit(1))
          .getSingleOrNull();

      if (lastRow == null) {
        final fresh = DayProgress(dayKey: to);
        await _upsertDay(fresh);
        return fresh;
      }

      final from = DayKey(lastRow.dayKey);
      if (to <= from) return dayProgress(to);

      final previous = await dayProgress(from);
      final expires = _engine.balanceExpires(
        from: from,
        to: to,
        rules: rules,
        expiryWeekday: expiryWeekday,
      );

      if (expires && previous.balanceUnits > 0) {
        await _appendLedger(
          day: from,
          kind: LedgerKind.expiry,
          units: -previous.balanceUnits,
          balanceAfter: 0,
          now: now,
          note: 'Art. 6.7',
        );
        await (_db.update(_db.dayProgressRows)
              ..where((t) => t.dayKey.equals(from.daysSinceEpoch)))
            .write(DayProgressRowsCompanion(expiredAtMs: Value(now.epochMs)));
      }

      final next = _engine.rollOver(
        day: previous,
        to: to,
        rules: rules,
        expiryWeekday: expiryWeekday,
      );
      await _upsertDay(next);
      return next;
    });
  }

  /// Record the size of today's session, which is what Article 6.5's "100 % of
  /// the day's tasks" is measured against.
  Future<void> setTaskCounts({
    required DayKey day,
    required int total,
    required int answered,
  }) async {
    final progress = await dayProgress(day);
    await _upsertDay(
      progress.copyWith(tasksTotal: total, tasksAnswered: answered),
    );
  }

  // ------------------------------------------------------------- internals

  Future<void> _upsertDay(DayProgress day) async {
    await _db.into(_db.dayProgressRows).insertOnConflictUpdate(
          DayProgressRowsCompanion.insert(
            dayKey: Value(day.dayKey.daysSinceEpoch),
            earnedUnits: Value(day.earnedUnits),
            grantedUnits: Value(day.grantedUnits),
            usedPlaySeconds: Value(day.usedPlaySeconds),
            tasksTotal: Value(day.tasksTotal),
            tasksAnswered: Value(day.tasksAnswered),
            sessionBonusAwarded: Value(day.sessionBonusAwarded),
            streakBonusAwarded: Value(day.streakBonusAwarded),
          ),
        );
  }

  Future<void> _appendLedger({
    required DayKey day,
    required LedgerKind kind,
    required int units,
    required int balanceAfter,
    required TrustedInstant now,
    int? sourceRef,
    String note = '',
  }) async {
    await _db.into(_db.starLedger).insert(
          StarLedgerCompanion.insert(
            dayKey: day.daysSinceEpoch,
            kind: kind,
            starUnits: units,
            balanceAfterUnits: balanceAfter,
            sourceRef: Value(sourceRef),
            atMs: now.epochMs,
            trustLevel: _trustRow(now.level),
            note: Value(note),
          ),
        );
  }

  Future<void> _writeStreak(StreakState state) async {
    await (_db.update(_db.streakStates)..where((t) => t.id.equals(1))).write(
      StreakStatesCompanion(
        lastActiveDay: Value(state.lastActiveDay?.daysSinceEpoch),
        consecutiveDays: Value(state.consecutiveDays),
        best: Value(state.best),
      ),
    );
  }

  /// The engine dedupes on an opaque string; the database keys on (kind, id).
  /// This is the one translation between them, and it is why every caller must
  /// build target ids through [targetKeyFor] rather than by hand.
  static String _targetKey(TaskKind kind, int id) => '${kind.name}:$id';

  static String targetKeyFor(EarnKind kind, int id) =>
      _targetKey(_taskKindOf(kind), id);

  static TaskKind _taskKindOf(EarnKind kind) => switch (kind) {
        EarnKind.memorizeCardFirstTime => TaskKind.memorize,
        EarnKind.cardInLaterReview => TaskKind.memorize,
        EarnKind.reviewQuestion => TaskKind.review,
      };

  static LedgerKind _ledgerKindOf(EarnKind kind) => switch (kind) {
        EarnKind.memorizeCardFirstTime => LedgerKind.cardFirstTime,
        EarnKind.cardInLaterReview => LedgerKind.cardReview,
        EarnKind.reviewQuestion => LedgerKind.reviewQuestion,
      };

  static TrustLevelRow _trustRow(TrustLevel level) => switch (level) {
        TrustLevel.serverAnchored => TrustLevelRow.serverAnchored,
        TrustLevel.monotonic => TrustLevelRow.monotonic,
        TrustLevel.untrusted => TrustLevelRow.untrusted,
      };

  static RejectionRow _rejectionRow(Rejection? rejection) => switch (rejection) {
        null => RejectionRow.none,
        Rejection.untrustedClock => RejectionRow.untrustedClock,
        Rejection.wrongAnswer => RejectionRow.wrongAnswer,
        Rejection.solutionRevealed => RejectionRow.solutionRevealed,
        Rejection.notFirstAttempt => RejectionRow.notFirstAttempt,
        Rejection.alreadyCountedToday => RejectionRow.alreadyCountedToday,
        Rejection.belowMinimumTime => RejectionRow.belowMinimumTime,
        Rejection.dailyCeilingReached => RejectionRow.dailyCeilingReached,
        Rejection.alreadyAwardedToday => RejectionRow.alreadyAwardedToday,
        Rejection.sessionIncomplete => RejectionRow.sessionIncomplete,
        Rejection.streakTooShort => RejectionRow.streakTooShort,
      };
}
