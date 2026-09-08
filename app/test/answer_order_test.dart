import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/domain/answer_order.dart';

/// The re-ordering applied to a question every time it is asked.
///
/// The client asked on 2026-08-31 that a question answered wrongly come back
/// with the answer somewhere else. A question re-asked in the order the child
/// just saw is not a second attempt; it is a memory test on a screen they were
/// looking at ten seconds ago.
void main() {
  const choices = ['الجزائر', 'وهران', 'قسنطينة', 'عنابة'];

  group('the answer travels with its index', () {
    test('the index always points at the right text', () {
      // Swept, because the failure is positional: an inverted lookup is right
      // whenever the shuffle happens to be the identity, so one case can pass
      // while the arithmetic is wrong. Getting this wrong marks a child wrong
      // for being right, and nothing on screen would look unusual.
      for (var correct = 0; correct < choices.length; correct++) {
        for (var seed = 0; seed < 200; seed++) {
          final asked = AnswerOrder.reorder(
            choices: choices,
            correctIndex: correct,
            seed: seed,
          );
          expect(
            asked.choices[asked.correctIndex],
            choices[correct],
            reason: 'correct=$correct seed=$seed',
          );
        }
      }
    });

    test('nothing is lost or duplicated', () {
      final asked = AnswerOrder.reorder(
        choices: choices,
        correctIndex: 2,
        seed: 7,
      );

      expect(asked.choices, hasLength(choices.length));
      expect(asked.choices.toSet(), choices.toSet());
    });

    test('a two-choice question survives both outcomes', () {
      // `shuffle` on two items is a coin flip, and the mapping has to hold
      // whichever way it lands.
      final seen = <int>{};
      for (var seed = 0; seed < 50; seed++) {
        final asked = AnswerOrder.reorder(
          choices: const ['نعم', 'لا'],
          correctIndex: 0,
          seed: seed,
        );
        expect(asked.choices[asked.correctIndex], 'نعم');
        seen.add(asked.correctIndex);
      }
      expect(seen, {0, 1}, reason: 'both placements must occur');
    });
  });

  group('the order actually moves', () {
    test('the answer does not sit in the same place every time', () {
      final places = <int>{};
      for (var seed = 0; seed < 40; seed++) {
        places.add(
          AnswerOrder.reorder(
            choices: choices,
            correctIndex: 0,
            seed: seed,
          ).correctIndex,
        );
      }
      expect(places.length, greaterThan(1));
    });

    test('the same seed asks the same way twice', () {
      // A child who leaves mid-question and comes back must find the options as
      // they left them; the seed is the task row, which does not change.
      final first = AnswerOrder.reorder(
        choices: choices,
        correctIndex: 1,
        seed: 4242,
      );
      final again = AnswerOrder.reorder(
        choices: choices,
        correctIndex: 1,
        seed: 4242,
      );

      expect(again.choices, first.choices);
      expect(again.correctIndex, first.correctIndex);
    });
  });

  group('degenerate input is left alone rather than mangled', () {
    test('a single choice is returned untouched', () {
      final asked = AnswerOrder.reorder(
        choices: const ['وحيد'],
        correctIndex: 0,
        seed: 1,
      );

      expect(asked.choices, ['وحيد']);
      expect(asked.correctIndex, 0);
    });

    test('an index outside the list is not moved around', () {
      // The row is already wrong. Shuffling would relocate the damage instead
      // of leaving it where somebody can find it.
      final asked = AnswerOrder.reorder(
        choices: choices,
        correctIndex: 9,
        seed: 1,
      );

      expect(asked.choices, choices);
      expect(asked.correctIndex, 9);
    });

    test('an empty list does not throw', () {
      final asked = AnswerOrder.reorder(
        choices: const [],
        correctIndex: 0,
        seed: 1,
      );

      expect(asked.choices, isEmpty);
    });
  });
}
