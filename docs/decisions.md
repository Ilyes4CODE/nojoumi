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
