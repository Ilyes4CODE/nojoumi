# Decisions — resolutions to the open questions

The developer authorised me to decide anything I could decide myself and start coding. This file records **what
I decided, on what authority, and what I am still waiting on.** Anything marked ⏳ still needs the client.

Authority order: contract → appendix «آلية النجوم ووقت اللعب» (Art. 19 makes it inseparable) → this file.

---

## What the appendix settled outright

The appendix arrived and answered four open questions with contractual force.

### D-1 · Parent-adjustable settings — exact defaults and ranges (was Q1)

Appendix §5. These are now the only legal values; `StarRules` validates against them and rejects out-of-range
configuration rather than clamping silently.

| Setting | Default | Range |
|---|---|---|
| Star value in minutes | 1 | 0.5 – 3 |
| Daily star ceiling | 60 stars | 20 – 150 |
| Minimum time on a card | 1.5 s | 1 – 5 s |
| Balance expiry | end of day | daily / **weekly** |
| Welcome balance at start | 10 stars | 0 – 30 |
| Daily session size | 12 cards | 5 – 30 |

Two of these are new information, not in the main contract:

- **Welcome balance (10 stars default).** A one-time grant so the child's first encounter with the app is not a
  locked door. Granted once at onboarding completion, written to the ledger as `welcomeGrant`, guarded by a flag
  so it can never be granted twice.
- **Weekly expiry is a legal option.** Art. 6 says unused balance expires at end of day; the appendix makes that
  the *default* and offers weekly as a parent choice. Read together: `expiryMode ∈ {daily, weekly}`,
  default `daily`. Art. 6's wording is the default, not a prohibition.

**Star value 0.5 min is legal ⇒ all accounting is in seconds.** 0.5 stars × 0.5 min = 15 seconds. See D-4.

### D-2 · There is only one daily cap (was Q2)

Art. 2 says the parent sets "daily play time and the value of one star in minutes". The appendix's list of what
the parent controls has **no daily-play-minutes setting** — it has a daily *star* ceiling.

**Resolved by construction:** the single source of truth is `dailyCeilingStarUnits`. Daily play minutes is the
same quantity in different units: `ceiling × starValue`. The parent UI shows both fields, linked — editing
either recomputes the other, and the underlying stored value is the ceiling in star units. Default 60 stars × 1
min = 60 minutes/day. Maximum expressible: 150 × 3 = 450 min/day.

No "surplus stars" case can arise, because there is no second cap to collide with. Nothing to ask the client.

### D-3 · The play counter stops instantly, with no grace period (was Q15)

Appendix §2, quoted: *"العدّاد يحسب وقت اللعب الفعلي فقط: يتوقف تلقائياً عند إطفاء الشاشة أو الخروج من اللعبة،
ويستأنف عند العودة. الطفل لا يخسر دقائق وهو لا يلعب."*

Immediate stop, immediate resume, no tolerance window. Implemented by measuring accumulated
foreground-seconds rather than by running a timer, so exactness is a property of the design, not of a threshold.

### D-4 · Half-stars are 30 seconds, not a rounded minute (was Q14)

Appendix §2 says the counter deducts "دقيقة بدقيقة", but the star value may be 0.5 min, so minute granularity is
not representable. Decision: **the ledger is in integer star units (1 star = 100 units) and playtime is in whole
seconds.** 0.5 stars at the default value = 30 s. The child's display shows `mm:ss`. No rounding, no drift.

### D-5 · Session completion means all tasks *attempted*, not all *correct* (new — the appendix forced this)

Art. 6 says the completion bonus is granted "only on completing 100% of the day's tasks". The appendix's worked
example (§3) grants the +5 bonus to a child who got **10 of 12 cards** and **4 of 5 questions** right.

Both are contractual, so "completing" must mean *presented and answered*, not *answered correctly*. This also
matches the appendix's stated design principle: *"النظام لا يعاقب الطفل على الخطأ، بل يكتفي بعدم مكافأته"* — the
system does not punish a mistake, it merely withholds the reward, and the wrong card returns in a later review.

**Implemented as:** `sessionComplete = every task instance for the day is in a terminal answered state`.
The appendix's example is encoded as a test (`appendix_worked_example_test.dart`) that must produce exactly
0 → 10 → 18 → 23 stars. If a future refactor breaks the client's own printed example, the test fails.

### D-6 · Memorization cards survive the weekly purge (was Q11)

Art. 4.8 / Art. 14 delete "الصور والتمارين" and retain "الملخص والنتائج". Cards are named in neither list.
The appendix says a failed card *"تعود تلقائيا في مراجعة لاحقة"* — it comes back in a later review — and SM-2
intervals exceed a week almost immediately.

**Decision: cards are retained. Purged weekly = lesson images (files + rows) + exercise/question items.**
Deleting cards would make the spaced-repetition system weekly-only and empty a headline feature of Art. 2.
⏳ Flagged for written client confirmation, but coding proceeds on this reading — it is the only one that leaves
the contract internally consistent.

---

## Decided by me, on the developer's authority

### D-7 · Blocked game icons are shown greyed with a price, not hidden (was Q4)

Art. 12 scenario 1 says "الأيقونة محجوبة". Art. 1 says the app is a motivation tool, not a prevention tool, and
the appendix's whole framing is *"النجمة هي العملة… الطفل لا يُمنع من اللعب، بل يكسبه"*. A hidden icon cannot
motivate; a visible, greyed icon showing "تحتاج ١٠ نجوم" is the motivation surface itself.
Tapping it routes to the tasks screen. ⏳ Client can veto; costs one screen to change.

### D-8 · Non-launcher mode exposes everything except blocking (was Q5)

The 12 Play testers (Art. 15.2) get: lesson capture, tasks, stars, SM-2, weekly test, parent dashboard,
subscription — with an in-app home screen instead of the system one. Blocking and launcher are one opt-in step
in the setup wizard. Checklist scenario 1 is N/A in this mode and marked as such.

### D-9 · Any app can be marked blocked, and the UI calls them "ألعاب وتطبيقات مشتّتة" (was Q6)

Art. 2 says "التطبيقات المصنّفة كـألعاب", but the mechanism is package-name-based and indifferent to category —
blocking TikTok costs zero extra lines. Restricting the picker to Play's "game" category would be an artificial
limitation that hurts the actual use case in Algeria. The picker defaults to showing games first, with a toggle
to show all apps. Lunio, Settings, Phone, Messages and the current IME are permanently unblockable
(a hard allowlist — a parental control app that can lock the parent out of Settings is a bricked phone).

### D-10 · PIN recovery goes through the parent's server account (was Q7)

The PIN is stored locally as a salted hash (never recoverable). Reset requires authenticating to the parent's
JWT account and receiving a signed reset token. Offline forgotten PIN = no reset until the phone is online; this
is the correct trade-off, since a locally-resettable PIN is not a PIN. Documented in the parent guide.

### D-11 · Grade level, not age; sent per-request, never stored (was Q8)

The app collects **school grade** (e.g. «السنة الرابعة ابتدائي») rather than a birth date or age in years. It
is a pedagogical parameter, it is not a personal identifier under Art. 14, and it is sent in the lesson-processing
request and never persisted server-side. The server logs a content-free usage record only.

### D-12 · Uninstall protection is warn + detect + react, and the client must be told (was risk 2)

Verified in the framework sources (see `android-behaviour-notes.md` V5): `setUninstallBlocked` requires device
owner, which Art. 17 excludes. A plain active admin gets a **warning string** (`onDisableRequested`) and an
**after-the-fact callback** (`onDisabled`) — no veto. The system's own refusal to uninstall an active admin is
the real protection, and it is defeatable by deactivating the admin first.

**Implemented as:** strongly-worded Arabic warning on `onDisableRequested`; on `onDisabled`, immediately
re-assert what we still can, mark protection as degraded, and surface it on the parent's dashboard and via a
local notification. ⏳ **This gap must be put to the client in writing before the Phase 7 acceptance run**, since
Art. 12 scenario 9 says *ممنوع* and Art. 12's four exclusions do not cover it.

### D-13 · Weekly test runs on a fixed weekday, default Friday (was Q12)

A fixed weekday is predictable for an Algerian family and makes the purge auditable; "7 days from the first
lesson" drifts and produces a different boundary per child. Default **Friday**, parent-adjustable.
If fewer than 5 cards exist for the week, the test is skipped, no stars are awarded, and no purge runs —
a test on 2 cards would hand out 10–40 stars for nothing. ⏳ Client may prefer a different weekday.

### D-14 · 0 % correct still awards 10 stars — implemented as written (was Q13)

Art. 5's scale says "أقل من 50% ← 10". Implemented literally. It is defensible under the appendix's
no-punishment principle, and it is not my call to soften a signed number. ⏳ Flagged; one constant to change.

### D-15 · Questions per day is its own setting, default 5 (new gap)

The appendix fixes the daily session size at 12 cards (range 5–30) but never states the number of review
questions; its worked example uses 5. Decision: `dailyQuestionCount`, default **5**, range 0–15, parent-adjustable
— rather than deriving it from the card count by an invented formula. ⏳ Confirm the default.

### D-16 · The parent can pause play (new — appendix §4)

Appendix §4 gives the parent "سلطة… منح أو خصم النجوم يدوياً في أي وقت (مكافأة على سلوك جيد، أو إيقاف مؤقت)" —
"or a temporary pause". This is not in the main contract. Implemented as a parent-controlled `playPaused` flag
that blocks consumption without destroying the balance, PIN-protected, visible to the child as
«اللعب موقوف مؤقتاً من طرف الوالد» so it never reads as a bug.

### D-17 · `specialUse` foreground service, not `systemExempted`

See `android-behaviour-notes.md` V4. We would qualify for `systemExempted` as a device admin, but it is
documented as reserved for system apps and would raise our Play rejection risk on an app that already carries
two rejection-prone permissions. `specialUse` is also not on the Android 15 `BOOT_COMPLETED` prohibition list,
which scenario 11 needs.

### D-38 · The weekly purge erases content but keeps the row · 2026-08-21

Article 14: *"تُحذف الصور والتمارين من الجهاز بعد الاختبار الأسبوعي، ويبقى الملخّص والنتائج."*

Two things are deleted, and they are deleted differently, because "delete" means something different for a file
than for a row that other rows point at.

**Images — the file and the row both go.** A row pointing at a path that no longer exists is not a deletion, and
neither is a file left on disk because only the row was removed. The file deletion happens **outside** the
transaction: a file cannot be rolled back, so doing it inside one would let the database disagree with the disk
in the one direction that matters — rows claiming an image exists when it does not. If a file cannot be deleted,
its row is left in place so the next purge retries it rather than recording a deletion that never happened.

**Exercises — the content is erased, the row is tombstoned.** `prompt` becomes empty, `choicesJson` becomes
`[]`, `correctIndex` becomes 0, and `purgedAtMs` is set. The alternative was dropping the rows outright, and the
reason not to is narrow but real: `star_ledger.sourceRef` and `attempts.targetId` hold question ids, and reusing
an id later would make a historical ledger row point at a different question than the one it paid for.

**The distinction that matters, and the test that enforces it:** a tombstone that still reads back the question
has not been deleted in any sense the client would accept. So the test does not merely check the flag — it
queries the table for the seeded prompt text and requires zero rows. Tombstoning is a schema decision; erasure
is the contractual one.

**Kept, deliberately:** the lesson row and its summary (Art. 14 names both), every weekly-test result, and the
**memorization cards** — D-6, because deleting those would make spaced repetition weekly-only and empty a
headline feature of Article 2.

**And the results stay explainable without the questions.** `weekly_test_items.promptSnapshot` copies the prompt
at the moment it is answered, precisely because the question is erased minutes later. Without it, a client
disputing a score would be asking about questions that no longer exist anywhere.

**The ordering is the contract's.** Article 4.8 deletes *after* the test, so `finish()` scores, pays Article 5's
scale, and only then purges. A crash between the two must never cost the child a week's work and a week's stars
at once.

### D-37 · ✅ The Android build works — and it needed one fix that had nothing to do with the rename · 2026-08-21

After the Lunio rename the whole Flutter project was verified, and **the Android build was attempted for the
first time in the project's life.** It failed, and the failure was worth finding:

```
Execution failed for task ':app:checkDebugAarMetadata'.
> Dependency ':flutter_local_notifications' requires core library desugaring to be enabled for :app.
```

**This was latent, not caused by the rename.** `flutter_local_notifications` has been in `pubspec.yaml` since the
scaffold, and this would have stopped the very first `flutter run` whatever the app was called. It was invisible
because nothing had ever asked Gradle to assemble anything — `flutter analyze` and `flutter test` never touch the
Android toolchain. **A dependency that compiles in Dart is not a dependency that builds on Android**, and the
gap between those two facts was two weeks wide here.

**The fix, verified against the plugin's own README on 2026-08-21 rather than written from memory:**

```kotlin
compileOptions {
    isCoreLibraryDesugaringEnabled = true
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

The README specifies `desugar_jdk_libs:2.1.4`, AGP **8.11.1 minimum**, and `compileSdk` **35 minimum**. Ours were
already AGP 8.11.1 exactly, compileSdk 36 and Java 17, so only the two blocks above were missing.

**What now builds:**

| Artefact | Result |
|---|---|
| `flutter build apk --debug` | ✅ `app-debug.apk`, 161 MB (debug, unshrunk) |
| `flutter build appbundle --release` | ✅ `app-release.aab`, **43.6 MB** |
| Merged manifest | `package="dz.lunio"` · `android:label="Lunio"` · `minSdkVersion=29` · `targetSdkVersion=36` |

**This also closes the half of D-31 that was never tested.** That decision renamed the working directory because
the Arabic path broke Dart code generation, and warned that "Gradle and the Android build are very likely next"
— the risk was removed by construction but never verified. It is verified now: both builds succeed from
`C:\Users\Ilyes\Desktop\nojoumi`, an ASCII path. The folder keeps its old name at the developer's request, which
is fine — ASCII is the requirement, not the word.

**Still not done, and both are Article 15.4 / Article 19 deliverables:**

- **The release build is signed with the debug keys.** A real upload keystore is required before the first Play
  submission. It is handed to the client directly, never committed — `.gitignore` already refuses `*.jks`,
  `*.keystore` and `key.properties`, because a leaked upload key cannot be rotated on Play.
- **43.6 MB is large for a market where storage is scarce.** Most of it is the Flutter engine across three ABIs.
  `--split-per-abi` or a Play App Bundle delivery cuts it substantially, and the seven illustration assets have
  not landed yet. Worth measuring once, not worth optimising blind.

**And the build still proves nothing about behaviour.** It compiles and it packages. Whether the clock channel
answers, whether the setup wizard is legible, whether blocking works — all of that is
`docs/hardware-verification.md`, and all of it is UNVERIFIED until the reference device exists.

### D-36 · ✅ The app was renamed Nojoumi → Lunio · 2026-08-21

The client asked for the name change and confirmed it should happen immediately. Executed the same day, in one
pass, across 68 files and five directories. All 410 tests green afterwards.

**Why it had to be now, and not later.** `applicationId` is the one identifier Android never lets you change:
after the first upload to Google Play it is permanent, and a different one is a *different app* — zero installs,
zero reviews, and the twelve testers of Article 15.2 starting their fourteen days again. Nothing had been
published yet, so this was the cheapest moment the rename would ever have. Doing it a week into the closed test
would have cost the whole test.

**What changed:**

| Layer | Before | After |
|---|---|---|
| Android application id and namespace | `dz.nojoumi` | `dz.lunio` |
| Android display label | `nojoumi` | `Lunio` |
| Kotlin package and file | `dz.nojoumi.NojoumiClock` | `dz.lunio.LunioClock` |
| Logcat tags | `NJM_*` | `LNO_*` |
| Dart app package | `nojoumi` | `lunio` |
| The four pure packages | `nojoumi_stars` … | `lunio_stars` … |
| Dart types | `NojoumiTheme`, `NojoumiDatabase`, `NojoumiApp`, `NojoumiSpacing`, `NojoumiRadius` | `Lunio*` |
| Local database file | `nojoumi.sqlite` | `lunio.sqlite` |
| Django loggers and API title | `nojoumi.*` | `lunio.*` |
| `appName`, both locales | «نجومي» / `Nojoumi` | `Lunio` |

**The Arabic name is the Latin wordmark, deliberately.** A brand mark is not normally transliterated, and the
client's own mockups draw the Latin `LUNIO` logo on every Arabic screen. So `appName` is `Lunio` in `app_ar.arb`
as well, and the Arabic strings that used to read «إعداد نجومي» now read «إعداد Lunio». This is one ARB value in
each locale if the client later prefers «لونيو».

**The database filename changed, and that is free exactly once.** `lunio.sqlite` is a different file from
`nojoumi.sqlite`, so any install carrying the old name would appear to lose all its data. There are no installs
— nothing has shipped — so no migration was written. **If the name ever changes again after a release, that is
no longer true** and a migration becomes mandatory.

**Two things left undone, on purpose:**

1. **The working directory is still `C:\Users\Ilyes\Desktop\nojoumi`.** Renaming it invalidates every absolute
   path cached in `.dart_tool` (the D-31 lesson) and moves the developer's workspace root mid-session. It is
   cosmetic, it is theirs to do, and `lunio` is ASCII so D-31 does not recur. The steps are the same four from
   the resume prompt: delete `.dart_tool`, `pub get`, `build_runner`, run the suites.
2. **`docs/contract.pdf` still names نجومي**, and it is a signed document that is not ours to edit. The rename
   needs one written line from the client, and it counts against the two modification rounds Article 17
   includes.

**One thing to verify before the first Play upload, and it is not a code question:** `Lunio` is an existing
trademark of an ad-fraud-prevention company (lunio.ai). Whether that matters for an Algerian children's app on
Play is a question for the client and, if they want certainty, for a trademark search at INAPI. It is being
flagged because `dz.lunio` becomes permanent at that upload, and because a Play listing name collision is
resolved by Google in favour of whoever registered first.

### D-35 · ✅ Chargily integrated from live documentation, not from memory · 2026-08-18

docs/CONVENTIONS.md forbids writing Chargily code from memory, and decisions.md listed five facts as blocked on the client
(Art. 7.8). The developer supplied **keys**, which unblock none of them — a key does not reveal a signature
algorithm or a status vocabulary. So the documentation was fetched directly and every fact below is quoted with
the URL it came from, on **2026-08-18**. Re-verify before Phase 7: a payment gateway is exactly the kind of API
that renames a field between minor releases.

| Fact | Value | Source |
|---|---|---|
| Test base URL | `https://pay.chargily.net/test/api/v2` | quick guide, create-a-checkout |
| Live base URL | `https://pay.chargily.net/api/v2` | same |
| Auth | `Authorization: Bearer <secret key>` | same |
| Create checkout | `POST {base}/checkouts` | same |
| Signature header | **`signature`** | webhooks |
| Signature algorithm | **HMAC-SHA256 of the raw body, hex-encoded**, keyed with the API secret key | webhooks |
| Webhook envelope | `{id, entity, livemode, type, data, created_at, updated_at}` | webhooks |
| Event id | root-level **`id`** | webhooks |
| Checkout status | *"Can be one of"* `pending` · `processing` · `paid` · `failed` · `canceled` | checkout-object reference |

