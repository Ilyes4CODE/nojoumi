import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunio_subscription/lunio_subscription.dart';
import 'package:lunio_time/lunio_time.dart';

import '../../core/config.dart';
import '../../core/illustrations.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/remote/api_client.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../l10n/app_localizations.dart';

/// The subscription, for the parent, behind the PIN.
///
/// ## A recorded departure from Article 7.2
///
/// The article says the app shows **no price, no buy button and no payment
/// link**, and states the reason: that separation is what keeps Lunio clear of
/// Google Play's billing policy, which requires digital purchases made inside an
/// app to go through Play Billing.
///
/// On 2026-08-29 the client was shown the two options and **chose the button**.
/// It is built below, and the risk was put in writing first: Google treats a
/// third-party payment flow reached from inside an app as a policy violation,
/// and enforcement is removal. Removal takes Article 15.2's twelve-tester closed
/// test and Article 11's acceptance with it. This is a change order, not a
/// defect, and it is recorded as D-66.
///
/// **What was kept, because it costs nothing and narrows the exposure:**
///
///  * **still no price anywhere in the app.** Both amounts live on the web page,
///    read from `plans.py`. A screen with no number on it is a weaker case
///    against us than one advertising a monthly fee — and it is also why a
///    price change is a server deploy and never a new APK;
///  * the button opens the **system browser**, never a WebView. A payment page
///    rendered inside the app is unambiguously an in-app purchase flow; handing
///    the URL to the browser keeps the transaction visibly outside Lunio, with
///    the address bar the parent knows how to read;
///  * Article 7.7 is untouched and always will be — no card field exists
///    anywhere in this codebase, and the parent's card is entered on Chargily's
///    hosted page alone.
///
/// The rest of the screen is unchanged: it shows status, and Article 7.1's
/// promise that blocking, stars and saved lessons keep working in every state.
///
/// The other half of Article 7 is just as visible: whatever the state, the card at
/// the bottom says what keeps working. Blocking, stars and saved lessons never
/// stop (Art. 7.1) — only new AI lesson generation does, and the child is never
/// punished for the parent's payment delay.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Article 7.6 — revalidate from the server when the screen opens, so the
    // parent is never reading a week-old answer while online.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final capabilities = ref.watch(capabilitiesProvider).value;
    final cache = ref.watch(subscriptionCacheProvider).value;
    final signedIn = ref.watch(isSignedInProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscription)),
      body: SafeArea(
        child: ListView(
          padding: LunioSpacing.page,
          children: [
            if (!AppConfig.hasApi)
              _Notice(text: l10n.serverNotConfigured)
            else if (!signedIn)
              _Notice(text: l10n.signInRequired)
            else ...[
              _StatusCard(
                state: capabilities?.state ?? SubscriptionState.expired,
                plan: cache?.plan ?? '',
                endsAtMs: cache?.endsAtMs,
              ),
              const SizedBox(height: LunioSpacing.l),
              if ((capabilities?.state ?? SubscriptionState.expired) ==
                  SubscriptionState.expired) ...[
                _TrialCard(busy: _busy, onStart: _startTrial),
                const SizedBox(height: LunioSpacing.l),
              ],
              _ActivationCard(
                controller: _code,
                busy: _busy,
                error: _error,
                onActivate: _activate,
              ),
              const SizedBox(height: LunioSpacing.m),
              _BuyCard(onOpen: _openPaymentPage),
              const SizedBox(height: LunioSpacing.l),
              // Plain text, no button, no link styling — Art. 7.2.
              _Notice(text: l10n.renewNotice),
            ],
            const SizedBox(height: LunioSpacing.l),
            _WhatKeepsWorking(
              aiPaused: capabilities?.canGenerateNewLessons == false,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final now = ref.read(trustedNowProvider).value;
    if (now == null) return;
    await ref.read(subscriptionRepositoryProvider).refresh(now);
    ref.invalidate(capabilitiesProvider);
  }

  /// Open the payment page in the parent's browser.
  ///
  /// The browser rather than a WebView, deliberately — see the class doc. If the
  /// device somehow has no browser the call returns false and the parent is shown
  /// the address instead of being left with a button that does nothing.
  Future<void> _openPaymentPage() async {
    final messenger = ScaffoldMessenger.of(context);

    final opened = await ref
        .read(blockingChannelProvider)
        .openUrl(AppConfig.payUrl);

    if (!mounted) return;
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(AppConfig.payUrl)));
    }
    // Coming back from the browser with a code in hand is the common case, so
    // the state is re-read on return rather than waiting for the next 24-hour
    // revalidation (Art. 7.6).
    _refresh();
  }

  Future<void> _startTrial() async {
    await _run((repository, now) => repository.startTrial(now));
  }

  /// Redeem the code, and **say so plainly when it works.**
  ///
  /// Asked for by the client on 2026-08-31. Until now a correct code cleared the
  /// field and changed a chip further up the screen, and that is not enough at
  /// this particular moment: the parent has just paid real money on a web page
  /// outside the app and typed a string they carried back by hand. A silent
  /// success is indistinguishable from a form that did nothing.
  Future<void> _activate() async {
    final activated = await _run(
      (repository, now) => repository.activate(_code.text, now),
    );
    if (!activated || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => const ActivationDoneDialog(),
    );
  }

  /// Runs one subscription action and reports whether it got through.
  ///
  /// **Success is the absence of an `ApiFailure`, not the returned bool.**
  /// `activate` posts the code and then returns whatever `refresh` returned — so
  /// a subscription that was activated on the server but whose snapshot refresh
  /// came back empty would report `false`. Treating that as a failure would tell
  /// a parent who has just paid that their code did not work.
  Future<bool> _run(
    Future<bool> Function(SubscriptionRepository, TrustedInstant) action,
  ) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final now = await ref.read(trustedNowProvider.notifier).refresh();
    try {
      await action(ref.read(subscriptionRepositoryProvider), now);
      ref.invalidate(capabilitiesProvider);
      _code.clear();
      return true;
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// The buy button — Article 7.2's exception, built at the client's direction.
///
/// Deliberately plain: no price, no plan comparison, no urgency. It says what it
/// does and opens a browser. Everything that would make it *look* like a store
/// front is exactly what the article was written to keep out of the app, and the
/// client asked for a way through, not for a shop.
class _BuyCard extends StatelessWidget {
  const _BuyCard({required this.onOpen});

  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.buyOpensBrowser,
              style: theme.textTheme.bodySmall?.copyWith(
                color: LunioTheme.ink.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: LunioSpacing.m),
            OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.buyActivationCode),
            ),
          ],
        ),
      ),
    );
  }
}

