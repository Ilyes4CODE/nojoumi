import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunio_subscription/lunio_subscription.dart';

import '../../core/illustrations.dart';
import '../../core/pin.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/remote/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../auth/account_form.dart';
import 'post_auth_route.dart';
import 'protection_choice.dart';

/// The parent's first five minutes with the app.
///
/// Article 15.2 shapes this screen more than anything else: Google requires a
/// closed test with 12 testers for 14 continuous days, and external testers will
/// not hand over their personal phones as a kiosk. So **blocking and launcher
/// mode are one optional step**, declining is a first-class path with its own
/// button, and every other feature is reachable without them.
///
/// The disclosure step is Play policy expressed as code, not paperwork: a
/// prominent disclosure with explicit parental consent must *precede* the
/// AccessibilityService request. It is a full screen, it names what the service
/// is used for and what it is not used for, and consent is a deliberate tap that
/// starts unchecked.
class SetupWizard extends ConsumerStatefulWidget {
  const SetupWizard({super.key});

  /// Kept as an alias so call sites read naturally; the value itself lives in
  /// `core/providers.dart`, because providers gate on it and `core` must not
  /// import `features`.
  static const int completedStep = onboardingCompletedStep;

  @override
  ConsumerState<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends ConsumerState<SetupWizard> {
  final _grade = TextEditingController();
  final _pin = TextEditingController();
  final _pinConfirm = TextEditingController();

  int _step = 0;
  String? _pinError;

  /// The protection step's three booleans and the rules between them, as one
  /// value — see `protection_choice.dart` for why they are not three fields.
  ProtectionChoice _protection = ProtectionChoice.none;
  bool _busy = false;

  static const int _totalSteps = 5;

  @override
  void dispose() {
    _grade.dispose();
    _pin.dispose();
    _pinConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.setupTitle),
        leading: _step == 0
            ? null
            : IconButton(
                icon: const BackButtonIcon(),
                tooltip: l10n.back,
                onPressed: _busy ? null : () => setState(() => _step--),
              ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_step + 1) / _totalSteps),
        ),
      ),
      body: SafeArea(
        // The welcome step draws soft circles that bleed to the screen edges, so
        // it takes no shared padding and applies its own inside. The three form
        // steps keep the common frame — a parent filling in a PIN wants the same
        // margins every time, not a designed one.
        child: Padding(
          padding: _step == 0 ? EdgeInsets.zero : LunioSpacing.page,
          child: switch (_step) {
            0 => _WelcomeStep(onNext: () => setState(() => _step = 1)),
            // Client request, 2026-08-28: the account comes straight after the
            // welcome screen rather than living only in the parent dashboard.
            1 => _AccountStep(
              onNext: () => setState(() => _step = 2),
              onFinishNow: _finishAlreadyConfigured,
            ),
            2 => _GradeStep(controller: _grade, onNext: _saveGradeAndContinue),
            3 => _PinStep(
              pin: _pin,
              confirm: _pinConfirm,
              error: _pinError,
              busy: _busy,
              onNext: _savePinAndContinue,
            ),
            _ => ProtectionStep(
              consented: _protection.consented,
              wantsBlocking: _protection.blocking,
              wantsLauncher: _protection.launcher,
              busy: _busy,
              onConsentChanged: (v) =>
                  setState(() => _protection = _protection.withConsent(v)),
              onBlockingChanged: (v) =>
                  setState(() => _protection = _protection.withBlocking(v)),
              onLauncherChanged: (v) =>
                  setState(() => _protection = _protection.withLauncher(v)),
              onFinish: _finish,
              onSkip: _finishWithoutProtection,
            ),
          },
        ),
      ),
    );
  }

  Future<void> _saveGradeAndContinue() async {
    await ref.read(settingsRepositoryProvider).setGrade(_grade.text);
    if (mounted) setState(() => _step = 3);
  }

  Future<void> _savePinAndContinue() async {
    final l10n = AppL10n.of(context)!;
    if (!PinHasher.isAcceptable(_pin.text)) {
      setState(() => _pinError = l10n.setupPinTooShort);
      return;
    }
    if (_pin.text != _pinConfirm.text) {
      setState(() => _pinError = l10n.setupPinMismatch);
      return;
    }

    setState(() {
      _pinError = null;
      _busy = true;
    });
    final credential = await const PinHasher().hash(_pin.text);
    await ref
        .read(settingsRepositoryProvider)
        .setPin(hash: credential.hash, salt: credential.salt);
    // The PIN itself is dropped here and exists nowhere else (D-10).
    _pin.clear();
    _pinConfirm.clear();
    if (mounted) {
      setState(() {
        _busy = false;
        _step = 4;
      });
    }
  }

  /// A parent signed back in on a phone that is already configured.
  ///
  /// Marks setup complete and **touches nothing else**. That restraint is the
  /// whole point: the grade, the PIN and the two Article 15.2 switches are
  /// already stored from the first run, and `_finish` would overwrite the
  /// switches with this session's untouched defaults — silently turning blocking
  /// off for a family that had it on.
  Future<void> _finishAlreadyConfigured() async {
    setState(() => _busy = true);
    await ref.read(trustedNowProvider.notifier).refresh();
    await ref
        .read(settingsRepositoryProvider)
        .setOnboardingStep(SetupWizard.completedStep);
    if (mounted) setState(() => _busy = false);
  }

  /// Article 15.2's escape hatch — finish with both features off, whatever the
  /// switches currently say.
  ///
  /// This exists as its own method because of a bug it would otherwise have:
  /// the decline button used to be safe by accident. Both switches defaulted to
  /// off, so "finish" and "finish without blocking" did the same thing and one
  /// callback served both. The moment consent started turning them on, tapping
  /// "أكمل بدون حجب" would have finished setup **with blocking enabled** — the
  /// exact opposite of what the button says, on the one path the twelve Play
  /// testers depend on.
  Future<void> _finishWithoutProtection() async {
    setState(() => _protection = _protection.declined());
    await _finish();
  }

  /// Finish setup.
  ///
  /// The welcome balance is **not** granted here. It is granted by
  /// `welcomeGrantProvider` on the first day the clock can be defended — see
  /// the comment there for why finishing setup with an unread clock used to
  /// strand ten stars on 1970-01-01.
  Future<void> _finish() async {
    setState(() => _busy = true);

    final settings = ref.read(settingsRepositoryProvider);
    await settings.setBlockingEnabled(_protection.blocking);
    await settings.setLauncherMode(_protection.launcher);
    // Re-anchor before handing over, so the child's first screen has a day key
    // rather than waiting a frame for one.
    await ref.read(trustedNowProvider.notifier).refresh();
    await settings.setOnboardingStep(SetupWizard.completedStep);

    if (mounted) setState(() => _busy = false);
  }
}

