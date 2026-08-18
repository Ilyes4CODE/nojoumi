# Hardware verification — what to do the day the phone arrives

Everything native in this repository is **UNVERIFIED** until a step below is signed off. This file is the
checklist for the parts that are not blocking; `blocking-checklist.md` covers Article 12.

The assistant is blind to the device. Each step therefore states: what to do, **what should appear**, how long it
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
cd C:\Users\Ilyes\Desktop\nojoumi\app
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

## H2 — the clock channel (`NojoumiClock`, notes V9)

Filter: `adb logcat -s NJM_CLOCK`

The Dart side never reads a clock; it folds what this channel reports. So a wrong reading here silently poisons
Article 6.8 and Article 7.6 everywhere else, and none of the 21 pure-package tests would notice.

### H2.1 — first run

- ☐ `NJM_CLOCK  boot token rotated: first_run` appears once, on the first reading after install
- ☐ it does **not** appear again while the app stays open

### H2.2 — a reboot rotates the token

1. Note the time, reboot the phone, open Nojoumi.
- ☐ `boot token rotated: elapsed_regressed` **or** `boot_instant_moved` appears
- ☐ the child's star balance is unchanged
- ☐ the "ساعة الهاتف غير موثوقة" card does **not** appear (a reboot is not tampering)

### H2.3 — a reboot after a long uptime

The important one, and the reason signal 2 exists: leave the phone up for **longer than the previous session**
before rebooting, so `elapsedRealtime` does not regress.

1. Leave the phone on for several hours with Nojoumi open at least once.
2. Reboot, wait past that earlier uptime, then open Nojoumi.
- ☐ the token still rotates — expect `boot_instant_moved`
- ☐ if it does **not** rotate, stop and report: this is the one failure that could over-state time

### H2.4 — Doze overnight must not rotate the token

1. Leave the phone unplugged and untouched overnight.
2. Open Nojoumi in the morning.
- ☐ **no** rotation line for that reading — `elapsedRealtime` is documented to keep counting through deep sleep,
  and a rotation every morning would mean a needless re-anchor every morning

### H2.5 — moving the clock (this is checklist scenario 12, from the app's side)

For each of: forward one day · backward one day · automatic time off then set by hand · timezone change

- ☐ the child's screen shows **ساعة الهاتف غير موثوقة**
- ☐ answering a card correctly earns **nothing**
- ☐ the balance and the remaining play time are **unchanged** — nothing is confiscated either
- ☐ `NJM_CLOCK` shows a rotation on the wall-clock change
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

1. Sideload the APK, then try to enable Nojoumi's accessibility service.
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

## Not covered here

Blocking, launcher mode, overlay, DeviceAdmin and boot recovery are `blocking-checklist.md`. None of that code
exists yet — the Kotlin blocking spike is the first thing to run on the device after H1 and H2 pass.
