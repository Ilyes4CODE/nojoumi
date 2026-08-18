import 'package:nojoumi_time/nojoumi_time.dart';

import 'sm2.dart';

/// Today's card selection.
class DailySelection {
  const DailySelection({
    required this.cards,
    required this.dueCount,
    required this.newCount,
    required this.backlogCount,
  });

  /// The cards to present, in presentation order.
  final List<CardSchedule> cards;

  /// How many of [cards] were review cards that had come due.
  final int dueCount;

  /// How many were seen for the first time.
  final int newCount;

  /// Due cards that did not fit in today's session. Article 6.5's session bonus
  /// is measured against what was *presented*, so a backlog must never make the
  /// bonus unreachable — see [SessionBuilder.build].
  final int backlogCount;

  bool get isEmpty => cards.isEmpty;
  int get total => cards.length;
}

/// Chooses which cards the child sees today.
///
/// The appendix fixes the session size ("حجم الجلسة اليومية", default 12,
/// range 5–30) and Article 2 requires that weak cards resurface automatically.
/// This builder is where those two meet, and it is pure so the policy is
/// testable without a database.
class SessionBuilder {
  const SessionBuilder({this.newCardShare = 0.4});

  /// The share of a session that may go to cards never seen before, when there
  /// is a backlog competing for the same slots. Overdue review is more valuable
  /// than new material — a child drowning in forgotten cards should not be
  /// handed more of them — but a session with no new cards at all feels like a
  /// punishment, so new cards keep a guaranteed minority share.
  final double newCardShare;

  /// Build today's session.
  ///
  /// Order of priority:
  ///  1. the most overdue review cards, worst first;
  ///  2. then new cards, up to [newCardShare] of the session;
  ///  3. then more review cards if space remains.
  ///
  /// The result is always at most [sessionSize], which is what makes the
  /// session completable — and therefore what makes Article 5's +5 bonus
  /// reachable on a day when 200 cards are overdue.
  DailySelection build({
    required List<CardSchedule> allCards,
    required DayKey today,
    required int sessionSize,
  }) {
    if (sessionSize <= 0 || allCards.isEmpty) {
      return const DailySelection(
        cards: [],
        dueCount: 0,
        newCount: 0,
        backlogCount: 0,
      );
    }

    final due = <CardSchedule>[];
    final fresh = <CardSchedule>[];
    for (final c in allCards) {
      if (c.isNew) {
        fresh.add(c);
      } else if (c.isDue(today)) {
        due.add(c);
      }
    }

    // Worst first: most overdue, then weakest ease, then most lapses. Stable on
    // card id so the order is reproducible for a given day.
    due.sort((a, b) {
      final byOverdue = b.overdueBy(today).compareTo(a.overdueBy(today));
      if (byOverdue != 0) return byOverdue;
      final byEase = a.easePermille.compareTo(b.easePermille);
      if (byEase != 0) return byEase;
      final byLapses = b.lapses.compareTo(a.lapses);
      if (byLapses != 0) return byLapses;
      return a.cardId.compareTo(b.cardId);
    });
    fresh.sort((a, b) => a.cardId.compareTo(b.cardId));

    final newBudget = due.isEmpty
        ? sessionSize
        : (sessionSize * newCardShare).floor();

    final picked = <CardSchedule>[];
    var takenDue = 0;
    var takenNew = 0;

    final reviewBudget = sessionSize - newBudget;
    for (final c in due) {
      if (takenDue >= reviewBudget) break;
      picked.add(c);
      takenDue++;
    }
    for (final c in fresh) {
      if (takenNew >= newBudget || picked.length >= sessionSize) break;
      picked.add(c);
      takenNew++;
    }
    // New cards did not use their whole budget — give the room back to review.
    for (final c in due.skip(takenDue)) {
      if (picked.length >= sessionSize) break;
      picked.add(c);
      takenDue++;
    }

    return DailySelection(
      cards: picked,
      dueCount: takenDue,
      newCount: takenNew,
      backlogCount: due.length - takenDue,
    );
  }
}
