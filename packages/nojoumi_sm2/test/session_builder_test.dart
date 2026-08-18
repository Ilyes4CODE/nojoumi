import 'package:nojoumi_sm2/nojoumi_sm2.dart';
import 'package:nojoumi_time/nojoumi_time.dart';
import 'package:test/test.dart';

final DayKey day0 = DayKey.fromEpochMs(
  DateTime.utc(2026, 8, 15, 16).millisecondsSinceEpoch,
  utcOffsetMinutes: DayKey.algeriaUtcOffsetMinutes,
);

DayKey plus(int days) => DayKey(day0.daysSinceEpoch + days);

CardSchedule newCard(String id) => CardSchedule(cardId: id);

CardSchedule dueCard(
  String id, {
  int overdueDays = 0,
  int ease = 2500,
  int lapses = 0,
}) =>
    CardSchedule(
      cardId: id,
      repetitions: 2,
      intervalDays: 6,
      easePermille: ease,
      lapses: lapses,
      dueDay: DayKey(day0.daysSinceEpoch - overdueDays),
      lastReviewedDay: DayKey(day0.daysSinceEpoch - overdueDays - 6),
    );

CardSchedule futureCard(String id, {int inDays = 5}) => CardSchedule(
      cardId: id,
      repetitions: 3,
      intervalDays: 15,
      dueDay: plus(inDays),
      lastReviewedDay: day0,
    );

