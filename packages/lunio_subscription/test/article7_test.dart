import 'package:lunio_subscription/lunio_subscription.dart';
import 'package:lunio_time/lunio_time.dart';
import 'package:test/test.dart';

const int day = 86400000;
const int hour = 3600000;

/// 2026-08-15 12:00 UTC.
final int t0 = DateTime.utc(2026, 8, 15, 12).millisecondsSinceEpoch;

TrustedInstant at(int epochMs,
        {TrustLevel level = TrustLevel.serverAnchored}) =>
    TrustedInstant(epochMs: epochMs, level: level);

SubscriptionSnapshot snap({
  SubscriptionState state = SubscriptionState.active,
  SubscriptionPlan plan = SubscriptionPlan.monthly,
  int? startedAtMs,
  int? endsAtMs,
  int? issuedAtMs,
  bool signatureValid = true,
}) =>
    SubscriptionSnapshot(
      state: state,
      plan: plan,
      startedAtMs: startedAtMs ?? t0,
      endsAtMs: endsAtMs ?? t0 + plan.durationMs,
      issuedAtMs: issuedAtMs ?? t0,
      signatureValid: signatureValid,
    );

SubscriptionCache cacheOf(SubscriptionSnapshot s, {int? fetchedAtMs}) =>
    SubscriptionCache(snapshot: s, fetchedAtMs: fetchedAtMs ?? t0);