/// The five states of Article 7.6, and only these five.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.state,
    required this.plan,
    required this.endsAtMs,
  });

  final SubscriptionState state;
  final String plan;
  final int? endsAtMs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.subscription,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(_label(l10n, state)),
                  backgroundColor: _tint(state),
                  side: BorderSide.none,
                ),
              ],
            ),
            if (plan.isNotEmpty) ...[
              const Divider(height: LunioSpacing.xl),
              _Row(label: l10n.subscriptionPlan, value: _planLabel(l10n, plan)),
            ],
            if (endsAtMs != null && endsAtMs! > 0)
              _Row(label: l10n.expiresOn(''), value: _formatDate(endsAtMs!)),
          ],
        ),
      ),
    );
  }

  static String _label(AppL10n l10n, SubscriptionState state) =>
      switch (state) {
        SubscriptionState.trial => l10n.subscriptionTrial,
        SubscriptionState.active => l10n.subscriptionActive,
        SubscriptionState.grace => l10n.subscriptionGrace,
        SubscriptionState.expired => l10n.subscriptionExpired,
        SubscriptionState.refunded => l10n.subscriptionRefunded,
      };

  static Color _tint(SubscriptionState state) => switch (state) {
    SubscriptionState.active => LunioTheme.tintMint,
    SubscriptionState.trial => LunioTheme.tintSky,
    SubscriptionState.grace => LunioTheme.tintPeach,
    // Expired and refunded are grey, never red. Article 1 calls this a
    // motivation tool, and a parent behind on a payment is not an error state.
    _ => LunioTheme.tintLavender,
  };

  static String _planLabel(AppL10n l10n, String plan) => switch (plan) {
    'monthly' => l10n.planMonthly,
    'annual' => l10n.planAnnual,
    _ => l10n.planTrial,
  };

  /// `yyyy-MM-dd`, built from the stored epoch rather than from a `DateTime.now()`
  /// anywhere. Display only — no decision is ever taken on this value.
  static String _formatDate(int epochMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true);
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}

class _TrialCard extends StatelessWidget {
  const _TrialCard({required this.busy, required this.onStart});

  final bool busy;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.trialOncePerDevice,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: LunioSpacing.m),
            FilledButton(
              onPressed: busy ? null : onStart,
              child: Text(l10n.startTrial),
            ),
          ],
        ),
      ),
    );
  }
}

/// Article 7.3 step 5 — the one thing that crosses from the payment page.
class _ActivationCard extends StatelessWidget {
  const _ActivationCard({
    required this.controller,
    required this.busy,
    required this.error,
    required this.onActivate,
  });