void main() {
  const builder = SessionBuilder();

  group('session size (appendix §5: default 12, range 5–30)', () {
    test('a session never exceeds its size, however large the backlog', () {
      final cards = [for (var i = 0; i < 200; i++) dueCard('d$i', overdueDays: i)];
      final s = builder.build(allCards: cards, today: day0, sessionSize: 12);

      expect(s.total, 12);
      expect(s.backlogCount, 188);
    });

    test(
        'a huge backlog still leaves the session completable — which is what '
        'keeps Article 5\'s +5 bonus reachable', () {
      final cards = [for (var i = 0; i < 500; i++) dueCard('d$i')];
      final s = builder.build(allCards: cards, today: day0, sessionSize: 5);

      expect(s.total, 5);
      expect(s.total, lessThanOrEqualTo(5));
    });

    test('the maximum session of 30 is honoured', () {
      final cards = [for (var i = 0; i < 100; i++) dueCard('d$i')];
      expect(
        builder.build(allCards: cards, today: day0, sessionSize: 30).total,
        30,
      );
    });

    test('an empty deck yields an empty session, not an error', () {
      final s = builder.build(allCards: [], today: day0, sessionSize: 12);
      expect(s.isEmpty, isTrue);
      expect(s.total, 0);
    });

    test('a zero or negative session size yields nothing', () {
      final cards = [dueCard('a'), newCard('b')];
      expect(builder.build(allCards: cards, today: day0, sessionSize: 0).total, 0);
      expect(builder.build(allCards: cards, today: day0, sessionSize: -5).total, 0);
    });
  });

  group('what gets picked', () {
    test('cards not yet due are never included', () {
      final cards = [futureCard('f1'), futureCard('f2'), dueCard('d1')];
      final s = builder.build(allCards: cards, today: day0, sessionSize: 12);

      expect(s.cards.map((c) => c.cardId), ['d1']);
    });

    test('a card due exactly today is included', () {
      final cards = [dueCard('today')];
      final s = builder.build(allCards: cards, today: day0, sessionSize: 12);
      expect(s.total, 1);
    });

    test('the most overdue card comes first — worst first', () {
      final cards = [
        dueCard('mild', overdueDays: 1),
        dueCard('worst', overdueDays: 30),
        dueCard('medium', overdueDays: 7),
      ];
      final s = builder.build(allCards: cards, today: day0, sessionSize: 12);

      expect(s.cards.map((c) => c.cardId), ['worst', 'medium', 'mild']);
    });

    test('at equal overdue, the weaker ease is presented first', () {
      final cards = [
        dueCard('strong', overdueDays: 3, ease: 2500),
        dueCard('weak', overdueDays: 3, ease: 1400),
      ];
      final s = builder.build(allCards: cards, today: day0, sessionSize: 12);

      expect(s.cards.first.cardId, 'weak');
    });

    test('at equal overdue and ease, more lapses wins', () {
      final cards = [
        dueCard('clean', overdueDays: 2, lapses: 0),
        dueCard('troubled', overdueDays: 2, lapses: 5),
      ];
      final s = builder.build(allCards: cards, today: day0, sessionSize: 12);

      expect(s.cards.first.cardId, 'troubled');
    });

    test('the order is reproducible for identical cards', () {
      final cards = [dueCard('b'), dueCard('a'), dueCard('c')];
      final first = builder.build(allCards: cards, today: day0, sessionSize: 12);
      final second = builder.build(allCards: cards, today: day0, sessionSize: 12);

      expect(
        first.cards.map((c) => c.cardId).toList(),
        second.cards.map((c) => c.cardId).toList(),
      );
    });
  });

  group('new cards versus the backlog', () {
    test('with no backlog, the session is all new cards', () {
      final cards = [for (var i = 0; i < 40; i++) newCard('n$i')];
      final s = builder.build(allCards: cards, today: day0, sessionSize: 12);

      expect(s.newCount, 12);
      expect(s.dueCount, 0);
    });

    test('with a backlog, new cards keep a minority share but never zero', () {
      final cards = [
        for (var i = 0; i < 100; i++) dueCard('d$i', overdueDays: i),
        for (var i = 0; i < 100; i++) newCard('n$i'),
      ];
      final s = builder.build(allCards: cards, today: day0, sessionSize: 12);

      expect(s.total, 12);
      expect(s.newCount, 4, reason: '40% of 12, floored');
      expect(s.dueCount, 8);
      expect(s.newCount, greaterThan(0),
          reason: 'a session with no new material feels like a punishment');
    });

    test('review reclaims the slots new cards do not use', () {
      final cards = [
        for (var i = 0; i < 20; i++) dueCard('d$i', overdueDays: i),
        newCard('n1'),
      ];
      final s = builder.build(allCards: cards, today: day0, sessionSize: 12);

      expect(s.total, 12);
      expect(s.newCount, 1);
      expect(s.dueCount, 11, reason: 'the unused new-card budget went to review');
    });

    test('the new-card share is configurable', () {
      const heavy = SessionBuilder(newCardShare: 0.75);
      final cards = [
        for (var i = 0; i < 50; i++) dueCard('d$i'),
        for (var i = 0; i < 50; i++) newCard('n$i'),
      ];
      final s = heavy.build(allCards: cards, today: day0, sessionSize: 12);

      expect(s.newCount, 9);
      expect(s.dueCount, 3);
    });

    test('the counts always add up to the session total', () {
      final cards = [
        for (var i = 0; i < 30; i++) dueCard('d$i', overdueDays: i % 9),
        for (var i = 0; i < 30; i++) newCard('n$i'),
        for (var i = 0; i < 10; i++) futureCard('f$i'),
      ];
      for (final size in [5, 8, 12, 20, 30]) {
        final s = builder.build(allCards: cards, today: day0, sessionSize: size);
        expect(s.dueCount + s.newCount, s.total, reason: 'size $size');
        expect(s.total, size, reason: 'size $size');
      }
    });

    test('no card is ever selected twice in one session', () {
      final cards = [
        for (var i = 0; i < 30; i++) dueCard('d$i', overdueDays: i),
        for (var i = 0; i < 30; i++) newCard('n$i'),
      ];
      final s = builder.build(allCards: cards, today: day0, sessionSize: 30);
      final ids = s.cards.map((c) => c.cardId).toList();

      expect(ids.toSet().length, ids.length);
    });
  });

  group('a full week, scheduler and builder together', () {
    test('a child who answers everything correctly sees the backlog drain', () {
      const sm2 = Sm2Scheduler();
      var deck = [for (var i = 0; i < 30; i++) newCard('c$i')];

      for (var d = 0; d < 7; d++) {
        final today = plus(d);
        final session =
            builder.build(allCards: deck, today: today, sessionSize: 12);
        final reviewed = {
          for (final c in session.cards)
            c.cardId: sm2.review(
              card: c,
              grade: Sm2Grade.correctEasy,
              today: today,
            ),
        };
        deck = [for (final c in deck) reviewed[c.cardId] ?? c];
      }

      // Every card has been introduced, and none is still unseen.
      expect(deck.where((c) => c.isNew), isEmpty);
      // Nothing is scheduled in the past.
      for (final c in deck) {
        expect(c.dueDay!.daysSinceEpoch, greaterThan(plus(6).daysSinceEpoch - 7));
      }
    });

    test('cards the child keeps failing keep coming back', () {
      const sm2 = Sm2Scheduler();
      var weak = newCard('hard-one');

      for (var d = 0; d < 5; d++) {
        final today = plus(d);
        expect(weak.isDue(today), isTrue,
            reason: 'day $d: a failed card must resurface (Art. 2)');
        weak = sm2.review(card: weak, grade: Sm2Grade.blackout, today: today);
      }
      expect(weak.lapses, 5);
    });
  });
}
