# Blocking checklist — Article 12 · daily hardware run

**Purpose:** Article 12's twelve scenarios are the gate on Article 11 acceptance and on the final 30 % payment.
They cannot be verified on an emulator. Re-run this **every day** that native code changed,
on the reference device, and record the result. A scenario that passed yesterday and was never re-run today
counts as **unknown**, not as pass.

**Acceptance also requires (Art. 11.2): blocking response ≤ 2 seconds from the moment the game appears.**
Record the observed time for scenarios 2–7, not just pass/fail. Use the stopwatch on a second phone or count
video frames — "felt fast" is not a measurement.

---

## Run header — fill in every run

| Field | Value |
|---|---|
| Date |  |
| Build / commit |  |
| Device model |  |
| Android version + OEM skin |  |
| RAM |  |
| Launcher mode | Lunio is default launcher / not default launcher |
| Blocking opt-in | on / off |
| Battery optimisation for Lunio | unrestricted / optimised |
| Star balance at start of run | 0 stars (required for scenarios 1–7) |
| Target game package used |  |
| Subscription state | trial / active / grace / expired / refunded |

Preconditions before starting: star balance **exactly zero**, the target game installed and marked as a game by
the parent, accessibility service enabled, DeviceAdmin active, phone unplugged from ADB.

Logcat one-liner:

```
adb logcat -c && adb logcat -s LNO_BLOCKING LNO_LAUNCHER LNO_OVERLAY LNO_ADMIN LNO_BOOT LNO_CLOCK
```

---

## The twelve scenarios

### 1 — Open the game from the Lunio home screen, balance zero
**Contract result:** the icon is **blocked** (الأيقونة محجوبة).
**Steps:** open the Lunio home screen → locate the game.
**Look for:** the icon is not launchable — blocked/hidden per the agreed UX — and tapping it leads to the tasks
screen, not to the game. No flash of the game at all.
**Time:** n/a (prevention, not interception).
**Note:** only meaningful in launcher mode. In non-launcher mode (Art. 15.2) this scenario is not applicable —
mark N/A and say so.
**Result:** ☐ pass ☐ fail ☐ N/A · observed: ____________

### 2 — Open the game from the recent-apps list
**Contract result:** immediate close.
**Steps:** launch the game while balance > 0 (or before blocking arms), leave it, empty the balance, open recents,
tap the game.
**Look for:** the game appears and is closed; Lunio's block card appears. **Measure the seconds.**
**Result:** ☐ pass ☐ fail · observed time: ______ s

### 3 — Open the game from Settings → Apps → Open
**Contract result:** immediate close.
**Steps:** Settings → Apps → the game → Open.
**Look for:** closed within 2 s; the user lands on the block card or the home screen, not back inside Settings'
app page in a loop.
**Result:** ☐ pass ☐ fail · observed time: ______ s

### 4 — Open the game from its own notification
**Contract result:** immediate close.
**Steps:** make the game post a notification (or use a game that posts one), pull down the shade, tap it.
**Look for:** closed within 2 s. Note whether the notification shade behaves oddly afterwards.
**Result:** ☐ pass ☐ fail · observed time: ______ s

### 5 — Open the game from the "Open" button in Google Play
**Contract result:** immediate close.
**Steps:** Play Store → the game's page → Open.
**Look for:** closed within 2 s, and the Play Store is not left in a broken state.
**Result:** ☐ pass ☐ fail · observed time: ______ s

### 6 — Open the game via phone search or the voice assistant
**Contract result:** immediate close.
**Steps:** run both — (a) the device search field, (b) the voice assistant ("open <game>").
**Look for:** closed within 2 s in **both** paths. Record them separately; the accessibility path often behaves
differently because the launch comes from a system component.
**Result:** search ☐ pass ☐ fail (______ s) · assistant ☐ pass ☐ fail (______ s)

### 7 — Open the game via a shortcut or a widget on the screen
**Contract result:** immediate close.
**Steps:** create a home-screen shortcut and, if the game offers one, a widget; launch from each.
**Look for:** closed within 2 s from both. Also long-press shortcuts (app shortcuts) if the game exposes any.
**Result:** shortcut ☐ pass ☐ fail (______ s) · widget ☐ pass ☐ fail (______ s)

### 8 — Attempt to change the default home screen
**Contract result:** requires the parent PIN.
**Steps:** Settings → Apps → Default apps → Home app → pick another launcher. Also try the OEM shortcut if the
skin has one, and the "Home" chooser that appears on pressing home.
**Look for:** a PIN prompt appears before the change can complete, and cancelling leaves Lunio as home.
**Record:** whether the PIN surface actually appears **on top of Settings** — this is the riskiest part of the
whole checklist and OEM/Android version behaviour varies.
**Result:** ☐ pass ☐ fail · what appeared: ____________

### 9 — Attempt to uninstall Lunio
**Contract result:** prevented (ممنوع). ⚠️ **Not achievable as literally worded — see below.**

