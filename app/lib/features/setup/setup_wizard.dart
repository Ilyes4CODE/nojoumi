import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojoumi_stars/nojoumi_stars.dart';

import '../../core/pin.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

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

  /// `app_settings.onboarding_step` at or above this means setup is done.
  static const int completedStep = 4;

  @override
  ConsumerState<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends ConsumerState<SetupWizard> {
  final _grade = TextEditingController();
  final _pin = TextEditingController();
  final _pinConfirm = TextEditingController();

  int _step = 0;
  String? _pinError;
  bool _consented = false;
  bool _wantsBlocking = false;
  bool _wantsLauncher = false;
  bool _busy = false;

  static const int _totalSteps = 4;

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
        child: Padding(
          padding: NojoumiSpacing.page,
          child: switch (_step) {
            0 => _WelcomeStep(onNext: () => setState(() => _step = 1)),
            1 => _GradeStep(
                controller: _grade,
                onNext: _saveGradeAndContinue,
              ),
            2 => _PinStep(
                pin: _pin,
                confirm: _pinConfirm,
                error: _pinError,
                busy: _busy,
                onNext: _savePinAndContinue,
              ),
            _ => ProtectionStep(
                consented: _consented,
                wantsBlocking: _wantsBlocking,
                wantsLauncher: _wantsLauncher,
                busy: _busy,
                onConsentChanged: (v) => setState(() {
                  _consented = v;
                  if (!v) {
                    _wantsBlocking = false;
                    _wantsLauncher = false;
                  }
                }),
                onBlockingChanged: (v) => setState(() => _wantsBlocking = v),
                onLauncherChanged: (v) => setState(() => _wantsLauncher = v),
                onFinish: _finish,
              ),
          },
        ),
      ),
    );
  }

  Future<void> _saveGradeAndContinue() async {
    await ref.read(settingsRepositoryProvider).setGrade(_grade.text);
    if (mounted) setState(() => _step = 2);
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
    await ref.read(settingsRepositoryProvider).setPin(
          hash: credential.hash,
          salt: credential.salt,
        );
    // The PIN itself is dropped here and exists nowhere else (D-10).
    _pin.clear();
    _pinConfirm.clear();
    if (mounted) {
      setState(() {
        _busy = false;
        _step = 3;
      });
    }
  }

  /// Finish setup.
  ///
  /// The welcome balance (appendix §5, 10 stars by default) is granted here
  /// rather than at first launch, so the child's first encounter with the app is
  /// not a locked door. It is guarded by a flag inside the same transaction, so
  /// re-running setup cannot grant it twice.
  Future<void> _finish() async {
    setState(() => _busy = true);

    final settings = ref.read(settingsRepositoryProvider);
    await settings.setBlockingEnabled(_wantsBlocking);
    await settings.setLauncherMode(_wantsLauncher);

    final rules = await settings.readRules();
    final now = await ref.read(trustedNowProvider.notifier).refresh();
    final day = now.dayKey(
      utcOffsetMinutes: await settings.utcOffsetMinutes(),
    );
    await ref.read(starRepositoryProvider).grantWelcomeOnce(
          rules: rules,
          day: day,
          now: now,
        );

    await settings.setOnboardingStep(SetupWizard.completedStep);
    if (mounted) {
      _showWelcomeGrant(rules.welcomeUnits);
      setState(() => _busy = false);
    }
  }

  void _showWelcomeGrant(int units) {
    if (units == 0) return;
    final l10n = AppL10n.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.setupDoneBody(unitsToStars(units).toString())),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    return _StepScaffold(
      title: l10n.setupWelcomeTitle,
      body: l10n.setupWelcomeBody,
      fields: const [],
      action: FilledButton(onPressed: onNext, child: Text(l10n.next)),
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
      ],
      action: FilledButton(
        onPressed:
            widget.controller.text.trim().isEmpty ? null : widget.onNext,
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
        const SizedBox(height: NojoumiSpacing.m),
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
  });

  final bool consented;
  final bool wantsBlocking;
  final bool wantsLauncher;
  final bool busy;
  final ValueChanged<bool> onConsentChanged;
  final ValueChanged<bool> onBlockingChanged;
  final ValueChanged<bool> onLauncherChanged;
  final VoidCallback onFinish;

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
            padding: const EdgeInsets.all(NojoumiSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.setupDisclosureTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: NojoumiSpacing.s),
                Text(
                  l10n.setupDisclosureBody,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: NojoumiSpacing.s),
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
        const SizedBox(height: NojoumiSpacing.m),
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
          const SizedBox(height: NojoumiSpacing.s),
          // Declining is a real, equal path — Article 15.2 depends on it.
          TextButton(
            onPressed: busy ? null : onFinish,
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
                const SizedBox(height: NojoumiSpacing.s),
                Text(body, style: theme.textTheme.bodyLarge),
                const SizedBox(height: NojoumiSpacing.l),
                ...fields,
              ],
            ),
          ),
        ),
        const SizedBox(height: NojoumiSpacing.m),
        action,
      ],
    );
  }
}
