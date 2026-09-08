import 'dart:math';

/// The answer options offered for one memorization card.
///
/// [choices] is the full list as it should be painted, already shuffled;
/// [correctIndex] points into it. Empty when the device does not hold enough
/// distinct answers to build an honest question — see [isUsable].
class CardChoiceSet {
  const CardChoiceSet({required this.choices, required this.correctIndex});

  static const CardChoiceSet none = CardChoiceSet(
    choices: <String>[],
    correctIndex: 0,
  );

  final List<String> choices;
  final int correctIndex;

  /// Whether these choices can be shown to a child.
  ///
  /// **A single-option question is not a question.** It would award a star for
  /// one tap on the only button on screen, which is precisely the "rapid random
  /// tapping" Article 6.3 exists to refuse. When this is false the caller must
  /// fall back to the recall card rather than paint what it has.
  bool get isUsable => choices.length >= CardChoices.minChoices;
}

/// Builds the options for a memorization card out of other cards' answers.
///
/// ### Why the cards became multiple choice
///
/// Requested by the client on 2026-08-30: «و تكون البطاقات فقط خيارات».
///
/// It is worth recording that this **strengthens** Article 6 rather than
/// bending it. The previous card asked the child to self-report — «أعرفها» or
/// «لم أعرفها» — and a self-report is 100 % exploitable: a child who taps
/// «أعرفها» on every card earns every star in the table without reading a word.
/// Article 6.1 grants a star for an answer "correct on the first attempt", and
/// a claim is not an observation. Choosing the right answer out of four is one.
///
/// It also makes D-22 true rather than aspirational. That decision says the
/// SM-2 grade must come from what was observed and never from a rating a child
/// cannot honestly give — but the observation being fed in was itself the
/// child's claim. Now it is a fact.
///
/// The residue is that a guess succeeds one time in four. That is a real
/// weakening against a *determined* gamer and it is worth saying out loud, but
/// it replaces a mechanism that succeeded four times in four, and Article 6.3's
/// minimum time on the card still has to be cleared before any of it counts.
///
/// ### Where the wrong answers come from
///
/// Other cards' backs, same lesson first. A distractor from the same page is
/// the one that actually tests recall: all four options are plausible answers
/// about the same material, so the child has to know which, not merely which
/// looks like it belongs. Cards from other lessons fill the gap only when the
/// lesson is too small, because an option about fractions under a question
/// about grammar is a free elimination.
///
/// ### Why it is seeded rather than random
///
/// A child who leaves mid-session and comes back must see the same four
/// options in the same order. Re-rolling them would look like the app losing
/// its place, and worse, would let a child re-enter a card until the options
/// were easy. The seed is the card and the day, so the set is stable within a
/// day and different when the card comes round again on a later review — which
/// stops the child memorising a position instead of an answer.
class CardChoices {
  const CardChoices._();

  /// Four is the ceiling used by the generated review questions too, so the two
  /// task kinds look like each other on screen.
  static const int maxChoices = 4;

  /// Below this there is nothing to choose between. See [CardChoiceSet.isUsable].
  static const int minChoices = 2;

  static CardChoiceSet build({
    required int cardId,
    required String back,
    required List<String> sameLessonBacks,
    required List<String> otherLessonBacks,
    required int daySeed,
  }) {
    final correct = back.trim();
    if (correct.isEmpty) return CardChoiceSet.none;

    final seen = <String>{_key(correct)};
    final near = _distinct(sameLessonBacks, seen);
    final far = _distinct(otherLessonBacks, seen);

    // One generator for every draw below, so the whole set — which distractors,
    // and where the answer lands — is one deterministic function of the card
    // and the day.
    final random = Random((cardId * 1000003 + daySeed) & 0x7fffffff);

    near.shuffle(random);
    far.shuffle(random);

    final wanted = maxChoices - 1;
    final distractors = <String>[
      ...near.take(wanted),
      ...far.take(wanted - near.length.clamp(0, wanted)),
    ];
    if (distractors.isEmpty) return CardChoiceSet.none;

    final choices = <String>[correct, ...distractors]..shuffle(random);
    return CardChoiceSet(
      choices: choices,
      correctIndex: choices.indexOf(correct),
    );
  }

  /// Trimmed, non-empty, and not already taken — mutating [seen] as it goes.
  ///
  /// Duplicates matter more than they look: two cards on a page often carry the
  /// same short answer, and offering it twice would put **two correct options**
  /// in front of the child and mark one of them wrong.
  static List<String> _distinct(List<String> source, Set<String> seen) {
    final out = <String>[];
    for (final raw in source) {
      final text = raw.trim();
      if (text.isEmpty) continue;
      if (!seen.add(_key(text))) continue;
      out.add(text);
    }
    return out;
  }

  /// Collapses whitespace so answers differing only in spacing count as one.
  static String _key(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
