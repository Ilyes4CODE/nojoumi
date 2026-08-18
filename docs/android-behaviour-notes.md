# Android behaviour verification notes

Every sensitive API this project relies on, verified before use. **Nothing in here is a memory claim** — each
row cites either current official documentation (fetched on the date shown) or the Android SDK sources installed
on this machine (`android-36.1`, which is the framework source, i.e. authoritative).

Re-verify anything older than ~3 months, and re-verify everything before the Phase 7 delivery.

| Verified | Date | Source |
|---|---|---|
| Round 1 | 2026-08-14 | developer.android.com + local SDK sources `android-36.1` |

Build targets decided from this: `minSdk 29` (Android 10 — Art. 13 low-resource device) ·
`compileSdk 36` · `targetSdk 36`.

---

## V1 — Google Play target API level (build config)

**Verified:** New apps and app updates must target **API 36 (Android 16)** or higher to be submitted to Play.
All apps must meet the requirement by 2026-08-31, with an extension available to 2026-11-01.

**Consequence:** we target 36, so **every Android 15 and 16 restriction below applies to us.** We do not get to
target an older API to dodge them.

---

## V2 — Background activity launch (BAL) — the single most important constraint

**Verified** (documented exemption list, `guide/components/activities/background-starts`). An app in the
background may start an activity only if one of these holds:

- it has a visible window (e.g. a foreground activity)
- it is the current IME
- the activity is started from a `PendingIntent` **sent by the system** (e.g. a notification tap)
- it holds **`SYSTEM_ALERT_WINDOW`** granted by the user
- it holds `START_ACTIVITIES_FROM_BACKGROUND` (privileged, not us)
- it is bound by a service that has been granted background-activity-start permission
- **the launch is initiated by the device's launcher app** (user taps an icon, interacts with a widget)
- the launch comes from a core always-running OS component

**Two findings that shape the whole design:**

1. **Having an AccessibilityService is NOT on the exemption list.** Our a11y service can *observe* and can
   perform global actions, but it does **not** buy us the right to start an activity from the background.
   → Enforcement must never depend on `startActivity` from the service.
