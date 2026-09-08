# Hardware verification — what to do the day the phone arrives

Everything native in this repository is **UNVERIFIED** until a step below is signed off. This file is the
checklist for the parts that are not blocking; `blocking-checklist.md` covers Article 12.

None of this can be seen from a build machine. Each step therefore states: what to do, **what should appear**, how long it
should take, and which logcat tag to filter. If what appears is not what is written here, report all six items
from the bottom of `blocking-checklist.md` — device model, Android version + skin, exact steps, expected, actual,
logcat.

---

## Run header

| Field | Value |
|---|---|
| Date | |
| Build / commit | |
| Device model | |
| Android version + OEM skin | |
| RAM | |
| Installed via | `flutter run` / sideloaded APK / internal test track |

---

## H1 — the app builds and installs from the ASCII path

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
cd C:\Users\Ilyes\Desktop\lunio\app
flutter run
```

**Why this is step one.** `decisions.md` D-31 renamed the project folder to fix Dart code generation, and the
Gradle half of that worry has **never been tested** — the risk was removed by construction, not verified. If
Gradle fails on a path or a 260-character limit, it fails here, on day one, and not on delivery day.

- ☐ Gradle configures and the APK installs
- ☐ the app opens on the **setup wizard**, in Arabic, laid out right-to-left
- ☐ nothing in the tree is mirrored wrongly — check the back arrow, the progress bar and the text fields

Expected time: first Gradle build 3–10 minutes; afterwards under a minute.

---

## H2 — the clock channel (`LunioClock`, notes V9)

Filter: `adb logcat -s LNO_CLOCK`

The Dart side never reads a clock; it folds what this channel reports. So a wrong reading here silently poisons
Article 6.8 and Article 7.6 everywhere else, and none of the 21 pure-package tests would notice.

### H2.1 — first run

- ☐ `LNO_CLOCK  boot token rotated: first_run` appears once, on the first reading after install
- ☐ it does **not** appear again while the app stays open

### H2.2 — a reboot rotates the token

1. Note the time, reboot the phone, open Lunio.
- ☐ `boot token rotated: elapsed_regressed` **or** `boot_instant_moved` appears
- ☐ the child's star balance is unchanged
- ☐ the "ساعة الهاتف غير موثوقة" card does **not** appear (a reboot is not tampering)

### H2.3 — a reboot after a long uptime

The important one, and the reason signal 2 exists: leave the phone up for **longer than the previous session**
before rebooting, so `elapsedRealtime` does not regress.

1. Leave the phone on for several hours with Lunio open at least once.
2. Reboot, wait past that earlier uptime, then open Lunio.
- ☐ the token still rotates — expect `boot_instant_moved`
- ☐ if it does **not** rotate, stop and report: this is the one failure that could over-state time

### H2.4 — Doze overnight must not rotate the token

1. Leave the phone unplugged and untouched overnight.
2. Open Lunio in the morning.
- ☐ **no** rotation line for that reading — `elapsedRealtime` is documented to keep counting through deep sleep,
  and a rotation every morning would mean a needless re-anchor every morning

### H2.5 — moving the clock (this is checklist scenario 12, from the app's side)

For each of: forward one day · backward one day · automatic time off then set by hand · timezone change

- ☐ the child's screen shows **ساعة الهاتف غير موثوقة**
- ☐ answering a card correctly earns **nothing**
- ☐ the balance and the remaining play time are **unchanged** — nothing is confiscated either
- ☐ `LNO_CLOCK` shows a rotation on the wall-clock change
- ☐ restoring automatic time recovers the app with **no parent action**

---

## H3 — the setup wizard, including the Play disclosure

No logcat tag; this is read with the eyes. It is also the screen a Play reviewer opens first.

- ☐ four steps, and the progress bar advances
- ☐ the grade field accepts Arabic and the "next" button stays disabled while it is empty
- ☐ the PIN step rejects three digits and rejects two PINs that differ
- ☐ **the disclosure checkbox starts unchecked, every single time**
- ☐ both switches are greyed out until the checkbox is ticked
- ☐ "أكمل بدونهما الآن" finishes setup with blocking and launcher mode **off** (Art. 15.2)
- ☐ after finishing, the child's screen shows **10 نجمة** and **10:00** of play time
- ☐ reinstalling and finishing setup again does **not** grant the welcome balance twice

### H3.1 — PBKDF2 cost on the low-end device

`PinHasher.iterations` is 120 000, chosen on a desktop.

- ☐ time the PIN step on the Article 13 reference device — from tapping "next" to the next screen
- ☐ **if it exceeds roughly a quarter of a second, lower the constant** and note the measured value here.
  Measured: ______ ms on ______________

---

## H4 — the child's home screen

- ☐ the balance reads `3.5` for three and a half stars, and `4` — never `4.0` — for four
- ☐ play time reads `mm:ss` and the digits do not jitter as they change (tabular figures)
- ☐ pull-to-refresh re-reads the clock
- ☐ **nothing on this screen mentions a price, a plan, a purchase or a subscription** (Art. 7.2). Read every
  word on it once, deliberately, and confirm.

---

## H5 — restricted settings (notes V6)

Only when installing from a file rather than from Play.

1. Sideload the APK, then try to enable Lunio's accessibility service.
- ☐ record whether Android refuses with **"Restricted setting"**
- ☐ record the exact path that unblocks it: App info → ⋮ → Allow restricted settings
- ☐ this path, with screenshots, belongs in the Arabic parent guide (Art. 16.4's fallback depends on it)

## H6 — the daily session

Added 2026-08-18 with the session screen. No logcat tag; read with the eyes, on the device, with a real child if
possible.

- ☐ the front of a card shows **أعرفها · لم أعرفها · أظهر الجواب**, and the back is **not** visible yet
- ☐ after any of the three, the back appears with "إجابة صحيحة" or "إجابة خاطئة"
- ☐ **أظهر الجواب** earns nothing — check the balance before and after
- ☐ **أعرفها** on a card never seen before adds exactly **1** star
- ☐ the same card tomorrow adds exactly **0.5**
- ☐ a correct review question adds **2**
- ☐ tapping through a card faster than 1.5 s earns **nothing** (Art. 6.3) — try deliberately
- ☐ idling on the *answer* screen for a minute does **not** rescue a too-fast choice
- ☐ answering the last task adds **+5**, and **+3** more if yesterday's session was also completed
- ☐ killing the app mid-session and reopening resumes at the same task, with the same cards in the same order
- ☐ the whole session is legible one-handed on the reference device, in daylight

### H6.1 — the Article 11.4 full cycle

The acceptance criterion, run end to end with **no manual intervention**: capture a lesson → tasks appear →
answer them → stars appear → a blocked game opens → the balance runs down → blocking returns.

Blocking does not exist yet, so today this stops at "stars appear". Re-run it in full once the Kotlin modules
land, and record the date it first passed unbroken: ______________

---

## H7 — the parent's dashboard

Reached from the icon at the top of the child's screen. Everything below is behind the PIN.

- ☐ the gate hides the dashboard until the correct PIN is entered, and the field shows dots
- ☐ four wrong PINs in a row still allow a fifth try; the fifth wrong one starts a wait, and the wait doubles
- ☐ the wait is announced in seconds, not as a dead button
- ☐ the ceiling bar moves when the **child earns**, and does **not** move when **you grant** — Art. 6.4 caps
  earning only, and a parent grant sits above the system
- ☐ granting 2.5 stars adds exactly 2.5, and the ledger shows `+2.5`
- ☐ deducting more than the balance is refused with a message, not silently clamped
- ☐ a grant works while the "ساعة الهاتف غير موثوقة" warning is showing (appendix §4)
- ☐ pausing play makes the child's remaining time read `00:00` and shows
  "اللعب موقوف مؤقتاً من طرف الوالد" — and un-pausing restores the **same** balance, not a reset one

### H7.1 — the six numbers of appendix §5

For each: push it to both ends of its printed range and confirm the button greys out rather than accepting more.

| Setting | Floor | Ceiling |
|---|---|---|
| قيمة النجمة بالدقائق | 0.5 | 3 |
| السقف اليومي للنجوم | 20 | 150 |
| الحد الأدنى للوقت على البطاقة | 1 s | 5 s |
| حجم الجلسة اليومية | 5 | 30 |
| أسئلة المراجعة يومياً | 0 | 15 |
| الرصيد الترحيبي | 0 | 30 |

- ☐ "دقائق اللعب اليومية" recomputes when either the ceiling or the star value changes (D-2: one stored value)
- ☐ lowering the star value to 0.5 makes the child's play time halve **without** their star balance changing
- ☐ lowering the minimum card time to 1 s changes what earns on the next card, not retroactively

### H7.2 — the ledger, which is the answer to the client's questions

- ☐ every award, grant, deduction and expiry appears as its own row with the right sign
- ☐ the "لماذا لم تُمنح نجمة؟" tab names the Article 6 condition that stopped each attempt
- ☐ deliberately tap a card in under 1.5 s, then check the tab says
  "الوقت على البطاقة أقل من الحد الأدنى (المادة 6.3)"

---

## Not covered here

Blocking, launcher mode, overlay, DeviceAdmin and boot recovery are `blocking-checklist.md`. None of that code
exists yet — the Kotlin blocking spike is the first thing to run on the device after H1 and H2 pass.

---

## H8 — the lesson cycle, end to end

Added 2026-08-21 with the capture flow. This is the first half of acceptance
criterion 11.4 — a full Article 4 cycle with no manual intervention — and the only
half that can be run before the blocking layer exists.

**Before you start**, the app needs a server it can actually reach. The emulator
default is `http://10.0.2.2:8000`; a real phone needs the machine's LAN address:

