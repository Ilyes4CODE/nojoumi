import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/domain/card_choices.dart';

/// The options offered on a memorization card.
///
/// Two of these guard star accounting rather than presentation, and they are
/// the reason this file exists at all:
///
///  * **the correct index must point at the correct text.** The builder shuffles
///    and then looks the answer up again; getting that inversion wrong marks a
///    right answer wrong and withholds a star the child earned, and it is
///    invisible from the outside — the screen would look perfectly normal.
///  * **a one-option card is refused.** Article 6.3 exists to stop stars being
///    earned by tapping, and a question with a single button is a tap.
void main() {
  const back = 'الجزائر العاصمة';

  CardChoiceSet build({
    List<String> same = const [],
    List<String> other = const [],
    int cardId = 7,
    int daySeed = 20500,
    String correct = back,
  }) => CardChoices.build(
    cardId: cardId,
    back: correct,
    sameLessonBacks: same,
    otherLessonBacks: other,
    daySeed: daySeed,
  );

  group('the set that is built', () {
    test('offers four options when the lesson has enough answers', () {
      final set = build(same: ['وهران', 'قسنطينة', 'عنابة', 'باتنة']);

      expect(set.choices, hasLength(CardChoices.maxChoices));
      expect(set.isUsable, isTrue);
    });

    test('the correct index points at the correct answer', () {
      // Swept across many cards and days because the failure is positional: an
      // inverted lookup is right whenever the shuffle happens to be identity,
      // so a single case can pass while the arithmetic is wrong.
      for (var cardId = 1; cardId <= 40; cardId++) {
        for (var day = 20500; day < 20510; day++) {
          final set = build(
            cardId: cardId,
            daySeed: day,
            same: ['وهران', 'قسنطينة', 'عنابة', 'باتنة', 'سطيف'],
          );
          expect(
            set.choices[set.correctIndex],
            back,
            reason: 'card $cardId on day $day',
          );
        }
      }
    });

    test('the answer does not sit in the same place every time', () {
      // The point of shuffling at all. If this ever fails the child can learn
      // the position instead of the answer, which is the same defect the review
      // questions had before the server started shuffling them (D-74).
      final places = <int>{};
      for (var cardId = 1; cardId <= 40; cardId++) {
        places.add(
          build(cardId: cardId, same: ['أ', 'ب', 'ج', 'د']).correctIndex,
        );
      }
      expect(places.length, greaterThan(1));
    });
  });

  group('stability', () {
    test('the same card on the same day gets the same options in order', () {
      // A child who leaves mid-session and comes back must find the card as
      // they left it. Re-rolling would also let them reopen a card until the
      // options got easy.
      final first = build(same: ['وهران', 'قسنطينة', 'عنابة', 'باتنة']);
      final again = build(same: ['وهران', 'قسنطينة', 'عنابة', 'باتنة']);

      expect(again.choices, first.choices);
      expect(again.correctIndex, first.correctIndex);
    });

    test('the same card on another day is asked differently', () {
      final pool = ['وهران', 'قسنطينة', 'عنابة', 'باتنة', 'سطيف', 'تلمسان'];
      final today = build(same: pool, daySeed: 20500);

      // Compared across a stretch of days rather than one: two consecutive
      // seeds could coincide by chance, and a flaky test is worse than none.
      final later = [
        for (var day = 20501; day < 20510; day++)
          build(same: pool, daySeed: day).choices.join('|'),
      ];
      expect(later.any((c) => c != today.choices.join('|')), isTrue);
    });
  });

  group('what is refused', () {
    test('nothing to choose between is refused, not padded', () {
      final set = build();

      expect(set.isUsable, isFalse);
      expect(set.choices, isEmpty);
      // The caller falls back to the recall card. Awarding a star for the only
      // button on screen is exactly what Article 6.3 is about.
    });

    test('an empty answer is refused', () {
      expect(build(correct: '   ', same: ['أ', 'ب', 'ج']).isUsable, isFalse);
    });

    test('the correct answer is never offered twice', () {
      // Two cards on a page often share a short answer. Offering it as a
      // distractor would put two right answers on screen and mark one wrong.
      final set = build(same: [back, 'وهران', 'قسنطينة']);

      expect(set.choices.where((c) => c == back), hasLength(1));
      expect(set.choices[set.correctIndex], back);
    });

    test('spacing does not smuggle a duplicate through', () {
      final set = build(same: ['الجزائر   العاصمة', 'وهران', 'قسنطينة']);

      expect(set.choices, hasLength(3));
      expect(set.choices.toSet(), hasLength(3));
    });

    test('two distinct answers are enough to ask a question', () {
      final set = build(same: ['وهران']);

      expect(set.choices, hasLength(2));
      expect(set.isUsable, isTrue);
    });
  });

  group('where the wrong answers come from', () {
    test('the lesson is preferred over the rest of the device', () {
      // A distractor from the same page tests recall. One from another subject
      // is a free elimination — a child who knows the question is about the
      // capital rules out a fraction without knowing the answer.
      final set = build(
        same: ['وهران', 'قسنطينة', 'عنابة'],
        other: ['الكسر العشري', 'الفاعل مرفوع'],
      );

      expect(set.choices, hasLength(4));
      expect(set.choices, isNot(contains('الكسر العشري')));
      expect(set.choices, isNot(contains('الفاعل مرفوع')));
    });

    test('a small lesson is topped up from elsewhere', () {
      // Better a distant distractor than a two-option card on a lesson that
      // generated a single pair.
      final set = build(same: ['وهران'], other: ['الكسر العشري', 'الفاعل مرفوع']);

      expect(set.choices, hasLength(4));
      expect(set.choices, contains('وهران'));
    });
  });
}