void main() {
  const machine = SubscriptionMachine();

  group('7.1 — the three plans', () {
    test('trial is 7 days and free', () {
      expect(SubscriptionPlan.trial.days, 7);
      expect(SubscriptionPlan.trial.priceDzd, 0);
    });

    test('monthly is 30 days at 1.000 DZD', () {
      expect(SubscriptionPlan.monthly.days, 30);
      expect(SubscriptionPlan.monthly.priceDzd, 1000);
    });

    test('annual is 365 days at 10.000 DZD — two months saved', () {
      expect(SubscriptionPlan.annual.days, 365);
      expect(SubscriptionPlan.annual.priceDzd, 10000);
      expect(SubscriptionPlan.annual.priceDzd,
          SubscriptionPlan.monthly.priceDzd * 10);
    });

    test('there are exactly five states, no more', () {
      expect(SubscriptionState.values, hasLength(5));
      expect(
        SubscriptionState.values.map((s) => s.name),
        containsAll(['trial', 'active', 'grace', 'expired', 'refunded']),
      );
    });
  });

  group('7.1 — the free mode never punishes the child', () {
    test('blocking, stars and saved lessons stay on in EVERY state', () {
      final scenarios = <String, SubscriptionCache>{
        'trial': cacheOf(snap(
          state: SubscriptionState.trial,
          plan: SubscriptionPlan.trial,
        )),
        'active': cacheOf(snap()),
        'grace': cacheOf(snap(endsAtMs: t0 - 1 * day)),
        'expired': cacheOf(snap(endsAtMs: t0 - 30 * day)),
        'refunded': cacheOf(snap(state: SubscriptionState.refunded)),
        'never validated': const SubscriptionCache(),
        'bad signature': cacheOf(snap(signatureValid: false)),
      };

      scenarios.forEach((label, cache) {
        final caps = machine.capabilities(cache, at(t0));
        expect(caps.blockingActive, isTrue, reason: '$label: blocking');
        expect(caps.starsActive, isTrue, reason: '$label: stars');
        expect(caps.savedLessonsAccessible, isTrue, reason: '$label: lessons');
      });
    });

    test('only new AI generation is ever withdrawn', () {
      final expired = cacheOf(snap(endsAtMs: t0 - 30 * day));
      final caps = machine.capabilities(expired, at(t0));

      expect(caps.canGenerateNewLessons, isFalse);
      expect(caps.aiUnavailableReason, AiUnavailableReason.subscriptionExpired);
      expect(caps.blockingActive, isTrue);
      expect(caps.starsActive, isTrue);
    });
  });

  group('7.4 — the 3-day grace period', () {
    test('one second before the end, still active', () {
      final cache = cacheOf(snap(endsAtMs: t0 + 1000));
      expect(machine.effectiveState(cache, at(t0)), SubscriptionState.active);
    });

    test('one second after the end, grace begins', () {
      final cache = cacheOf(snap(endsAtMs: t0 - 1000));
      expect(machine.effectiveState(cache, at(t0)), SubscriptionState.grace);
    });

    test('AI still works during grace', () {
      final cache = cacheOf(snap(endsAtMs: t0 - 2 * day), fetchedAtMs: t0);
      final caps = machine.capabilities(cache, at(t0));
      expect(caps.state, SubscriptionState.grace);
      expect(caps.canGenerateNewLessons, isTrue);
    });

    test('grace lasts exactly three days, to the millisecond', () {
      final endsAt = t0;
      final cache = cacheOf(snap(endsAtMs: endsAt), fetchedAtMs: endsAt);

      expect(machine.effectiveState(cache, at(endsAt + 3 * day - 1)),
          SubscriptionState.grace);
      expect(machine.effectiveState(cache, at(endsAt + 3 * day)),
          SubscriptionState.expired);
    });

    test('after grace, free mode', () {
      final cache = cacheOf(snap(endsAtMs: t0 - 4 * day), fetchedAtMs: t0);
      expect(machine.effectiveState(cache, at(t0)), SubscriptionState.expired);
      expect(machine.capabilities(cache, at(t0)).canGenerateNewLessons, isFalse);
    });
  });

  group('7.4 — renewal adds to the remainder, it never replaces it', () {
    test('renewing 10 days early gives 30 + 10, not 30', () {
      final endsAt = t0 + 10 * day;
      final renewed = machine.renewedEndsAtMs(
        currentEndsAtMs: endsAt,
        plan: SubscriptionPlan.monthly,
        now: at(t0),
      );
      expect(renewed, endsAt + 30 * day);
      expect(renewed - t0, 40 * day);
    });

    test('renewing after expiry starts from now, not back-dated', () {
      final endsAt = t0 - 5 * day;
      final renewed = machine.renewedEndsAtMs(
        currentEndsAtMs: endsAt,
        plan: SubscriptionPlan.monthly,
        now: at(t0),
      );
      expect(renewed, t0 + 30 * day);
    });

    test('renewing exactly at the expiry instant loses nothing', () {
      final renewed = machine.renewedEndsAtMs(
        currentEndsAtMs: t0,
        plan: SubscriptionPlan.annual,
        now: at(t0),
      );
      expect(renewed, t0 + 365 * day);
    });

    test('an annual renewal on top of a running monthly stacks', () {
      final endsAt = t0 + 20 * day;
      final renewed = machine.renewedEndsAtMs(
        currentEndsAtMs: endsAt,
        plan: SubscriptionPlan.annual,
        now: at(t0),
      );
      expect(renewed - t0, (365 + 20) * day);
    });

    test('cancellation requires no action — not renewing simply lets it run out',
        () {
      // There is no "cancel" transition anywhere in this machine, by design.
      final cache = cacheOf(snap(endsAtMs: t0 + 5 * day), fetchedAtMs: t0);
      expect(machine.effectiveState(cache, at(t0)), SubscriptionState.active,
          reason: 'still paid for, still working');
      expect(machine.effectiveState(cache, at(t0 + 9 * day)),
          SubscriptionState.expired);
    });
  });

  group('7.4 — reminders at 7 days then 2 days', () {
    final cache = cacheOf(snap(endsAtMs: t0 + 30 * day), fetchedAtMs: t0);

    test('no reminder while expiry is far away', () {
      expect(machine.dueReminder(cache, at(t0)), isNull);
      expect(machine.dueReminder(cache, at(t0 + 22 * day)), isNull);
    });

    test('the 7-day reminder becomes due at 7 days', () {
      final r = machine.dueReminder(cache, at(t0 + 23 * day));
      expect(r?.daysBefore, 7);
    });

    test('the 2-day reminder takes over inside 2 days', () {
      final r = machine.dueReminder(cache, at(t0 + 28 * day + hour));
      expect(r?.daysBefore, 2);
    });

    test('no reminder once it has already expired — that is not a reminder', () {
      expect(machine.dueReminder(cache, at(t0 + 31 * day)), isNull);
    });

    test('no reminder for a refunded subscription', () {
      final refunded = cacheOf(
        snap(state: SubscriptionState.refunded, endsAtMs: t0 + 3 * day),
        fetchedAtMs: t0,
      );
      expect(machine.dueReminder(refunded, at(t0)), isNull);
    });
  });

  group('7.5 — a refund stops it immediately', () {
    test('refunded wins even with a month left on the clock', () {
      final cache = cacheOf(
        snap(state: SubscriptionState.refunded, endsAtMs: t0 + 30 * day),
        fetchedAtMs: t0,
      );
      final caps = machine.capabilities(cache, at(t0));

      expect(caps.state, SubscriptionState.refunded);
      expect(caps.canGenerateNewLessons, isFalse);
      expect(caps.aiUnavailableReason, AiUnavailableReason.refunded);
    });

    test('refunded is terminal — no grace period softens it', () {
      final cache = cacheOf(
        snap(state: SubscriptionState.refunded, endsAtMs: t0 - 1000),
        fetchedAtMs: t0,
      );
      expect(machine.effectiveState(cache, at(t0)), SubscriptionState.refunded);
    });

    test('but blocking and stars still keep working', () {
      final cache = cacheOf(
        snap(state: SubscriptionState.refunded),
        fetchedAtMs: t0,
      );
      final caps = machine.capabilities(cache, at(t0));
      expect(caps.blockingActive, isTrue);
      expect(caps.starsActive, isTrue);
    });
  });

  group('7.6 — the server is the source of truth, not the device', () {
    test('an unsigned snapshot proves nothing and yields free mode', () {
      final cache = cacheOf(snap(signatureValid: false), fetchedAtMs: t0);
      final caps = machine.capabilities(cache, at(t0));

      expect(caps.state, SubscriptionState.expired);
      expect(caps.canGenerateNewLessons, isFalse);
      expect(caps.aiUnavailableReason, AiUnavailableReason.signatureInvalid);
    });

    test('an unsigned snapshot is refused at the cache boundary', () {
      expect(
        () => machine.accept(
          snapshot: snap(signatureValid: false),
          now: at(t0),
        ),
        throwsArgumentError,
      );
    });

    test('a snapshot may not be cached against untrusted time', () {
      expect(
        () => machine.accept(
          snapshot: snap(),
          now: at(t0, level: TrustLevel.untrusted),
        ),
        throwsArgumentError,
      );
    });

    test('accepting a valid snapshot stamps it with trusted time', () {
      final cache = machine.accept(snapshot: snap(), now: at(t0 + hour));
      expect(cache.fetchedAtMs, t0 + hour);
      expect(cache.isEmpty, isFalse);
    });

    test('never having reached the server means free mode, not full access', () {
      const empty = SubscriptionCache();
      final caps = machine.capabilities(empty, at(t0));

      expect(caps.state, SubscriptionState.expired);
      expect(caps.canGenerateNewLessons, isFalse);
      expect(caps.aiUnavailableReason, AiUnavailableReason.neverValidated);
      expect(caps.blockingActive, isTrue,
          reason: 'a server we cannot reach must never disable the blocking');
    });

    test('the device may downgrade what the server said, never upgrade it', () {
      // The server says active for 30 days; 40 days of trusted time have passed.
      final cache = cacheOf(snap(endsAtMs: t0 + 30 * day), fetchedAtMs: t0);
      expect(machine.effectiveState(cache, at(t0 + 40 * day)),
          SubscriptionState.expired);

      // The server says expired; no amount of local time makes it active again.
      final dead = cacheOf(
        snap(state: SubscriptionState.expired, endsAtMs: t0 - 100 * day),
        fetchedAtMs: t0,
      );
      expect(machine.effectiveState(dead, at(t0)), SubscriptionState.expired);
    });
  });

  group('7.6 — the 7-day offline window', () {
    test('works fully for the first 7 days offline', () {
      final cache = cacheOf(snap(endsAtMs: t0 + 30 * day), fetchedAtMs: t0);

      expect(machine.offlineWindowExceeded(cache, at(t0 + 6 * day)), isFalse);
      expect(
        machine.capabilities(cache, at(t0 + 6 * day)).canGenerateNewLessons,
        isTrue,
      );
    });

    test('at exactly 7 days it is still inside the window', () {
      final cache = cacheOf(snap(endsAtMs: t0 + 30 * day), fetchedAtMs: t0);
      expect(machine.offlineWindowExceeded(cache, at(t0 + 7 * day)), isFalse);
    });

    test('past 7 days the cache stops authorising AI — but nothing else', () {
      final cache = cacheOf(snap(endsAtMs: t0 + 30 * day), fetchedAtMs: t0);
      final caps = machine.capabilities(cache, at(t0 + 7 * day + 1));

      expect(caps.canGenerateNewLessons, isFalse);
      expect(caps.aiUnavailableReason,
          AiUnavailableReason.offlineWindowExceeded);
      expect(caps.state, SubscriptionState.active,
          reason: 'the subscription itself has not ended, only our proof of it');
      expect(caps.blockingActive, isTrue);
      expect(caps.starsActive, isTrue);
    });

    test('revalidation is due after 24 h, well before anything breaks', () {
      final cache = cacheOf(snap(), fetchedAtMs: t0);

      expect(machine.needsRevalidation(cache, at(t0 + 23 * hour)), isFalse);
      expect(machine.needsRevalidation(cache, at(t0 + 24 * hour)), isTrue);
      expect(
        machine.capabilities(cache, at(t0 + 24 * hour)).canGenerateNewLessons,
        isTrue,
        reason: 'a due revalidation is not a failure — intermittent internet is '
            'the normal case, and day 7 is the deadline, not day 1',
      );
    });

    test('an empty cache always needs revalidation', () {
      const empty = SubscriptionCache();
      expect(machine.needsRevalidation(empty, at(t0)), isTrue);
      expect(machine.offlineWindowExceeded(empty, at(t0)), isTrue);
    });
  });

  group('7.6 — changing the device date or time never extends a subscription',
      () {
    test('an untrusted clock yields free mode, never extra time', () {
      final cache = cacheOf(snap(endsAtMs: t0 + 30 * day), fetchedAtMs: t0);
      final caps =
          machine.capabilities(cache, at(t0, level: TrustLevel.untrusted));

      expect(caps.state, SubscriptionState.expired);
      expect(caps.canGenerateNewLessons, isFalse);
      expect(caps.aiUnavailableReason, AiUnavailableReason.clockUntrusted);
      expect(caps.blockingActive, isTrue);
    });

    test('winding the clock back inside the grace period does not restore AI',
        () {
      // Really expired 10 days ago; the clock claims we are back in grace.
      final cache = cacheOf(snap(endsAtMs: t0 - 10 * day), fetchedAtMs: t0);
      final fakedBack = at(t0 - 9 * day, level: TrustLevel.untrusted);

      expect(machine.capabilities(cache, fakedBack).canGenerateNewLessons,
          isFalse);
    });

    test('the offline window cannot be extended by moving the clock', () {
      final cache = cacheOf(snap(endsAtMs: t0 + 30 * day), fetchedAtMs: t0);
      expect(
        machine.offlineWindowExceeded(
          cache,
          at(t0 + 2 * day, level: TrustLevel.untrusted),
        ),
        isTrue,
        reason: 'with no trustworthy clock there is no window to be inside of',
      );
    });

    test('an honest offline family on a monotonic clock still works', () {
      final cache = cacheOf(snap(endsAtMs: t0 + 30 * day), fetchedAtMs: t0);
      final caps = machine.capabilities(
        cache,
        at(t0 + 3 * day, level: TrustLevel.monotonic),
      );

      expect(caps.state, SubscriptionState.active);
      expect(caps.canGenerateNewLessons, isTrue);
    });
  });

  group('the trial (7.1)', () {
    test('a running trial has full access', () {
      final cache = cacheOf(
        snap(
          state: SubscriptionState.trial,
          plan: SubscriptionPlan.trial,
          endsAtMs: t0 + 7 * day,
        ),
        fetchedAtMs: t0,
      );
      final caps = machine.capabilities(cache, at(t0 + 3 * day));

      expect(caps.state, SubscriptionState.trial);
      expect(caps.canGenerateNewLessons, isTrue);
    });

    test('an ended trial also gets the 3-day grace, then free mode', () {
      final cache = cacheOf(
        snap(
          state: SubscriptionState.trial,
          plan: SubscriptionPlan.trial,
          endsAtMs: t0,
        ),
        fetchedAtMs: t0,
      );

      expect(machine.effectiveState(cache, at(t0 + day)),
          SubscriptionState.grace);
      expect(machine.effectiveState(cache, at(t0 + 4 * day)),
          SubscriptionState.expired);
    });

    test('days until expiry is floored, for display only', () {
      final cache = cacheOf(snap(endsAtMs: t0 + 7 * day + 12 * hour));
      expect(machine.daysUntilExpiry(cache, at(t0)), 7);
    });
  });
}