```powershell
cd C:\Users\Ilyes\Desktop\nojoumi\server ; python manage.py runserver 0.0.0.0:8000
cd C:\Users\Ilyes\Desktop\nojoumi\app    ; flutter run --dart-define=LUNIO_API_BASE=http://192.168.x.x:8000
```

Android blocks cleartext HTTP by default on targetSdk 28+. If the app cannot reach
the server over plain `http`, that is the cause, not a bug in the client — and it
is one more reason the real deployment needs the HTTPS URL of Q19.

### H8.1 — the account

- ☐ "إنشاء حساب" with a fresh email succeeds and signs in immediately
- ☐ a password of four characters is **refused by the server** with a readable
  Arabic message (Django's validators, D-26 — the setting was missing once)
- ☐ signing in with a wrong password says «البريد الإلكتروني أو كلمة المرور غير صحيحة»,
  not a stack trace and not a generic failure
- ☐ **sign out, then confirm the child's screen is unchanged**: stars, play time and
  saved lessons all still work (Art. 7.1). Only capture stops.

### H8.2 — capturing a page

- ☐ the capture screen offers both camera and gallery
- ☐ with the parent signed out, both buttons are replaced by «سجّل الدخول لتوليد درس جديد»
- ☐ photograph one clear schoolbook page; the processing screen names itself rather
  than showing a bare spinner
- ☐ **time it.** Groq measured ~2 s per page on the desktop (D-28); record what an
  Algerian mobile upload actually costs: ______ s
- ☐ a deliberately blurred or dark page returns «الصورة غير واضحة» and offers a retry
- ☐ turning off wifi and mobile data mid-capture gives «لا يوجد اتصال بالإنترنت», not a
  hang

### H8.3 — reviewing before saving

- ☐ the summary, the cards and the questions all appear before anything is saved
- ☐ removing a single card with the × leaves the rest intact
- ☐ removing **every** card disables the save button — a lesson with no cards is a
  lesson the child can never study
- ☐ "تجاهل" leaves the database untouched: the lessons list is unchanged

### H8.4 — Article 14, on the device

This is the one the client will ask about, and it is checkable with `adb`.

```
adb shell run-as dz.lunio ls -R files/lesson_images
adb shell ls /sdcard/Android/data/dz.lunio 2>&1
```

- ☐ the photograph is **inside** `run-as` private storage — that is the point of the
  first command: only the app itself can list it
- ☐ **nothing** app-related appears in `/sdcard`, `DCIM`, `Pictures` or `Download`
- ☐ the photo does **not** appear in the phone's gallery app
- ☐ on the server, confirm no image was written: the lesson endpoint has no model
  and no storage, and `apps/lessons/tests/test_privacy.py` fails the build if one
  appears — but look at the server's `media/` directory once with your own eyes

### H8.5 — the cycle closes

- ☐ after saving, the child's home shows «مهام اليوم» with a task count instead of
  «لا توجد مهام بعد»
- ☐ the session opens, the cards are the ones just saved, and answering them awards
  the Article 5 amounts
- ☐ finishing the day awards **+5**, and play time appears on the balance card

At that point Article 4's cycle is proven up to "the game opens" — which needs the
Kotlin blocking layer, and is H1 of `blocking-checklist.md`.

---

## H9 — the subscription, and the signature that guards it

Added 2026-08-21. Article 7.6 makes the server the source of truth and the local
copy a **signed** cache, so the checks below are as much about what must *fail* as
what must work.

**The build needs the public key**, or nothing verifies and every state reads as
expired — which is free mode, and correct, but not what you are testing:

```powershell
cd C:\Users\Ilyes\Desktop\nojoumi\server ; python manage.py generate_signing_key
# private half -> server/.env, public half -> the flag below
cd ..\app ; flutter run `
  --dart-define=LUNIO_API_BASE=http://192.168.x.x:8000 `
  --dart-define=LUNIO_SNAPSHOT_PUBLIC_KEY=<64 hex characters>
```

### H9.1 — the ordinary path

- ☐ "ابدأ الفترة التجريبية" moves the state to **تجريبي** with an end date seven days out
- ☐ starting it a second time is refused — Art. 7.1, once per device
- ☐ a valid activation code moves the state to **فعّال** and shows the plan
- ☐ an invalid code is refused with a readable Arabic message, and the state does
  not change

### H9.2 — Article 7.2, read with your own eyes

- ☐ **no price, no amount, no buy button and no payment link** appears anywhere on
  this screen or any other screen inside the app
- ☐ the renewal line is plain text — not a button, not underlined, not tappable

This is the check a Play reviewer effectively performs, and it is why the app is
outside the billing policy. Read every word on the screen once, deliberately.

### H9.3 — the signature, tampered with on purpose

The interesting half. With the app signed in and active:

```
adb shell run-as dz.lunio sqlite3 files/lunio.sqlite \
  "UPDATE subscription_caches SET ends_at_ms = ends_at_ms + 2592000000;"
```

- ☐ reopen the subscription screen **offline** and confirm the state reads
  **منتهٍ**, not active — the payload no longer matches its signature
- ☐ confirm the child's screen is unaffected: stars, play time and saved lessons
  all still work (Art. 7.1). Tampering costs the child nothing and gains them
  nothing.
- ☐ go online and reopen: the real state returns from the server

### H9.4 — the seven-day offline window

- ☐ sign in, let a snapshot cache, then turn off all connectivity
- ☐ the app keeps working: the recorded state persists, and new-lesson generation
  is the only thing that fails
- ☐ **do not** test the seven-day boundary by moving the device clock — that is
  scenario 12, and it must show the tamper card rather than expiring the
  subscription (Art. 7.6). Test the window by waiting, or not at all.

---

## H10 — the blocking spike on the Oppo A15 (ColorOS, Android 10)

Added 2026-08-27, the day the first real device arrived.

**Read this first: the Oppo A15 is not the reference device and cannot sign off Article 11.**
Article 13 fixes the acceptance device as Samsung / One UI, Android 12+, 4 GB+ RAM. The A15 is
ColorOS, Android 10, 2–3 GB. Everything below is *development* verification: it can prove a thing
is broken, and it cannot prove a thing is accepted.

What it is unusually good for, and why it is worth a full session:

| It tests | Because |
|---|---|
| **API 29 exactly** — our `minSdk` floor | Nothing else in the project runs there. The reference device never will. |
| **ColorOS auto-start**, the harshest of the three skins | Scenario 11 fails *silently* here if it fails anywhere. |
| **The version where BAL restrictions began** | Android 10 introduced the background-activity-launch rules that notes V2 is built around. |
| **2 GB RAM**, Article 13's stated floor | Process death under memory pressure is a real event here, not a theory. |

What it **cannot** answer, and must not be reported as answering:

- the two seconds of Article 11.2 **on the reference device** — different SoC, different skin, different scheduler;
- One UI "Sleeping apps", which is a different mechanism from ColorOS's startup manager;
- notes V7, the overlay over One UI Settings screens — still the largest unknown in the project;
- anything about Android 13's restricted-settings flow (notes V6), which does not exist on Android 10:
  **enabling the accessibility service from a sideloaded APK will be easier here than on the reference device.**

### H10.0 — install

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
cd C:\Users\Ilyes\Desktop\nojoumi\app
flutter run
```

Enable **Developer options → USB debugging** on the phone first (tap *Version* seven times under
**Settings → About phone**). ColorOS also has a separate **"Disable permission monitoring"** toggle in
Developer options; leave it alone — the goal is to see what a real family's phone does.

- ☐ APK installs and the app opens on the setup wizard, in Arabic, right-to-left

### H10.1 — the switch and the three grants

Parent area → **الحجب والألعاب**.

- ☐ with the switch **off**, the screen shows «الحجب موقوف» and no permission rows — Article 15.2
- ☐ turning it **on** reveals three rows, all marked «مطلوب»
- ☐ the device line at the bottom reads `OPPO · أندرويد API 29`

Tap each «مطلوب» in turn. After each, **return to the app** and confirm the row flips to «مُفعّل» by
itself — the screen re-reads the system on resume, and a row that stays «مطلوب» after a successful
grant is a bug in `didChangeAppLifecycleState`, not in the grant.

- ☐ **خدمة إمكانية الوصول** — the disclosure the wizard showed must have appeared *before* this point
- ☐ **الرسم فوق التطبيقات**
- ☐ **الإشعارات** — on Android 10 this opens app info; the notification is on by default
- ☐ a fourth row, **التشغيل التلقائي**, appears on this device. Tap it: ColorOS should open its
  startup manager. **If it opens the wrong screen or nothing at all, write down what happened** — the
  activity names in `LunioBlockingBridge.AUTOSTART_COMPONENTS` are undocumented and this is the only
  way to correct them.

Filter throughout: `adb logcat -s LNO_BLOCKING LNO_BRIDGE`

- ☐ `LNO_BLOCKING: connected home_action_available=true critical=[...]` appears when the service is enabled
- ☐ `critical=` lists the ColorOS launcher and the active keyboard. **If either is missing, stop.**
  A blocked keyboard is a phone on which the parent cannot type their own PIN.

### H10.2 — the picker

- ☐ **الألعاب المحجوبة** lists installed apps with icons and labels, sorted
- ☐ Settings, the dialer and Lunio itself are **absent or unblockable** — and confirm the note at the
  bottom of the screen says why
- ☐ tick one game. The count on the previous screen updates.
- ☐ `LNO_BRIDGE: state enabled=true blocked=1 remaining_s=... paused=false`

### H10.3 — the block, with zero stars

Parent area → deduct stars until the balance is zero, or use a fresh install before any session.

Open the ticked game from the ColorOS home screen.

- ☐ the phone returns to the home screen
- ☐ the card «انتهى وقت اللعب» appears, in Arabic, and dismisses itself after about six seconds
- ☐ `LNO_BLOCKING: block pkg=... reason=NoPlayTimeLeft home=true card=true internal_ms=NN`

**`internal_ms` is not Article 11.2's two seconds.** It measures event-received → home-performed, and
the part before the event reaches us is invisible from inside the app. **Record the screen at 60 fps
and count frames from the game's first pixel to the home screen.** That number is the contractual one;
`internal_ms` only tells you which half to blame if it is too slow.

- ☐ frame-counted latency, first attempt: ______ ms
- ☐ frame-counted latency, after the app has been idle 30 minutes: ______ ms

The second number is the one that matters. ColorOS deprioritises idle processes, and a first-try pass
followed by an idle failure is the exact shape of a bug the client would find in week two.

### H10.4 — the two messages

- ☐ with stars in the balance, the game **opens normally**
- ☐ parent area → **إيقاف اللعب مؤقتًا**, then open the game: the card must say
  «اللعب متوقّف مؤقتًا», **not** «انتهى وقت اللعب», and `reason=ParentPaused` in logcat
- ☐ the balance shown on the child's home screen is unchanged by the pause

A child told "play time is over" while their balance says otherwise learns the app is unreliable, and
that is a product failure even though nothing crashed.

### H10.5 — the eviction while playing

- ☐ grant one star (one minute), open the game, and **wait**
- ☐ when the minute expires the game must be evicted without the child switching apps

This is `shouldEvictForeground`, and **it is the one part of the engine with no caller yet.** Tier 1 is
event-driven and no window event fires while a child sits inside one game. Expect this step to
**fail** — record it, because the failure is what decides whether tier 2 (`UsageStatsManager`, notes
V10, a third permission) has to be built, or whether a countdown inside the app is enough.

### H10.6 — Article 12 scenario 11, the reboot

```
adb reboot
```

Do not open Lunio afterwards. Wait for the home screen, then open the blocked game directly.

- ☐ `LNO_BLOCKING: boot received enabled=true` appears in logcat
- ☐ `LNO_BLOCKING: watchdog up ...` follows it
- ☐ the game is blocked with no parent action

**If the boot line never appears**, ColorOS withheld the broadcast. That is not a code failure and
re-tuning the receiver will not fix it — go to the startup manager, allow Lunio, reboot again, and
record **both** results. The difference between them is precisely what the setup wizard has to teach
every parent, and it is a step the client has to be told about.

### H10.7 — the thirty minutes of Article 11.10

- ☐ leave the phone untouched for 30 minutes with the screen off, then repeat H10.3
- ☐ the foreground-service notification is still in the shade
- ☐ no crash, no ANR

Then the harder version, which is the one ColorOS is famous for:

- ☐ swipe Lunio away from recents, wait 10 minutes, and repeat H10.3

Blocking must still work — the Flutter engine is gone, and that is exactly the case AD-7 exists for.
If it does not, the finding is about the watchdog, not about Dart.

---

## H10.3 result — first hardware run, 2026-08-28

**Blocking works.** Reported by the developer on an Oppo A15 / ColorOS / Android 10: the game is
stopped, the phone returns to the home screen. This is the first confirmation that tier 1 of AD-8
functions on a real device, and it retires the largest single unknown in the project.

Everything else in H10 remains **UNVERIFIED**, including the frame-counted latency of Article 11.2,
the idle-30-minutes repeat, the reboot of H10.6 and the swipe-from-recents of H10.7.

### Defect found: the block card was dismissed by the eviction itself

**Symptom:** the card appeared for roughly one second and vanished.

**Cause, and it is worth understanding rather than just patching.**
`LunioAccessibilityService` did two things on a block: put the card up, then call
`performGlobalAction(GLOBAL_ACTION_HOME)`. The eviction moves the launcher to the foreground; the
launcher fires its own `TYPE_WINDOW_STATE_CHANGED`; that event resolves to `Allow` with a package
different from the one just blocked; and the `Allow` branch — written to clear the debounce guard
when a child *leaves* a blocked app — also called `overlay.hide()`.

So the card was torn down by the very action it existed to explain, about a second later, which is
exactly how long the home transition takes. Nothing was wrong with the timer, the permission, or the
window type.

**Why no test caught it.** The 17 JVM tests cover `BlockPolicy`, which is correct and was never
involved. This is a lifecycle interaction between two Android subsystems — a global action and the
event it causes — and it exists only on a device. It is a clean example of the split this project
is built around: the decision is provable without hardware, the *consequence* is not.

**Fix:** the `Allow` branch clears the guard and nothing else. The card's lifetime belongs to the
card — its own six-second timer, or the child tapping «فهمت».

**Re-verify (H10.3b):**

- ☐ the card now stays up for about six seconds after the eviction
- ☐ `LNO_BLOCKING: card down why=timer visible_ms=~6000`
- ☐ tapping «فهمت» takes it down early and logs `why=tapped`
- ☐ opening the game again immediately still blocks — the guard reset is unchanged

`why=` was added for this: from outside the process, a card dismissed by its timer, by a tap, and by
a bug look identical.

---

## H10.5 result and re-verify — the play clock, 2026-08-28

**Reported from hardware: blocking works, but the remaining time does not move while the child plays.**
Correct, and predicted: this was written into H10.5 in advance as the step expected to fail, because
tier 1 is event-driven and no window event fires while a child sits inside one game.

`PlayClock` now charges time while a blocked app is in the foreground, and evicts at zero. Re-verify:

### H10.5b — the countdown

- ☐ grant 2 stars (2 minutes), open the blocked game, and **watch the clock in logcat**:
  `LNO_PLAY: play start pkg=... remaining_s=120`
- ☐ leave the game after ~30 s. `LNO_PLAY: play stop pkg=... why=left the game remaining_s=~90`
- ☐ return to Lunio: the balance on the child's home screen has dropped by the seconds spent
  (`LNO_BRIDGE: drained play seconds=~30`)
- ☐ reopen the game, wait for the balance to reach zero **without touching the phone** — the game
  must be evicted with the card, `why=exhausted`

### H10.5c — the case a naive timer gets wrong by an hour

- ☐ open the game, then **turn the screen off** and wait two minutes
- ☐ `LNO_PLAY: play stop ... why=screen off` appears, and the balance is unchanged when you return

The appendix is explicit: «الطفل لا يخسر دقائق وهو لا يلعب». A phone in a pocket must not drain the
balance.

### H10.5d — the parent pause, mid-game

- ☐ with the child inside the game, pause play from the parent dashboard
- ☐ within a second or two the game is evicted and the card says «اللعب متوقّف مؤقتًا»

### H10.5e — process death

- ☐ open the game, play 30 s, then swipe Lunio from recents **while still in the game**
- ☐ the seconds already spent must survive: return to Lunio and confirm the balance dropped

This is why the tally is written with `commit()` rather than `apply()` — an asynchronous write would
be dropped by an OEM kill, handing the child back the time they had just spent.

---

## H11 — the app reaches the server

Added 2026-08-28 after "الربط بين التطبيق و الباكند لا يوجد".

The setup wizard's account step now shows a connection banner **before anything depends on it**, so a
phone on the wrong network, a build launched without `--dart-define`, and a wrong password are three
different messages instead of one silence.

- ☐ the banner reads «متصل بالخادم» in green-tinted card
- ☐ turn the dev server off and tap «أعد المحاولة» — it turns peach and prints the address it tried
- ☐ **read that address.** If it says `10.0.2.2`, the build was launched without `--dart-define` and is
  pointing at the emulator alias from a real phone. That is the single commonest cause.

Then the chain, verified on the server side already but not yet from the phone:

- ☐ create an account → `LNO` no errors, and the step shows «تم تسجيل الدخول»
- ☐ the trial starts by itself: «بدأت فترتك التجريبية: 7 أيام بكل المزايا»
- ☐ sign out from the parent dashboard and try a **different** email → refused, «هذا الهاتف مرتبط بحساب آخر»
- ☐ the same email signs in again with no complaint

---

## H11 result — the app reaches the server, 2026-08-29

**Verified on the Oppo A15 over Wi-Fi: the banner reads «متصل بالخادم» and the server logged the request.**

Getting there took three fixes, and the order matters because each one made the next look like more of
the same problem:

1. **Windows Firewall, inbound TCP 8000.** The Wi-Fi network was classified `Public`, where Windows
   blocks essentially all inbound traffic. The server bound `0.0.0.0` and answered `curl` on the host,
   the phone was on the same `/24`, and nothing crossed. Fixed with a `LocalSubnet`-scoped rule.
2. **ICMP, so `ping` is a usable diagnostic.** The TCP rule alone left `ping` blocked — meaning the
   obvious verification step reported failure after a successful fix. A second `LocalSubnet` rule for
   ICMPv4 type 8 makes `ping` separate "the network is down" from "the port is closed", which are two
   different faults that look identical from inside the app.
3. **`android.permission.INTERNET`** — see decisions.md D-52. The one that mattered most, and the one
   the firewall work would have hidden indefinitely.

Both firewall rules must stay for the rest of development:

```powershell
New-NetFirewallRule -DisplayName "Lunio dev 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow -Profile Any -RemoteAddress LocalSubnet
New-NetFirewallRule -DisplayName "Lunio dev ping" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -Action Allow -Profile Any -RemoteAddress LocalSubnet
```

### A number worth keeping

`ActivityTaskManager: Displayed dz.lunio/.MainActivity: +9s794ms` on a **debug** build. Debug Flutter is
JIT with no AOT snapshot, on a 2 GB device, so a release build will be far faster — but this is the
first cold-start measurement the project has, and Article 11.10's thirty-minute session should be run
against a release build before any conclusion is drawn about startup.

### Still unverified

- **H10.5b–e** — the play clock: countdown, screen-off, mid-game pause, process death
- **H10.6** — the reboot, and whether ColorOS withholds `BOOT_COMPLETED`
- Article 11.2's two seconds, counted frame by frame from a screen recording

---

## H11.2 — the account chain, verified on the device 2026-08-29

Driven on the Oppo A15 against `192.168.1.3:8000`. Server log, in order, from one tap of «إنشاء حساب»:

```
POST /api/accounts/register/     201
POST /api/accounts/token/        200
POST /api/subscriptions/trial/   201
GET  /api/subscriptions/status/  200
```

On screen: «تم تسجيل الدخول», then «بدأت فترتك التجريبية: 7 أيام بكل المزايا», and «التالي» becomes
enabled. The connection banner is absent, which is now its correct appearance when the server is
reachable.

- ☑ register, sign-in, trial and the signed snapshot all reach the server from the phone
- ☑ the seven-day trial starts by itself once an account exists (Art. 7.1)
- ☑ the account step blocks progress until a token exists

Still to check by hand, because scripted taps cannot judge them:

- ☐ a **second** account on this phone is refused with «هذا الهاتف مرتبط بحساب آخر» (D-48)
- ☐ the same account signs in again with no complaint
- ☐ a wrong password says so, and does not mention the device

---

## H11.3 — the dialog, verified on the device 2026-08-29

Registered from the phone against `192.168.1.3:8000`. The server log shows the full chain, and the
dialog appears over the account step: star illustration, «أهلاً بك في Lunio», «بدأت فترتك التجريبية:
7 أيام بكل المزايا», the note that two steps remain on this phone, and «متابعة». Tapping it advances
to «المستوى الدراسي» — step 3 of 5.

- ☑ the popup replaces the inline «تم تسجيل الدخول» line
- ☑ registration continues into the wizard
- ☐ **sign-in on a phone that already has a grade and a PIN goes straight into the app** — needs a
  device in that state: finish setup once, sign out from the parent dashboard, then sign in again
- ☐ sign-in on a bare phone shows «مرحبًا بعودتك» and the note about the two remaining steps

---

## H10.5f — the frozen clock, 2026-08-29

The Oppo reported the countdown stopping mid-game. Cause confirmed: `dz.lunio` is not exempt from
battery optimisation, so ColorOS freezes it while a game is in the foreground. See decisions.md D-67.

Verify the three defences **in this order**, because each one masks the next:

### With the exemption granted (the intended state)

- ☐ parent area → الحجب والألعاب → **تشغيل غير مقيّد** → grant it in the system dialog
- ☐ confirm: `adb shell dumpsys deviceidle whitelist | grep lunio` now lists the package
- ☐ open a blocked game with 2 minutes and watch the pill for a full minute — it must not stop
- ☐ `LNO_PLAY` shows no `clock stalled` lines

### With the exemption revoked (what most parents will have at first)

Revoke it in Settings → Apps → Lunio → Battery, then repeat. This is the case that was reported.

- ☐ the pill may still stall — that is the OEM, not us
- ☐ but `LNO_PLAY: deadline armed in Ns` appears when play starts
- ☐ **and the game is still closed within a few seconds of the balance ending**, with
  `deadline fired` followed by `clock stalled for …ms — catching up` and the ordinary
  `block pkg=… reason=NoPlayTimeLeft`

The second block is the one that matters. The exemption is the fix; the alarm is the promise that
holds when a parent says no to it.

### The gap, measured rather than described

- ☐ note the `clock stalled for NNNNms` values over a ten-minute session. If they are routinely
  above ~30 s even *with* the exemption, the alarm is doing all the work and that is worth knowing
  before the client is told the timer is reliable.