2. **Being the launcher IS on the list**, and `SYSTEM_ALERT_WINDOW` IS on the list. So in launcher mode we are
   privileged for launches the user initiates from our home screen (this is what makes Art. 4.5 "games open
   automatically" workable), and the overlay permission covers the rest.

**Android 15 tightening, verified verbatim:** the `SYSTEM_ALERT_WINDOW` exemption for starting a **foreground
service** from the background is now narrower — *"The app now needs to have the `SYSTEM_ALERT_WINDOW`
permission and also have a visible overlay window. That is, the app needs to first launch a
`TYPE_APPLICATION_OVERLAY` window and the window needs to be visible before you start a foreground service."*

**Android 16:** adds a strict mode that reports launches that are blocked or at risk of being blocked. We should
enable it in debug builds — it converts a silent failure into a log line, which is exactly what we need given
that the developer is testing blind.

**What we rely on:** enforcement = `AccessibilityService.performGlobalAction(GLOBAL_ACTION_HOME)` +
a `TYPE_APPLICATION_OVERLAY` window for the block card. **Not** an activity start from the background.

---

## V3 — `performGlobalAction` and the global action constants

**Verified in local framework source** `android-36.1/android/accessibilityservice/AccessibilityService.java`:

- `public static final int GLOBAL_ACTION_BACK = 1;` — present, not deprecated
- `public static final int GLOBAL_ACTION_HOME = 2;` — present, not deprecated
- `public final boolean performGlobalAction(int action)` — present, returns whether the action was performed

**Documented caveat, quoted from source:** *"The global action ids themselves give no information about the
current availability of their corresponding actions. To determine if a global action is available, use
`getSystemActions()`."*

**What we rely on:** `performGlobalAction(GLOBAL_ACTION_HOME)` as the primary eviction mechanism, with the
return value checked and logged (`NJM_BLOCKING`), and `getSystemActions()` consulted at service-connect time so
we discover unavailability at startup rather than at the moment a child opens a game.

---

## V4 — Foreground service type, and starting one after boot

**Verified.** Since Android 14, a foreground service must declare a type. Our watchdog fits **`specialUse`**:

```xml
<service android:name=".BlockingWatchdogService"
         android:foregroundServiceType="specialUse"
         android:exported="false">
    <property android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
              android:value="parental_control_app_blocking"/>
</service>
```

Requires `FOREGROUND_SERVICE_SPECIAL_USE`, no runtime prerequisite. The `<property>` free-form explanation is
**reviewed by Google Play**, and apps targeting 14+ must declare their FGS types in Play Console under
**Policy → App content**. That declaration is a Phase 7 deliverable, not an afterthought.

**`systemExempted` — deliberately not used.** We would technically qualify (the documented eligibility list
includes *"App is a Device Admin"*, and we are one), but the type is documented as reserved for system apps and
system integrations, and claiming it invites a Play rejection on an app that already carries two
rejection-prone permissions. Not worth it.

**BOOT_COMPLETED, verified:** apps targeting 15+ **may not** start `dataSync`, `camera`, `mediaPlayback`,
`phoneCall`, `mediaProjection`, or `microphone` foreground services from a `BOOT_COMPLETED` receiver.
**`specialUse` is not on that prohibition list** — which is precisely why it is the right choice for us:
Article 12 scenario 11 (reboot → blocking returns) needs a foreground service started from boot.

**Unverified until hardware:** whether OEM skins (One UI "Sleeping apps", MIUI/HyperOS autostart) actually let
the boot receiver fire. This is a device fact, not a documentation fact, and it is checklist scenario 11.

---

## V5 — Device admin and uninstall protection — **this one changes what we can promise**

**Verified in local framework source** `android-36.1/android/app/admin/DevicePolicyManager.java`:

```
@throws SecurityException if {@code admin} is not a device or profile owner or holder of the
permission MANAGE_DEVICE_POLICY_APPS_CONTROL
public void setUninstallBlocked(...)
```

→ **A plain active device admin cannot call `setUninstallBlocked`.** It requires device owner / profile owner,
and Device Owner is explicitly out of scope (Art. 17).

**Verified in** `android-36.1/android/app/admin/DeviceAdminReceiver.java` — what we *do* get:

- `ACTION_DEVICE_ADMIN_DISABLE_REQUESTED`: *"Action sent to a device administrator when the user has requested
  to disable it, but before this has actually been done. This gives you a chance to supply a message to the user
  about the impact of disabling your admin… If set, the given text will be shown to the user before they
  disable your admin."*
- `onDisableRequested(context, intent)` — present, **not deprecated**, available to a plain active admin,
  returns a `CharSequence` warning. **It cannot veto the deactivation.**
- `onDisabled(context, intent)` — fires after the fact.

**So the honest mechanism for Article 12 scenario 9 is:**

1. While our admin is active, the system itself refuses uninstall until the admin is deactivated (documented
   in Play/Android help: a device admin app must be unregistered as administrator before it can be uninstalled).
   This is the actual protection, and it is a system behaviour we do not call — so **it must be verified on
   hardware, per skin.**
2. The deactivation path is user-reachable. We can show a warning (`onDisableRequested`), we can detect the
   deactivation (`onDisabled`), and we can react — but **we cannot block it.**

**This is a contract exposure, not a coding problem.** Art. 12 scenario 9 says *ممنوع* (prevented) and scenario
10 says *يتطلب رمز الوالد* (requires the parent PIN). Without Device Owner, the best truthful implementation is
**warn + detect + react + notify the parent**, and a PIN gate that is a *reaction to* the settings screen rather
than a *precondition of* it. Art. 12's four exclusions do not cover this. Raise it with the client in writing
before the Phase 7 acceptance run — see `docs/decisions.md` D-12.

---

## V6 — Restricted settings on sideloaded installs

**Verified** (Android Help, *Learn about restricted settings*): apps installed from a local file — identified by
`PackageManager` as `PACKAGE_SOURCE_LOCAL_FILE` — are blocked from being granted accessibility access until the
user explicitly goes to **App info → ⋮ → Allow restricted settings**.

**Consequences, both real:**

1. **Every development install and every hardware test run hits this.** The setup wizard must detect that
   accessibility cannot be granted and walk the user through "Allow restricted settings" — otherwise the
   developer's first hardware test looks like our bug when it is the platform's flow.
2. **Article 16.4's fallback matters more than it looks.** If Play rejects us three times, we deliver an APK for
   direct distribution — and every one of those users will hit the restricted-settings wall. That belongs in the
   parent guide in Arabic, with screenshots.

---

## V7 — Overlay over Settings screens · **NOT YET VERIFIED**

Open item, and it is the highest-risk unknown in the project (checklist scenarios 8 and 10). To establish:

- whether a `TYPE_APPLICATION_OVERLAY` window is drawn, hidden, or ignored on top of **Settings →
  Accessibility** and **Settings → Default apps → Home app** on current Android and on One UI
- `HIDE_OVERLAY_WINDOWS` / `setHideOverlayWindows` and which system surfaces use it
- Android 12+ untrusted-touch-event blocking, and whether our block card is affected
- whether `GLOBAL_ACTION_BACK` from the a11y service is a reliable substitute for an overlay on those screens

**This is a device question more than a docs question, so it is a spike objective, not a reading task.** The
day-2 spike deliberately includes "open Settings → Accessibility and see what our overlay does" as a test case.
Until then, the PIN gate on scenarios 8 and 10 is **unproven**.

---

## V9 — the three clocks, and how a boot session is identified

**Verified in local framework source** `android-36.1/android/os/SystemClock.java`, 2026-08-18. Quoted verbatim:

- Class javadoc on the wall clock: *"`System.currentTimeMillis()` is the standard "wall" clock (time and date)
  expressing milliseconds since the epoch. **The wall clock can be set by the user or the phone network** (see
  `setCurrentTimeMillis`), so **the time may jump backwards or forwards unpredictably**. … Interval or elapsed
  time measurements should use a different clock."*
  → This sentence *is* Article 6.8 and Article 7.6, written by Google. The wall clock is the untrusted input.

- Class javadoc on `uptimeMillis`: *"counted in milliseconds since the system was booted. **This clock stops when
  the system enters deep sleep**"* → unusable for us: a phone asleep overnight would lose the night.

- Class javadoc on `elapsedRealtime`: *"`elapsedRealtime` and `elapsedRealtimeNanos` return the time since the
  system was booted, **and include deep sleep**. This clock is **guaranteed to be monotonic**, and continues to
  tick even when the CPU is in power saving modes, so is the recommend basis for general purpose interval
  timing."* Method javadoc: *"Returns milliseconds since boot, including time spent in sleep."*

- `setCurrentTimeMillis(long)`: *"Sets the current wall time, in milliseconds. **Requires the calling process to
  have appropriate permissions.**"* → an ordinary app cannot move the wall clock. The user can, through Settings,
  and that is exactly the scenario Article 12.12 tests.

**What we rely on:** `elapsedRealtime()` as the monotonic witness inside one boot session, and
`System.currentTimeMillis()` as the input we check *against* it. This is precisely the split `nojoumi_time`
was written for.

### The boot id is derived, because Android does not give apps one

`/proc/sys/kernel/random/boot_id` is the obvious candidate and we are **not** using it: on modern Android an
`untrusted_app` domain has no SELinux rule granting it, and a search turned up no authority saying otherwise.
Building the tamper model on a file that may return `EACCES` on the reference device is not acceptable.

**Instead the boot token is derived in Kotlin, persisted in the app's own preferences, and rotated on either of
two signals:**

1. `elapsedRealtime()` came back **lower than the highest value we have stored**. Within one boot that is
   impossible — the framework guarantees monotonicity — so it proves a reboot.
2. The derived boot instant, `currentTimeMillis() − elapsedRealtime()`, moved by more than a tolerance from the
   stored one. After a reboot this is a genuinely different value, which catches the case signal 1 misses: a
   reboot followed by an uptime *longer* than the previous session's.

Signal 2 also fires when the user simply changes the clock, which is **not** a reboot. That false positive is
deliberate and safe: rotating the token only pushes `TrustedClock` onto its reboot branch, where the sole
surviving rule is that time never runs backwards. A rotation can cost trust; it can never grant anything.

**Why this matters enough to spell out:** if a reboot were *missed*, `TrustedClock` would keep extrapolating from
a stale anchor and could over-state the current time — the one direction that could extend a subscription. Every
mechanism above is chosen so the failure mode is a lost anchor, never an inflated one.

**UNVERIFIED-ON-HARDWARE, and this is a device fact, not a documentation fact.** What the developer must check
once the reference device exists:

- reboot the phone and confirm `NJM_CLOCK` logs a token rotation on the first reading after boot;
- reboot after a *long* uptime and confirm rotation still happens (that is signal 2 doing its job);
- change the clock forward a day, then back, and confirm the token rotates and the star balance does not move —
  this is checklist scenario 12;
- confirm `elapsedRealtime()` does not regress across a Doze cycle overnight, since a false rotation every
  morning would mean a re-anchor every morning.

Logcat: `adb logcat -s NJM_CLOCK`.

---

## V8 — Still to verify before their phase

| Item | Needed by | Why |
|---|---|---|
| `QUERY_ALL_PACKAGES` Play policy + accepted justifications | Phase 2 | the parent's game picker depends on it |
| `PACKAGE_USAGE_STATS` / `UsageStatsManager` polling cost + accuracy on Android 10 | Phase 2 | AD-8 tier 2 safety net, on a 2 GB device |
| Accessibility API Play policy — current declaration wording for parental control | Phase 7 | #1 rejection cause (Art. 16) |
| Designed for Families policy vs. accessibility + device admin | Phase 7 | Art. 15.3 |
| Exact-alarm permission rules for day-rollover scheduling | Phase 4 | end-of-day balance expiry (Art. 6) |
| `SCHEDULE_EXACT_ALARM` vs `USE_EXACT_ALARM` eligibility | Phase 4 | same |

---

## Sources (round 1, 2026-08-14)

- [Restrictions on starting activities from the background](https://developer.android.com/guide/components/activities/background-starts)
- [Behavior changes: apps targeting Android 15](https://developer.android.com/about/versions/15/behavior-changes-15)
- [Foreground service types](https://developer.android.com/develop/background-work/services/fg-service-types)
- [Activity security / BAL](https://developer.android.com/guide/components/activities/secure-bal)
- [Meet Google Play's target API level requirement](https://developer.android.com/google/play/requirements/target-sdk)
- [Target API level requirements for Google Play apps](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Learn about restricted settings](https://support.google.com/android/answer/12623953)
- [Device administration overview](https://developer.android.com/work/device-admin)
- Local framework sources: `android-36.1/android/accessibilityservice/AccessibilityService.java`,
  `android-36.1/android/app/admin/DeviceAdminReceiver.java`,
  `android-36.1/android/app/admin/DevicePolicyManager.java`
