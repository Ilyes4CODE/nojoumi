/// The five subscription states of Article 7.6, and only these five:
/// "حالات الاشتراك المعتمدة: تجريبي، فعّال، مهلة سماح، منتهٍ، مسترجع".
enum SubscriptionState {
  /// تجريبي — 7 days, all features, once per device (Art. 7.1).
  trial,

  /// فعّال — a paid period is running.
  active,

  /// مهلة سماح — the 3 days added after expiry, during which everything still
  /// works (Art. 7.4).
  grace,

  /// منتهٍ — the free mode of Art. 7.1.
  expired,

  /// مسترجع — refunded; the client marked it in the admin dashboard and it
  /// stops immediately on the parent's device (Art. 7.5).
  refunded,
}

/// The three plans of Article 7.1. Prices are here for reference only — the
/// Android app never displays them (Art. 7.2 forbids showing a price, a buy
/// button, or a payment link inside the app).
enum SubscriptionPlan {
  trial(days: 7, priceDzd: 0),
  monthly(days: 30, priceDzd: 1000),
  annual(days: 365, priceDzd: 10000);

  const SubscriptionPlan({required this.days, required this.priceDzd});

  final int days;
  final int priceDzd;

  int get durationMs => days * 86400000;
}

/// What the server said, as the app received it.
///
/// Article 7.6: "المرجع الأساسي لحالة الاشتراك هو الخادم، وليس الجهاز، منعاً
/// للتلاعب." So this is the only thing the app is allowed to believe — and only
/// if the signature checks out.
class SubscriptionSnapshot {
  const SubscriptionSnapshot({
    required this.state,
    required this.plan,
    required this.startedAtMs,
    required this.endsAtMs,
    required this.issuedAtMs,
    required this.signatureValid,
  });

  final SubscriptionState state;
  final SubscriptionPlan plan;

  final int startedAtMs;

  /// End of the paid period, **before** the grace period is added.
  final int endsAtMs;

  /// Server time when this snapshot was signed. Doubles as the clock anchor,
  /// so subscription revalidation and time re-anchoring are one network call.
  final int issuedAtMs;

  /// Whether the app verified the server's signature over this payload.
  /// A false here means the snapshot is evidence of nothing.
  final bool signatureValid;

  SubscriptionSnapshot copyWith({
    SubscriptionState? state,
    SubscriptionPlan? plan,
    int? startedAtMs,
    int? endsAtMs,
    int? issuedAtMs,
    bool? signatureValid,
  }) {
    return SubscriptionSnapshot(
      state: state ?? this.state,
      plan: plan ?? this.plan,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      endsAtMs: endsAtMs ?? this.endsAtMs,
      issuedAtMs: issuedAtMs ?? this.issuedAtMs,
      signatureValid: signatureValid ?? this.signatureValid,
    );
  }
}

/// The local signed cache of Article 7.6, plus when we last managed to refresh
/// it. `null` snapshot = the app has never successfully talked to the server.
class SubscriptionCache {
  const SubscriptionCache({this.snapshot, this.fetchedAtMs});

  final SubscriptionSnapshot? snapshot;

  /// Trusted time at which [snapshot] was fetched — not wall-clock time.
  final int? fetchedAtMs;

  bool get isEmpty => snapshot == null || fetchedAtMs == null;
}

/// The numbers Article 7 fixes. Not parent-adjustable — unlike the star rules,
/// nothing in Article 7 is offered as a setting.
class SubscriptionPolicy {
  const SubscriptionPolicy({
    this.offlineWindowMs = 7 * 86400000,
    this.revalidateEveryMs = 24 * 3600000,
    this.graceMs = 3 * 86400000,
    this.reminderDaysBefore = const [7, 2],
  });

  /// Art. 7.6: "نسخة موقّعة محلياً تسمح له بالعمل دون اتصال بالإنترنت لمدة 7 أيام".
  final int offlineWindowMs;

  /// Art. 7.6: "ويتحقّق من الخادم كل 24 ساعة عند توفّر الاتصال".
  final int revalidateEveryMs;

  /// Art. 7.4: "مهلة سماح ثلاثة أيام".
  final int graceMs;

  /// Art. 7.4: "يُنبّه الوالد داخل التطبيق قبل 7 أيام ثم قبل يومين".
  final List<int> reminderDaysBefore;
}

/// Why new AI lesson generation is unavailable.
///
/// Article 7.1 is emphatic that only *this* stops: "يبقى محرك الحجب ونظام النجوم
/// والدروس المحفوظة سابقاً يعملون بالكامل، ويتوقّف توليد الدروس الجديدة بالذكاء
/// الاصطناعي وحده." The reason is recorded so the parent's screen can explain
/// itself instead of just failing.
enum AiUnavailableReason {
  /// The subscription ended and the grace period is over.
  subscriptionExpired,

  /// Refunded — stops immediately (Art. 7.5).
  refunded,

  /// Offline longer than the 7-day window; the cache can no longer be trusted.
  offlineWindowExceeded,

  /// The signature did not verify. Treated as no subscription at all.
  signatureInvalid,

  /// The app has never reached the server.
  neverValidated,

  /// The device clock cannot be trusted, so no window can be evaluated
  /// (Art. 7.6: changing the date or time must not extend a subscription).
  clockUntrusted,
}

/// What the app may currently do.
///
/// Three of these four are constants by contract. That is the point of the type:
/// it makes it structurally hard to write a feature that punishes the child for
/// the parent's payment delay.
class Capabilities {
  const Capabilities({
    required this.state,
    required this.canGenerateNewLessons,
    this.aiUnavailableReason,
  });

  final SubscriptionState state;

  /// The only capability Article 7 ever takes away.
  final bool canGenerateNewLessons;

  final AiUnavailableReason? aiUnavailableReason;

  /// Art. 7.1 — the blocking engine keeps working, always, in every state.
  bool get blockingActive => true;

  /// Art. 7.1 — stars keep working, always, in every state.
  bool get starsActive => true;

  /// Art. 7.1 — lessons already saved stay readable, always.
  bool get savedLessonsAccessible => true;

  @override
  String toString() => 'Capabilities($state, ai: $canGenerateNewLessons'
      '${aiUnavailableReason == null ? '' : ' [${aiUnavailableReason!.name}]'})';
}

/// A due in-app reminder before expiry (Art. 7.4).
class ExpiryReminder {
  const ExpiryReminder({required this.daysBefore, required this.endsAtMs});

  final int daysBefore;
  final int endsAtMs;

  @override
  String toString() => 'ExpiryReminder($daysBefore days before)';
}
