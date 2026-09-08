import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/illustrations.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../l10n/app_localizations.dart';
import '../session/session_controller.dart';

/// What the model made of the page, before any of it is kept.
///
/// **This screen exists because the model is not always right.** Article 11.3 sets
/// the bar at eight clear images out of ten producing a sound summary with
/// matching cards and questions — which means up to two in ten will not, and a
/// parent who cannot see that before it reaches their child has no defence
/// against it. Nothing is written to the database until they tap save.
///
/// Deleting an individual card here is deliberate too. A single wrong card among
/// twelve good ones should cost one tap, not the whole lesson.
class LessonReviewScreen extends ConsumerStatefulWidget {
  const LessonReviewScreen({
    super.key,
    required this.lesson,
    required this.image,
  });

  final ProcessedLesson lesson;
  final File image;

  @override
  ConsumerState<LessonReviewScreen> createState() => _LessonReviewScreenState();
}

class _LessonReviewScreenState extends ConsumerState<LessonReviewScreen> {
  final _title = TextEditingController();
  final _subject = TextEditingController();

  late final List<({String front, String back})> _cards = List.of(
    widget.lesson.cards,
  );
  late final List<({String prompt, List<String> choices, int correctIndex})>
  _questions = List.of(widget.lesson.questions);

  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewLesson)),
      body: SafeArea(
        child: ListView(
          padding: LunioSpacing.page,
          children: [
            _Section(
              title: l10n.summaryHeading,
              child: Text(
                widget.lesson.summary,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: LunioSpacing.m),

            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: l10n.lessonTitleLabel,
                hintText: l10n.lessonTitleHint,
              ),
            ),
            const SizedBox(height: LunioSpacing.s),
            TextField(
              controller: _subject,
              decoration: InputDecoration(labelText: l10n.subjectOptional),
            ),
            const SizedBox(height: LunioSpacing.l),

            _Heading('${l10n.cardsHeading} · ${_cards.length}'),
            for (var i = 0; i < _cards.length; i++)
              _RemovableTile(
                title: _cards[i].front,
                subtitle: _cards[i].back,
                onRemove: () => setState(() => _cards.removeAt(i)),
              ),

            const SizedBox(height: LunioSpacing.l),
            _Heading('${l10n.questionsHeading} · ${_questions.length}'),
            for (var i = 0; i < _questions.length; i++)
              _RemovableTile(
                title: _questions[i].prompt,
                subtitle: _questions[i].choices.join(' · '),
                onRemove: () => setState(() => _questions.removeAt(i)),
              ),

            const SizedBox(height: LunioSpacing.xl),
            FilledButton(
              // A lesson with no cards left is not a lesson: the daily session is
              // built from cards, so saving one would produce a row the child can
              // never study.
              onPressed: _saving || _cards.isEmpty ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.saveLesson),
            ),
            const SizedBox(height: LunioSpacing.s),
            TextButton(
              onPressed: _saving
                  ? null
                  : () => Navigator.of(context).maybePop(),
              child: Text(l10n.discardLesson),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppL10n.of(context)!;
    final settings = ref.read(settingsProvider).value;
    final now = await ref.read(trustedNowProvider.notifier).refresh();

    final lessonId = await ref
        .read(lessonRepositoryProvider)
        .save(
          lesson: ProcessedLesson(
            summary: widget.lesson.summary,
            cards: _cards,
            questions: _questions,
          ),
          image: widget.image,
          grade: settings?.grade ?? '',
          title: _title.text,
          subject: _subject.text,
          now: now,
        );

    // The child studies it today, not tomorrow.
    //
    // This used to rebuild the day and only while nothing had been answered, so
    // a parent who photographed a page after the child had started got nothing
    // at all — no lesson, no message, indistinguishable from a failed capture.
    // Reported 2026-08-30. `absorbLesson` appends instead: nothing already in
    // the day moves, and Article 6.5's once-per-day bonus guard is what keeps
    // the +5 honest rather than the length of the list.
    final day = ref.read(todayProvider).value;
    final rules = ref.read(starRulesProvider).value;
    if (day != null && rules != null) {
      final inToday = await ref
          .read(sessionRepositoryProvider)
          .absorbLesson(day: day, rules: rules, lessonId: lessonId);
      // Refreshed whenever the lesson is in the day at all — including the case
      // where the day had not been built and the build itself picked it up, in
      // which case nothing was *appended* and an insert count would have been
      // zero.
      if (inToday > 0) ref.invalidate(sessionControllerProvider);
    }

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.lessonSaved('${_cards.length}', '${_questions.length}'),
        ),
      ),
    );
    Navigator.of(context).maybePop();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const TintedIcon(Icons.menu_book_outlined),
                const SizedBox(width: LunioSpacing.m),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: LunioSpacing.m),
            child,
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LunioSpacing.s),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _RemovableTile extends StatelessWidget {
  const _RemovableTile({
    required this.title,
    required this.subtitle,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: LunioSpacing.s),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ),
    );
  }
}
