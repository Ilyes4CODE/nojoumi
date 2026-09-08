import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config.dart';
import '../../core/illustrations.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/remote/api_client.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../l10n/app_localizations.dart';
import 'lesson_review_screen.dart';

/// Article 4.1 — the parent photographs one page of a schoolbook.
///
/// The intro line on this screen is not marketing copy. Article 14 promises the
/// image is processed inside the request and never stored server-side, and a
/// parent about to photograph their child's homework and send it somewhere is
/// owed that promise **before** they tap, not in a policy document. It is the one
/// sentence on the screen that had to be written carefully.
///
/// Both camera and gallery are offered. A page photographed earlier in good light
/// beats one taken in a hurry under a kitchen bulb, and Article 11.3 measures the
/// pipeline on *clear* images.
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _picker = ImagePicker();

  bool _processing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    final signedIn = ref.watch(isSignedInProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.captureLesson)),
      body: SafeArea(
        child: Padding(
          padding: LunioSpacing.page,
          child: _processing
              ? const _Processing()
              : ListView(
                  children: [
                    Center(child: Illustration.backpack.show(size: 160)),
                    const SizedBox(height: LunioSpacing.l),
                    Text(
                      l10n.captureIntro,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: LunioTheme.ink.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: LunioSpacing.l),
                    _Hints(
                      hints: [
                        l10n.captureHintFlat,
                        l10n.captureHintLight,
                        l10n.captureHintStraight,
                      ],
                    ),
                    const SizedBox(height: LunioSpacing.xl),
                    if (!AppConfig.hasApi)
                      _Message(text: l10n.serverNotConfigured)
                    else if (!signedIn)
                      _Message(text: l10n.signInRequired)
                    else ...[
                      FilledButton.icon(
                        onPressed: () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(l10n.captureFromCamera),
                      ),
                      const SizedBox(height: LunioSpacing.s),
                      OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(l10n.captureFromGallery),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: LunioSpacing.l),
                      _Message(text: _error!, isError: true),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      // Downscaled and recompressed before it leaves the phone. Three reasons,
      // in order of weight: an Algerian mobile upload of a 12 MP photo is slow
      // enough that a parent gives up; the server refuses anything over its size
      // ceiling (Art. 14 keeps the upload handler in memory only); and a
      // schoolbook page is legible far below full sensor resolution.
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _processing = true;
      _error = null;
    });

    final rules = ref.read(starRulesProvider).value;
    final settings = ref.read(settingsProvider).value;
    if (rules == null || settings == null) return;

    try {
      final lesson = await ref
          .read(lessonRepositoryProvider)
          .process(
            image: File(picked.path),
            grade: settings.grade,
            // **How much the page yields, not how much the child does today.**
            // These were the parent's daily settings until 2026-08-31, when
            // `dailySessionCards` went to 0 for D-85 and the app began asking
            // the server for zero cards — which the serializer refuses, so
            // every capture failed validation. See [LessonYield].
            cardCount: LessonYield.cards,
            questionCount: LessonYield.questions,
          );

      if (!mounted) return;
      if (!lesson.isUsable) {
        setState(() {
          _processing = false;
          _error = AppL10n.of(context)!.imageUnclear;
        });
        return;
      }

      setState(() => _processing = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              LessonReviewScreen(lesson: lesson, image: File(picked.path)),
        ),
      );
      if (mounted) Navigator.of(context).maybePop();
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _processing = false;
          _error = failure.message;
        });
      }
    }
  }
}

/// The waiting state.
///
/// Named rather than a bare spinner because the parent has just handed over a
/// photograph of their child's schoolbook, and silence at that moment is the
/// wrong answer.
class _Processing extends StatelessWidget {
  const _Processing();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Illustration.astronaut.show(size: 140),
          const SizedBox(height: LunioSpacing.l),
          const CircularProgressIndicator(),
          const SizedBox(height: LunioSpacing.l),
          Text(l10n.processing, style: theme.textTheme.titleMedium),
          const SizedBox(height: LunioSpacing.xs),
          Text(
            l10n.processingHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: LunioTheme.ink.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hints extends StatelessWidget {
  const _Hints({required this.hints});

  final List<String> hints;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: LunioSpacing.s,
      runSpacing: LunioSpacing.s,
      children: [
        for (final hint in hints)
          Chip(
            label: Text(hint),
            backgroundColor: LunioTheme.tintLavender,
            side: BorderSide.none,
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: isError ? scheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.m),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? scheme.onErrorContainer : scheme.primary,
            ),
            const SizedBox(width: LunioSpacing.m),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isError ? scheme.onErrorContainer : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