**Three decisions the documentation forced:**

1. **The decision comes from `data.status`, not from the event `type`.** The docs show `checkout.paid`,
   `checkout.failed` and `checkout.canceled` but never claim that list is complete, while the status field *is*
   published exhaustively. So `type` is used only to confirm the event concerns a checkout at all, and an event
   about anything else is recorded and refused.
2. **`processing` maps to PENDING, not PAID.** Money in flight is not money received; activating a subscription
   on a payment that may still fail is the one error that costs the client real money.
3. **The mode is an explicit setting, never inferred from the key prefix.** `CHARGILY_LIVE_MODE` decides the
   base URL. A test key on the live endpoint and a live key on the test endpoint both fail confusingly, and
   making the mode deliberate turns that into a one-line configuration review.

**The earlier draft had a real bug this work found.** `_apply` read `payload["status"]` and `payload["id"]` from
the **root** — the flat shape it was written against. Against the documented envelope that finds nothing:
`payload["id"]` is the *event* id, not the checkout's, and the status lives under `data`. It was never
exercised because `verify_signature` returned `False` and nothing ever reached it. **A refusal that is never
lifted hides everything behind it**, which is worth remembering the next time a module is stubbed out.

**What changed in the tests:** they no longer mock `verify_signature`. Each request now carries a real
HMAC-SHA256 of its own body, so the suite exercises the one line standing between this endpoint and a free
subscription. Added coverage: no header, wrong signature, a signature from a different secret, a tampered body,
and an empty configured secret — every one of which must reject.

**Still open, and not fixable by code:**

- **Q19 — a public HTTPS URL for the webhook.** `CHARGILY_WEBHOOK_URL` is empty, so today only the checkout half
  can be exercised end to end. Article 19 commits the client to a VPS before Phase 7, while the webhook is a
  Phase 6 need. Until then: a tunnel, or the acceptance run slips.
- **Refunds.** Article 17 excludes automatic refunds and chargebacks. `TransactionStatus.REFUNDED` exists and is
  set by the client in the admin dashboard (Art. 7.5); no webhook path writes it, deliberately.

**Key hygiene, recorded because it happened.** The test-mode keys were pasted into a chat transcript when they
were handed over. They are in `server/.env` only — gitignored, absent from `.env.example`, absent from every
commit — and the developer was asked to rotate both. `CHARGILY_WEBHOOK_SECRET` was removed entirely: the
documentation is explicit that the webhook is signed with the API secret key, so a second secret was a setting
that could only ever be wrong.

### D-34 · The card asks for a commitment *before* it shows the answer · 2026-08-18

Article 6.1 grants a star only for an answer that is correct **on the first attempt**, and adds: *"ولا بعد كشف
الحل"* — none after the solution was revealed.

The ordinary flashcard flow is: show the front → **أظهر الجواب** → the child says whether they knew it. Written
that way, **every card is revealed before it is answered**, so either `solutionRevealed` is always true and no
card can ever earn a star, or it is never reported and Article 6.1 becomes text with no mechanism behind it.
Neither is acceptable, and the second is the one that happens by default.

**The flow that ships instead.** The front of the card carries three actions, and the child commits before
seeing anything:

| Action | `correct` | `solutionRevealed` | Article 5 |
|---|---|---|---|
| **أعرفها** | true | false | 1 star, or 0.5 on a later review |
| **لم أعرفها** | false | false | nothing; SM-2 counts a lapse and brings the card back |
| **أظهر الجواب** | false | **true** | nothing — this is the reveal Article 6.1 names |

The back is displayed after any of the three, because learning the answer is the point of the exercise. **The
stopwatch stops at the moment of choice**, so the seconds spent reading the answer never count toward Article
6.3's minimum — otherwise a child could satisfy the minimum by idling on the feedback screen.

Two consequences worth stating plainly:

- **"أظهر الجواب" is offered prominently, not hidden.** A child who is stuck needs an exit that is not a lie.
  Making the honest option costly but easy is the whole design; making it hard would train them to click
  "أعرفها" and defeat both the stars and the scheduler.
- **A card is still self-reported, and that is inherent.** Nothing on a phone can verify that a child who
  pressed "أعرفها" truly recalled it. What bounds the abuse is already in the contract: the daily ceiling
  (Art. 6.4), the minimum time per card (Art. 6.3), the same-day dedupe (Art. 6.2), and above all the weekly
  test, which is not self-reported. Review questions are objectively graded, which is why Article 5 pays double
  for them.

`session_screen_test.dart` pins all of this, so a future redesign that quietly restores the reveal-first flow
fails the build rather than the contract.

### D-33 · Widget tests use provider overrides, never the database · 2026-08-18

The first widget test wired the real Drift database into `testWidgets` and **every test hung for ten minutes**.
The cause is structural, not a bug in any of the parts: `testWidgets` runs its body inside a fake-async zone,
while the database — created in `setUp`, in the real zone — completes its futures in real time. `pumpAndSettle`
therefore spins fake time forever waiting on a query that is making no progress. Wrapping the pumps in
`tester.runAsync` did not fix it either, which is where docs/CONVENTIONS.md's "if an approach fails twice, stop" applied.

**The split that replaced it, and it is a better design than the one that failed:**

- **The database is tested where real async works** — plain `test()` bodies. 15 schema tests, 14 star-repository
  tests, 10 clock-repository tests, 5 settings-defaults tests. These touch real SQLite and prove the persistence
  guarantees: Article 6.2's dedupe row living or dying with its award, AD-4's ledger staying the authority for
  the balance, the forward-only high-water mark surviving a restart.
- **The widget layer is tested against fixed values** — `test/support/widget_harness.dart` pumps a screen with
  `settingsProvider`, `starRulesProvider`, `todayProgressProvider` and `clockIsTrustworthyProvider` overridden.
  No I/O, no clock, and the whole file runs in about a second.

The seam that makes this work is AD-9: providers expose immutable state and widgets only read it. A widget that
needed a repository to render would not be testable this way — so if that ever becomes hard, the widget is
wrong, not the test.

**What the widget tests are actually for.** Each one asserts something that would otherwise be caught only by
looking at the reference device, which does not exist yet:

- consent starts unchecked and the accessibility-backed switches are unreachable until it is given;
- declining is a visible, equal path, so the 12 Play testers of Art. 15.2 can finish setup without ever granting
  accessibility;
- the disclosure still contains its **negative** half ("لا يقرأ Lunio محتوى الشاشة…"), which is the half a
  rewrite loses and the half Play reads;
- Art. 7.2 — the child's screen renders no price, no purchase word and no plan amount;
- Art. 6.8 — an untrusted clock is explained in the child's language *and* states that existing stars are safe,
  so the rule does not read as a punishment or as a bug;
- half stars render as "3.5" and whole ones as "4", not "4.0";
- the tree is right-to-left.

### D-32 · The clock MethodChannel lives in the app module, not `native/bridge` · 2026-08-18

AD-7 puts native code in independent Gradle modules with `native/bridge` owning every channel, because blocking
has to keep working while the Flutter engine is dead. The clock is the one piece where that reasoning does not
apply: it has no lifecycle, enforces nothing, and exists only to answer a Dart question. Scaffolding a Gradle
module for it today would add build risk with no device to verify it on.

`LunioClock.kt` therefore sits in `app/android/app/src/main/kotlin/dz/lunio/` and is registered in
`MainActivity.configureFlutterEngine`. **It moves into `native/bridge` when that module is scaffolded**, together
with the blocking channels — this is a sequencing decision, not an exception to AD-7.

### D-31 · ✅ RESOLVED: the Arabic project folder broke Dart code generation on Windows · fixed 2026-08-18

**The symptom.** `dart run build_runner build` failed in this repository with:

```
Error: Unable to write file: c:\users\ilyes\desktop\?????\app\.dart_tool\build\entrypoint\build.dart.aot
```

The AOT compiler mangled «Lunio» to `?????` and could not write its snapshot. Proven by elimination: the
identical sources built successfully in an ASCII path (14 outputs, 34 s), and a Windows junction from an ASCII
path did **not** help — the toolchain resolved the junction back to the real name.

**The fix, applied 2026-08-18: the working directory was renamed to ASCII** — `C:\Users\Ilyes\Desktop\lunio`.
The Arabic name lives where it belongs: the app's display name, the store listing, and every user-facing
string. It never needed to be in the filesystem path.

**Verified from the new path, in this order:**

1. `.dart_tool` deleted in `app/` and in all four packages — it caches absolute paths, so the stale ones had to go.
2. `flutter pub get` in `app/`, `dart pub get` in the four packages — all resolved.
3. `dart run build_runner build` — **`Built with build_runner/aot in 33s; wrote 21 outputs.`** This is the exact
   command that failed before; it now succeeds from the real project path with no scratch directory involved.
4. Full test sweep from the new path: `lunio_time` 21 · `lunio_stars` 89 · `lunio_subscription` 42 ·
   `lunio_sm2` 46 · `app` 16 · `server` 81. All green.

**The workaround is gone.** Copying sources to a scratch ASCII directory, building there, and copying
`database.g.dart` back is no longer needed and must not be reintroduced — if codegen ever fails again, that is a
new fault to diagnose, not a reason to resurrect a fragile copy step.

**Two notes carried forward:**

- **`--delete-conflicting-outputs` is now a no-op.** This build_runner emits
  `W These options have been removed and were ignored: --delete-conflicting-outputs`. Harmless, but drop it from
  scripts and docs so it does not read as a working safeguard that is silently doing nothing.
- **The Gradle/Android half of the original worry is untested.** The rename was recommended partly because the
  Android toolchain handles non-ASCII paths badly and the signed AAB is a contractual deliverable (Art. 15.4,
  Art. 19). No Android build has been run from the new path yet, so that risk is *removed by construction*, not
  *verified*. The shorter path also buys headroom against Windows' 260-character limit, which Gradle build trees
  reach easily.

### D-29 · Gemini requested by the client — built, gated, and NOT yet in use · 2026-08-17

The client asked to switch from Groq to Gemini. Two things had to be said before any code:

**1. This is the second deviation from Article 3**, which names *Claude API (Vision + Text)*. Groq was already a
deviation, justified as development-only. Gemini would be a third provider on a clause that names one.
⏳ **Needs one written line from the client:** "أوافق على استعمال Gemini API بدلاً من Claude API المذكور في المادة 3".

**2. Gemini's free tier breaches Article 14 outright.** From Google's Gemini API terms, quoted:

> Unpaid Services: *"Google uses the content you submit to the Services and any generated responses to provide,
> improve, and develop Google products and services"* · *"Human reviewers may read, annotate, and process your
> API input and output."*
> Paid Services: *"Google doesn't use your prompts or responses to improve our products."*

Article 14 forbids a provider that trains on inputs, and human reviewers reading a child's schoolbook pages is
worse still for an app enrolled in Designed for Families (Art. 15.3). **Intent is irrelevant here**: "we are only
checking accuracy, not training" describes *our* use, not Google's, and Google's terms are the binding fact.

`GeminiProcessor` therefore refuses to start unless `GEMINI_BILLING_ENABLED=1`. The flag cannot verify Google's
billing state — it forces a human to assert in configuration that the contractual condition is met.

**Findings from probing the API (all measured, none remembered):**

- The supplied credential starts with `AQ.` not `AIza` — an ephemeral/OAuth token, not a durable API key. It
  authenticates today and will expire without warning. A billed project must issue a real key.
- **`gemini-2.5-flash` is retired**: Google's own 404 says *"no longer available to new users… use
  models/gemini-3.6-flash"*. Exactly why the adapter refuses to boot without an explicit model name.
- On `gemini-3.6-flash`: `thinkingConfig: {thinkingBudget: 0}` returns **400**, and `thinkingLevel` is not a field
  in v1beta. Thinking cannot be switched off, and costs 400–650 tokens per page. Unlike Groq it is reported
  separately (`thoughtsTokenCount`), so it is a cost rather than a truncation risk — but `maxOutputTokens` carries
  1024 tokens of headroom because the interaction is not documented clearly enough to bet a truncated lesson on.
- **`responseSchema` works and is strictly better than Groq's `json_object`**: the shape is enforced server-side,
  so malformed output becomes impossible rather than unlikely — and it *reduced* output tokens (154 vs 280).

**Current state: `LESSON_PROCESSOR=groq`.** The developer reverted to Groq pending payment, which is the correct
call — Groq's agreement satisfies Art. 14 (D-27) and Gemini's free tier does not.

### D-30 · The acceptance image set does not match the contract — 22 files, not 10

Article 19 obliges the client to supply **ten** sample lesson images, and Article 11.3 measures "8 of 10". What
arrived is **22 images** (the developer said 19; the folder holds 22, plus a zip that turned out to contain the
same 22 files, not higher-resolution originals).

Two problems, both worth settling in writing before the acceptance run counts:

1. **Which ten are the measurement set?** Measuring on 22 is not what the contract says. Either the client
   designates 10, or both parties agree the criterion applies pro rata to the whole set — 80 % of 22 is 17.6,
   so **18 of 22**. The pro-rata reading is more demanding and more honest; either is defensible, neither should
   be assumed.
2. **All 22 arrived via WhatsApp, i.e. recompressed and downscaled.** Art. 11.3 measures on "صور دروس **واضحة**"
   and Art. 18 ties result quality to photo quality. Measuring the criterion on WhatsApp-compressed copies
   understates the pipeline and is unfair to both sides. Ask for the originals over a channel that does not
   recompress — a zip of the camera files, Drive, or email attachments.

Until both are settled, any number this run produces is **evidence, not the Article 11.3 result.**

### D-27 · Article 14's no-training clause is satisfied by Groq — verified 2026-08-16

Groq's public Terms of Use and Privacy Policy both punt to other documents, but the **Groq Services Agreement**
answers it directly: *"Groq is not permitted to use Inputs or Outputs for training or fine-tuning any AI Model
Services or other models"*, and *"Groq will never access Customer Data for training purposes."* The GroqCloud
data documentation adds: *"By default, Groq does not retain customer data for inference requests"*, with
Zero Data Retention available to **all customers**, not only enterprise tiers.

**Correction to an earlier note in D-23:** I had flagged "two providers in the chain" because Qwen is Alibaba's
model. That was wrong. Groq serves open weights on its own infrastructure, so Alibaba never receives the data.
One provider, one agreement, and it is explicit.

**Action taken:** the developer enables Zero Data Retention in the Groq console, removing even the 30-day
abuse-investigation retention. Art. 14 deserves that posture once real lesson images are involved.

### D-28 · Three provider bugs found by running real pages, all fixed

Running four real Algerian schoolbook pages surfaced three defects that no unit test would have caught, because
they only exist in the interaction with a live provider:

1. **`max_tokens` was never set.** Groq rejects a request whose *estimated* total exceeds the tokens-per-minute
   ceiling, and with no cap the estimate assumes a large completion — so ordinary pages returned HTTP 400. The
   budget is now sized from the requested card and question counts.
