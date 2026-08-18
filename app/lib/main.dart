import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'features/child/child_home_screen.dart';
import 'features/setup/setup_wizard.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const ProviderScope(child: NojoumiApp()));
}

/// The root widget.
///
/// Arabic is not a supported language here, it is *the* language: `ar` is first
/// in [AppL10n.supportedLocales] and is pinned as the locale, so the app is
/// right-to-left by default on a phone set to any language. English exists
/// because Article 14 requires the privacy policy in both, and because the Play
/// reviewer reads English.
class NojoumiApp extends StatelessWidget {
  const NojoumiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppL10n.of(context)!.appName,
      debugShowCheckedModeBanner: false,
      theme: NojoumiTheme.light(),
      darkTheme: NojoumiTheme.dark(),
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('ar'),
      home: const _Root(),
    );
  }
}

/// Decides which surface the app opens on.
///
/// The only branch is whether setup has finished. Article 15.2 is why there is
/// no second branch for "is blocking on": the app must be fully evaluable with
/// blocking and launcher mode both off, so those flags change what the app
/// *does*, never which screens exist.
class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return settings.when(
      loading: () => const _Splash(),
      error: (error, stack) => _StartupFailure(error: error),
      data: (row) => row.onboardingStep >= SetupWizard.completedStep
          ? const ChildHomeScreen()
          : const SetupWizard(),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// The database could not be opened.
///
/// Deliberately not a blank screen: this is the one failure a parent might have
/// to report, and "it does not open" is a useless bug report. Showing the error
/// text costs nothing and it contains no child data — the database holds the
/// child's data, but its failure message is about files and permissions.
class _StartupFailure extends StatelessWidget {
  const _StartupFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: NojoumiSpacing.page,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: NojoumiSpacing.m),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
