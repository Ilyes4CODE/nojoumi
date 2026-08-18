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
to show all apps. Nojoumi, Settings, Phone, Messages and the current IME are permanently unblockable
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
`tester.runAsync` did not fix it either, which is where CLAUDE.md's "if an approach fails twice, stop" applied.

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
- the disclosure still contains its **negative** half ("لا يقرأ نجومي محتوى الشاشة…"), which is the half a
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

`NojoumiClock.kt` therefore sits in `app/android/app/src/main/kotlin/dz/nojoumi/` and is registered in
`MainActivity.configureFlutterEngine`. **It moves into `native/bridge` when that module is scaffolded**, together
with the blocking channels — this is a sequencing decision, not an exception to AD-7.

### D-31 · ✅ RESOLVED: the Arabic project folder broke Dart code generation on Windows · fixed 2026-08-18

**The symptom.** `dart run build_runner build` failed in this repository with:

```
Error: Unable to write file: c:\users\ilyes\desktop\?????\app\.dart_tool\build\entrypoint\build.dart.aot
```

The AOT compiler mangled «نجومي» to `?????` and could not write its snapshot. Proven by elimination: the
identical sources built successfully in an ASCII path (14 outputs, 34 s), and a Windows junction from an ASCII
path did **not** help — the toolchain resolved the junction back to the real name.

**The fix, applied 2026-08-18: the working directory was renamed to ASCII** — `C:\Users\Ilyes\Desktop\nojoumi`.
The Arabic name lives where it belongs: the app's display name, the store listing, and every user-facing
string. It never needed to be in the filesystem path.

**Verified from the new path, in this order:**

1. `.dart_tool` deleted in `app/` and in all four packages — it caches absolute paths, so the stale ones had to go.
2. `flutter pub get` in `app/`, `dart pub get` in the four packages — all resolved.
3. `dart run build_runner build` — **`Built with build_runner/aot in 33s; wrote 21 outputs.`** This is the exact
   command that failed before; it now succeeds from the real project path with no scratch directory involved.
4. Full test sweep from the new path: `nojoumi_time` 21 · `nojoumi_stars` 89 · `nojoumi_subscription` 42 ·
   `nojoumi_sm2` 46 · `app` 16 · `server` 81. All green.

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
Choice: **SM-2**, every parameter injectable, in `packages/nojoumi_sm2`.

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
- Consistent with Art. 1: Nojoumi is a motivation tool, not a kiosk.

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