**Established fact, not a hypothesis:** `setUninstallBlocked` requires device owner or profile owner
(`android-36.1` framework sources, see `android-behaviour-notes.md` V5). The client **refused Device Owner** on
2026-08-15 (`decisions.md` D-21), so there is no route to absolute prevention. What ships is: the system's own
refusal while the admin is active, a warning on `onDisableRequested`, detection via `onDisabled`, and a parent
notification.

**Steps:** try all of — long-press icon → uninstall; Settings → Apps → Lunio → Uninstall; Play Store → My apps
→ Uninstall. Then separately: deactivate the device admin first, and retry each path.

**What to record:**
- ☐ uninstall refused while the admin is **active**, in all three paths — record the exact system message
- ☐ the warning text appears when deactivation is requested
- ☐ after deactivation, the parent gets a notification and the dashboard shows protection as degraded

**Do not mark this scenario pass/fail against the word ممنوع.** Record the observed behaviour and compare it to
the clarification the client agreed to in writing. **If that written agreement does not exist yet, this scenario
is contractually unresolved** — flag it, do not quietly score it.

### 10 — Attempt to disable the accessibility service, or force stop
**Contract result:** requires the parent PIN. ⚠️ **Partly achievable — the force-stop path is not.**

**Steps:** (a) Settings → Accessibility → Lunio → toggle off. (b) Settings → Apps → Lunio → Force stop.
(c) Settings → Apps → Lunio → Deactivate device admin.

**What to record, per path:**
- ☐ (a) does a PIN gate appear over the accessibility screen? **This is the largest open unknown in the project**
  — overlay behaviour over Settings screens is version- and OEM-dependent and has not been verified anywhere yet
  (`android-behaviour-notes.md` V7)
- ☐ (b) force stop cannot be intercepted — the button lives in a system screen. Record instead: **how many
  seconds until protection is live again**, and by what mechanism it recovered
- ☐ (c) warning shown, deactivation detected, parent notified
- ☐ after each path, re-run scenario 2 immediately and record whether blocking still works

**Result:** a11y off ☐ ____ · force stop, recovery time ______ s · admin off ☐ ____ · blocking live after? ☐ yes ☐ no

### 11 — Restart the phone
**Contract result:** blocking returns automatically.
**Steps:** reboot. Do **not** open Lunio. Wait 60 s, then run scenario 2 or 3.
**Look for:** blocking works with no parent action and no app launch. Note how many seconds after boot it becomes
effective, and whether the launcher is still the home app.
**Also test:** reboot with the screen locked and left locked for 5 minutes before unlocking.
**Result:** ☐ pass ☐ fail · effective after ______ s

### 12 — Change the device date or time to earn balance
**Contract result:** no extra balance.
**Steps:** run all of — (a) jump the clock forward one day; (b) jump it back one day; (c) turn off automatic time
then set a time; (d) change the time zone; (e) combine with a reboot while offline.
**Look for:** star balance unchanged, no new daily allowance, the daily ceiling not reset, expired balance not
resurrected, and the subscription end date unmoved. Then restore automatic time and confirm the app recovers
without the parent doing anything.
**Result:** forward ☐ ____ · backward ☐ ____ · manual ☐ ____ · timezone ☐ ____ · offline+reboot ☐ ____

---

## Out of scope — do not test, do not chase (Article 12 exclusions)

These have no solution on Android without Device Owner mode. They are **excluded from acceptance and from the
warranty**, and closing them is a separate paid service (Art. 17).

- ☒ Booting into Safe Mode
- ☒ Factory reset or intervention via Recovery
- ☒ Connecting a computer and using ADB / USB debugging
- ☒ Creating a second user or guest mode, or rooting the phone

If a scenario appears to fail *only* because one of these was used, note it as excluded, not as a failure.

---

## Related Article 11 items that are also hardware-only

Run these at least once per phase, and all of them in Phase 7:

- ☐ **11.2** — no interception measured above 2 s anywhere in scenarios 2–7.
- ☐ **11.4** — a full Article 4 cycle: capture a lesson → tasks → earn stars → games open → balance runs out →
  blocking returns, with **zero manual intervention**.
- ☐ **11.9** — the app keeps working automatically after restart with no parent intervention (= scenario 11, but
  including the tasks/stars side, not only blocking).
- ☐ **11.10** — **30 minutes continuous use, no crash.** Set a timer, use the app the way a child would, and
  report any ANR or restart.
- ☐ Devices 2 and 3 (Art. 13): Oppo/Xiaomi (MIUI/HyperOS) for continuity after reboot and battery restriction,
  Android 10 / 2 GB for performance. Document any extra manual setup step these need — the contract allows
  documented steps here, but they must go in the parent guide.

---

## Reporting a failure

Send, every time, all six:

1. Device model 2. Android version + OEM skin 3. Exact steps 4. Expected 5. Actual
6. Logcat around the moment of failure (the one-liner above)

Plus, when it is a timing failure, the measured seconds. Plus a screen recording when the failure is visual
(a flash of the game, an overlay that did not appear, a PIN gate on the wrong screen).