2. **Qwen3.6 is a reasoning model, and reasoning was pure cost.** Left alone it emitted ~3 900 characters of
   hidden chain-of-thought before answering, truncating the JSON to 3 cards and 0 questions. Measured with
   `reasoning_effort: "none"`: **714 completion tokens instead of 1 768, for byte-identical output** — same 8
   cards, same 4 questions. Reasoning buys nothing when the task is transcribing a page into a fixed schema.
3. **No retry or pacing.** The free tier allows 8 000 tokens/minute and one page costs ~1 900 prompt tokens, so
   an unpaced run throttled itself. `LessonProcessingError` now carries `retry_after_seconds`, parsed from
   `Retry-After` and Groq's own reset headers, and the eval harness backs off instead of reporting a rate limit
   as a failed image. Reporting "1 of 10 succeeded" when nine were merely throttled would misreport Art. 11.3.

After the fixes: **4 of 4 structurally sound, ~2 seconds per page.**

### D-25 · The parent account is identified by email; phone is optional

Art. 7.3 says the activation code is "displayed on the page and sent to them" without naming a channel — open
question Q17, still unanswered. Rather than block the whole server on it, the account is built on **email +
password**, which needs no SMS gateway, no per-message cost, and no phone-verification flow — none of which are
in scope. `ParentUser.phone` exists, is optional, and is never used for authentication, so the client can switch
the code-delivery channel to SMS later without a migration or a redesign.

A test asserts the parent model carries **no** field about the child (name, birth date, age, grade, school,
photo, location, stars, progress) and that `/api/accounts/me/` returns exactly four fields. Art. 14 and AD-6 as
a build failure rather than a review comment.

### D-26 · Password validators were missing, and a test caught it

`AUTH_PASSWORD_VALIDATORS` was absent from settings, and Django applies **no** validators at all when the setting
is absent — so `"1234"` was accepted as a parent password until a test failed. Now configured with the four
standard validators and an 8-character minimum.

This matters more here than in an ordinary app: the parent's password guards the subscription *and* is the
recovery path for the parent PIN (D-10). A child who guesses it unlocks the phone, which defeats the entire
blocking model. The gap existed because a missing Django setting fails silently in the permissive direction.

### D-23 · `GROQ_MODEL=qwen/qwen3.6-27b` — measured, not remembered · 2026-08-15

The developer asked me to pick a Groq model "professionally". Picking one from memory would have been the
opposite of professional, so it was established empirically, in three steps.

**Step 1 — what does this account actually have?** `GET /openai/v1/models` returned 15 models. Then each
plausible candidate was sent a real image. Result:

| Model | Response to an image |
|---|---|
| `qwen/qwen3.6-27b` | ✅ accepted — the only one |
| `openai/gpt-oss-120b` / `-20b` / `-safeguard-20b` | ❌ `content must be a string` — text only |
| `llama-3.3-70b-versatile`, `llama-3.1-8b-instant` | ❌ text only |
| `groq/compound`, `groq/compound-mini` | ❌ text only |
| `allam-2-7b` (SDAIA, Arabic) | ❌ text only, 4 096 ctx |
| `whisper-large-v3`, `orpheus-*` | audio, not applicable |
| `meta-llama/llama-4-scout…`, `…maverick…` | ❌ 404 — **not available to this account** |
| `llama-3.2-11b-vision-preview` | ❌ **`model_decommissioned`** |

**That last row is the whole argument for this policy.** `llama-3.2-11b-vision-preview` is the model a
from-memory answer would most likely have produced, and it is retired. `GroqProcessor` refusing to start without
an explicit `GROQ_MODEL` turned a silent delivery-day failure into a config error on day one. Keep that refusal.

**Step 2 — end-to-end verification** with the exact request shape the adapter sends: a 640×360 JPEG,
`response_format: {"type": "json_object"}`, the Arabic system prompt. Result: **HTTP 200**, ~1.9 s, 880 prompt +
765 completion tokens, and valid JSON with exactly the four keys the parser expects
(`readable`, `summary`, `cards`, `questions`), in Arabic.

**Step 3 — what this does *not* prove.** The test image carried **Latin** text, because rendering Arabic needs a
shaping library. So the plumbing is proven and **Arabic printed-schoolbook OCR quality is not**. Article 11.3's
8-of-10 is a question about Arabic on a curved page in household light, and it is answered only by the
developer's own photographs (tomorrow) and then by the client's ten.

**Consequences to carry forward:**

- Article 3 names Claude, and this finding strengthens that: a 27B general model reading Arabic schoolbook print
  is a weaker bet than Claude Vision for the acceptance criterion. Groq stays a development convenience.
- **Article 14 is still unverified for Groq.** The no-training obligation requires reading Groq's terms for this
  tier as text. Until then: the developer's own photographs only, never a real child's schoolbook.
- The model is served by Groq but owned by Alibaba Cloud — a second provider in the chain, which the Art. 14
  no-training review must cover, not just Groq.

### D-24 · ✅ CLOSED: card and question counts are threaded, not hardcoded · confirmed 2026-08-18

The original gap: `GroqProcessor.process` asked for 12 cards and 5 questions as literals, contradicting the
appendix, where the session size is parent-adjustable (5–30) and the question count is its own setting (D-15).
Exactly the class of mistake AD-1 exists to prevent — a contract number living as a literal.

**Verified closed by reading the whole chain, 2026-08-18:**

- `LessonProcessor.process` declares `card_count` and `question_count` as **required keyword arguments with no
  default**, deliberately, so no adapter can quietly reintroduce its own number.
- `GroqProcessor` and `GeminiProcessor` pass them to `user_prompt(cards=…, questions=…)` and size the token
  budget from them via `_completion_budget(card_count, question_count)`.
- `ProcessLessonView` reads them from the validated request.
- `LessonRequestSerializer` bounds them to the contractual ranges — `card_count` 5–30, `question_count` 0–15 —
  so an out-of-range value is a 400, not a silent clamp. Its `default=12` / `default=5` are the appendix's own
  defaults, and they apply only when the client omits the field; the app always sends the parent's stored values.
- `tools/eval/run_eval.py` takes `--cards` / `--questions` and checks the returned counts against what it asked
  for, so an Article 11.3 run measures the configured session, not a fixed twelve.

Nothing left to do here.

### D-22 · SM-2, with the grade derived rather than asked

The contract requires "نظام مراجعة متباعدة يعيد عرض البطاقات الضعيفة تلقائياً" (Art. 2) but names no algorithm.
Choice: **SM-2**, every parameter injectable, in `packages/lunio_sm2`.

Two adaptations, both forced by the contract rather than by taste:

1. **The child is never asked to grade themselves.** Classic SM-2 wants a 0–5 self-rating, which a child cannot
   give reliably. The grade is instead **derived from the same observation the star engine already makes** —
   correct, attempt number, solution revealed, milliseconds on the card. Notably, revealing the solution can
   never produce a recall, which keeps scheduling consistent with Art. 6.1's rule that a revealed answer earns
   nothing.
2. **Ease is an integer in permille** (2500 = 2.5), like the star ledger is in integer units (AD-3). Every SM-2
   ease adjustment is an exact multiple of 0.01, so permille is lossless — a card reviewed across a school year
   takes dozens of updates and float error would compound.

Two additions the original algorithm lacks: a **maximum interval** (default 365 days), because a card scheduled
years out is meaningless for a school year and reads as a bug on the parent's dashboard; and a guarantee that
the interval always advances, since `round(1 × 1.3) = 1` would otherwise stall a weak card forever.

Session selection lives in `SessionBuilder`: worst-overdue first, with a guaranteed minority share for new cards
(default 40%). The reason is Art. 5's session bonus — a session capped at the appendix's size stays completable
even with 500 cards overdue, so a child who fell behind can still reach 100% and earn the +5.

### D-21 · Device Owner is refused by the client — decided 2026-08-15

The client's instruction: **do not introduce Device Owner.** The developer's reasoning, which I agree with: most
parents cannot carry out a factory reset plus a provisioning flow, and an app that demands one is an app they
abandon at setup.

**What this settles, positively:**

- One enforcement path, not two. No device-owner branch to write, test, or explain.
- No factory reset, so the trial works, and the 12 Play testers of Art. 15.2 can actually evaluate the app.
- Nothing to justify to Google beyond what we already carry.
- Consistent with Art. 1: Lunio is a motivation tool, not a kiosk.

**What this closes off, and it matters:** Device Owner was the *only* route to Art. 12 scenario 9's *ممنوع*
(prevented). With it refused, the deliverable for scenarios 9 and 10 is permanently the limited form of D-12 —
warn, detect, react, notify. There is no second option left to fall back on.

**Consequence:** the written clarification of scenarios 9 and 10 is no longer advisable, it is **required**, and
it must be agreed **before the day-11 payment gate**, not at Phase 7 acceptance. Draft letter:
`docs/client-letter-scenarios-9-10-ar.md`. Until the client replies in writing, treat scenarios 9 and 10 as
**contractually unresolved** and say so in every milestone report.

The Art. 12 exclusions (Safe Mode, factory reset / Recovery, ADB, second user) stay excluded and stay unchased,
exactly as before — and now with no paid escape hatch on offer, do not let a request to "just make it stronger"
reopen them. Art. 16 is explicit that tightening raises the rejection risk, and that the trade-off is the
client's commercial decision, already reviewed before signing.

### D-19 · The attendance bonus is granted once per day, from the second day of a run

Article 5 pays "+3" for "يومان متتاليان دون انقطاع (مواظبة)" but does not say whether that is once per pair of
days, once per run, or once per day of an unbroken run. Decision: **once per day, on every day where the run
reaches two or more consecutive days**, capped at one per day by a flag on the day record. Article 6.6's reset
rule ("يصفّر العداد بأي يوم انقطاع") makes the run cheap to break, which bounds the total.
An "active day" for the streak = a day with a **completed session**, consistent with D-5.
⏳ Client may prefer once-per-pair; it is one branch to change, and the test names say which reading is encoded.

### D-20 · The star value moves in half-minute steps

Appendix §5 gives the star value a range of 0.5 – 3 minutes but no step size. Decision: **half-minute steps**
(30, 60, 90, 120, 150, 180 seconds) — that is how the range itself is written, and it keeps every conversion in
the engine exact, because award amounts are always multiples of 50 units. `StarRules` rejects anything else
rather than rounding it. Without this, a value like 0.7 min would make half-star awards land on fractional
seconds and reintroduce exactly the drift that integer units exist to prevent.

### D-18 · Enforcement never starts an activity from the background

See V2. An AccessibilityService is **not** a background-activity-launch exemption. Eviction =
`performGlobalAction(GLOBAL_ACTION_HOME)`; the visible surface = a `TYPE_APPLICATION_OVERLAY` window.
Any design that needs `startActivity` from the service is wrong on current Android.

---

## ⏳ Still blocked on the client — none of these block today's coding

| # | Needed | By |
|---|---|---|
| Q3 | **The reference device.** Art. 13 permits day 18; Phases 2 and 4 are unverifiable until it exists. Written acknowledgement of Art. 19's extension clause if it will be late. | day 3 |
| Q9 | The 10 sample lesson images (Art. 19) — they become the locked Art. 11.3 measurement set | day 8 |
| Q10 | Groq or Claude for the acceptance run and for production, **in writing** (Art. 3 names Claude; Art. 14 requires a no-training provider) | day 8 |
| Q16 | Current Chargily docs + test-mode keys (Art. 7.8) | day 18 |
| Q17 | Activation-code delivery channel — decides whether the parent account is email or phone (Art. 7.3) | day 18 |
| Q18 | Acceptable "once per device" identifier for the trial (Art. 7.1) | day 18 |
| Q19 | VPS + domain, or approval to use a dev tunnel through Phase 6 (Art. 19 says before Phase 7, but the Chargily webhook in Phase 6 needs a public HTTPS URL) | day 18 |
| D-6, D-12, D-14 | Written confirmation of my readings above | before Phase 7 |

---

## D-39 — the Flutter channel handlers stay in the app module, not `native/bridge`

**Decided 2026-08-27, on the developer's authority. docs/CONVENTIONS.md §5 says otherwise and this is the deviation.**

The layout in docs/CONVENTIONS.md lists `native/bridge` as the one module that talks to Flutter. AD-7's actual
requirement is narrower and is the part that matters: **enforcement must never depend on Dart**, because
blocking has to keep working while the Flutter engine is dead.

`native/blocking` satisfies that literally — it contains no Flutter type, no `MethodChannel`, and would still
compile with Flutter deleted from the machine. The Kotlin service reads its state from `SharedPreferences` via
`BlockingStore`, never from a channel, so a dead engine changes nothing about a blocking decision.

What a separate `native/bridge` Gradle library would have added: a `compileOnly` dependency on
`io.flutter:flutter_embedding_debug`, which is published **per engine hash** and normally resolved by the
Flutter Gradle plugin. A plain Android library would have to pin that hash by hand, add Flutter's storage
Maven repository, and re-pin on every Flutter upgrade — new failure modes, no new guarantee.

So `LunioBlockingBridge` sits beside `LunioClock` in the app module. Both are **writers and readers only**,
never on the path of a decision. If a future module genuinely needs a channel of its own, this decision gets
revisited rather than copied.

**What the deviation costs:** the app module can now reference `dz.lunio.blocking` types directly, so nothing
mechanically stops a future edit from putting a rule there. The defence is `BlockPolicy` being the only place
that decides and having tests that say so, not a Gradle boundary.

---

## D-40 — the push to the engine is whole-state or nothing

**Decided 2026-08-27.** `BlockingRepository.sync` sends every field every time, including a re-query of the
blocked-package list, even when only the balance changed.

There was a cheaper design with two methods: a light one for the balance (which changes on every answered
card) and a full one for the list (which changes when a parent edits it). It is wrong for a reason that is not
about performance. A partial push still has to put **something** in the field it skips, and an empty package
list unblocks every game on the phone. The engine cannot distinguish that from a parent who deliberately
cleared their list — from inside `BlockPolicy` the two are the same value.

More generally: the engine enforces against the last snapshot it was handed and has no way to judge its age.
Every failure at this seam is therefore silent, on a child's phone, in one of two shapes — a child who earned
stars stays locked out, or one whose time ran out keeps playing. The extra query is what makes correctness
structural instead of a review comment.

The same reasoning puts `blockingSyncProvider` at the **root** of the widget tree rather than on the screens
that cause changes. A screen can be forgotten; a dependency edge cannot.

---

## D-41 — `server/.env` was never actually loaded, and nothing said so

**Found 2026-08-28, during the first end-to-end run of the server.**

`config/settings/base.py` read every value with `os.environ.get(...)`. Nothing ever loaded `server/.env` into
the environment. `python-dotenv` was in `requirements.txt` and installed; it was simply never called.

**The reason it survived this long is the interesting part.** Every read had a default, so nothing failed
loudly. The server started, migrated, registered a parent, issued a JWT and served the schema — all on
`SECRET_KEY = "dev-only-insecure-key"`, with no Chargily keys, no AI key, and `ALLOWED_HOSTS` at its fallback.
112 tests passed, because tests set what they need. The first symptom was a 500 from the lesson endpoint
saying **"GROQ_API_KEY is not configured"** about a key that had been sitting in `.env` for days — and the
obvious next move, checking the key, is checking the one thing that was not wrong.

Fixed by calling `load_dotenv(BASE_DIR / ".env", override=False)` before the first read. `override=False`
matters: on the VPS and in Docker the configuration arrives through the real environment (Art. 3), and a `.env`
left inside an image must never outrank it.

**The lesson worth keeping:** a configuration layer where every value has a working default cannot report its
own absence. Two things silently depended on this and would have shipped broken — `CHARGILY_SECRET_KEY` empty
means `verify_signature` returns False for *every* webhook, so no payment would ever have activated; and an
empty `SUBSCRIPTION_SIGNING_KEY_HEX` means no snapshot is signed, so every device reads `expired`. Both are
correct-looking failures. Neither would have raised anything.

---

## D-42 — a forged webhook could permanently lock a real payment out

**Found 2026-08-28, immediately after D-41 — and only because fixing D-41 made the payment path run at all.**

