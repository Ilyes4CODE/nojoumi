# CLAUDE.md — Nojoumi (نجومي)

Android parental-control / educational-motivation app for the Algerian market.
Client: سماحي محمد أمين · Developer: بن دايخة إلياس · 70.000 DZD · 23 working days · Android 10+.

**`docs/contract.pdf` is the source of truth.** It is a signed Arabic specification. Every number in it is a
contractual obligation. When this file and the contract disagree, the contract wins and this file gets fixed.
When the contract is silent, **ask the developer — never invent a rule.**

---

## 0. Working agreement

- **The assistant is blind to the device. The developer is the only pair of eyes.** There is no emulator
  substitute for Articles 11 and 12.
- **Never write that something "works."** Write what it *should* do and exactly what to look for
  (screen, timing, logcat tag). "Compiles" is not "works." "Passes unit tests" is not "works."
- Every milestone must state which parts are **UNVERIFIED-ON-HARDWARE**. Default state of all native code is
  unverified.
- Failure reports must contain: device model, Android version + OEM skin, exact steps, expected vs actual,
  logcat. If a report is missing any of these, ask for them before theorising.
- **If an approach fails twice, stop and propose a different one.** Do not iterate a third time on the same idea.
- Work in small increments: one feature → one hardware verification cycle → next.
- **Before using any sensitive Android API, verify it against current official Android documentation** and state
  in the message which documented behaviour is being relied on. Assistant Android knowledge is stale by
  construction; background-activity-start rules, foreground-service types, overlay rules and accessibility
  policy tighten every release. Record each verification in `docs/android-behaviour-notes.md`.
- **Chargily has thin public documentation. Never write Chargily code from memory.** Ask the developer to paste
  the current docs.

---

## 1. Contract obligations that must never be violated

### Star accounting — Articles 5 & 6 (exact)

| Achievement | Stars |
|---|---|
| Memorization card correct, **first time** | 1 |
| Card in a **later review** | 0.5 |
| Correct review question | 2 |
| Completing the **full** daily session | +5 bonus |
| Two consecutive days without interruption (streak) | +3 |
| Weekly test | 10–40 by result |

Weekly test scale: `<50% → 10` · `50–74% → 20` · `75–89% → 30` · `≥90% → 40`.

All of these conditions must hold **jointly** before any star is granted (Art. 6):

1. Correct **on the first attempt**. No stars for a wrong answer, and none after the solution was revealed.
2. The card or question was **not already counted the same day**.
3. Time on card **exceeded** the minimum (default **1.5 s**). Rapid random tapping earns nothing.
4. The **daily star ceiling** is not exhausted (default **60 stars**).
5. Session bonus only on **100 %** of the day's tasks.
6. Streak bonus counted on **actual** consecutive days; the counter **resets on any missed day**.
7. **Unused balance expires at end of day.** It never carries over. No hoarding of play hours.
8. **Changing device date or time never produces balance.** Time comes from a protected reference.
9. The parent can always grant and deduct manually.

1 star = 1 minute of play (parent-adjustable). The appendix «آلية النجوم ووقت اللعب» (Art. 19) defines the
adjustable ranges and **is an inseparable part of the contract** — it is currently missing; do not guess ranges.

### Subscription — Article 7

- **The server is the source of truth for subscription state, not the device** (7.6).
- Local copy is a **signed** cache: 7-day offline window, revalidated from the server **every 24 h** when online.
- States, exactly five: `trial` · `active` · `grace` · `expired` · `refunded`.
- Trial: 7 days, all features, **once per device**. Monthly 1.000 DZD / 30 days. Annual 10.000 DZD / 365 days.
- **No auto-debit. No stored card. Renewal is a manual new payment** (7.4).
- Reminders 7 days then 2 days before expiry. **3-day grace period** after expiry, then free mode.
- Cancellation requires no action; renewal before expiry **adds** to the remainder.
- After trial/subscription ends: **blocking engine, stars and already-saved lessons keep working**; only
  **new AI lesson generation** stops. Never punish the child for the parent's payment delay (7.1).
