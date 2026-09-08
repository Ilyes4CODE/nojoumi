import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/local/database.dart';
import '../../data/local/tables.dart';
import '../../l10n/app_localizations.dart';

/// The append-only ledger, and the rejections beside it.
///
/// This screen is AD-4 paying for itself. Article 6 has nine joint conditions,
/// and the predictable support question is "my child answered that correctly,
/// why did they get nothing?". Without this, the answer is a guess. With it,
/// the answer is a row: the condition that stopped it, the time, and the trust
/// level of the clock at that moment.
class StarLedgerScreen extends ConsumerWidget {
  const StarLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    final ledger = ref.watch(todayLedgerProvider).value ?? const [];
    final rejections = ref.watch(todayRejectionsProvider).value ?? const [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.parentLedgerTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.parentLedgerTitle),
              Tab(text: l10n.parentWhyNoStar),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LedgerList(rows: ledger),
            _RejectionList(rows: rejections),
          ],
        ),
      ),
    );
  }
}

class _LedgerList extends StatelessWidget {
  const _LedgerList({required this.rows});

  final List<StarLedgerRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    if (rows.isEmpty) return _Empty(message: l10n.parentLedgerEmpty);

    return ListView.separated(
      padding: LunioSpacing.page,
      itemCount: rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = rows[index];
        final positive = row.starUnits >= 0;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_ledgerKind(l10n, row.kind)),
          subtitle: row.note.isEmpty ? null : Text(row.note),
          trailing: Text(
            Fmt.signedStars(row.starUnits),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: positive
                  ? LunioTheme.play
                  : Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  static String _ledgerKind(AppL10n l10n, LedgerKind kind) => switch (kind) {
    LedgerKind.cardFirstTime => l10n.ledgerCardFirstTime,
    LedgerKind.cardReview => l10n.ledgerCardReview,
    LedgerKind.reviewQuestion => l10n.ledgerReviewQuestion,
    LedgerKind.sessionBonus => l10n.ledgerSessionBonus,
    LedgerKind.streakBonus => l10n.ledgerStreakBonus,
    LedgerKind.weeklyTest => l10n.ledgerWeeklyTest,
    LedgerKind.welcomeGrant => l10n.ledgerWelcomeGrant,
    LedgerKind.parentGrant => l10n.ledgerParentGrant,
    LedgerKind.parentDeduct => l10n.ledgerParentDeduct,
    LedgerKind.expiry => l10n.ledgerExpiry,
  };
}

class _RejectionList extends StatelessWidget {
  const _RejectionList({required this.rows});

  final List<AttemptRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    if (rows.isEmpty) return _Empty(message: l10n.parentLedgerEmpty);

    return ListView.separated(
      padding: LunioSpacing.page,
      itemCount: rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = rows[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_rejection(l10n, row.rejection)),
          subtitle: Text('${_taskKind(l10n, row.kind)} · ${row.msOnTarget} ms'),
        );
      },
    );
  }

  /// The nine conditions of Article 6, in the parent's language.
  ///
  /// Written as full sentences rather than error codes, because the audience is
  /// a parent who is about to decide whether the app is broken or the rule is
  /// working. Each one names the article so the answer can be checked against
  /// the signed contract rather than trusted.
  static String _rejection(AppL10n l10n, RejectionRow rejection) =>
      switch (rejection) {
        RejectionRow.none => '',
        RejectionRow.untrustedClock => l10n.rejectUntrustedClock,
        RejectionRow.wrongAnswer => l10n.rejectWrongAnswer,
        RejectionRow.solutionRevealed => l10n.rejectSolutionRevealed,
        RejectionRow.notFirstAttempt => l10n.rejectNotFirstAttempt,
        RejectionRow.alreadyCountedToday => l10n.rejectAlreadyCountedToday,
        RejectionRow.belowMinimumTime => l10n.rejectBelowMinimumTime,
        RejectionRow.dailyCeilingReached => l10n.rejectDailyCeilingReached,
        RejectionRow.alreadyAwardedToday => l10n.rejectAlreadyAwardedToday,
        RejectionRow.sessionIncomplete => l10n.rejectSessionIncomplete,
        RejectionRow.streakTooShort => l10n.rejectStreakTooShort,
      };

  static String _taskKind(AppL10n l10n, TaskKind kind) => switch (kind) {
    TaskKind.memorize => l10n.taskMemorize,
    TaskKind.review => l10n.taskReview,
    TaskKind.exercise => l10n.taskExercise,
  };
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: LunioSpacing.page,
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
