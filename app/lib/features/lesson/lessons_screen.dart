import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/illustrations.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'capture_screen.dart';

/// The lessons saved on this device.
///
/// **There is no cloud icon on this screen and there never will be.** Article 14
/// keeps summaries, cards, questions and progress on the phone only, so there is
/// nothing to sync, nothing to back up and no second copy anywhere. A sync
/// indicator would be a lie about where the child's work lives.
///
/// A lesson whose images have been purged keeps its row and its summary. Article
/// 14 deletes the photographs and the exercises after the weekly test; the summary
/// and the results stay, and D-6 keeps the cards too — deleting those would make
/// spaced repetition weekly-only and empty a headline feature of Article 2.
class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    final lessons = ref.watch(lessonsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.lessonsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const CaptureScreen())),
        icon: const Icon(Icons.photo_camera_outlined),
        label: Text(l10n.captureLesson),
      ),
      body: lessons.isEmpty
          ? _Empty(message: l10n.lessonsEmpty)
          : ListView.builder(
              padding: LunioSpacing.page,
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: LunioSpacing.s),
                  child: ListTile(
                    leading: const TintedIcon(Icons.menu_book_outlined),
                    title: Text(
                      lesson.title.isEmpty ? l10n.untitledLesson : lesson.title,
                    ),
                    subtitle: Text(
                      lesson.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: lesson.purgedAtMs == null
                        ? null
                        : Chip(
                            label: Text(l10n.imagesDeleted),
                            backgroundColor: LunioTheme.tintLavender,
                            side: BorderSide.none,
                          ),
                  ),
                );
              },
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: LunioSpacing.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Illustration.astronaut.show(size: 140),
            const SizedBox(height: LunioSpacing.l),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