  final TextEditingController controller;
  final bool busy;
  final String? error;
  final Future<void> Function() onActivate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The same ticket the payment page shows beside the code the parent
            // was just given. The code is the only thing that crosses from the
            // browser into the app (Art. 7.2 keeps everything else outside), and
            // repeating the drawing is how a parent sees that the two screens
            // are one errand.
            Center(child: Illustration.codeTicket.show(size: 96)),
            const SizedBox(height: LunioSpacing.s),
            Text(l10n.enterActivationCode, style: theme.textTheme.titleMedium),
            const SizedBox(height: LunioSpacing.s),
            Text(l10n.activationHelp, style: theme.textTheme.bodySmall),
            const SizedBox(height: LunioSpacing.m),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              // An activation code is Latin characters; forcing LTR keeps the
              // grouping readable inside an otherwise right-to-left screen.
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                hintText: 'XXXX - XXXX - XXXX',
                errorText: error,
              ),
            ),
            const SizedBox(height: LunioSpacing.m),
            FilledButton(
              onPressed: busy ? null : onActivate,
              child: Text(l10n.activate),
            ),
          ],
        ),
      ),
    );
  }
}

/// Article 7.1, stated on every state of this screen.
///
/// Three of the four capabilities are constants by contract, and saying so where
/// the parent can read it is the difference between a rule and a suspicion.
class _WhatKeepsWorking extends StatelessWidget {
  const _WhatKeepsWorking({required this.aiPaused});

  final bool aiPaused;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    return Card(
      color: LunioTheme.tintLavender,
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Illustration.shield.show(size: 40),
                const SizedBox(width: LunioSpacing.m),
                Expanded(
                  child: Text(
                    aiPaused ? l10n.aiPausedTitle : l10n.subscription,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LunioSpacing.s),
            Text(l10n.freeModeNotice, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LunioSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.m),
        child: Row(
          children: [
            const TintedIcon(Icons.info_outline),
            const SizedBox(width: LunioSpacing.m),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

/// Shown once, the moment an activation code is accepted.
///
/// ### Why this is a dialog and not another line on the screen
///
/// Asked for by the client on 2026-08-31. The parent has just left the app for
/// a browser, paid on a page they had never seen, and carried a short string
/// back by hand. That is the least certain minute in the whole product, and
/// until now it ended with a text field clearing itself and a chip changing
/// colour further up a screen they may not even be looking at.
///
/// ### What it says, and what it deliberately does not
///
/// It states the two facts the parent actually needs — **it worked**, and
/// **until when** — and then one they do not know they need: Article 7.1 keeps
/// the blocking engine, the stars and every saved lesson working whether or not
/// there is a subscription, and only *new* AI generation stops. A parent who
/// believes the whole app dies at expiry pays under a false impression, and the
/// contract is explicit that the child is never punished for a payment delay.
///
/// No price and no plan comparison: Article 7.2 keeps the shop outside, and a
/// confirmation is not a place to sell the next renewal.
class ActivationDoneDialog extends ConsumerWidget {
  const ActivationDoneDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);
    // Read live rather than passed in: `activate` refreshes the snapshot, and
    // this dialog opens on the frame after. Whatever the cache holds now is
    // what the status card above will show once the dialog closes, so the two
    // cannot disagree.
    final cache = ref.watch(subscriptionCacheProvider).value;
    final plan = cache?.plan ?? '';
    final endsAtMs = cache?.endsAtMs;

    return AlertDialog(
      backgroundColor: LunioTheme.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LunioRadius.card),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        LunioSpacing.l,
        LunioSpacing.xl,
        LunioSpacing.l,
        LunioSpacing.m,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Illustration.subscriptionDone.show(
            size: 132,
            placeholderTint: LunioTheme.tintMint,
          ),
          const SizedBox(height: LunioSpacing.l),
          Text(
            l10n.activatedTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (plan.isNotEmpty) ...[
            const SizedBox(height: LunioSpacing.s),
            Chip(
              label: Text(_StatusCard._planLabel(l10n, plan)),
              backgroundColor: LunioTheme.tintMint,
              side: BorderSide.none,
            ),
          ],
          if (endsAtMs != null && endsAtMs > 0) ...[
            const SizedBox(height: LunioSpacing.s),
            Text(
              l10n.activatedUntil(_StatusCard._formatDate(endsAtMs)),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: LunioSpacing.m),
          Container(
            padding: const EdgeInsets.all(LunioSpacing.m),
            decoration: BoxDecoration(
              color: LunioTheme.tintLavender,
              borderRadius: BorderRadius.circular(LunioRadius.card),
            ),
            child: Text(
              l10n.activatedBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        LunioSpacing.l,
        0,
        LunioSpacing.l,
        LunioSpacing.l,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.continueAction),
          ),
        ),
      ],
    );
  }
}