/// The first screen anyone ever sees, rebuilt to the client's mockup
/// (`client_design/first page.jpeg`, 2026-08-28).
///
/// It deliberately breaks the [_StepScaffold] rhythm the other three steps share.
/// Those are forms — a grade, a PIN, two switches — and a form wants the same
/// left-aligned, predictable frame every time. This one is not a form: it is the
/// only screen in the app whose whole job is to say what Lunio is before asking
/// for anything, and the mockup centres everything for exactly that reason.
///
/// Three things carry the design and each is load-bearing:
///
///  * the **logo mark** at the top, the client's own and untouched;
///  * the headline splitting «أهلاً بك في» from **Lunio** so the brand name is
///    the coloured word — the mockup's one typographic idea;
///  * three pillars that answer, in three words each, the questions a parent
///    actually has: is it safe, does it get anywhere, does it have a point.
///
/// The soft circles behind it come from the same family as the client's logo
/// background, which is why they are drawn rather than shipped as an asset:
/// two `Positioned` circles cost nothing and cannot be a missing-file error in
/// front of a parent on first launch.
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return Stack(
      children: [
        const Positioned.fill(child: _WelcomeBackdrop()),
        Padding(
          padding: LunioSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Centred in whatever space is left, and scrollable when there
              // is not enough. A fixed top offset looked right on the mockup's
              // 360 dp frame and left a dead band under the pillars on a taller
              // phone; centring holds on both without a breakpoint.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: LunioSpacing.l),
                          Illustration.logoMark.show(size: 170),
                          const SizedBox(height: LunioSpacing.l),

                          // «أهلاً بك في Lunio» — one line, two colours. Written as a
                          // RichText rather than two Texts so it wraps as a sentence
                          // on a narrow screen instead of breaking into two rows.
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: '${l10n.setupWelcomeHeadline} '),
                                TextSpan(
                                  text: 'Lunio',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    // Latin inside an Arabic sentence: pinned LTR so
                                    // the word never renders reversed next to the
                                    // Arabic that surrounds it.
                                    locale: const Locale('en'),
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: LunioTheme.ink,
                            ),
                          ),

                          const SizedBox(height: LunioSpacing.m),
                          Text(
                            l10n.setupWelcomeLine1,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: LunioTheme.ink.withValues(alpha: 0.6),
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: LunioSpacing.s),
                          Text(
                            l10n.setupWelcomeLine2,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: LunioTheme.ink.withValues(alpha: 0.6),
                              height: 1.7,
                            ),
                          ),

                          const SizedBox(height: LunioSpacing.xl),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Safety first, and first in reading order — the mockup
                              // puts it on the right, which in RTL is where the eye
                              // lands. For a parental-control app that ordering is an
                              // argument, not a layout accident.
                              _Pillar(
                                icon: Icons.verified_user_outlined,
                                label: l10n.setupWelcomePillarSafe,
                              ),
                              _Pillar(
                                icon: Icons.bar_chart_rounded,
                                label: l10n.setupWelcomePillarProgress,
                              ),
                              _Pillar(
                                icon: Icons.track_changes,
                                label: l10n.setupWelcomePillarGoals,
                              ),
                            ],
                          ),
                          const SizedBox(height: LunioSpacing.l),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: LunioSpacing.m),
              FilledButton(onPressed: onNext, child: Text(l10n.next)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The two soft circles behind the welcome content.
///
/// `IgnorePointer` because they are decoration and must never eat a tap meant
/// for the button underneath them.
///
/// The alpha is low deliberately, and it was lower than the first attempt by a
/// long way. Rendered at 412 dp, circles at 0.55 alpha read as two grey shapes
/// the eye tracks before it reaches the logo — the opposite of a backdrop. The
/// client's mockup keeps them barely present, which is the correct instinct:
/// they exist to stop a near-white screen looking unfinished, not to be seen.
class _WelcomeBackdrop extends StatelessWidget {
  const _WelcomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: -70, right: -70, child: _Blob(size: 210)),
          Positioned(top: 300, left: -100, child: _Blob(size: 240)),
          Positioned(bottom: -80, right: -60, child: _Blob(size: 190)),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // One tint, not two. The first version used the sky blue for the second
        // circle and it read as a separate object rather than as texture.
        color: LunioTheme.tintLavender.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// One of the three promises on the welcome screen: a tinted disc, a glyph, a
/// two-word label.
class _Pillar extends StatelessWidget {
  const _Pillar({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      // Fixed so the three labels sit on the same baseline whatever their
      // length, and so a long Arabic label wraps instead of shoving its
      // neighbours sideways.
      width: 96,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: LunioTheme.tintLavender,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: LunioSpacing.s),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The parent account — step 2, and **mandatory** (client, 2026-08-28).
///
/// It replaced a skippable version, and the reason for the change is the client's
/// to make; the reason the earlier one was skippable is worth keeping on record,
/// because it names the one case this now breaks. The account buys exactly two
/// things — lessons generated from a photo, and the subscription (AD-6).
/// Everything else runs on the device: the daily session, stars, play time,
/// blocking, the weekly test, every saved lesson (Art. 14). So a parent setting
/// the app up somewhere with no signal cannot now finish setup, of an app whose
/// core loop is offline.
///
/// **That is a real cost and it is the client's call, not a defect.** What it is
/// not: it does not touch Article 15.2, which is about blocking and launcher
/// mode being opt-in — both still on the next step. And it does not touch
/// Article 7.1: once signed in the token is cached locally, and an expired
/// subscription never stops stars, blocking or saved lessons.
///
/// The connection banner is not decoration either. Without it a phone on the
/// wrong network, a build launched without `--dart-define`, and a wrong password
/// all read as the same silent failure on the same screen.
class _AccountStep extends ConsumerStatefulWidget {
  const _AccountStep({required this.onNext, required this.onFinishNow});

  final VoidCallback onNext;

  /// Skip the rest of the wizard because this device is already configured.
  final VoidCallback onFinishNow;

  @override
  ConsumerState<_AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends ConsumerState<_AccountStep> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    final signedIn = ref.watch(isSignedInProvider).value ?? false;

    return _StepScaffold(
      title: l10n.setupAccountTitle,
      body: l10n.setupAccountBody,
      fields: [
        const _ServerBanner(),
        if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: LunioSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (!signedIn)
          AccountForm(onSignedIn: _afterAuth),
        const SizedBox(height: LunioSpacing.m),
        Text(
          l10n.oneAccountPerDevice,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: LunioTheme.ink.withValues(alpha: 0.6),
          ),
        ),
      ],
      action: FilledButton(
        // Mandatory: no skip, and the button stays disabled until the server has
        // actually issued a token. Article 15.2's optional step is the next one.
        onPressed: signedIn && !_busy ? widget.onNext : null,
        child: Text(signedIn ? l10n.next : l10n.setupAccountRequired),
      ),
    );
  }

  /// What happens after the server accepts the parent — and where they go next.
  ///
  /// The outcome is reported in a **dialog**, not as a line of text on the form
  /// (client request, 2026-08-29). It earns the interruption: two things
  /// happened at once — an account exists and seven free days started — and the
  /// parent is about to be moved to a different screen. A notice they can scroll
  /// past is the wrong shape for that.
  ///
  /// **Where they go afterwards depends on which action it was, and on what this
  /// device already holds.**
  ///
  ///  * **Registered** — a new account, so the whole setup is ahead of them.
  ///  * **Signed in, and this phone already has a school level and a parent
  ///    PIN** — nothing is left to ask. Straight into the app.
  ///  * **Signed in on a bare phone** — the setup still has to run, and the
  ///    dialog says why rather than dropping them into a form with no
  ///    explanation.
  ///
  /// That last case is not a limitation that could be engineered away. The grade
  /// and the PIN are **never** sent to the server: Article 14 keeps every byte
  /// about the child on the device and AD-6 keeps the server free of it. So
  /// there is nothing to restore them from, and a sign-in on a fresh phone
  /// cannot skip them. Skipping anyway would be worse than tedious — `PinGate`
  /// refuses to unlock when no PIN is set, so the parent would be locked out of
  /// their own settings permanently, and lesson capture would fail on an empty
  /// grade.
  Future<void> _afterAuth(bool registered) async {
    if (!mounted) return;
    setState(() => _busy = true);

    final l10n = AppL10n.of(context)!;
    final now = await ref.read(trustedNowProvider.notifier).refresh();

    // **A trial is claimed for a new account, and never for a sign-in.**
    //
    // It used to run on both, which was wrong twice. A parent signing back in
    // was offered seven free days they may already have spent — and on a phone
    // that had not itself claimed a trial, they would actually have been granted
    // them, because Article 7.1 keys the trial on the *device*. That article
    // exists to stop a new email resetting the seven days; using it to hand a
    // second trial to an account that already had one is the same hole from the
    // other side.
    //
    // Signing in creates nothing. It reads what the server already says (Art.
    // 7.6 — the server is the source of truth) and reports it.
    final subscriptions = ref.read(subscriptionRepositoryProvider);
    String outcome;
    if (registered) {
      try {
        await subscriptions.startTrial(now);
        outcome = l10n.setupTrialStarted;
      } on ApiFailure catch (failure) {
        // 409 means this device already had its turn — an ordinary answer, not
        // an error, and setup carries on either way.
        outcome = failure.statusCode == 409
            ? l10n.setupTrialAlready
            : failure.message;
      }
    } else {
      try {
        await subscriptions.refresh(now);
        final state = ref.read(capabilitiesProvider).value?.state;
        outcome = state == null
            ? l10n.signedInNothingNew
            : l10n.signedInSubscription(_stateLabel(l10n, state));
      } on ApiFailure catch (failure) {
        outcome = failure.message;
      }
    }
    ref.invalidate(capabilitiesProvider);

    final settings = await ref.read(settingsRepositoryProvider).read();
    final route = routeAfterAuth(
      registered: registered,
      deviceHasGrade: settings.grade.trim().isNotEmpty,
      deviceHasPin: settings.pinHash.isNotEmpty,
    );
    final canFinishNow = route == PostAuthRoute.straightToApp;

    if (!mounted) return;
    setState(() => _busy = false);

    await showDialog<void>(
      context: context,
      // Not dismissible: the button is the navigation, so a tap outside would
      // leave the parent on a step that has already done its work.
      barrierDismissible: false,
      builder: (context) => _AuthResultDialog(
        registered: registered,
        trialMessage: outcome,
        setupRemains: !canFinishNow,
        actionLabel: canFinishNow ? l10n.dialogStartNow : l10n.dialogContinue,
      ),
    );

    if (!mounted) return;
    if (canFinishNow) {
      widget.onFinishNow();
    } else {
      widget.onNext();
    }
  }
}

/// The five states of Article 7.6, in the parent's language.
///
/// Duplicated from the subscription screen rather than shared, because that one
/// is a `_StatusCard` private to its file and lifting it out for two callers
/// would be a widget with no home. If a third caller appears, that is the moment
/// to move it.
String _stateLabel(AppL10n l10n, SubscriptionState state) => switch (state) {
  SubscriptionState.trial => l10n.subscriptionTrial,
  SubscriptionState.active => l10n.subscriptionActive,
  SubscriptionState.grace => l10n.subscriptionGrace,
  SubscriptionState.expired => l10n.subscriptionExpired,
  SubscriptionState.refunded => l10n.subscriptionRefunded,
};

/// The one moment in setup that interrupts the parent, and what it says.
class _AuthResultDialog extends StatelessWidget {
  const _AuthResultDialog({
    required this.registered,
    required this.trialMessage,
    required this.setupRemains,
    required this.actionLabel,
  });

  final bool registered;
  final String trialMessage;
  final bool setupRemains;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LunioRadius.card),
      ),
      title: Column(
        children: [
          Illustration.starBig.show(size: 84),
          const SizedBox(height: LunioSpacing.s),
          Text(
            registered ? l10n.dialogWelcomeTitle : l10n.dialogWelcomeBackTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trialMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (setupRemains) ...[
            const SizedBox(height: LunioSpacing.m),
            Text(
              l10n.dialogSetupRemains,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: LunioTheme.ink.withValues(alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

/// Says something **only when the server cannot be reached.**
///
/// It used to show a green "connected" card on success too. That was wrong, and
/// the reason is worth keeping: this screen exists to collect an email and a
/// password, and a card confirming that the network works is not an answer to
/// any question the parent was asking. Interface that reports its own success
/// teaches people to stop reading it, which is exactly the habit that makes the
/// *failure* message get skipped when it finally appears.
///
/// So: silent when healthy, silent while probing, and loud only when there is
/// something the parent can act on. The address is printed in that case because
/// the commonest cause by far is a build launched without `--dart-define`, still
/// pointing at the emulator alias `10.0.2.2` from a real phone — and reading it
/// once settles the question that would otherwise cost an evening.
class _ServerBanner extends ConsumerWidget {
  const _ServerBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    final health = ref.watch(serverHealthProvider);

    final state = health.value;
    // Nothing yet, or nothing wrong. Both are silence — a spinner that resolves
    // into an empty space is a flicker, not information.
    if (state == null || state.healthy) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: LunioSpacing.l),
      child: Container(
        padding: const EdgeInsets.all(LunioSpacing.m),
        decoration: BoxDecoration(
          color: LunioTheme.tintPeach,
          borderRadius: BorderRadius.circular(LunioRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_off_outlined),
                const SizedBox(width: LunioSpacing.s),
                Expanded(
                  child: Text(
                    state.reachable
                        ? l10n.serverDegraded
                        : l10n.serverUnreachable,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            // **The server address is not shown to the parent.**
            //
            // It was here for the workshop, where the build's address was the
            // first thing worth knowing and it changed with the router's mood.
            // A parent has no use for it: they cannot check it, cannot change
            // it, and a URL inside an error box reads as the app having leaked
            // something technical at the exact moment they most need calm.
            //
            // It stays in the string table, and `serverHealthProvider` still
            // carries `baseUrl`, so a support conversation can still ask for it
            // through the parent settings screen.
            const SizedBox(height: LunioSpacing.xs),
            if (state.detail.isNotEmpty)
              Text(state.detail, style: theme.textTheme.bodySmall),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => ref.invalidate(serverHealthProvider),
                child: Text(l10n.serverRetry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeStep extends StatefulWidget {
  const _GradeStep({required this.controller, required this.onNext});

  final TextEditingController controller;
  final VoidCallback onNext;

  @override
  State<_GradeStep> createState() => _GradeStepState();
}

class _GradeStepState extends State<_GradeStep> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    return _StepScaffold(
      title: l10n.setupGradeTitle,
      body: l10n.setupGradeBody,
      fields: [
        TextField(
          controller: widget.controller,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.setupGradeTitle,
            hintText: l10n.setupGradeHint,
          ),
        ),
        const SizedBox(height: LunioSpacing.l),
        Center(child: Illustration.backpack.show(size: 180)),
      ],
      action: FilledButton(
        onPressed: widget.controller.text.trim().isEmpty ? null : widget.onNext,
        child: Text(l10n.next),
      ),
    );
  }
}

class _PinStep extends StatelessWidget {
  const _PinStep({
    required this.pin,
    required this.confirm,
    required this.error,
    required this.busy,
    required this.onNext,
  });

  final TextEditingController pin;
  final TextEditingController confirm;
  final String? error;
  final bool busy;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    return _StepScaffold(
      title: l10n.setupPinTitle,
      body: l10n.setupPinBody,
      fields: [
        TextField(
          controller: pin,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.setupPinCreate),
        ),
        const SizedBox(height: LunioSpacing.m),
        TextField(
          controller: confirm,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.setupPinConfirm,
            errorText: error,
          ),
        ),
      ],
      action: FilledButton(
        onPressed: busy ? null : onNext,
        child: busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.next),
      ),
    );
  }
}

/// The optional step, and the disclosure that must precede the permission.
class ProtectionStep extends StatelessWidget {
  const ProtectionStep({
    super.key,
    required this.consented,
    required this.wantsBlocking,
    required this.wantsLauncher,
    required this.busy,
    required this.onConsentChanged,
    required this.onBlockingChanged,
    required this.onLauncherChanged,
    required this.onFinish,
    required this.onSkip,
  });

  final bool consented;
  final bool wantsBlocking;
  final bool wantsLauncher;
  final bool busy;
  final ValueChanged<bool> onConsentChanged;
  final ValueChanged<bool> onBlockingChanged;
  final ValueChanged<bool> onLauncherChanged;
  final VoidCallback onFinish;

  /// Finish with both features off, regardless of the switches. Article 15.2.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return _StepScaffold(
      title: l10n.setupProtectionTitle,
      body: l10n.setupProtectionBody,
      fields: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(LunioSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Illustration.shield.show(size: 88)),
                const SizedBox(height: LunioSpacing.s),
                Text(
                  l10n.setupDisclosureTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: LunioSpacing.s),
                Text(
                  l10n.setupDisclosureBody,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: LunioSpacing.s),
                // Starts unchecked, every time. Consent that is pre-granted is
                // not consent, and Play reviews this exact interaction.
                CheckboxListTile(
                  value: consented,
                  onChanged: (v) => onConsentChanged(v ?? false),
                  title: Text(l10n.setupDisclosureConsent),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: LunioSpacing.m),
        SwitchListTile(
          value: wantsBlocking,
          onChanged: consented ? onBlockingChanged : null,
          title: Text(l10n.setupEnableBlocking),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          value: wantsLauncher,
          onChanged: consented ? onLauncherChanged : null,
          title: Text(l10n.setupEnableLauncher),
          contentPadding: EdgeInsets.zero,
        ),
      ],
      action: Column(
        children: [
          FilledButton(
            onPressed: busy ? null : onFinish,
            child: Text(l10n.setupFinish),
          ),
          const SizedBox(height: LunioSpacing.s),
          // Declining is a real, equal path — Article 15.2 depends on it, and
          // it clears both switches rather than sharing onFinish.
          TextButton(
            onPressed: busy ? null : onSkip,
            child: Text(l10n.setupSkipProtection),
          ),
        ],
      ),
    );
  }
}

/// Shared layout so every step has the same rhythm and the same safe insets.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.body,
    required this.fields,
    required this.action,
  });

  final String title;
  final String body;
  final List<Widget> fields;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: LunioSpacing.s),
                Text(body, style: theme.textTheme.bodyLarge),
                const SizedBox(height: LunioSpacing.l),
                ...fields,
              ],
            ),
          ),
        ),
        const SizedBox(height: LunioSpacing.m),
        action,
      ],
    );
  }
}
