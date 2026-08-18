import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories/session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(
    ref.watch(databaseProvider),
    ref.watch(starRepositoryProvider),
  );
});

/// Holds today's session and applies answers to it.
///
/// AD-9 in practice: the widgets dispatch one intent — "this task was answered
/// this way, after this many milliseconds" — and read back immutable state.
/// Not one condition from Article 5 or 6 is evaluated in a widget; the decision
/// is made by the engine, applied by the repository, and only its *result*
/// reaches the screen.
final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, DailySession>(
  SessionController.new,
);

class SessionController extends AsyncNotifier<DailySession> {
  @override
  Future<DailySession> build() async {
    final rules = await ref.watch(
      starRulesProvider.select((v) async => v.requireValue),
    );
    final day = ref.watch(todayProvider).requireValue;
    return ref.watch(sessionRepositoryProvider).sessionFor(
          day: day,
          rules: rules,
        );
  }

  /// Record one answer and refresh the session.
  ///
  /// Returns the outcome so a caller can show what was earned; the state update
  /// happens regardless, because the progress bar must move even when the
  /// answer earned nothing.
  Future<AnswerOutcome?> answer({
    required SessionTask task,
    required bool correct,
    required int msOnTarget,
    int attemptNumber = 1,
    bool solutionRevealed = false,
  }) async {
    final rules = ref.read(starRulesProvider).value;
    final day = ref.read(todayProvider).value;
    if (rules == null || day == null) return null;

    // Re-read the clock on every answer rather than once per session. A session
    // can span a day boundary, and it can span someone changing the clock —
    // Article 6.8 has to be evaluated against the moment of the answer, not the
    // moment the screen opened.
    final now = await ref.read(trustedNowProvider.notifier).refresh();

    final outcome =
        await ref.read(sessionRepositoryProvider).submitAnswer(
              day: day,
              rules: rules,
              now: now,
              task: task,
              correct: correct,
              attemptNumber: attemptNumber,
              msOnTarget: msOnTarget,
              solutionRevealed: solutionRevealed,
            );

    state = AsyncData(
      await ref.read(sessionRepositoryProvider).sessionFor(
            day: day,
            rules: rules,
          ),
    );
    return outcome;
  }
}
