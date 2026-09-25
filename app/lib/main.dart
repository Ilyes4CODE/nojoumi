import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'features/parent/pin_gate.dart';
import 'features/child/child_home_screen.dart';
import 'features/setup/setup_wizard.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const ProviderScope(child: LunioApp()));
}

/// The root widget.
///
/// Arabic is not a supported language here, it is *the* language: `ar` is first
/// in [AppL10n.supportedLocales] and is pinned as the locale, so the app is
/// right-to-left by default on a phone set to any language. English exists
/// because Article 14 requires the privacy policy in both, and because the Play
/// reviewer reads English.
class LunioApp extends StatelessWidget {
  const LunioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppL10n.of(context)!.appName,
      debugShowCheckedModeBanner: false,
      theme: LunioTheme.light(),
      darkTheme: LunioTheme.dark(),
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
class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A cold start after the child was playing: the engine may hold seconds
    // nobody has written down yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _collectPlayTime();
      _answerGuardIfAsked();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _collectPlayTime();
    // Resume is the moment that matters: the accessibility service brought this
    // activity to the front precisely so the PIN could be asked for, and on a
    // warm app that arrives as a resume rather than a cold start.
    _answerGuardIfAsked();
  }

  /// True while the guard's PIN screen is up, so a second resume does not stack
  /// another one on top of it.
  bool _askingForPin = false;

  /// Show the PIN if somebody just opened Lunio's uninstall screen.
  ///
  /// The decision was made in Kotlin ([UninstallGuard]); all that is left here
  /// is to ask, and on success to tell the engine to stand down for a couple of
  /// minutes so the parent can finish what they authorised.
  ///
  /// **The PIN check itself is not reimplemented.** `PinGate` owns it, and the
  /// hashing lives in `core/pin.dart` — a second comparison written here would
  /// be a second place for it to be wrong.
  Future<void> _answerGuardIfAsked() async {
    if (_askingForPin) return;

    final channel = ref.read(blockingChannelProvider);
    final reason = await channel.consumePendingPinRequest();
    if (reason == null || !mounted) return;

    _askingForPin = true;
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      await navigator.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (context) => _GuardPinRequest(onAccepted: channel.openGuardGrace),
        ),
      );
    } finally {
      _askingForPin = false;
    }
  }

  /// Write down the play time the engine measured while Dart was not running.
  ///
  /// This is the moment the two halves of Article 4.7 meet. The Kotlin engine
  /// counts seconds down while a game is in the foreground — it must, because no
  /// window event fires while a child sits inside one app, and because Flutter is
  /// not running at all — but the ledger is Dart's and append-only (AD-4). The
  /// child comes back to Lunio, the app resumes, and the seconds are recorded
  /// here.
  ///
  /// Without it the symptom is precisely what the first hardware run reported:
  /// the balance on screen does not move while the child plays.
  ///
  /// Ordering matters and is easy to get backwards. The drain happens **before**
  /// the next push, because `blockingSyncProvider` overwrites the engine's copy of
  /// the remaining balance — seconds still sitting in the tally at that moment
  /// would be handed back to the child for free. Reading the providers below and
  /// only then invalidating is what keeps that order.
  Future<void> _collectPlayTime() async {
    final day = ref.read(todayProvider).value;
    final rules = ref.read(starRulesProvider).value;
    if (day == null || rules == null) return;

    final consumed = await ref
        .read(blockingRepositoryProvider)
        .collectPlayTime(day: day, rules: rules);

    // Nothing to say when the child was not playing, and invalidating anyway
    // would rebuild the whole tree on every resume.
    if (consumed == null || !mounted) return;
    ref.invalidate(todayProgressProvider);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    // Watched here, at the root, and deliberately nowhere else that matters.
    //
    // The Kotlin engine enforces against a snapshot it was handed and has no way
    // to know how stale it is — from inside, a forgotten push and a correct one
    // are the same value. Subscribing at the root means the push follows the app's
    // whole lifetime instead of one screen's, so a star earned in the session, a
    // second of play consumed, a parent grant and the day rolling over all reach
    // the engine without any of those screens having to remember to say so.
    ref.watch(blockingSyncProvider);

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
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        padding: LunioSpacing.page,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: LunioSpacing.m),
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


/// The PIN screen the uninstall guard puts in front of Settings.
///
/// A thin wrapper around [PinGate] so the guard reuses the one PIN
/// implementation rather than growing a second. Accepting it opens the engine's
/// grace window and closes this screen, putting the parent back where they
/// were — which, since the service pressed Back first, is the screen before the
/// uninstall prompt rather than the prompt itself. They tap once more and
/// proceed; a child who does not know the PIN cannot.
class _GuardPinRequest extends StatelessWidget {
  const _GuardPinRequest({required this.onAccepted});

  final Future<void> Function() onAccepted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;

    return PinGate(
      title: l10n.guardPinTitle,
      child: _GuardAccepted(onAccepted: onAccepted, message: l10n.guardPinBody),
    );
  }
}

/// Shown for the instant between the PIN being accepted and this screen closing.
class _GuardAccepted extends StatefulWidget {
  const _GuardAccepted({required this.onAccepted, required this.message});

  final Future<void> Function() onAccepted;
  final String message;

  @override
  State<_GuardAccepted> createState() => _GuardAcceptedState();
}

class _GuardAcceptedState extends State<_GuardAccepted> {
  @override
  void initState() {
    super.initState();
    // In a post-frame callback rather than inline: `PinGate` builds this the
    // moment the PIN is accepted, and popping during a build throws.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.onAccepted();
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: LunioSpacing.page,
        child: Text(widget.message, textAlign: TextAlign.center),
      ),
    ),
  );
}