`WebhookEvent.event_id` carried a plain `unique=True`, and the view records **every** inbound webhook including
refused ones (deliberately: Art. 7.3, "when the client asks why a payment did not activate, the answer must be
a row, not a theory"). The two together were a hole.

An unsigned request carrying a guessed event id was rejected with 400 — **and wrote its audit row first**,
consuming the idempotency key. Chargily's genuine delivery of that same event then violated the unique
constraint and was answered `{"detail": "duplicate ignored"}`. No activation code, ever.

What it costs: the parent pays 1.000 DZD, Article 7.3 step 4 never fires, and the audit trail says *duplicate* —
the single word most likely to send whoever investigates to the wrong conclusion. It needs no credential: the
webhook URL is public by construction and the event id is derivable from a checkout id.

Fixed by scoping the constraint to authenticated rows:

```python
models.UniqueConstraint(
    fields=["event_id"],
    condition=models.Q(signature_valid=True),
    name="unique_verified_webhook_event",
)
```

A refused delivery is still recorded and can no longer reserve anything. Four tests in
`apps/payments/tests/test_webhook_lockout.py` hold the property, including the one that had to keep working —
a genuine retry is still ignored and still issues exactly one code.

**How it was found is worth recording too.** Not by reading the code. By running the forged case *before* the
valid one, in the order an attacker would, rather than after it in the order a test author naturally writes.

---

## D-43 — the welcome screen is the client's mockup, and the logo is the client's own

**2026-08-28, from `client_design/first page.jpeg`.**

The first screen was rebuilt to the client's second mockup: logo mark, a headline that colours the brand name,
two lines of body copy, three pillars, one primary button. Three notes worth keeping.

**The logo asset.** `assets/illustrations/logo_mark.webp` is cut out of `illustrators and logo/logo.jpeg` — the
capped-book mascot on transparency, wordmark and tagline cropped away. The cutout is a corner flood-fill rather
than a colour-key: the mascot's eye-whites and book pages are within ~33 of the background colour, so only
connectivity separates them and a global threshold would have punched holes in the character's face. The
wordmark is dropped because the title directly beneath already reads «أهلاً بك في **Lunio**», and a second
wordmark eighty pixels above it says the brand name twice.

**It is the one asset that is not interchangeable.** The other seven are decoration and can be redrawn on
request. This is identity and it is the client's choice, so it is never restyled, retinted, or cropped further.

**The backdrop circles were wrong twice before they were right.** First at 0.55 alpha in two different tints:
rendered at 412 dp they read as two grey objects the eye tracks *before* it reaches the logo — the opposite of
a backdrop. One tint at 0.45 alpha is texture. This was found by rendering the screen to a PNG and looking at
it, not by reading the widget tree, and it is a good argument for doing that on any screen the client has drawn.

---

## D-44 — consent on the protection step turns both switches on

**Client request, 2026-08-28.** Ticking «قرأت الإفصاح وأوافق كوليّ أمر» now enables both
«تفعيل حجب الألعاب» and «جعل Lunio الشاشة الرئيسية». Withdrawing consent clears both.

**Article 15.2 and the Play disclosure requirement are untouched, and it is worth being exact about why.** The
consent tick still starts unchecked on every launch and is still a deliberate tap — that is the interaction
Play reviews, and it is unchanged. Both switches stay individually adjustable afterwards. The
«أكمل بدون حجب» path still finishes setup with both off. What changed is the default *after* an explicit yes,
not whether the yes is required.

**One bug came with it, and it was not obvious.** The decline button used to be safe by accident: both switches
defaulted to off, so "finish" and "finish without blocking" did the same thing and shared a single callback.
The moment consent started turning them on, tapping «أكمل بدون حجب» would have finished setup **with blocking
enabled** — the opposite of what the button says, on the one path the twelve Play testers of Article 15.2
depend on. It now has its own callback that clears both first.

The three booleans and the rules between them moved out of the wizard into `ProtectionChoice`, a plain value
class with seven tests. They could not be tested where they were: the wizard's state is private and the widget
harness refuses database access by design (D-33), so a rule that decides whether a phone ends up blocking games
had no coverage at all. It is set once, on a screen a parent sees once — high consequence, single exposure,
which is exactly the shape hardware testing skips because it only appears on a fresh install.

---

## D-45 — Tajawal, bundled, and the two places `ThemeData.fontFamily` does not reach

**Client choice, 2026-08-28.** The app font is Tajawal (SIL Open Font License, `assets/fonts/OFL.txt`),
three weights, ~180 KB.

**Bundled, not fetched.** `google_fonts` downloads at first use. Article 7.1 keeps blocking, stars and saved
lessons working when the subscription lapses, and the app has to open correctly on a phone with no signal — a
first launch that silently falls back to the system font because Wi-Fi is off is a different-looking app for
no reason.

This replaces a deliberate `fontFamily: null`, and the reasoning behind that null is worth keeping because it
names the failure mode to watch for: a **Latin-first** family with no Arabic coverage falls back glyph by
glyph and the screen ends up in two typefaces at once. Tajawal is an Arabic family with a matching Latin set
drawn alongside it, so «أهلاً بك في Lunio» renders in one voice. That is why this particular choice is safe
and a different one might not be.

**Two places the theme's family does not reach, both found by rendering the screen and looking at it:**

1. **A standalone `TextStyle` in a component theme.** `ThemeData.fontFamily` populates the text theme; a
   `FilledButton.styleFrom(textStyle: TextStyle(...))` with no family falls through to the platform default.
   Every button in the app would have been in the system face while every label was in Tajawal. Fixed by
   naming `LunioTheme.fontFamily` and using it wherever a raw TextStyle is unavoidable.

2. **The Kotlin block card.** It is drawn by `BlockCardOverlay` with Android TextViews and knows nothing about
   Flutter's theme. It now loads Tajawal from **the blocking module's own assets** — a duplicated 120 KB — 
   rather than reaching into `flutter_assets/`. AD-7 says the engine keeps working with the Flutter engine
   dead, so it must not depend on how Flutter packages itself. The load is wrapped and falls back to the
   system face: the right message in the wrong typeface beats an exception inside an accessibility service.

---

## D-46 — the parent account is step 2 of setup, and it is skippable

**Client request, 2026-08-28.** Sign-in / registration now comes directly after the welcome screen instead of
living only in the parent dashboard. Five steps: welcome, account, grade, PIN, protection.
`onboardingCompletedStep` moves 4 → 5.

**Skippable, and that is not a shortcut.** The account buys exactly two things: lessons generated from a photo,
and the subscription (AD-6). The daily session, stars, play time, blocking, the weekly test and every already
saved lesson run entirely on the device and never touch the server (Art. 14). Making the step mandatory would
mean a parent with no signal at setup time cannot finish setup — of an app whose core loop is offline — and it
would contradict Article 7.1 in spirit: the contract is emphatic that the child is never punished for the
parent's payment state, and unreachable Wi-Fi is a thinner reason still. The skip is the same weight as the
one on the protection step.

The form itself was **extracted, not copied**, into `features/auth/account_form.dart` and is now shared with
`AccountScreen`. It is where a password is typed; a second copy is a second place for the LTR field direction,
the error handling and the clear-on-success to drift apart, and two login forms in one app is how one of them
ends up subtly worse.

**Note for anyone updating a device that already finished setup:** its stored step is 4, now below the
sentinel, so it runs the wizard once more. That is correct — the account step is new — and there are no
production installs to disturb.

---

## D-47 — the app was never sending its install id, and two contract rules rested on it

**Found 2026-08-28, while wiring the mandatory account.**

`SubscriptionRepository.startTrial` posted an **empty body** to an endpoint whose `install_id` is a required
field. So Article 7.1's free trial — 7 days, all features, «مرة واحدة لكل جهاز» — could never have started at
all. The app had no install id to send: nothing generated one, and no column held one.

The device anchor now exists end to end: `app_settings.install_id`, a v4 UUID minted from `Random.secure()` on
first read and written inside a transaction (two providers reading it at startup would otherwise race and mint
two, and the second would silently claim a second device on the server). It is sent with register, sign-in,
trial and activation.

**What it is, and what it must never be described as.** It identifies an *installation*. Not an advertising ID
— forbidden for Designed for Families (Art. 15.3); not IMEI, serial or MAC, which describe a person's hardware
and are unavailable to ordinary apps in any case; nothing derived from the child (Art. 14). Clearing the app's
data mints a new one. That limitation is the same one Article 7.1 already accepts and is documented in
`apps/devices/models.py`; closing it needs a persistent hardware identifier, which policy forbids.

`settings_defaults_test.dart` caught the new column and failed, which is exactly its job. It is admitted to the
allowed list deliberately, with the argument above written beside it, rather than by relaxing the assertion.

---

## D-48 — one account per phone

**Client request, 2026-08-28.** Enforced on **both** register and sign-in, keyed on the install UUID.

Sign-in is the path that matters, and checking only registration would have guarded the wrong one: a second
account does not arrive on a phone by being created there. A parent creates it elsewhere, hands the phone over,
and it is signed in with. Registration is the rarer case.

Two ordering details, both of which would be bugs the other way round:

* **Register checks before creating.** Creating the account and then refusing to bind would strand an orphan
  account on every attempt and burn an email address that could never be registered again.
* **Sign-in checks after authenticating.** Refusing an unknown email *because the device is claimed* would tell
  somebody holding the phone which addresses exist.

Sign-in also got its own throttle scope. Sharing `register`'s 10/hour was wrong twice over: a parent who
mistypes a password three times would be locked out of their own phone for an hour, and account creation — the
expensive, abusable operation — would have its budget spent by ordinary logins.

**This is a rule against casual account-swapping on a family phone, not a security boundary,** because clearing
app data resets it. The client must not be told otherwise.

---

## D-49 — the account step is mandatory, and the trial starts with it

**Client request, 2026-08-28.** Setup cannot be completed without an account; the seven-day trial is claimed
automatically the moment there is one to hang it on.

The reason the previous version was skippable is kept on record because it names the one case this breaks: the
account buys only lessons-from-photos and the subscription (AD-6), while the daily session, stars, play time,
blocking, the weekly test and every saved lesson run on the device (Art. 14). A parent setting the app up
somewhere with no signal now cannot finish setup, of an app whose core loop is offline. **That is a real cost
and it is the client's call.**

What it does *not* touch, and this matters for the Play submission: Article 15.2 is about blocking and launcher
mode being opt-in, and both remain so on the next step. Article 7.1 is untouched too — once signed in the token
is cached, and an expired subscription never stops stars, blocking or saved lessons.

A 409 from the trial endpoint is treated as an ordinary answer, not an error: it means this device already had
its seven days, and setup continues.

---

## D-50 — the play clock: Article 4.7's other half

**Reported from hardware, 2026-08-28: "the time does not update in real time while playing."** Correct, and
predicted — it was written into `hardware-verification.md` as H10.5, the step expected to fail, because
`shouldEvictForeground` had no caller.

Tier 1 is event-driven and **no window event fires while a child sits inside one game**. So the balance was
checked when the game opened and never again: a child with one minute left could play for an hour while the
counter on the home screen still read one minute.

`PlayClock` runs in the blocking module and charges time only while *all* of these hold — the appendix is
explicit that «الطفل لا يخسر دقائق وهو لا يلعب»:

* a package on the parent's list is the foreground window;
* blocking is on and play is not paused;
* **the screen is on.** A phone in a pocket must not drain the balance, and this is the case a naive
  `postDelayed(remaining)` gets wrong by an hour.

**It measures elapsed time, not its own ticks.** A Handler tick is a request, not a promise: under memory
pressure or in a doze window ticks are dropped, and a counter that trusts them under-charges exactly when the
child is playing hardest.

**The ledger stays in Dart.** Kotlin decrements a *copy* for enforcement and tallies seconds spent;
`_RootState._collectPlayTime` drains that tally on resume and writes it through `StarRepository.consumePlay`.
Articles 5 and 6 keep exactly one implementation.

Two ordering rules hold it together, and both are one-line mistakes away from being wrong:

1. **Drain before push.** `blockingSyncProvider` overwrites the engine's remaining; seconds still in the tally
   at that moment are seconds handed back to the child for free.
2. **Read-and-clear is atomic**, and written with `commit()` rather than `apply()`. The engine keeps adding
   while Dart reads, and an OEM battery manager may kill the process between two ticks — an asynchronous write
   would drop the seconds just spent.

---

## D-51 — the debug network config allows any host

The first version listed one IP, `192.168.1.3`. It broke the moment the router handed out a different lease,
and the failure was indistinguishable from a server that was not running: a refused connection, no error naming
the address.

A debug build is not a security boundary — throwaway signing key, development server address — so pinning a
subnet bought nothing and cost an afternoon of misdiagnosis. `src/debug/` is the property that matters; the
release AAB never sees the file and keeps cleartext blocked with no exception list to audit.

Paired with `GET /api/health/` and the connection banner on the account step, which prints the base URL it
tried. The commonest cause of "it does not connect" is a build launched without `--dart-define`, still pointing
at the emulator alias `10.0.2.2` from a real phone — and reading the address once settles it.

---

## D-52 — the app had no INTERNET permission, and the release build never would have

**Found 2026-08-28, on hardware, after two firewall rules that were both necessary and neither sufficient.**

The setup screen reported "cannot reach the server" while `nc` from a shell on the *same phone* got
`HTTP/1.1 200 OK` from that exact address one second later. The merged manifest explained it:

```
grep -c "android.permission.INTERNET" merged_manifest/debug/.../AndroidManifest.xml
0
```

**Two separate faults, and the second is the serious one.**

1. **Mine.** `src/debug/AndroidManifest.xml` was rewritten to point at the network security config, and
   Flutter's template content — whose only line is `<uses-permission android:name="android.permission.INTERNET"/>` —
   went with it. Debug builds silently lost the network.

2. **Latent since the project was created, and it would have shipped.** Flutter's template declares INTERNET
   **only in `src/debug/`**, because the tool needs it for hot reload. `src/main` never had it. So a release
   AAB of this app — the deliverable — would have been unable to reach any server at all: no sign-in, no
   lesson generation, no subscription check, no activation code. Every call failing with a permission error
   that on screen is indistinguishable from a server outage. The earliest it would plausibly have been noticed
   is a tester's phone after a Play upload.

Declared in `src/main` now, where it belongs, with the reasoning beside it. Kept in the debug manifest too —
redundant, but a second deletion should be obvious rather than invisible.

**What made it findable at all** was the connection banner printing the address it tried, next to a shell that
could reach that address. Without that contrast the search would have stayed on the network, where two real
firewall problems had already been found and fixed — each of which made the next symptom look like more of the
same.

---

## D-53 — the health probe retries once

The first probe fires while the setup wizard is still opening. On the Article 13 class of device that is a slow
moment: the Oppo A15 logged `Displayed MainActivity: +9s794ms` for a debug build, with ColorOS raising its own
`TheiaBootFail` marker, and Wi-Fi still associating behind it.

A single attempt landing in that window reports a failure about a server that is answering, and sends the
parent looking for a fault that is not there. One retry after 700 ms costs a second and removes the class.
`serverHealthProvider` is `autoDispose` for the same reason: reachability is the one value in the app with no
useful shelf life, so leaving the screen and returning re-probes rather than replaying a minute-old answer.

---

## D-54 — a Riverpod cycle killed every authenticated call, and only hardware could show it

**Found 2026-08-29 on the Oppo A15, reported as «الـ API لا يعمل».**

`apiClientProvider` read `authRepositoryProvider` to get the access token; `AuthRepository` was built from
`apiClientProvider`. Written through closures it looked deferred enough to be safe, and the comment beside it
said as much: *"the two genuinely need each other, and the closure is the smallest way to say so without a
cycle."* That comment was wrong.

On the device, the first call through `ApiClient._send` threw:

```
Unhandled Exception: Instance of 'CircularDependencyError'
  #3 apiClientProvider.<anonymous closure> (providers.dart:67)
  #4 ApiClient._send (api_client.dart:207)
  #6 AuthRepository.register
```

**Before the HTTP request was assembled.** So nothing reached the server, nothing appeared in its log, and the
UI showed no error — `_submit` catches `ApiFailure`, and this is not one, so the button simply reset. Register,
sign-in, the trial, activation, the lesson endpoint and the subscription snapshot were all dead. The health
probe was the only thing that worked, because it calls `dio.get` directly and never asks for a token.

**That asymmetry is what solved it.** "The server is unreachable" had already been the right answer twice that
evening — a firewall profile, then a missing INTERNET permission — so a third network-shaped symptom was
entirely plausible. What made it not-the-network was one shell command: `nc` from the same phone got
`HTTP/1.1 200 OK` from the same address one second after the app reported failure.

### The fix is structural

`TokenStore` (`data/repositories/token_store.dart`) owns the tokens and depends on the database alone. Both
`ApiClient` and `AuthRepository` depend on it; neither depends on the other. The token refresh moved into
`ApiClient`, where it belongs on its own merits: the refresh endpoint is **unauthenticated** — it carries the
refresh token in the body and takes no Authorization header — so it is the one call that must not go through
the token path, and putting it behind the interceptor that triggers it was circular in spirit as well as in
wiring.

### Why it reached a phone, which is the part worth fixing

Nothing had ever built the real provider graph and made a call through it.

* `flutter analyze` is happy with a cycle written through closures — the earlier fix for this pair was type
  annotations, which settled *inference* and left the runtime cycle untouched.
* Widget tests override the providers they use. That is what makes them fast, and it is exactly what hides a
  composition-root fault.
* Server tests never see Dart.

`test/provider_graph_test.dart` closes that gap: a real `ProviderContainer` with only the database swapped,
calling register, sign-in, trial, activate and refresh, and asserting each fails with a **network**
`ApiFailure` rather than a dependency error. `apiBaseProvider` exists so the test can point that real graph at
`127.0.0.1:1`, which refuses instantly — five calls at a twenty-second connect timeout is a suite nobody runs,
and a suite nobody runs is how this reached a phone.

### Endpoint inventory, checked on the same day

Eight of the server's ten routes are called by the app and were exercised live from the device. The two that
are not are deliberate: `payments/checkout/` belongs to the independent web page (Art. 7.2 keeps every price,
buy button and payment link out of the app), and `payments/webhook/chargily/` is called by Chargily.
`accounts/me/` is reachable and unused — the parent's email is read from the local token row — and it is left
in place as a diagnostic rather than wired to nothing.

---

## D-55 — the auth outcome is a dialog, and where it leads depends on the case

**Client request, 2026-08-29:** replace the inline «تم تسجيل الدخول» line with a popup, and branch after
sign-in so a returning parent is not walked through onboarding again.

### The dialog

It earns the interruption rather than merely being one. Two things happen in the same instant — an account now
exists and seven free days have started — and the parent is about to be moved to a different screen. A notice
they can scroll past is the wrong shape for that. `barrierDismissible: false`, because the button *is* the
navigation: a tap outside would strand them on a step that has already done its work.

### The branch, and the part of it that could not be built as asked

`routeAfterAuth` in `features/setup/post_auth_route.dart`. A device skips the rest of setup only when it was a
**sign-in** *and* the phone already holds a **school level** *and* a **parent PIN**.

The request was "if it is a sign-in, skip the setup". That cannot be done unconditionally, and the reason is
the privacy architecture rather than an implementation gap: **the grade and the PIN are never sent to the
server** (Art. 14 keeps every byte about the child on the device; AD-6 keeps the server's tables free of it).
There is nothing to restore them from, so a sign-in on a fresh phone has nothing to inherit.

Skipping anyway would be worse than tedious, in two ways that are easy to miss when the rule looks like a
convenience:

* `PinGate` refuses to unlock when no PIN is set — deliberately, so that "no PIN" is not an open door. A parent
  dropped into the app without one is **locked out of their own settings permanently**: app picker, star
  adjustments, subscription screen, all unreachable short of clearing the app's data.
* the lesson endpoint requires a grade; an empty one is a 400 that surfaces as "capture does not work".

So the skip serves the case it can actually serve — the parent who signed out from the dashboard and back in,
or whose wizard was interrupted after the PIN step — and for them the setup would be pure repetition. On a bare
phone the dialog says *why* two steps remain rather than dropping them into a form with no explanation.

### One thing the shortcut must not do

`_finishAlreadyConfigured` marks setup complete and **touches nothing else**. `_finish` would have written this
session's untouched `ProtectionChoice` defaults over the stored ones — silently turning blocking off for a
family that had it on. The restraint is the whole point of the separate method.

Five tests in `test/post_auth_route_test.dart` hold the rule, including the two "never skips" cases that are
the reason it exists.

---

## D-56 — the child could never reach a captured lesson

**Reported from the device 2026-08-29: «الدروس لا تظهر عند الطفل» after two lessons were photographed.**

Both lessons were saved correctly. The cards were in the database, the SM-2 builder selected new cards
properly, the star engine was fine. There was simply **no path from the home screen into the day.**

The day's tasks are created by `SessionRepository.sessionFor`, which ran only when the *session screen* was
opened. The button that opens the session screen was disabled until `DayProgress.tasksTotal > 0` — a value only
`sessionFor` writes. A closed circle: the child was shown «لا توجد مهام بعد» for ever, beside a card the app
had every reason to give them.

`ChildHomeScreen` now watches `sessionControllerProvider`. Arriving at the home screen is what creates the day.

**Why every test passed throughout.** Each one tested a piece — the builder selects new cards, the repository
writes tasks, the star engine counts them — and every piece was right. Nothing asked the question that matters:
*starting from a captured lesson, does the child end up with something to do?*
`test/session_reachability_test.dart` asks exactly that. It is a reminder that a suite of correct unit tests
says nothing about whether the parts are connected.

### A lesson captured after the day was built

`rebuildIfUntouched` rebuilds today's tasks **only while nothing has been answered**. `sessionFor` is
idempotent on purpose: Article 6.5 pays the +5 bonus for finishing *the day's* tasks, so a list that grows
underneath a child turns a finished session back into an unfinished one, or un-earns a bonus already paid.
Before the first answer the day is still ours to rewrite; after it, the new cards wait for tomorrow.

---

## D-57 — the live countdown is an EventChannel and a notification, not a WebSocket

**Client asked for a WebSocket, 2026-08-29.** It is the wrong tool here, for two reasons that are worth
stating because they are not obvious from the outside.

**Nothing about play time involves the server.** The balance is Article 5 arithmetic over data that never
leaves the phone (Art. 14 keeps every byte about the child local; AD-6 keeps the server free of it). A round
trip to ask how many seconds are left on this device would add latency, a network dependency and a privacy
surface to a number already in memory.

**And it could not work.** While the child is inside a game there is no Flutter engine running to hold a socket
open — that is the entire reason `PlayClock` lives in Kotlin. A socket would be closed at precisely the moments
it was supposed to report.

So the countdown reaches the two surfaces that can actually be seen:

* **the foreground-service notification**, updated once a second — the only thing visible *while a child is
  playing*. The notification is already required by the platform for the service; carrying the number turns an
  obligation into the feature.
* **an `EventChannel`** (`dz.lunio/play_ticks`), for when Lunio itself is on screen — launcher mode, or the
  instant the child comes back. `PlayTicks` holds one nullable sink; with nobody listening, emitting costs a
  null check.

Stopping and resuming was already correct and needed no change: the clock runs only while a blocked app is the
foreground window, blocking is on, play is not paused **and the screen is on** — «الطفل لا يخسر دقائق وهو لا
يلعب».

---

## D-58 — cloudflared, not ngrok, for the webhook

**Client asked for ngrok, 2026-08-29.** ngrok now requires an account and an authtoken before it will open a
tunnel. cloudflared quick tunnels need neither, which matters for a step the client may have to repeat on their
own machine without our help.

`tools/webhook_tunnel.ps1` checks that the server is up, opens the tunnel, and prints the exact line to paste
into the Chargily dashboard and into `CHARGILY_WEBHOOK_URL`. The binary is gitignored — 55 MB, downloaded, not
authored.

**The address is random and changes on every run.** That is fine for development and unfit for anything else,
which is the argument Q19 has been making all along: the real fix is the client's VPS.

---

## D-59 — the payment page, and the line it keeps

**Client chose the compliant path, 2026-08-29**, after being shown the risk of in-app payment. Built as
`server/apps/web`, served at `/pay/`.

Three pages: the plans, the waiting-and-code page, and a failure page. Same violet, same soft circles, same
Tajawal, same illustrations as the app — deliberately, because a parent about to type a card number on the next
screen should recognise where they are. **An unfamiliar page asking for money is the exact shape of a scam,**
and the client will be the one answering that question from parents if it looks wrong.

### What the page is allowed to do that the app is not

Show a price. It is the only surface in the product that may, and the amounts come from
`subscriptions/plans.py` — the same constant the checkout endpoint stamps a transaction with, so the page
cannot advertise one number while the gateway charges another. The form posts a **plan code**, never an amount:
a number that arrives over the wire is a number somebody can edit.

### The app does not link here, and that is the whole point

Article 7.2 keeps every price, buy button and payment link outside the app because that separation is what
keeps Lunio clear of Google Play's billing policy. A button, a URL, or a QR code in the app would put it back
inside. The parent reaches the page the way they reach any page — the client publishes the address — and what
crosses back is a **short activation code typed once** (Art. 7.3 step 5).

"We remembered not to link it" is not a property, so it is now a test:
`app/test/article_7_2_test.dart` reads every Dart source and refuses a price in a user-facing string, any
payment link, any call to `/api/payments/`, any Arabic buying verb, and any card-shaped identifier. Its first
run failed on `'${ms / 1000}'` — a millisecond divisor, not a price — which is why interpolations are stripped
before the search. A guard that cries wolf is a guard somebody deletes.

### The redirect is not proof of payment

`/pay/done/` polls rather than trusting the query string it was called with. The browser usually arrives before
Chargily's server-to-server call does, and a query string is something anybody can type — only the **signed**
webhook moves a transaction to paid (Art. 7.3). Two tests hold that: an unknown checkout and a pending one both
yield no code.

### Article 7.7, checked against the markup

Eight server tests, including a regex sweep of every template and every rendered page for a card-shaped field.
Card details are entered on Chargily's hosted checkout and nowhere else; this server stores a transaction id, an
amount, a status and timestamps.

---

## D-60 — four illustrations for the payment page, and the one that crosses back

**Delivered by the client 2026-08-29** from the prompts in the previous message: `code_ticket`,
`secure_lock`, `calendar_month`, `gift_year`. All four came back text-free, which is what the prompts pushed
hardest for — image models insert broken Latin lettering into anything ticket- or calendar-shaped, and a
mangled Latin glyph on an Arabic page reads cheaper than any drawing.

Cut out with the same corner flood-fill used for the logo mark (D-43): connectivity rather than a colour key,
because the calendar's pale pages sit within ~30 of the lavender background and a global threshold would have
punched holes straight through them. 284 KB for nine files.

**`secure_lock` replaces the generic shield on the trust card, and it is a padlock — not a card.** That was
specified in the prompt and it matters: an illustration of a bank card sitting above the sentence "we never see
your card" contradicts itself, and Article 7.7 is the one clause with no room in it at all.

**`code_ticket` is used twice, on purpose.** It appears on the payment page beside the code the parent has just
been given, and again in the app beside the field where they type it. The activation code is the *only* thing
that crosses from the browser into the app — Article 7.2 keeps every price, button and link outside — so the
repeated drawing is what tells a parent carrying a short string between two screens that it is one errand.

### One production bug caught on the way

The plan illustrations were first wired as `{% static 'web/img/' %}{{ plan.illustration }}`. That works with
the plain storage backend and breaks the moment production enables hashed filenames, because `{% static %}`
would be looking up a bare directory. The full path now lives in the view so the tag gets a real key. It would
have surfaced as missing artwork on the one page in the product that has to look trustworthy.

---

## D-61 — a Django template comment that was not one

**Reported from the browser 2026-08-29:** the entire header comment of `base.html` — a paragraph of English
explaining why the payment page must not look like a scam — was rendering as **visible text above the prices**,
on the one page in the product that has to look trustworthy.

**`{# … #}` is single-line only.** It stops at the first newline, so everything after line one was ordinary
markup and was served as such. The multi-line form is `{% comment %} … {% endcomment %}`, which has the further
advantage of being stripped from the response rather than shipped as an HTML comment: the note is for whoever
edits the file, not for everyone who views the source of a page that asks for money.

**Nothing caught it.** Not the template source, which looked like a comment; not `manage.py check`; and not the
eight tests already covering this page, because every one of them asserted on what the page *contains* and none
on what it must not. Three tests now close that: no template token survives into any response, no phrase from
the developer comments appears, and the first thing in the body is the heading.

The general shape is worth keeping in mind — it is the third bug in two days found only by looking at the
actual output (the blocking card's flash, the welcome screen's backdrop, this). A suite that only asserts
presence cannot see what is wrongly present.

---

## D-62 — payment was down because of yesterday's tunnel

**Reported 2026-08-29 as «الدفع لا يعمل».** `.env` still held the previous run's cloudflared address.
Chargily **resolves** `webhook_endpoint` and refuses the entire checkout when the host no longer exists:

```
HTTP 422 {"message":"The webhook endpoint field must be a valid URL."}
```

So a tunnel that closed an hour earlier stopped parents paying at all, and the error named a field they have
never heard of. In development that address changes on every run, which makes it a recurring failure and not a
one-off.

`create_checkout` now distinguishes a webhook rejection from every other refusal and retries once **without**
the field, logging at ERROR because such a checkout may have no webhook at all — a payment whose confirmation
never arrives is worse than one that never started. Chargily falls back to the endpoint set in its own
dashboard, which is where the client configures it for production anyway. Three tests hold it, including that a
*working* webhook is never retried away and that other refusals are not swallowed.

Two smaller things found alongside:

* **Activation codes did not retry on collision.** `code` carries a unique constraint and
  `default=generate_code` had no second attempt, so a collision would have raised `IntegrityError` inside the
  **webhook** — on a payment that had already succeeded, with the gateway's retry hitting the same path. 31¹⁰
  makes that vanishingly unlikely and vanishingly unlikely is not handled; six tries cost nothing.
* **The retry built a fresh payload rather than `pop`-ing the original.** A dict that changes under the caller
  reads correctly and confuses whoever debugs it next — the first version of the test recorded the same mutated
  object twice and asserted against itself.

---

## D-63 — one lesson at a time, and a card is not an exam

**Three complaints from the device, 2026-08-29, all about the child's session.**

**«البطاقات كلها مختلطة».** SM-2 chooses *which* cards are due across every lesson at once, and that is right —
forgetting does not respect chapter boundaries. But it returns them sorted by how overdue they are, so lessons
interleaved: a card about الكسور, then one about فضل العلم, then الكسور again. A child working through that
switches subject every fifteen seconds.

The **selection** is untouched; only the **order** changed. Each lesson's cards together, its questions
immediately after them, then the next lesson. Article 4.3's memorize-then-review now holds inside each block
rather than across the whole day, which is the more useful reading — the review follows the material just seen.
Lessons appear in the order their first due card did, so the most urgent material still comes first.

**«لا تقل اجابة خاطئة لان الطفل يحفظ هنا».** Correct, and the reason is mechanical as well as kind. The child
was asked whether they remembered and answered honestly; calling that a wrong answer teaches them to press
«أعرفها» to avoid the word — and a spaced-repetition schedule fed on flattering answers stops scheduling
anything useful, which quietly breaks Article 2's entire mechanism. Article 6.1 still governs the *star*:
nothing is earned for a card that was not recalled or whose answer was revealed. Only what is *said* changed.

**Questions submitted on tap and advanced immediately**, so a wrong answer taught nothing — the question simply
vanished. The correct choice is now marked green with a tick, the chosen wrong one orange with a cross, and a
«متابعة» button submits. Colour is never the only signal: each state carries an icon, which costs nothing and
is the difference between usable and not.

The clock stops at the tap, not at the submit — Article 6.3 measures time on the *question*, and seconds spent
reading why you were wrong are not thinking time. Recording them would let a slow reader clear the 1.5 s
minimum without having engaged.

---

## D-64 — the countdown the child sees, and why it is not a socket

**Asked for a third time as a WebSocket.** It cannot work, and the reason is worth writing down once more
because it is not obvious from outside: **while the child is inside a game there is no Flutter engine running**
— that is the entire reason `PlayClock` lives in Kotlin — so nothing exists to hold a connection open at exactly
the moment it would need to. And the server has nothing to say: the balance is Article 5 arithmetic over data
that never leaves the phone (Art. 14), so a round trip would add latency, a network dependency and a privacy
surface to a number already in memory.

What was actually wanted — *the child sees the timer when they enter a game and it counts in real time* — is now
built. `PlayTimerOverlay` floats a small pill over whatever is running, updating once a second, violet until the
last minute and warm orange after it. The colour change is the only warning: no sound, no dialog, because the
eviction a minute later is jarring enough on its own.

**`FLAG_NOT_TOUCHABLE` is the flag that matters.** This window sits on top of a game a child is playing, and a
pill that swallowed taps would make the game unplayable while looking like the game itself was broken.

It disappears whenever the clock stops — leaving the game, screen off, parent pause, balance exhausted, service
unbound. `PlayClock` gained a single `onStopped` callback for all five rather than a hook per reason, because
every caller wants the same thing and five hooks is five places to forget one.

---

## D-65 — the session's artwork, and the one number that mattered

**Delivered by the client 2026-08-29:** `card_book`, `card_question`, `background`. All three text-free again,
which the prompts pushed for and which matters most on the background — a mangled Latin glyph *behind* Arabic
text is worse than one beside it.

The two card illustrations are cut out with the usual corner flood-fill. The background is **not** cut out and
never tinted: it is texture, not a subject.

**It is shipped at its native 1254 px, and that was a correction.** The first version was thumbnailed to 900
like every other asset, and rendering the screen showed why that was wrong: a square pattern stretched to cover
a tall phone is upscaled on the long axis, and the softness showed in the **empty** half of the card view —
which is exactly where the eye goes when there is nothing else to read. A flat pattern compresses to almost
nothing, so the full-size file is 6 KB. Cheaper than the smaller one was to look at.

Opacity settled at **0.4**, also by looking rather than by choosing. At 0.5 the scattered stars were noticeable.
The rule this asset is written to: *if you can see it, it is too strong.*

Both card illustrations are hidden once the child has answered. On a 412 dp screen the picture and the revealed
answer together push the buttons off the bottom — and past the reveal the child should be reading the answer,
not looking at a book.

---

## D-66 — the buy button, at the client's direction, against Article 7.2

**The client was given both options on 2026-08-29 and chose (b): a button in the app that opens the payment
page.** It is built. This entry is the written record, because the risk is not ours to absorb silently.

### What the article says and why

> «التطبيق لا يعرض أي سعر ولا زرّ شراء ولا رابط دفع. الشراء يتمّ في صفحة ويب مستقلّة خارج التطبيق.»

And the contract gives the reason in the same breath: it is what keeps Lunio clear of Google Play's billing
policy, which requires digital purchases made inside an app to go through Play Billing. **Google treats a
third-party payment flow reached from inside an app as a policy violation, and enforcement is removal.**
Removal would take Article 15.2's twelve-tester closed test and Article 11's acceptance with it — so the
exposure is not a feature, it is the delivery.

This is a change order. It was flagged before it was built, and the client decided.

### What was kept, because it costs nothing and narrows the exposure

* **Still no price anywhere in the app.** Both amounts live on the web page, read from `plans.py`. A screen
  with no number on it is a weaker case against us than one advertising 1.000 دج.
* **The system browser, never a WebView.** A payment page rendered inside the app is unambiguously an in-app
  purchase flow; handing the URL to the browser keeps the transaction visibly outside Lunio, with the address
  bar and the padlock a parent knows how to read. There is now a test that fails if a WebView ever appears.
* **The button is plain.** No urgency, no plan comparison, no store front. The client asked for a way through,
  not for a shop.
* **Article 7.7 is untouched and always will be.** No card field exists anywhere in this codebase.
* **The address lives in exactly one place** — `AppConfig.payUrl`, a `--dart-define`. An address that starts
  appearing in screens is one that gets copied into a second screen with a different path.

### The guard was narrowed, not deleted

`app/test/article_7_2_test.dart` kept every assertion that is still true and gained two. Deleting it would have
thrown away four live protections to accommodate one agreed change.

Its first run after the change failed on a **comment** — the sentence "never a WebView" in the very file the
rule was written for. The guards now strip comments before searching: a guard that fires on the prose
explaining why it exists is a guard nobody keeps.

---

## D-67 — the play clock froze, because ColorOS froze the process

**Reported 2026-08-29: «المؤقت في بعض الأحيان يحبس».** Not slow and not wrong — *stopped*, then resuming later
as if nothing had happened. That is the signature of an OEM freeze, and `adb shell dumpsys deviceidle
whitelist` confirmed the cause in one line: `dz.lunio` is not exempt from battery optimisation.

While a child is inside a game, **Lunio is a background process.** ColorOS's `ColorHansManager` (and One UI's
"Sleeping apps", and MIUI's equivalent) is entitled to freeze it, and a frozen process runs no `Handler`
callbacks at all.

**The accounting was already safe.** `PlayClock` bills elapsed time between ticks rather than counting ticks,
so a frozen minute is still charged when the process wakes — that decision, made because dropped ticks
under-charge exactly when a child is playing hardest, turned out to cover a case it was not written for.

**Enforcement was not safe, and Article 4.7 is about enforcement.** The tick that notices the balance reaching
zero never fired, so the game stayed open. Three defences now, in order of how directly they address it:

**1. The exemption — the fix for the cause.** A new row on the blocking screen requests
`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, which is a system dialog rather than a trek through a settings
tree that differs on every skin. It is placed *above* notifications because it matters more: without it the
countdown freezes mid-game and the eviction is late, which is the difference between blocking working and
blocking appearing to work. The permission is Play-restricted and needs a Console declaration; the
justification is written into the manifest beside it, and it is not a stretch — this is the app's core function
failing, not a convenience.

**2. `PlayDeadline` — the backstop for parents who refuse.** One alarm, set for the second the balance is due
to reach zero. An alarm is delivered by the system rather than by our own thread, and delivering it **wakes the
process**, which charges the elapsed time, sees zero, and evicts by the ordinary path. It does not evict
itself: only an AccessibilityService can perform a global action, and the enforcement path stays in one place.

`setAndAllowWhileIdle`, not an exact alarm. Exact alarms need `SCHEDULE_EXACT_ALARM`, a user grant on
Android 13+ that Play scrutinises as an alarm-clock permission — and this app's permission budget is already
close to what Article 15 can defend. The inexact form is accurate enough while the screen is on, which is the
only case that matters: the clock stops itself when the screen goes off.

**3. `catchUpIfStalled` — promptness.** Every accessibility event is a free signal that the process is awake.
If the last tick was more than three seconds ago the clock charges immediately and logs the gap, rather than
waiting for the next scheduled tick and making the eviction later still. The log line is there so the next
freeze can be *measured* instead of described.

---

## D-68 — the counter did not work, and the cause was ours not the OEM's

**Reported 2026-08-30: «العداد لا يعمل و لا يظهر في اللعبة و لا يتحدث».**

The day before, a stalling clock had been diagnosed as ColorOS freezing the process, and three defences were
built for it (D-67). All three were correct and none of them was the problem here.

`LunioAccessibilityService` stopped the clock on **every** window event whose package was not the blocked game:

```kotlin
if (state.enabled && pkg in state.blockedPackages) playClock?.start(pkg)
else playClock?.stop("left the game")
```

A child inside a game produces those constantly — the status bar, the volume dialog, a toast, the keyboard,
a permission prompt. Each is a `TYPE_WINDOW_STATE_CHANGED` from SystemUI or the IME, and each was read as *the
child left*. The countdown stopped about a second after it started, every time they touched anything.

**It is the block card's bug in a different costume.** That one flashed and vanished because our own eviction
fired a window event that the Allow branch treated as a departure (D-52's neighbour, recorded in
`hardware-verification.md` H10.3). Same misreading, same branch, second time: **a transient window floating over
an app is not a foreground app change.**

`BlockPolicy.isTransientWindow` now names the exception — SystemUI, the active IME, the permission and install
dialogs, and a blank package. Seven JVM tests, including the two that matter most in the other direction: the
**launcher is not transient** (going home really is leaving, and swallowing that would drain play time while
the child is nowhere near the game), and neither is any ordinary app.

**What this says about the previous day's diagnosis.** D-67's evidence was real — `dz.lunio` genuinely is not
exempt from battery optimisation, and a frozen process genuinely runs no Handler. But the *reported symptom*
had a simpler cause sitting in our own branch, and the OEM explanation was reached first because it was the
more interesting one. The exemption row and `PlayDeadline` stay: they are correct and they cover a real case.
They were just not this case.

---

## D-69 — a sign-in claimed a free trial

**Reported the same day: «كما انه يقدم له trial و هذا غير مسموح به».**

`_afterAuth` called `startTrial` unconditionally — after a registration *and* after a sign-in. Wrong twice
over. A returning parent was offered seven days they may already have spent; and on a phone that had not itself
claimed a trial they would genuinely have been **granted** them, because Article 7.1 keys the trial on the
device. That article exists to stop a new email address resetting the seven days, and calling it after a
sign-in opens the same hole from the other side.

Signing in now creates nothing. It refreshes the signed snapshot and reports whatever the server already says
(Art. 7.6 — the server is the source of truth), in the parent's language: «اشتراكك الحالي: فعّال».

### What I did not change, and why it is worth knowing

The obvious companion fix is to make the trial once per **account** on the server. I wrote it, and then reverted
it: `test_a_different_device_gets_its_own_trial` asserts the opposite, quoting Article 7.1's «مرة واحدة لكل
جهاز» in its name. The contract chose per-device deliberately and states the rationale.

So a parent with two phones can still have seven days on each. That is what the signed contract says, the
client-side bug is fixed without touching it, and **tightening it is a contract amendment rather than a
defect fix** — it needs to be raised with the client, not decided in a commit.

---

## D-70 — the accessibility service was crashing on connect, on an API-30 call

**Third round of «العداد لا يعمل», and this time I measured instead of reasoning.** The previous two answers —
an OEM freeze (D-67) and transient windows stopping the clock (D-68) — were both real bugs and neither was the
reported one.

Four commands settled it:

```
run-as dz.lunio cat shared_prefs/lunio_blocking.xml   → consumed_play_seconds = 0   (never charged a second)
settings get secure enabled_accessibility_services    → listed
dumpsys accessibility                                  → installed, NOT in "Bound services"
logcat | grep "crashed service"                        → Scheduling restart of crashed service
                                                          dz.lunio/.blocking.LunioAccessibilityService
```

The service was **crashing on connect**, ColorOS then stripped it from the enabled list, and the symptom was
everything silently doing nothing: no countdown, no overlay, no logs at all — on a service `dumpsys` still
listed as installed.

### The cause

`onServiceConnected` called `getSystemActions()`, which is **API 30**. The project's floor is **29**, and the
device it is tested on daily is an Android 10 phone.

It was wrapped in `runCatching`, on the assumption that a missing method throws and is caught. That assumption
is wrong in a way worth remembering: **ART resolves a method reference when the enclosing method is entered**,
not when the call site is reached. `onServiceConnected` failed before its first line ran, so the `runCatching`
inside it never existed.

Fixed with two changes, both necessary:

* an explicit `SDK_INT` gate;
* the call **isolated in its own method**, so the unresolvable reference lives in a frame that is never entered
  below API 30. A version check alone leaves the reference inside `onServiceConnected` and changes nothing.

Below API 30 the honest answer is "we do not know whether HOME is offered", and the code does what it always
did — calls `performGlobalAction` and checks the return value, which is the only signal Android 10 gives.

### Two operational facts that cost three rounds

**Every reinstall clears the accessibility grant.** `flutter run`, `adb install -r`, and a Play update all do
it. During this session the service was off for that reason as often as it was off from the crash, and nothing
on screen said so. **ColorOS also refuses to let adb restore it** — `settings put secure
enabled_accessibility_services` is silently reverted, so it must be granted through the Settings UI by hand.

**I had been installing from the wrong path.** `./gradlew :app:assembleDebug` writes
`build/app/outputs/apk/debug/`, while `flutter build apk` writes `build/app/outputs/flutter-apk/` — and
`adb install` was pointed at the latter. Several rounds of "fixed" code never reached the phone.

---

## D-71 — the quietest dangerous state now has a banner

Blocking switched on while the accessibility service is not running is the worst state this app has: the switch
says on, the parent believes the phone is guarded, and nothing is blocked and no play time is counted. **A
parental-control app that believes it is guarding when it is not is worse than one that is honestly off**,
because the parent stops watching.

It is not rare — every app update clears the grant — and until now the only place that showed it was a row
inside the parent's blocking screen, which nobody opens unless they already suspect something. Three rounds of
"the counter does not work" included this state and the app said nothing.

`_BlockingBrokenBanner` now sits at the top of the **child's home screen**, the first thing anyone opens, with
the one action that fixes it. It is silent when blocking is off, because that is a legitimate state
(Art. 15.2) and says nothing about health.

Two test-harness gaps surfaced while adding it, both worth keeping fixed:

* widget tests reached a real `MethodChannel` — `defaultTargetPlatform` is android in a test run, so
  `BlockingChannel.forPlatform()` returned the Android implementation and threw `MissingPluginException`. The
  harness now injects `UnavailableBlockingChannel`, which is also the honest answer off-device.
* `blockingStatusProvider` went through `BlockingRepository` and therefore depended on the **database**, for a
  question that is purely a platform query. Three tests about the star balance failed with an error naming
  `databaseProvider`. It reads the channel directly now: a provider should depend on what it actually needs,
  and anything more is a trap set for the next caller.

---

## D-72 — the timer killed the window that draws it

**Measured on the device 2026-08-30, from a log line the developer sent:**

```
01:23:07.630  play start pkg=com.block.juggle remaining_s=599
01:23:07.686  play stop  pkg=com.block.juggle why=left the game
```

Fifty-six milliseconds. `PlayTimerOverlay` adds a `TYPE_APPLICATION_OVERLAY` owned by Lunio, and **adding a
window fires a window-state event carrying our own package** — which the Allow branch read as the child leaving
the game. The countdown stopped the clock that draws it, every time, immediately.

`isTransientWindow` now takes `selfPackage`. **This is the third appearance of the same shape:** the block card
flashing because our own eviction fired an event (H10.3), system windows stopping the clock (D-68), and now our
own overlay. Each time the lesson is identical — *a window arriving is not the foreground app changing* — and
each time it was rediscovered from a device log. That is why the rule is a named function with tests instead of
a condition inline in the service.

**The stop reason now names the package** — `why=left for com.oppo.launcher` rather than `why=left the game`.
Those three words cost three rounds of guessing; the next occurrence is a lookup.

---

## D-73 — a shadowed parameter disabled the mid-game eviction

**Reported immediately after: the balance reached zero while the child was playing and nothing happened — but
leaving the game and re-entering blocked it instantly.**

That asymmetry is the whole diagnosis. Both paths call `BlockPolicy.decide`; only one of them was passing the
right `selfPackage`.

```kotlin
private fun onPlayTimeExhausted(packageName: String) {   // the GAME's package
    BlockPolicy.decide(
        packageName = packageName,
        selfPackage = packageName,   // ← shadowed Context.getPackageName()
```

The parameter shadowed `Context.getPackageName()`, so the policy was told the game **was Lunio** — and D-9's
self-protection, which exists so the app can never block itself, returned Allow. Re-entry worked because that
path runs in `onAccessibilityEvent`, where `packageName` really is ours.

The parameter is renamed to `gamePackage` rather than qualifying the call site with `this.`, so the shadowing
cannot be reintroduced by someone shortening it back. Two tests pin it, including one that asserts the *wrong*
call returns Allow — documenting exactly why the bug looked like nothing at all.

**What made both of these findable** was a change made for its own sake in D-72: putting the package name into
the log. Neither bug is visible in the code without already suspecting it; both are obvious in one line of
output.

---

## D-74 — the right answer was always first

**Reported 2026-08-30.** Language models put the correct choice at index 0 far more often than chance, and the
bias is strong enough to be obvious across a handful of lessons.

It is not a cosmetic problem. A child works out within a day that the top option is usually right; the review
then measures nothing, and Article 5's **two stars for a correct review question** are paid for spotting a
pattern rather than for knowing anything — which quietly empties the review half of Article 4.3.

Shuffled in `_parse_payload`, **once, on the way out of the provider**. Every consumer is downstream of that
point — the daily session, the weekly test, and whatever is added later — so there is no second place to
remember. Doing it at display time instead would have put the same logic in two screens and let one of them
drift.

`random`, not `secrets`: this is presentation order, not a secret. Nothing is protected by it and nobody gains
by predicting it, because the answer is on screen either way.

**The dangerous half is the index, not the order.** `order` maps *new position → old*, so the new correct index
is `order.index(old)` — the position now holding the old one. Inverting that is a one-character mistake that
stays invisible until a child is marked wrong for being right, so it has its own test that re-parses fifty
times and asserts the text at `correct_index` is still the right answer. Two-choice questions are tested
separately: `shuffle` on two items is a coin flip and the mapping has to survive both outcomes.

Verified live against Groq on two real lesson images: `correct_index` came back 0, 3, 1, 2.

## D-75 — the summary comes before the cards, and the button waits a minute

**Client request, 2026-08-30.** The day used to open on a card. It now opens on the lesson's summary, and the
button to the cards is disabled for **60 seconds** (`lessonIntroGate`).

The delay is the feature. A child who can skip to the cards will, and then answers about a page they never
read — which turns Article 4.3's memorize step into guessing and feeds SM-2 a schedule built on noise. The
button counts down rather than appearing from nowhere, so the wait is legible instead of feeling broken.

**Once per lesson per day, not once per card.** The rule that survives an app restart is derived, not stored:
*a lesson with any answered task today has been introduced.* A child who closes the app after two cards is not
made to sit through the minute again, and it needs no new column, no migration and no extra row. A child who
leaves **during** the intro sees it again, which is right — nothing was studied yet.

The intro is **not** a task instance. Making it one would have added a row to `task_instances`, and that count
is what Article 6.5 pays the +5 bonus against: a day of 12 tasks would have silently become 15, and 100 % of
the day's tasks would have meant something different. It is a presentation step, and the star engine never
hears about it.

A lesson whose summary is empty gets no intro. A blank page between a child and their cards is not a feature.

Not yet a parent setting. The minute is a single named constant in one file; if the client wants it adjustable
it belongs in the appendix §5 ranges, which are still missing.

## D-76 — memorization cards became multiple choice, and that tightened Article 6

**Client request, 2026-08-30.** The card no longer asks «أعرفها / لم أعرفها»; it offers up to four answers.

**This makes Article 6 stricter, not looser, and that is the reason to record it.** The old card was a
self-report, and a self-report is 100 % exploitable: a child tapping «أعرفها» on every card earned every star
in Article 5's table without reading a word. Article 6.1 pays for an answer *correct on the first attempt*, and
a claim is not an answer. Choosing the right one out of four is.

It also makes **D-22** true rather than aspirational. That decision says the SM-2 grade must come from what was
observed and never from a rating a child cannot honestly give — but the observation being fed in *was* the
child's claim. Now it is a fact.

The residue is honest and worth stating to the client: a guess now succeeds one time in four, where before a
determined child succeeded four times in four. Article 6.3's minimum time on the card still has to be cleared
either way, and the daily ceiling still caps the damage.

**Article 6.1's "and none after the solution was revealed" is unreachable on this card**, because there is no
reveal button to press. The clause still governs the recall card, which remains as the fallback. Nothing
reports a reveal that did not happen.

**Where the wrong answers come from:** other cards' backs, same lesson first, other lessons only to top up a
small one. A distractor from the same page tests recall; one from another subject is a free elimination — a
child who knows the question is about a capital rules out a fraction without knowing the answer. Answers
identical to the right one (after collapsing whitespace) are dropped, or the child would face two correct
options and be marked wrong for one of them.

**Seeded on `(cardId, day)`, not random.** A child who leaves mid-card must find it as they left it; re-rolling
would look like the app losing its place and would let them reopen a card until the options got easy. The day
is half the seed, so the same card on a later review is not asked with the same four options in the same
order — the D-74 defect, one level down.

**A card with nothing to choose between falls back to the recall card.** A one-option question awards a star
for a single tap on the only button on screen, which is precisely what Article 6.3 exists to refuse. In
practice this is only the very first lesson on a fresh install.

**Nothing calls the child wrong.** The client's instruction of 2026-08-29 survives the redesign: a missed card
marks the right answer green, says «لا بأس», and leaves the child's own pick unmarked. A red cross tells them
nothing they do not already know, in the one place the app is supposed to be teaching. The star is withheld by
the engine, silently, exactly as Article 6.1 requires.

## D-77 — the camera is on the parent dashboard

**Client request, 2026-08-30.** Photographing a page is the one thing a parent does every day, and it was three
taps down: dashboard → lessons → button. There is now a camera button on the dashboard itself.

It is a shortcut to the same screen, not a second way of doing it — the lessons screen keeps its own button,
and both push `CaptureScreen`. The list gained bottom padding so the floating button covers nothing.

## D-78 — a lesson captured today now joins today, always

**Reported 2026-08-30:** a second lesson was photographed, saved correctly, and never appeared for the child.

The cause was `rebuildIfUntouched`, and it was working exactly as written: it rebuilt the day **only while
nothing had been answered**. Once the child had answered a single task, a newly captured lesson waited for
tomorrow — silently. From the outside that is indistinguishable from the capture having failed, which is the
worst kind of correct behaviour.

The fear behind it was real. Article 6.5 pays the +5 bonus for finishing *the day's* tasks, and a list that
grows underneath a child can turn a finished session back into an unfinished one, or pay the bonus twice. Both
are handled without refusing the parent:

* **`absorbLesson` appends; it does not rebuild.** Nothing already in the day moves, no answered task is
  touched, no card is reshuffled. The count Article 6.5 measures against only ever grows at the end.
* **The bonus was already once-per-day.** `DayProgress.sessionBonusAwarded` is what prevents a second payment,
  not the length of the list. That is now asserted by a test that completes a day, absorbs a new lesson,
  completes it too, and counts exactly one `sessionBonus` row in the ledger.

Deduped by target id, so capturing the same page twice cannot put a card in the day twice — Article 6.2 would
refuse to pay for the duplicate anyway, leaving the child visible work that can never earn.

Capped at the parent's own `dailySessionCards` / `dailyQuestionCount`, so one very long lesson cannot make the
day unfinishable and put the +5 out of reach.

## D-79 — the day became a shelf of lessons instead of one queue

**Client request, 2026-08-30.** The child's work opened as a single list running from the first card of the
first lesson to the last question of the last. It now opens on a **picker**: one tile per lesson, with its own
progress. Tapping one opens a **lesson page** — the summary, then the two halves as cards.

**Choosing changes the route through the day, never the day.** `DailySession.lessonSlices` is a view over the
same task list, not a division of it, and `submitAnswer` still evaluates completion across every lesson at
once. A child who does three lessons in any order has done the same day, and Article 6.5's +5 fires on the last
answer wherever it happens.

The minute of D-75 moved with the summary: it is now the lock on the memory-cards half of the lesson page,
spent once per lesson per day, derived the same way — *a lesson with an answered card has had its summary.*

**Article 4.3 is enforced rather than implied.** The review half is held shut until the cards are done. A child
answering questions about a page they have not studied is being examined rather than taught, and the grade SM-2
gets out of it means nothing. The lock always shows its reason: a tile that simply does not respond is
indistinguishable from a broken one.

Four illustrations were specified for these screens (`docs/illustration-prompts.md`). All four degrade to a
calm tinted placeholder, so none of this waits on artwork.

## D-80 — a memorization card is held for a minute, and why not a study card

**Client request, 2026-08-30:** the child must not be able to rush a card, «حتى يستوعبها».

`cardDwell` = 60 s, **counted from the card appearing, not from the answer.** A child who thinks for forty
seconds waits twenty more; a child who taps instantly spends almost the whole minute with the right answer in
front of them. The card lasts a minute either way, and the child who was actually thinking is not punished for
having done so.

**It does not touch Article 6.3.** The stopwatch feeding the star engine still stops at the moment of the
answer, so the wait is never counted as time spent deciding. If it leaked into `msOnTarget`, every card would
clear the 1.5 s minimum by standing still and the clause would stop refusing anything — that has its own test.

Review questions are **not** paced. Only the cards were asked for, and rightly: a question is answered from what
is already known, and holding a child in front of one teaches nothing.

**The reading that was not built, and why it needs the client's word.** «يقضي دقيقة حتى يستوعبها» could also
mean a *study* card: show the front and the back together for a minute, then quiz. That is a better lesson and
a contract problem — Article 6.1 grants nothing "after the solution was revealed", so every card would be a
revealed one and **the star economy would quietly go to zero**. It is a contract question, not a layout one,
and it is not ours to decide. What was built holds the child on the card for the full minute without showing
the answer first.

**Arithmetic the client should see before approving:** one lesson of 8 cards now costs at least
1 minute (summary) + 8 minutes (cards) = **9 minutes** before the questions begin. Both durations are single
named constants in one file each, so shortening either is a one-line change if 9 minutes turns out to be too
long in front of a real child.

## D-81 — the day never reconciled with the lesson table, so a lesson could be lost for good

**D-78 fixed the wrong half.** It put a lesson into today *at the moment it is captured*, which covers lessons
captured from that build onwards and nothing else. A lesson captured at any other moment — before that code
existed, or through any path that did not reach the capture screen — had **no way back in, ever**: `sessionFor`
is idempotent, and the builder only ever looks at `cards`, never at `lessons`.

**Measured, not reasoned about.** The device database was pulled on 2026-08-30:

```
lessons          1 ('protein'), 2 ('test')
cards            lesson 1 → 12,  lesson 2 → 12
task_instances   day 20695: 12 memorize + 5 review — all of them lesson 1's
lesson 2 cards ever presented, on any day: 0
```

The parent could see the lesson in their own list. The child had no route to it and never would have had one.

`_absorbUnseenLessons` now runs on **every read of the day**, which is what makes it self-healing: the lesson
stranded before this code existed is picked up the next time the child opens their work, with no migration and
nothing for the parent to do. Confirmed on the same device after installing: 34 tasks where there were 17, and
lesson 2 on the shelf.

**Orphaned means never presented, not merely absent today.** A lesson whose cards are partly in the day, or
whose cards SM-2 has scheduled for next week, is being *paced* — dragging it back every morning would undo
spaced repetition entirely. The condition is the narrow one: not one of the lesson's cards or questions appears
in any day's task list. It has its own test.

`absorbLesson` now returns **how many tasks the lesson has in today's list**, not how many rows were inserted.
The two differ in the ordinary case of a day that had not been built yet: the build itself picks the new lesson
up, nothing is appended, and the caller — reading an insert count of zero — would have concluded the lesson had
not made it and skipped refreshing the screen.

**The cost, stated plainly:** several lessons captured on one day now all land on the same day, and
`dailySessionCards` bounds each lesson rather than the day. A day of 34 tasks is unlikely to be completed, and
an uncompleted day earns no +5 (Art. 5). That is visible to the parent on the shelf and is their own doing —
but if it becomes common the answer is to raise `dailySessionCards`, not to start hiding lessons again.

## D-82 — the minute is spent on the card, not on a list

**Completing D-80.** The dwell was already there, but what the child looked at during it was the choice list
with one row turned green. That is feedback; it is not something anybody memorises.

`_StudyBeat` now replaces the options once the answer is known: the front, and the answer under it, large and
alone on a white card, for the rest of the minute. Both card kinds use it — the choice card and the recall
fallback — so there is one study surface, not two that drift.

**The order stays answer-first, and that is a contract constraint rather than a layout preference.** Showing
the answer *before* the attempt is the better lesson and it is not ours to choose: Article 6.1 grants nothing
"after the solution was revealed", so a card that reveals first is a card that can never earn, and Articles 5
and 6 would go to zero **without a single test failing**. Answer first, study second, keeps both the clause and
the minute. Two tests hold that order in place.

If the client wants study-then-test, it is a contract amendment to Article 6.1 and it needs their word in
writing — not a code change decided here.

## D-83 — five payments were stranded, and the cause was a fallback I wrote

**Reported 2026-08-30:** payment sits at «في انتظار تأكيد Chargily» and never moves.

Measured before touching anything:

```
transactions   id 2  paid     2026-08-28
               id 3..7  pending  — none ever confirmed
tunnel log     "Registered tunnel connection"  x1, at 2026-08-29 23:44
               then 891 KB of retry errors, still being written 20 hours later
GET https://patterns-...trycloudflare.com/pay/  ->  000 (no route)
```

So the tunnel had registered **once**, died, and spent the next twenty hours retrying — with its window
sitting there looking perfectly healthy.

### The part that turned an outage into a silent one

`create_checkout` caught Chargily's refusal of the dead `webhook_endpoint` and **retried without the field**,
on the reasoning that the dashboard endpoint would take over and that a checkout beats an error (D-64). The
dashboard endpoint pointed at the same dead tunnel. So each attempt produced a real checkout with **no
reachable webhook at all**, and the parent was sent to a payment page whose result could never come back.

The comment above that code predicted this exactly — *"a checkout created this way may have no webhook at all,
and a payment whose confirmation never arrives is worse than a payment that never started"* — and the code did
it anyway. That is the whole lesson: the reasoning was written down, was correct, and was not followed.

**The two failures are not comparable.** A payment that never starts costs the parent ten seconds; they see it
fail and try again. A payment that starts and can never be confirmed cannot be recovered by the parent at all,
and from where they are sitting the two look identical. The refusal is now taken at face value and raised
**before** a payment exists, with a message a parent can act on rather than one naming `webhook_endpoint`.

In production `CHARGILY_WEBHOOK_URL` is a real domain and none of this branch runs. It exists so a development
mistake cannot look like a working payment.

### And the step that kept being skipped

`tools/webhook_tunnel.ps1` printed the new address and left a human to paste it into `server/.env` on every
single run. **A step a person has to repeat correctly every time is a step that eventually gets skipped.** It
now writes `.env` itself, and:

* **tests the address through the public internet before claiming success** — printing an address is not the
  same as having one that routes, and the 2026-08-29 tunnel proved a banner can be a lie;
* refuses to touch `.env` when the address does not answer, so a stale-but-working value is never replaced by
  a fresh-but-dead one;
* kills any existing cloudflared first, so two tunnels cannot leave half the run pointing at a hostname nothing
  wrote down.

Written **BOM-less** on purpose: `Set-Content -Encoding utf8` on PowerShell 5.1 emits a byte-order mark, and a
BOM on the first line of `.env` makes python-dotenv read the first key with the mark glued to its name — the
server would have started with no `DJANGO_SECRET_KEY` because of a webhook address. The script itself is now
plain ASCII with a BOM, because PowerShell 5.1 reads a BOM-less `.ps1` as ANSI and mangles any non-ASCII
character in it into a parse error pointing at the wrong line.

`CHARGILY_SUCCESS_URL` and `CHARGILY_FAILURE_URL` need no such handling — they are empty, and `apps/web/views`
derives them from the incoming request, so they follow whatever address the parent actually arrived on.

**The five pending rows stay pending.** They are test-mode checkouts that were never paid; there is nothing to
recover, and replaying a webhook for them would be issuing an activation code for a payment that never
happened.

## D-84 — free play is play time, not stars

**Client request, 2026-08-30:** a button on the parent dashboard that lets the child play freely, with a
settable duration — an hour, two hours.

### Why not simply grant stars

A grant of 60 stars buys the same hour and is already supported. It was rejected because it **puts a lie in the
ledger**: the child did not earn 60 stars, Article 5's table is the only thing that should ever add stars to the
balance, and AD-4 exists so that every star in the ledger can be answered for. Stars are what the child
achieved; free play is what the parent gave. Keeping them apart is what lets either be explained later.

So `DayProgress` gained `freePlaySeconds`, the day row gained a column (schema v3 → v4, plain `addColumn` with a
zero default), and the grant lands in the **event log** rather than the star ledger — because "why did my child
play for three hours" still needs an answer, and it is not a star-shaped one.

### One pool, on purpose

`remainingPlaySeconds` is `playable(balance) + freePlay − used`. Earned time and the parent's gift are spent
through the same counter, so there is no order-of-consumption rule to get wrong and no way for two counters to
disagree about when play ends. When the gift runs out the child falls back on what they earned — the behaviour
a parent expects without being told.

It also means the native side needed **no change at all**: the number pushed across the channel simply went up.

### What it is exempt from, and what it is not

* **Article 6.4 — exempt.** The daily ceiling caps what the child *earns*; every parent grant is outside it,
  and the appendix's «فوق النظام» (§4) is the authority.
* **Article 6.7 — not exempt.** It lives on the day, so tomorrow's row has none. A free-play pool stored
  per-child rather than per-day would be exactly the hoarding of play hours the clause forbids, and there is a
  test whose only job is to fail if it ever moves.
* **Article 6.8 — not exempt.** It is counted in *seconds of play consumed*, and consumption is measured by the
  monotonic clock in the native timer. Moving the device clock cannot extend it.
* **Article 5 — untouched.** No star is granted, and `balanceUnits` does not move.

### It adds; it does not set

Two taps on "one hour" mean two hours, because that is what two taps mean. Setting would throw the first hour
away silently and — worse — would do nothing at all once the child had spent part of it, so the button would
look broken.

**There is no stop button, deliberately.** The pause switch directly above it already stops play, and it stops
*all* play rather than unpicking a gift halfway through. Two ways to take time back would be two behaviours to
explain and the parent would have to guess which one they wanted.

### One thing the client should confirm

"An hour of free play" here means **an hour of actually playing**, not "until an hour from now". A child who
plays for ten minutes and puts the phone down still has fifty minutes waiting. That is consistent with how every
other minute in the app is counted, and it is the reading that cannot be cheated by walking away — but if the
client meant a wall-clock window that expires whether or not it is used, that is a different mechanism and a
different conversation.

`Fmt.duration` now shows hours when there are any. `MM:SS` was fine while play time came from stars — the daily
ceiling keeps that under an hour — but two hours of free play would have read `120:00`, which nobody parses as
two hours.

**Verified on the device:** the v3 → v4 migration ran on the real database with no error, `free_play_seconds` is
present, and the existing day, 2 lessons and 24 cards came through untouched.

## D-85 — the memorization cards are off, and this is a contract amendment

**Client request, 2026-08-31:** remove the cards; the day is questions only.

**This is not a UI change and it should not be recorded as one.** Appendix §5 publishes the daily session size
as **5–30 cards**, and that floor of 5 is precisely what guarantees the first two rows of Article 5's table are
reachable:

| Article 5 row | Stars | While cards are off |
|---|---|---|
| Memorization card correct, first time | 1 | **never earnable** |
| Card in a later review | 0.5 | **never earnable** |
| Correct review question | 2 | unchanged |

Article 2's spaced repetition has nothing left to schedule — SM-2 schedules cards — and Article 4.3's
memorize-then-review ordering has only the second half. **The client should confirm this in writing**, because
it changes what the delivered product does against a signed specification, and because it changes what a day is
worth: 12 cards + 5 questions was 22 stars before bonuses; 5 questions alone is 10.

### How it was done, and why that way

`dailySessionCards` now accepts **0–30 and defaults to 0**. One number, in the contract's own vocabulary,
parent-adjustable where appendix §5 says these numbers live.

**Nothing was deleted.** `lunio_sm2`, the card tables, `CardChoices`, the recall card and the study beat are all
still there and still tested — `session_repository_test` and `session_reachability_test` now ask for
`dailySessionCards: 12` by name, so Article 5's card rows keep their coverage and the day the client reverses
this, it is one setting rather than a re-implementation.

Two schema steps. **v4 → v5** writes `daily_session_cards = 0` on installs that already exist — a changed Dart
default reaches new installs only, and without this the client's own phone would have been the one place the
change did not happen. **v5 → v6** deletes the *unanswered* memorization tasks from days that were already
built, because otherwise the amendment appears to do nothing until tomorrow on the one device anybody is
looking at. Answered cards are left alone: they earned their star under the rules in force at the time, and the
ledger has to keep agreeing with the day it describes. It is a second step rather than part of the first only
because the development phone had already taken v5 by the time it was written.

That exposed something worth keeping: **the task counts on the day row now re-derive themselves.** They are what
the child's home screen reads and what Article 6.5 measures completion against, and they were written by
whoever last changed the list — so a migration removing rows behind their back left the home screen advertising
seventeen tasks when five existed. `sessionFor` now compares and rewrites them when they disagree, which also
makes any future drift self-correcting.

The lesson page drops the memorize half entirely when there are no cards rather than showing it greyed at
"0 of 0" — a permanently locked tile is a promise of something that is never coming. The summary minute moves
with it: it now guards whichever half the child meets first.

**The day is short.** Five questions is what `dailyQuestionCount` defaults to, and with the cards gone that is
the whole day. The range is 0–15 and it is on the parent settings screen; the client may well want it at 10–15
now. Not changed unasked — one amendment at a time.

## D-86 — the retry feature opened a hole in the star table, and a test caught it

**Client request, 2026-08-31:** a question answered wrongly comes back, with the answer in a different place.

The re-asking itself is cheap and needs no contract thought: Article 6.1 pays only for an answer correct on the
**first** attempt, so a repeat is practice. Capped at three presentations, because a child who has missed the
same question twice is not taught by a third identical screen — and an unbounded retry is a day that can never
be finished, which would put Article 6.5's +5 permanently out of reach for the child having the hardest time.

**Then the test for "the second attempt earns nothing" failed, and it was right to.** The retry paid the full
two stars.

The screen builds a fresh widget per task and therefore always reports `attemptNumber: 1`. That was harmless
while nothing was ever re-asked. With retries it became: **answer wrongly, read the right answer off the
screen, answer again, collect two stars** — repeatable on every question in the day.

Article 6.2's dedupe does not close it. That clause records targets that were *awarded*, and a wrong answer
awards nothing, so the second pass looked untouched. Article 6.1 is the clause that refuses it, and it can only
do that if it is told the truth.

So the attempt number is now **counted from the day's own task rows rather than claimed by the caller** — the
caller's value is kept as a floor, not discarded. The SM-2 reschedule is handed the same number, or a card
graded as a first recall would be scheduled as though it had been one.

**Worth stating plainly: the hole did not exist before this feature, and nothing in the app would have shown
it.** The stars would simply have been slightly too easy to get, for ever. It was found because the test was
written from the article rather than from the implementation.

### The re-ordering

Applied per *presentation*, in `_readSession`, seeded by the `task_instances` row id — not by the question. So
the same question asked twice today is asked two different ways, while a child who leaves mid-question and
comes back finds the options exactly as they left them. Re-rolling on every read would look like the app losing
its place and would let a child reopen a question until the layout felt easy.

This is a second shuffle on top of D-74's, and both are wanted: that one fixes the order the model stored, this
one fixes the order the child was just shown.

## D-87 — a code that works now says so

**Client request, 2026-08-31.** Redeeming an activation code used to clear the text field and change a chip
further up a screen the parent may not have been looking at.

That is thin at the one moment in the product where certainty matters most. The parent has left the app for a
browser, paid on a page they had never seen before, and carried a short string back by hand. **A silent success
is indistinguishable from a form that did nothing** — and the natural response to that is to type the code
again, or to ask whether the money went somewhere.

`ActivationDoneDialog` states the two facts they need — *it worked*, and *until when* — and one they do not
know they need: **Article 7.1 keeps the blocking engine, the stars and every saved lesson working with or
without a subscription**, and only new AI generation stops. A parent who believes the whole app dies at expiry
is paying under a false impression, and the contract is explicit that the child is never punished for a payment
delay.

**No price, no plan comparison, no renewal prompt.** Article 7.2 keeps the shop outside the app, and a
confirmation is not a place to sell the next one. A test asserts both.

**Success is the absence of an `ApiFailure`, not the returned bool.** `activate` posts the code and then
returns whatever `refresh` returned, so a subscription activated on the server whose snapshot refresh came back
empty would have reported `false` — and told a parent who had just paid that their code did not work. That
distinction is the only subtle line in the change.

The dialog reads the cache live rather than taking values passed in, so what it shows and what the status card
behind it shows cannot disagree.

Artwork: `subscription_done.webp`, prompt in `docs/illustration-prompts.md` §5. It degrades to a mint
placeholder, so none of this waits on the drawing.

## D-88 — MySQL instead of PostgreSQL, because the host has nothing else

**Established 2026-08-31 by looking at the cPanel account**, not by assuming: the Databases section offers
phpMyAdmin, *Manage My Databases* and a wizard. There is no PostgreSQL on the plan. The database
`zebqkuzf_db` and the user `zebqkuzf_Ilyes` already exist.

Article 3 names **PostgreSQL**, so this is an amendment and **needs one written line from the client**. It is
recorded here rather than absorbed quietly, because "the database engine changed" is exactly the kind of fact
that is obvious during a dispute and invisible before one.

**The cost is small, and that is checkable rather than a hope.** Django's ORM covers the difference, no raw SQL
exists outside migrations, and the longest indexed column in the schema is 160 characters — 640 bytes at four
bytes per character, comfortably inside MySQL's legacy 767-byte index limit. Nothing had to be redesigned.

Two changes were required:

* **PyMySQL, not `mysqlclient`.** Django speaks to MySQL through `MySQLdb`, which `mysqlclient` provides as a
  C extension needing a compiler and MySQL headers — shared hosting rarely has either. PyMySQL is pure Python
  and registers itself under that name. The call sits in `config/__init__.py` because it must run before
  Django resolves a backend, which happens before any settings module is imported. It is wrapped in a
  `try/except ImportError`, so a PostgreSQL deployment skips it and the agreed stack stays the default rather
  than becoming a special case.
* **utf8mb4 and `STRICT_TRANS_TABLES`.** MySQL's "utf8" is three bytes wide and silently truncates a row at
  the first character outside the basic plane. Strict mode turns a value that does not fit into an error
  instead of a quiet coercion — a star ledger that rounds a number because a column was too small is worse
  than one that refuses the insert (AD-4).

The other half of Article 3's stack — Docker, Nginx, Gunicorn — is equally absent on shared cPanel; Passenger
replaces it. Same amendment, same need for the client's agreement, recorded in the header of
`config/settings/prod.py`.

## D-89 — MariaDB silently dropped Article 7.3's idempotency guard

**Found on the production deployment, 2026-09-09**, in a line of `migrate` output that reads like
housekeeping:

```
payments.WebhookEvent: (models.W036) MariaDB does not support unique constraints with conditions.
        HINT: A constraint won't be created.
```

D-42's fix is a **partial** unique index — `event_id` unique only where `signature_valid` is true, so a forged
delivery can be recorded for the audit trail without reserving the id a genuine one will need. PostgreSQL has
partial indexes. **MariaDB does not**, and Django skips the constraint with a warning rather than an error.

**Nothing failed.** The migration reported OK, the table was created, and the webhook view's
`except IntegrityError` sat waiting for a violation that could no longer occur. A gateway retry of an already
processed payment would have been processed a second time and **issued a second activation code for one
payment** — on a live-mode deployment, with real money.

The fix is a plain unique nullable column, `verified_event_id`, set to `event_id` when the signature verified
and NULL otherwise. MySQL, MariaDB and PostgreSQL all allow many NULLs in a unique index, so refused
deliveries do not participate — the same guarantee, expressed in something every engine implements. It is
maintained in `save()` rather than at the three call sites, because the fourth call site is the one that would
forget. The partial constraint is **kept** for PostgreSQL, where it states the rule more directly.

**The tests are written against the column, not the constraint.** On SQLite the partial index works, so a test
that merely tried a duplicate insert would have passed for the wrong reason and said nothing about the engine
actually deployed to — which is exactly how this survived a green suite in the first place.

Two lessons worth keeping:

* **A warning during a deploy is a finding until proved otherwise.** This one was a single line among nineteen
  `OK`s, and it was the only sign.
* **The database engine belongs in the test matrix, not underneath it.** D-88 changed the engine, and this is
  the second defect that change surfaced — the first being a latin1 database that would have refused every
  Arabic lesson the app ever tried to save.

## D-90 — a settings merge that started from nothing deleted the file storage

**Reported by the client on 2026-09-09 as "the AI is not working".** The AI was never reached.

Adding WhiteNoise wrote the static-files backend like this:

```python
STORAGES = {**globals().get("STORAGES", {}), "staticfiles": {...}}
```

on the assumption that it was merging into Django's defaults. `base.py` never defines `STORAGES`, so the merge
began from an empty dict and the result had **no `default` entry**. A settings module that assigns `STORAGES`
replaces `global_settings` wholesale — there is no partial override, and nothing warns.

Every request that touched an uploaded file then raised `InvalidStorageError: Could not find config for
'default'` and returned 500. **Everything else kept working perfectly**: registration, login, tokens, the
subscription endpoints, the payment page, every static asset. Only the one endpoint that receives a photograph
was affected, which is exactly why it read as an AI failure.

### What let it through

Every check the deployment ran passed — `migrate`, `check --database default`, `collectstatic`, `200` on
`/api/health/`, `405` on the webhook, `200` on `/pay/`. The test suite passed too: it runs on
`config.settings.dev`, which never touches `STORAGES`.

**The production settings module was the one file nothing imported.**
`apps/lessons/tests/test_production_settings.py` now imports it directly and asserts both storage keys, `DEBUG`
off, no wildcard host, and that WhiteNoise sits where it is documented to sit. It lives beside the lessons app
because the lesson upload is the request that broke.

### The `default` entry is deliberately unusable

`MEDIA_ROOT` is None (base.py, Article 14 — nothing a child photographs is ever stored on the server), so the
backend resolves and then fails on any write. That is the correct shape: Django can serve a request, and an
accidental write fails loudly instead of quietly persisting a page from a schoolbook.

### How it was found

**By measurement, not by reading.** The same request was 500 against production and **200 in 3.2 seconds**
against a local server using the same key, the same model and the same image. That ruled out Groq, the API key,
the model name, the photograph and the network in a single step, and left only the environment — which is a
much smaller place to look.

## D-91 — the token-expiry retry could not re-send a photograph

**Found on the device on 2026-09-09, immediately after D-90 was fixed.** The same lesson upload that returned
**200 in 5.6 seconds** through `curl` failed inside the app with «تعذّر الوصول الى الخادم» — *the server could
not be reached*. It had been reached. It had answered.

`ApiClient._send` renews an expired access token and then calls the request closure a second time. The lesson
upload's closure captured one already-built `FormData`. Dio finalizes a `FormData` into a stream as it sends it
and throws on a second finalize, so the retry raised a `StateError` from inside Dio, Dio reported it as
`DioExceptionType.unknown`, and `_networkFailure` had no branch for that except the transport fallback.

### Why it was the normal case, not an edge case

SimpleJWT's default access-token lifetime is **five minutes**, and we never overrode it. The path from signing
up to photographing a page — grade, PIN, the accessibility disclosure, the dashboard, finding the schoolbook —
takes longer than five minutes for anyone doing it for the first time. So the 401 was not bad luck: it was the
ordinary state of the token by the time the parent pressed the shutter, and the one request in the app that had
to survive a retry was the only one that could not.

Every other call retried perfectly, because every other call sends JSON, and JSON can be sent twice.

### The fix

`ApiClient.post` now takes a **builder** — `Future<FormData> Function()` — rather than a `FormData`. There is no
pre-built body for a caller to hand over, so the retry gets a fresh one and the mistake cannot be made again by
someone who has not read this entry. `LessonRepository.process` passes `body`, which reopens the file.

`_networkFailure` also stopped calling this a transport problem. `unknown` is Dio's bucket for anything thrown
while it was working, and a bug of ours on the way into the socket lands there beside a genuine socket failure.
Sockets and TLS keep the connection wording; everything else now says less rather than something false.

### What let it through

`app/test/lesson_repository_test.dart` stages responses through a fake adapter and never staged a 401 followed
by a 200 — the only sequence that exercises the retry. `api_client_retry_test.dart` now does, for a multipart
body and a JSON one, and checks that the second attempt carries the renewed token **and** the photograph.

### The pattern behind D-89, D-90 and D-91

Three faults in one day, all invisible to a green suite, all found only by running the real thing against the
real server. The suite tested our code; none of it tested the seam between our code and everything underneath —
the database's charset, the production settings module, the HTTP client's own stream semantics. That seam is
where all three lived.

## D-92 — the password reset is a code in an email, not a link

**Client request, 2026-09-19.** A parent who forgets the account password currently has no way back in
except asking the client to edit the database.

### A six-digit code rather than a reset link

A link has to be opened by *the app*, and the app has no deep links — no intent filter, no
`assetlinks.json`, no App Links verification. A link would therefore open a browser, which would need its own
reset page, its own session handling and its own place to put a password. The parent would end up carrying a
credential between two programs.

A code goes the other way: the browser is never involved, the new password is typed inside the app over the
same TLS as everything else, and **the parent has already done this exact errand once** — Article 7.3 step 5
has them read an activation code on a web page and type it into the app.

Six digits is a million possibilities. What makes that safe is not the number, it is the budget: **five wrong
attempts and the code dies**, whichever endpoint spent them, so the chance of guessing is one in two hundred
thousand and the parent simply asks for another. Fifteen-minute lifetime, one live code per account, and a
sixty-second cooldown so nobody can bury an inbox by tapping a button.

The code is stored through Django's password hasher. Six digits under an unsalted digest is a rainbow table
somebody builds in an afternoon, and anyone who read the table would otherwise hold a live reset for every
account with a code outstanding.

### Three endpoints, because the middle one is a kindness

`verify/` exists only so the app can say "that code is wrong" **before** asking the parent to invent a
password. Being made to type a new password twice and only then told the code expired is the kind of small
cruelty that gets an app deleted. It costs nothing: it draws on the same five attempts as `confirm/`, so it
buys the parent patience and an attacker nothing.

### The same answer for an address that exists and one that does not

Requesting a code is always 200 — whether an account was found, whether a message was sent, and **whether the
mail server accepted it**. A wrong code, an expired code, a burnt-out code and an unknown address all return
one 400 with one sentence.

This matters more here than on an ordinary service. The account list is parents of school children in one
country, and the phone is regularly in a child's hands. "No account with that email" is a working lookup tool
for whoever is holding it.

The *timing* still leaks — an unknown address skips the mail send and answers faster. Closing that would mean
sleeping a request thread on a shared host, which costs more than the leak is worth. Written down rather than
pretended away.

### `CHECK_REVOKE_TOKEN`, and the one-time sign-out it causes

A reset that changes the password and leaves the intruder signed in has done nothing. SimpleJWT can bind a hash
of the password into every token and check it on each request, which ends every other session the moment the
password changes — one settings line instead of a blacklist app and two tables.

**It signs every currently-issued token out once.** A token minted before the setting carries no hash claim and
is refused; refreshing it yields another token with no claim, so the parent signs in again. That is why it went
in now, while the app is in nobody's hands but the client's.

### The email

Tables, inline CSS, fixed 600px, and **it has to be good with every image gone**, because that is what an
image-blocking client shows. The illustrations travel inside the message as `related` parts referenced by
`cid:` — a remote `<img>` is blocked by default in Outlook and proxied by Gmail, so artwork at a URL arrives
broken for a large share of readers, and this is the one message where looking broken matters: a parent who has
just asked for a reset is already wondering whether the mail is a phishing attempt. PNG, not the app's WebP,
because Outlook renders through Word and has no WebP decoder.

### Found while testing: the dev console backend cannot print this message

On Windows, Python opens stdout in the console code page (cp1252 here) and the subject line is Arabic, so
`console.EmailBackend` raises `UnicodeEncodeError` and prints nothing. The endpoint then answers 200 anyway —
**correctly**, since a visible send failure is the enumeration oracle above — so a developer asks for a code, is
told cheerfully that one was sent, and there is no code anywhere.

Development now writes each message to `server/sent_emails/` as a file, which is the better tool regardless:
the message is HTML with inline illustrations, and a `.eml` opened in a mail client shows what a parent will
actually see. Production is unaffected; it has always been SMTP, and `prod.py` refuses to start without the
credentials for the same reason it refuses to start without a database.

## D-93 — the reset email sends from the domain, not from a personal Gmail

A personal Gmail account with an app password was offered on 2026-09-20 as the sending mailbox, with two
requirements: **the owner's address must not be visible to parents, and neither must their profile photo.**

Neither is possible through a personal Gmail account, for two separate reasons.

### The address

Gmail's SMTP rewrites `From` to the authenticated account unless the address is a verified *Send mail as*
alias. Setting it to `Lunio <no-reply@bafisslunio.com>` and sending was **accepted at the SMTP layer** — which
proves nothing, because acceptance and header preservation are different things, and Google does the rewrite
silently after the transaction closes.

Worse, if the header *were* preserved, it would be actively harmful: SPF and DKIM would align with
`gmail.com` while the From claimed `bafisslunio.com`, so the message fails DMARC for the domain it claims to
come from. That is the exact signature of a spoofed email, and it is scored accordingly.

### The photo

Gmail shows the **sending account's** Google profile picture to every Gmail recipient. There is no per-message
control and no header that suppresses it. The only way to remove it is to remove the photo from the Google
account, which also removes it from the owner's personal correspondence.

### What is used instead

`no-reply@bafisslunio.com`, a cPanel mailbox on the site's own domain.

* It is not a Google account, so there is no avatar to leak.
* The address **is** the brand, so there is nothing to hide.
* SPF, DKIM and DMARC all align with the domain the message claims, which is the single biggest factor in
  whether a transactional email reaches an inbox rather than a spam folder.

The Gmail credentials remain usable for **development**, where the question being answered is "does it arrive,
does it look right, are the illustrations visible without pressing *show images*" — and for that, any working
SMTP server will do. `config/settings/base.py` reads the mail settings from the environment for exactly this
reason; production overrides all of them and refuses to start without them (D-92).
