import 'package:lunio_time/lunio_time.dart';

import 'subscription.dart';

/// Article 7's state machine.
///
/// Pure. It takes the signed cache and a [TrustedInstant] and returns what the
/// app may do. It performs no IO, holds no state, and never reads a clock —
/// which is how Article 7.6 ("changing the device date or time does not extend
/// a subscription") becomes a unit test instead of a hope.
///
/// The design rule that matters most: **the server decides, the device only
/// evaluates windows.** The device may downgrade what the server said — because
/// time passed, or the cache went stale — but it may never upgrade it.
class SubscriptionMachine {
  const SubscriptionMachine({this.policy = const SubscriptionPolicy()});

  final SubscriptionPolicy policy;

  /// The state to act on right now.
  SubscriptionState effectiveState(SubscriptionCache cache, TrustedInstant now) {
    final snapshot = cache.snapshot;
    if (snapshot == null || cache.fetchedAtMs == null) {
      return SubscriptionState.expired;
    }
    if (!snapshot.signatureValid) return SubscriptionState.expired;

    // Refunded is terminal and immediate: the client marked it, and it must not
    // be softened by any remaining window (Art. 7.5).
    if (snapshot.state == SubscriptionState.refunded) {
      return SubscriptionState.refunded;
    }

    // Without trusted time we cannot evaluate any window, so we fall back to
    // free mode rather than guess in the parent's favour or the child's.
    if (!now.isTrustworthy) return SubscriptionState.expired;

    if (now.epochMs < snapshot.endsAtMs) {
      // The server said trial or active; time has not run out, so it stands.
      return snapshot.state == SubscriptionState.trial
          ? SubscriptionState.trial
          : SubscriptionState.active;
    }
    if (now.epochMs < snapshot.endsAtMs + policy.graceMs) {
      return SubscriptionState.grace;
    }
    return SubscriptionState.expired;
  }

  /// What the app may do right now.
  Capabilities capabilities(SubscriptionCache cache, TrustedInstant now) {
    final state = effectiveState(cache, now);
    final snapshot = cache.snapshot;

    AiUnavailableReason? reason;
    if (snapshot == null || cache.fetchedAtMs == null) {
      reason = AiUnavailableReason.neverValidated;
    } else if (!snapshot.signatureValid) {
      reason = AiUnavailableReason.signatureInvalid;
    } else if (state == SubscriptionState.refunded) {
      reason = AiUnavailableReason.refunded;
    } else if (!now.isTrustworthy) {
      reason = AiUnavailableReason.clockUntrusted;
    } else if (offlineWindowExceeded(cache, now)) {
      reason = AiUnavailableReason.offlineWindowExceeded;
    } else if (state == SubscriptionState.expired) {
      reason = AiUnavailableReason.subscriptionExpired;
    }

    return Capabilities(
      state: state,
      canGenerateNewLessons: reason == null,
      aiUnavailableReason: reason,
    );
  }

  /// Art. 7.6 — the local copy is good for 7 days offline, no longer.
  bool offlineWindowExceeded(SubscriptionCache cache, TrustedInstant now) {
    final fetchedAt = cache.fetchedAtMs;
    if (fetchedAt == null) return true;
    if (!now.isTrustworthy) return true;
    return now.epochMs - fetchedAt > policy.offlineWindowMs;
  }

  /// Art. 7.6 — revalidate every 24 h when a connection is available.
  ///
  /// Deliberately separate from [offlineWindowExceeded]: the app should *try*
  /// after 24 h, but nothing bad happens until day 7. Conflating the two would
  /// break a family whose internet is intermittent, which is most of them.
  bool needsRevalidation(SubscriptionCache cache, TrustedInstant now) {
    final fetchedAt = cache.fetchedAtMs;
    if (fetchedAt == null) return true;
    if (!now.isTrustworthy) return true;
    return now.epochMs - fetchedAt >= policy.revalidateEveryMs;
  }

  /// Art. 7.4 — "التجديد قبل انتهاء المدة يضيف المدة الجديدة إلى ما تبقّى ولا يلغيه."
  ///
  /// Renewing early must never cost the parent the days they already paid for,
  /// and renewing late must not back-date the new period.
  int renewedEndsAtMs({
    required int currentEndsAtMs,
    required SubscriptionPlan plan,
    required TrustedInstant now,
  }) {
    final base =
        currentEndsAtMs > now.epochMs ? currentEndsAtMs : now.epochMs;
    return base + plan.durationMs;
  }

  /// Art. 7.4 — the in-app reminders, 7 days then 2 days before expiry.
  ///
  /// Returns the closest reminder that is currently due, or null. The caller is
  /// responsible for not showing the same one twice (it records which reminders
  /// it has already shown for this [SubscriptionSnapshot.endsAtMs]).
  ExpiryReminder? dueReminder(SubscriptionCache cache, TrustedInstant now) {
    final snapshot = cache.snapshot;
    if (snapshot == null || !snapshot.signatureValid) return null;
    if (!now.isTrustworthy) return null;
    if (snapshot.state == SubscriptionState.refunded) return null;
    if (now.epochMs >= snapshot.endsAtMs) return null;

    final msLeft = snapshot.endsAtMs - now.epochMs;
    final sorted = [...policy.reminderDaysBefore]..sort();
    for (final days in sorted) {
      if (msLeft <= days * 86400000) {
        return ExpiryReminder(daysBefore: days, endsAtMs: snapshot.endsAtMs);
      }
    }
    return null;
  }

  /// Whole days left before the paid period ends. Negative once it has ended.
  /// For display only — never for a decision.
  int daysUntilExpiry(SubscriptionCache cache, TrustedInstant now) {
    final snapshot = cache.snapshot;
    if (snapshot == null) return 0;
    final ms = snapshot.endsAtMs - now.epochMs;
    return (ms / 86400000).floor();
  }

  /// Fold a freshly verified server snapshot into the cache.
  ///
  /// [now] must be trusted, because [SubscriptionCache.fetchedAtMs] is the
  /// anchor for the offline window; storing an untrusted timestamp here would
  /// hand a child a way to extend the window by moving the clock.
  SubscriptionCache accept({
    required SubscriptionSnapshot snapshot,
    required TrustedInstant now,
  }) {
    if (!snapshot.signatureValid) {
      throw ArgumentError(
        'refusing to cache an unverified snapshot — Art. 7.6 makes the server '
        'the only source of truth, and an unsigned payload proves nothing',
      );
    }
    if (!now.isTrustworthy) {
      throw ArgumentError(
        'refusing to cache a snapshot against untrusted time — Art. 7.6: '
        'changing the device clock must not extend a subscription',
      );
    }
    return SubscriptionCache(snapshot: snapshot, fetchedAtMs: now.epochMs);
  }
}