- **Changing device date or time never extends a subscription** (7.6).

### Card data — Article 7.7 (absolute)

- The app and the server **never** touch card data: no card number, no expiry, no CVV, ever, in any form.
- Entry happens **exclusively** on Chargily's hosted page.
- The server stores **only**: transaction id, amount, status, timestamps.
- Every webhook signature is verified before acceptance; duplicates are rejected (idempotency).
- **No API keys in the app. Ever.** All AI and payment calls go through the Django server.
- A pull request that adds a card-shaped field anywhere is a contract breach, not a code-review comment.

### Payment placement — Article 7.2

The Android app **shows no price, no buy button, and no payment link.** Purchase happens on an independent
web page outside the app. This is what keeps the app off Google Play's billing-policy tripwire.

### Privacy — Article 14

- **No image storage.** The lesson image is processed inside the request and discarded. No server-side copy, in
  any case, for any duration. No temp files, no logs of image bytes, no S3, no cache.
- **No AI training on our data.** The provider must contractually not train on API inputs.
- **No personal identifiers:** no child full name, no child photo, no geolocation, no identifier that can
  determine the child's identity.
- **All child data is local only:** stars, tasks, progress, summaries.
- **Automatic deletion:** images and exercises are deleted from the device after the weekly test; only the
  summary and the results remain.
- Written privacy policy in **Arabic and English**, reflecting the above literally.

### Article 15.2 — the app must be fully usable *without* being the launcher

Google requires a closed test with **12 testers for 14 continuous days**. External testers will not hand over
their personal phones as a kiosk. Therefore: launcher mode and blocking are **opt-in during setup**, and the app
must be fully evaluable with both off. This is contractually committed and costs nothing extra.

### Play Store, as application code, not paperwork

A **prominent disclosure screen with explicit parental consent** must precede the AccessibilityService
permission request. Also required: DeviceAdmin justification, `QUERY_ALL_PACKAGES` justification,
`PACKAGE_USAGE_STATS` rationale.

### Acceptance — Article 11 (triggers final 30 % = 21.000 DZD)

1. All 12 blocking scenarios of Art. 12 pass. 2. Blocking response **≤ 2 s** from the game appearing.
3. ≥ **8 of 10** client-supplied clear lesson images produce sound summary + cards + matching questions.
4. A **full cycle** (Art. 4) with **no manual intervention**. 5. Stars conform to Art. 5 & 6 including ceiling and
daily expiry. 6. Weekly test + automatic deletion. 7. A **complete test-mode Chargily payment** through to in-app
activation. 8. Expiry behaviour per Art. 7. 9. Survives **device restart** with no parent action.
10. **No crash in a 30-minute continuous session.**

Measured on the **reference device**: Samsung (One UI), Android 12+, 4 GB+ RAM (Art. 13).

### Article 12 — out of scope, do not chase

Safe Mode · factory reset / Recovery · ADB / USB debugging · second user, guest mode, root. These are
impossible without Device Owner and are **excluded from acceptance and warranty**. Device Owner provisioning is
a separate paid service (Art. 17). Do not spend an hour on any of these four.

### Article 17 — out of scope entirely

iOS · Device Owner · the actual Play publishing and its fees · hosting and AI API costs · more than one child ·
cloud sync · multi-language · advanced analytics · badges / leaderboards / child comparison · Google Play
Billing · international payment · any gateway other than Chargily · automatic refunds · chargebacks ·
maintenance after the 30-day warranty. If a request lands here, say so and price it separately (two modification
rounds are included; anything beyond is a change order).

---

