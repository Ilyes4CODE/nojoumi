import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/illustrations.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../l10n/app_localizations.dart';
import 'session_controller.dart';
import 'session_screen.dart';

/// How long the lesson summary stays up before its cards can be opened.
///
/// Requested by the client on 2026-08-30: a summary first, and a way through to
/// the cards that only opens a minute later.
///
/// The delay is the feature, not an inconvenience around it. A child who can
/// skip straight to the cards will, and then answers about material they have
/// not read — which turns Article 4.3's memorize step into guessing and feeds
/// SM-2 a schedule built on noise.
///
/// It is spent **once per lesson per day**. The rule that survives closing the
/// app is derived rather than stored: *a lesson with an answered card has had
/// its summary.* A child who studies two cards and comes back is not made to
/// sit through it again, and it needs no new column and no migration. A child
/// who leaves during the minute sees it again, which is right — nothing was
/// studied yet.
const Duration lessonSummaryGate = Duration(seconds: 60);

/// One lesson: its summary, and the two halves of it.
///
/// The split into «بطاقات الحفظ» and «أسئلة المراجعة» is the client's, asked for
/// on 2026-08-30. It also happens to be Article 4.3's own division of the day,
/// which is why the review half is **held shut until the cards are done**
/// rather than merely listed second: a child answering questions about a page
/// they have not studied is being examined, not taught, and the grade SM-2 gets
/// out of it means nothing.
class LessonHubScreen extends ConsumerStatefulWidget {
  const LessonHubScreen({super.key, required this.lessonId});

  final int lessonId;

  @override
  ConsumerState<LessonHubScreen> createState() => _LessonHubScreenState();
}

class _LessonHubScreenState extends ConsumerState<LessonHubScreen> {
  Timer? _timer;
  int _secondsLeft = lessonSummaryGate.inSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft -= 1);
      // Cancelled the moment it is spent: nothing should keep ticking behind
      // the cards, and a periodic timer left running is also a widget test that
      // can never settle.
      if (_secondsLeft <= 0) {
        timer.cancel();
        _timer = null;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final slice = ref
        .watch(sessionControllerProvider)
        .value
        ?.sliceOf(widget.lessonId);

    final title = slice?.brief.title.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? l10n.myLessons : title),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: Backdrop(Illustration.lessonBackground, opacity: 0.9),
          ),
          SafeArea(
            child: slice == null
                ? const Center(child: CircularProgressIndicator())
                : _Body(slice: slice, secondsLeft: _gateFor(slice)),
          ),
        ],
      ),
    );
  }

  /// Zero once the child has answered **anything** here — see
  /// [lessonSummaryGate].
  ///
  /// Any task, not specifically a card: with the memorization cards turned off
  /// (2026-08-31) a lesson has only questions, and a rule phrased in terms of
  /// cards would have held the minute open for ever — the summary would have
  /// been re-gated on every single visit.
  int _gateFor(LessonSlice slice) => slice.answered > 0 ? 0 : _secondsLeft;
}

class _Body extends StatelessWidget {
  const _Body({required this.slice, required this.secondsLeft});

  final LessonSlice slice;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    final hasCards = slice.cards.isNotEmpty;
    final gate = secondsLeft > 0 ? l10n.lessonIntroWait('$secondsLeft') : null;

    return ListView(
      padding: LunioSpacing.page,
      children: [
        Center(child: Illustration.cardBook.show(size: 72)),
        const SizedBox(height: LunioSpacing.m),
        Container(
          padding: const EdgeInsets.all(LunioSpacing.l),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(LunioRadius.card),
          ),
          child: Text(
            slice.brief.summary,
            // Generous line height: this is the one screen in the app where a
            // child is asked to read a paragraph rather than a label.
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
          ),
        ),
        const SizedBox(height: LunioSpacing.l),

        // Only shown when there are cards. With `dailySessionCards` at 0 the
        // memorize half does not exist, and a permanently greyed-out tile
        // reading "0 of 0" is a promise of something that is never coming.
        if (hasCards) ...[
          _SectionCard(
            illustration: Illustration.sectionMemorize,
            tint: LunioTheme.tintMint,
            title: l10n.cardsHeading,
            subtitle: l10n.lessonCardsCount('${slice.cards.length}'),
            done: slice.cardsAnswered,
            total: slice.cards.length,
            lockedNote: gate,
            section: SessionSection.memorize,
            lessonId: slice.lessonId,
          ),
          const SizedBox(height: LunioSpacing.m),
        ],

        _SectionCard(
          illustration: Illustration.sectionQuestions,
          tint: LunioTheme.tintPeach,
          title: l10n.questionsHeading,
          subtitle: l10n.lessonQuestionsCount('${slice.questions.length}'),
          done: slice.questionsAnswered,
          total: slice.questions.length,
          // The minute belongs to whichever half the child meets first. With
          // cards present it guards them and Article 4.3 keeps the questions
          // shut behind them; with no cards the questions *are* the first half,
          // so the summary has to be read before them instead.
          lockedNote: hasCards
              ? (slice.questionsUnlocked ? null : l10n.sectionLocked)
              : gate,
          section: SessionSection.review,
          lessonId: slice.lessonId,
        ),
      ],
    );
  }
}

/// One half of a lesson, as a card a child taps.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.illustration,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.total,
    required this.lockedNote,
    required this.section,
    required this.lessonId,
  });

  final Illustration illustration;
  final Color tint;
  final String title;
  final String subtitle;
  final int done;
  final int total;

  /// Why this half cannot be opened yet, or null when it can.
  ///
  /// **The reason is always shown.** A tile that simply does not respond is
  /// indistinguishable from a broken one, and a child who taps twice and gets
  /// nothing stops trusting the screen.
  final String? lockedNote;

  final SessionSection section;
  final int lessonId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    final empty = total == 0;
    final complete = !empty && done >= total;
    final locked = lockedNote != null || empty;

    return Opacity(
      opacity: locked ? 0.6 : 1,
      child: Material(
        color: tint,
        borderRadius: BorderRadius.circular(LunioRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(LunioRadius.card),
          onTap: locked
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SessionScreen(
                      lessonId: lessonId,
                      section: section,
                    ),
                  ),
                ),
          child: Padding(
            padding: const EdgeInsets.all(LunioSpacing.l),
            child: Row(
              children: [
                illustration.show(size: 64, placeholderTint: Colors.white),
                const SizedBox(width: LunioSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: LunioSpacing.xs),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                      const SizedBox(height: LunioSpacing.s),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          LunioRadius.button,
                        ),
                        child: LinearProgressIndicator(
                          value: empty ? 0 : done / total,
                          minHeight: 8,
                          backgroundColor: Colors.white,
                          valueColor: const AlwaysStoppedAnimation(
                            LunioTheme.play,
                          ),
                        ),
                      ),
                      if (lockedNote != null) ...[
                        const SizedBox(height: LunioSpacing.xs),
                        Text(
                          lockedNote!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: LunioTheme.ink.withValues(alpha: 0.75),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: LunioSpacing.xs),
                        Text(
                          complete
                              ? l10n.lessonAllDone
                              : l10n.lessonProgress('$done', '$total'),
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  complete
                      ? Icons.check_circle
                      : locked
                      ? Icons.lock_outline
                      : Icons.chevron_left,
                  color: complete ? LunioTheme.play : LunioTheme.ink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
