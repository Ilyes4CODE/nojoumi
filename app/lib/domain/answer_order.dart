import 'dart:math';

/// Re-orders a question's answers, keeping hold of which one is right.
///
/// ### Why the app shuffles at all, when the server already did
///
/// D-74 shuffles once on the way out of the AI provider, because the model puts
/// the right answer first far more often than chance. That fixes the *stored*
/// order, and it is still the right place for it.
///
/// This is a different job. The client asked on 2026-08-31 that a question
/// answered wrongly **come back, with the answer somewhere else**. A question
/// re-asked with the four options in the order the child just saw is not a
/// second attempt at the question; it is a memory test on a screen they were
/// looking at ten seconds ago, and a child who guessed at random can pass it by
/// remembering which button was green.
///
/// ### Seeded by the presentation, not by the question
///
/// The seed is the `task_instances` row id — the *presentation* — so:
///
///  * the same question asked twice today is asked two different ways, because
///    each attempt is its own row;
///  * a child who leaves mid-question and comes back finds the options exactly
///    as they left them, because the row has not changed. Re-rolling on every
///    read would look like the app losing its place, and would let a child
///    reopen a question until the layout felt easy.
class AnswerOrder {
  const AnswerOrder._();

  /// Returns the choices in a new order, with the index of the right one.
  ///
  /// **The index is the dangerous half.** `order` maps *new position → old*, so
  /// the answer's new index is the position now holding the old one — that is
  /// `order.indexOf(correctIndex)`. Inverting it is a one-token mistake that
  /// stays invisible until a child is marked wrong for being right, which is
  /// why it has its own test.
  static ({List<String> choices, int correctIndex}) reorder({
    required List<String> choices,
    required int correctIndex,
    required int seed,
  }) {
    // Nothing to shuffle, and nothing that could be made wrong by trying.
    if (choices.length < 2) {
      return (choices: List<String>.from(choices), correctIndex: correctIndex);
    }
    // A correct index pointing outside the list means the row is already wrong;
    // shuffling would move the damage around rather than reveal it.
    if (correctIndex < 0 || correctIndex >= choices.length) {
      return (choices: List<String>.from(choices), correctIndex: correctIndex);
    }

    final order = List<int>.generate(choices.length, (i) => i)
      ..shuffle(Random(seed & 0x7fffffff));

    return (
      choices: [for (final i in order) choices[i]],
      correctIndex: order.indexOf(correctIndex),
    );
  }
}
