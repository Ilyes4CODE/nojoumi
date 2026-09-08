import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/illustrations.dart';
import '../../core/theme.dart';
import '../../data/repositories/session_repository.dart';
import '../../l10n/app_localizations.dart';
import 'lesson_hub_screen.dart';
import 'session_controller.dart';

/// The child's shelf: today's work, one tile per lesson.
///
/// ### Why the day stopped being one queue
///
/// Requested by the client on 2026-08-30. The session used to be a single list
/// that ran from the first card of the first lesson to the last question of the
/// last, and a child could not see what they were working on, how much of it
/// was left, or that a lesson had been added at all.
///
/// **Choosing changes the route through the day, never the day.** Article 6.5
/// pays the +5 bonus for finishing *the day's* tasks, so completion is still
/// counted across every lesson at once — see [DailySession.lessonSlices], which
/// is a view over the same list rather than a division of it. A child who does
/// three lessons in any order has done the same day.
class LessonPickerScreen extends ConsumerWidget {
  const LessonPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    final state = ref.watch(sessionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myLessons)),
      body: Stack(
        children: [
          const Positioned.fill(
            child: Backdrop(Illustration.lessonBackground, opacity: 0.9),
          ),
          SafeArea(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: LunioSpacing.page,
                  child: Text('$error', textAlign: TextAlign.center),
                ),
              ),
              data: (session) => _Shelf(session: session),
            ),
          ),
        ],
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.session});

  final DailySession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final slices = session.lessonSlices;

    if (slices.isEmpty) {
      return Center(
        child: Padding(
          padding: LunioSpacing.page,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Illustration.astronaut.show(size: 140),
              const SizedBox(height: LunioSpacing.l),
              Text(
                l10n.noTasksYet,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: LunioSpacing.page,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: LunioSpacing.m,
        mainAxisSpacing: LunioSpacing.m,
        // Tall enough for the drawing, two lines of title and the bar beneath
        // without any of them being clipped on a small phone.
        childAspectRatio: 0.82,
      ),
      itemCount: slices.length,
      itemBuilder: (context, index) =>
          _LessonTile(slice: slices[index], index: index),
    );
  }
}

/// One lesson, as something a child would want to open.
class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.slice, required this.index});

  final LessonSlice slice;
  final int index;

  /// The client's four pastels, cycled by position.
  ///
  /// By position rather than by lesson id, so a shelf of three lessons is
  /// always mint, sky, lavender — never three of the same colour because the
  /// row ids happened to land that way.
  static const _tints = [
    LunioTheme.tintMint,
    LunioTheme.tintSky,
    LunioTheme.tintLavender,
    LunioTheme.tintPeach,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    final tint = _tints[index % _tints.length];
    final title = slice.brief.title.trim();
    final done = slice.isComplete;

    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(LunioRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(LunioRadius.card),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LessonHubScreen(lessonId: slice.lessonId),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(LunioSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Illustration.lessonTile.show(
                      size: 76,
                      placeholderTint: Colors.white,
                    ),
                    // A finished lesson still opens — a child who wants to look
                    // at it again should be able to. The tick says "nothing
                    // owed here", not "closed".
                    if (done)
                      const Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: Icon(
                          Icons.check_circle,
                          color: LunioTheme.play,
                          size: 26,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: LunioSpacing.s),
              Text(
                title.isEmpty ? l10n.untitledLesson : title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: LunioSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(LunioRadius.button),
                child: LinearProgressIndicator(
                  value: slice.total == 0 ? 0 : slice.answered / slice.total,
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation(LunioTheme.play),
                ),
              ),
              const SizedBox(height: LunioSpacing.xs),
              Text(
                done
                    ? l10n.lessonAllDone
                    : l10n.lessonProgress('${slice.answered}', '${slice.total}'),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