## 2. Fixed stack — do not propose alternatives

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart), Arabic RTL |
| State | Riverpod |
| Native | Kotlin — Launcher, AccessibilityService, UsageStatsManager, Overlay, DeviceAdmin |
| Backend | Django REST Framework |
| Server DB | PostgreSQL |
| Local DB | SQLite via Drift |
| Auth | JWT |
| Lesson processing | Contract names **Claude API (Vision + Text)**. Groq (free tier) during development, behind one swappable interface. **The acceptance run and the delivered configuration use Claude unless the client agrees in writing otherwise** (Art. 3 + Art. 14 no-training clause). |
| Notifications | flutter_local_notifications (local only — no FCM in scope) |
| Payments | Chargily Pay (CIB / EDAHABIA) |
| API docs | drf-spectacular |
| Deploy | Docker + Nginx + Gunicorn |

`minSdk 29` (Android 10, per Art. 13's low-resource device). `targetSdk` = whatever Play currently mandates for
new submissions — **verify before setting it**, do not copy a remembered number.

---

## 3. Architecture decisions

### AD-1 — Contract logic lives in pure Dart packages, outside Flutter

`packages/` holds plain Dart packages with **no Flutter, no `dart:io`, no plugins, no platform channels, and
no `DateTime.now()`**:

| Package | Owns | Contract |
|---|---|---|
| `nojoumi_stars` | earning decisions, ceiling, daily expiry, bonuses, weekly-test scale, parent adjustments, play-time consumption | Art. 5, 6 |
| `nojoumi_time` | trusted clock, monotonic guard, tamper detection, day boundaries | Art. 6.8, 7.6 |
| `nojoumi_subscription` | the five-state machine and the capability set it yields | Art. 7 |
| `nojoumi_sm2` | SM-2 spaced repetition scheduling | Art. 2, 4 |

Rationale: Articles 5, 6 and 7 are the most precise and most testable parts of the contract, and they are the
parts that cannot be checked on hardware by eye. They must be verifiable by `dart test` alone, on a machine with
no device attached. **Every number from the contract enters as injected configuration, never as a literal in a
widget or a DAO.**

### AD-2 — Time is a value, never a call

Nothing in `lib/` or `packages/` may call `DateTime.now()`, `clock.now()`, or read the system wall clock
directly. Time is obtained from `TrustedClock` and passed in as a `TrustedInstant`. Rules:

- Anchor = signed server timestamp + `SystemClock.elapsedRealtime()` offset.
- Trusted time is **forward-only**: it never moves backwards, and a wall clock behind the last known maximum
  raises a tamper flag.
- Reboot resets `elapsedRealtime`; a boot-id change forces re-anchoring.
- Day rollover and subscription windows use trusted time only. Art. 6.8 and Art. 7.6 are the same mechanism.

### AD-3 — Integer star units, never floating point

0.5 stars exist (Art. 5). Balances are stored as **integer `starUnits`, 1 star = 100 units**. Play time is
derived in **whole seconds**. No `double` anywhere in the ledger, no float accumulation, no rounding drift.

### AD-4 — The star ledger is append-only, and rejections are recorded

Every earning decision writes a row — awarded or rejected, with the rejection reason enum. Art. 6 has nine
joint conditions; when the client questions a star, the answer must be a query, not a guess. Balance is
derived from the ledger, never patched in place.

### AD-5 — The AI provider sits behind one interface, on the server only

`server/apps/ai/` exposes one interface (`LessonProcessor.process(image, ageBand) -> LessonResult`) with
`GroqProcessor` and `ClaudeProcessor` adapters selected by settings. The Flutter app knows nothing about
providers and holds no keys. The image is read from the request, passed to the provider, and dropped — it is
never written to disk, never logged, never cached (Art. 14).

### AD-6 — The server holds no child data

The server holds: parent account, subscription, transactions, activation codes, install ids, content-free usage
counters. It holds **no** images, summaries, cards, questions, stars, tasks, progress, or anything about the
child. If a feature seems to need child data server-side, that feature is wrong — raise it.

### AD-7 — Native modules are separate Gradle modules with one bridge

`native/` modules are independent Gradle libraries. Exactly one module (`native/bridge`) talks to Flutter via
MethodChannel/EventChannel. Blocking must keep working while the Flutter engine is dead — so enforcement logic
lives in Kotlin, and Dart is a client of it, never a dependency of it.

### AD-8 — Blocking has tiers, declared in advance

1. **Primary:** AccessibilityService window-state events → immediate enforcement.
2. **Secondary:** `UsageStatsManager` foreground poll as a safety net for events the service misses.
3. **Tertiary:** overlay block card as the visible surface (never an activity start from background).
   Foreground service keeps the process alive and re-arms after boot.
   If the primary tier fails on hardware, fall to the next tier rather than re-tuning the same one twice.

### AD-9 — Riverpod, unidirectional

Providers expose immutable state. Native events arrive as streams from `native/bridge` and are folded into
state. No business rule lives in a widget; widgets read providers and dispatch intents.

---

## 4. Conventions

- **Language:** all user-facing strings in `l10n/` ARB files, `ar` first. RTL is the default direction; test every
  screen in RTL, and never hardcode `EdgeInsets.only(left:)` — use `start`/`end`.
- **Naming:** Dart `lower_snake_case` files, `UpperCamelCase` types. Kotlin package root
  `dz.nojoumi.<module>`. Django apps are plural nouns.
- **Tests:** every rule in Articles 5, 6, 7 and the SM-2 scheduler gets a named test that quotes the article in
  the test name. Table-driven for the star table and the weekly-test scale, with boundary cases at
  49/50/74/75/89/90 %. Server: a test asserting no image bytes are persisted, and a test asserting webhook
  replay is rejected.
- **Commits:** `phase<N>: <area>: <what>`. Reference the article when the change is contract-driven.
- **ADRs:** any decision the contract does not dictate goes in `docs/decisions/` in one page.
- **Logging:** tag `NJM_<MODULE>` in Kotlin so logcat filtering is one command. **Never log image bytes, lesson
  content, or anything card-shaped.**
- **Secrets:** `.env` on the server only, `.env.example` committed. Nothing secret in `app/`, ever.

---

## 5. Repo layout

```
docs/            contract, obligations, checklists, android behaviour notes, play assets, ADRs
spike/           throwaway Kotlin-only blocking spike (day 2) — never imported by app/
packages/        pure Dart: nojoumi_stars, nojoumi_time, nojoumi_subscription, nojoumi_sm2
app/             Flutter app (core, data, domain, features, platform, l10n) + android/
native/          Kotlin modules: core, blocking, launcher, overlay, deviceadmin,
                 appinventory, playsession, bridge
server/          Django: config/ + apps/{accounts,lessons,ai,subscriptions,payments,devices,common}
tools/           lesson eval harness (the 10-image / 8-pass acceptance run), scripts
```

---

## 6. Definition of done for anything touching native code

1. Documented Android behaviour verified and noted in `docs/android-behaviour-notes.md`.
2. Builds.
3. Pure logic covered by unit tests where any exists.
4. A **verification script for the developer**: what to do, what should appear, how long it should take, which
   logcat tag to filter.
5. Marked **UNVERIFIED** until the developer reports back from hardware.
6. `docs/blocking-checklist.md` re-run if the change touches blocking, launcher, overlay, boot or DeviceAdmin.

---

## 7. Hard reminders

- No API keys in the app. Ever.
- Server is the truth for subscription state.
- Never touch card data.
- Lesson images never persist server-side.
- The app must work without being the launcher.
- Disclosure + consent before the accessibility request.
- Device time changes never grant stars or extend a subscription.
- Unused stars expire at end of day.
- Blocking and stars keep working after the subscription ends; only new AI generation stops.
- Do not chase the four Article 12 exclusions.
- Reference device is client-supplied; until it exists, nothing native is verified.
