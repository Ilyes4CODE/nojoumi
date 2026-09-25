package dz.lunio.blocking

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * Tier 1 of AD-8 — the only channel Android gives an ordinary app for the question
 * "what just came to the foreground?"
 *
 * There is no API that tells a non-privileged, non-Device-Owner app that another
 * app was opened. Without that fact, blocking is not hard, it is impossible: we
 * would not know when to act. `TYPE_WINDOW_STATE_CHANGED` is the answer, and an
 * AccessibilityService is the only way to receive it.
 *
 * **Three things this service deliberately does not do:**
 *
 * 1. **It does not decide.** It asks [BlockPolicy], which is pure Kotlin with
 *    seventeen JVM tests on it. What is left here is small enough that "unverified
 *    until hardware" covers a narrow, nameable surface rather than the whole rule.
 * 2. **It does not read the screen.** `canRetrieveWindowContent` is false and the
 *    event type filter is a single value. The disclosure screen the parent consents
 *    to says Lunio sees only which app opened — that sentence has to be true in the
 *    service configuration, not only in the copy.
 * 3. **It never calls `startActivity`.** Notes V2, verified against the documented
 *    background-activity-launch exemption list: holding an AccessibilityService is
 *    *not* on it. A design that opens an activity from here fails silently on modern
 *    Android. Enforcement is `performGlobalAction(GLOBAL_ACTION_HOME)` plus a
 *    `TYPE_APPLICATION_OVERLAY` window, both of which are on solid ground.
 *
 * Logcat: `adb logcat -s LNO_BLOCKING`
 */
class LunioAccessibilityService : AccessibilityService() {

    private var overlay: BlockCardOverlay? = null
    private var playTimer: PlayTimerOverlay? = null
    /** Internal rather than private so [nudge] can reach it from the companion. */
    internal var playClock: PlayClock? = null

    /**
     * Screen on/off, which decides whether play time is being spent at all.
     *
     * The appendix is explicit that the child does not lose minutes while not
     * playing, and a phone going into a pocket with a game still technically in
     * the foreground is the case that gets that wrong by an hour. Registered at
     * runtime because `ACTION_SCREEN_OFF` cannot be received from a manifest
     * declaration.
     */
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> playClock?.setScreenOn(false)
                Intent.ACTION_SCREEN_ON -> playClock?.setScreenOn(true)
            }
        }
    }

    /**
     * The last package we evicted, and when.
     *
     * A single window transition can produce several events, and evicting three
     * times sends three `GLOBAL_ACTION_HOME` calls for one game launch. Worse, the
     * home screen itself then fires an event. The guard is per-package so that a
     * child who reopens the same game immediately is still blocked.
     */
    private var lastBlockedPackage: String? = null
    private var lastBlockedAt: Long = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        overlay = BlockCardOverlay(this)
        playTimer = PlayTimerOverlay(this)
        playClock = PlayClock(
            context = this,
            onExhausted = { pkg -> onPlayTimeExhausted(pkg) },
            // Every second, to the two surfaces that can be seen while a game is
            // in front of the child: the ongoing notification, and the app if it
            // happens to be listening (launcher mode, or the instant they come
            // back).
            onTick = { _, remaining ->
                // Three surfaces, in order of how likely the child is to be
                // looking at them: the pill floating over the game, the ongoing
                // notification, and the app itself if it is on screen at all.
                playTimer?.show(remaining)
                BlockingWatchdogService.showRemaining(this, remaining)
                PlayTicks.emit(remaining)
            },
            // Whenever the clock stops, the pill goes with it. A timer that keeps
            // counting while nothing is being spent is worse than none: it
            // teaches the child that the number lies.
            onStopped = { playTimer?.hide() },
        )
        registerReceiver(
            screenReceiver,
            IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_SCREEN_ON)
            },
        )
        BlockingStore.refreshCritical(this)

        Log.i(
            TAG,
            "connected home_action_available=" + homeActionAvailable() +
                " critical=" + BlockingStore.critical(this),
        )

        live = this

        // The service is our liveness signal: if Android connected it, the process
        // is alive and the watchdog should be running beside it.
        BlockingWatchdogService.start(this)
    }

    /**
     * Whether `GLOBAL_ACTION_HOME` is currently offered — **API 30 and above
     * only**, and that matters more than it looks.
     *
     * V3 quotes the framework source: *"The global action ids themselves give no
     * information about the current availability of their corresponding actions.
     * To determine if a global action is available, use `getSystemActions()`."*
     * So asking at startup is right.
     *
     * But `getSystemActions()` was added in **API 30**, and this project's floor
     * is **29** — the reference device for daily testing is an Android 10 phone.
     * The call was previously written inline in `onServiceConnected`, wrapped in
     * `runCatching`, on the assumption that a missing method would simply throw
     * and be caught. It is not that simple: ART resolves the method when the
     * *enclosing method* is entered, so on API 29 `onServiceConnected` itself
     * failed before a single line of it ran. The service crashed on connect,
     * ColorOS stripped it from the enabled list, and the symptom was everything
     * silently doing nothing — no countdown, no overlay, no logs at all, on a
     * service that `dumpsys` still listed as installed.
     *
     * Two changes, and both are needed:
     *
     *  * an explicit `SDK_INT` gate, so the call is never reached below 30;
     *  * the call **isolated in its own method**, so the unresolvable reference
     *    lives in a frame that is never entered on older devices. A version
     *    check alone still leaves the reference inside `onServiceConnected`.
     *
     * Below API 30 the honest answer is "we do not know", and the code behaves
     * as it always did: it calls `performGlobalAction` and checks the return
     * value, which is the only signal Android 10 offers.
     */
    private fun homeActionAvailable(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return true
        return runCatching { querySystemActions() }.getOrDefault(true)
    }

    /** API 30+ only. Reached solely through [homeActionAvailable]'s gate. */
    private fun querySystemActions(): Boolean =
        systemActions.any { it.id == GLOBAL_ACTION_HOME }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }
        val at = SystemClock.uptimeMillis()
        val pkg = event.packageName?.toString().orEmpty()

        // Any event at all means this process is awake. If the clock was frozen
        // by the OEM's battery manager, this is the first moment we can notice
        // and charge the time that passed — see PlayClock.catchUpIfStalled.
        playClock?.catchUpIfStalled()

        // Events arrive with a blank package more often than one expects — a system
        // dialog, a transient window. Evicting on one would send the child to the
        // home screen for no reason they can see. BlockPolicy also refuses a blank
        // package; the check is here too because this is the hot path.
        if (pkg.isBlank()) return

        val state = BlockingStore.state(this)
        val decision = BlockPolicy.decide(
            packageName = pkg,
            state = state,
            selfPackage = packageName,
            systemCriticalPackages = BlockingStore.critical(this),
        )

        when (decision) {
            is BlockDecision.Allow -> {
                // A blocked app that is *allowed* means the child is spending
                // play time right now — the only moment the clock may run.
                //
                // Anything else stops it, **except a window that merely floated
                // over the game**: the status bar, the volume dialog, a toast,
                // the keyboard. Treating those as a departure is what made the
                // counter appear not to work at all — it stopped a second after
                // it started, every time the child touched anything.
                if (state.enabled && pkg in state.blockedPackages) {
                    playClock?.start(pkg)
                } else if (!BlockPolicy.isTransientWindow(
                        pkg,
                        BlockingStore.ime(this),
                        packageName,
                    )
                ) {
                    // The package is in the reason on purpose. "left the game"
                    // alone cost three rounds of guessing; naming the window
                    // that ended the session turns the next one into a lookup.
                    playClock?.stop("left for " + pkg)
                }

                // Leaving a blocked app clears the guard, so returning to it blocks
                // again immediately rather than falling inside the debounce window.
                //
                // **It does not touch the card.** An earlier version hid the
                // overlay here too, and on the first hardware run the card flashed
                // for about a second and vanished. The cause was our own eviction:
                // `performGlobalAction(GLOBAL_ACTION_HOME)` moves the launcher to
                // the foreground, the launcher fires its own window-state event,
                // that event resolves to Allow with a package different from
                // `lastBlockedPackage` — and the branch tore down the card the
                // eviction had just put up. The card was being dismissed by the
                // very action it exists to explain.
                //
                // The card's lifetime belongs to the card: its own timer, or the
                // child tapping "فهمت". Window transitions have no say in it.
                if (lastBlockedPackage != null && lastBlockedPackage != pkg) {
                    lastBlockedPackage = null
                }
            }

            is BlockDecision.Block -> {
                playClock?.stop("blocked")
                enforce(decision, state, at)
            }
        }
    }

    private fun enforce(decision: BlockDecision.Block, state: BlockingState, at: Long) {
        if (decision.packageName == lastBlockedPackage && at - lastBlockedAt < DEBOUNCE_MS) {
            return
        }
        lastBlockedPackage = decision.packageName
        lastBlockedAt = at

        // The card goes up **before** the eviction, for two reasons. A child who is
        // thrown to the home screen with no explanation learns that the phone
        // breaks; and if `performGlobalAction` fails, the card over the game is a
        // degraded outcome rather than a silent one.
        val shown = overlay?.show(decision.reason, state.priceInStars) ?: false
        val evicted = performGlobalAction(GLOBAL_ACTION_HOME)

        // This number is our internal latency: event received -> home performed. It
        // is **not** Article 11.2's two seconds, which run from the game becoming
        // visible, and the part before the event reaches us is invisible from here.
        // The contractual measure is a screen recording counted frame by frame.
        Log.i(
            TAG,
            "block pkg=${decision.packageName} reason=${decision.reason} " +
                "home=$evicted card=$shown internal_ms=${SystemClock.uptimeMillis() - at}",
        )
    }

    /**
     * The balance ran out while the child was still inside the game.
     *
     * Reached only from [PlayClock], never from a window event, because there is
     * no window event to reach it from — that absence is the whole reason the
     * clock exists. The eviction path is the same one an ordinary block takes,
     * so the card, the logging and the debounce all behave identically.
     */
    private fun onPlayTimeExhausted(gamePackage: String) {
        val state = BlockingStore.state(this)
        val decision = BlockPolicy.decide(
            packageName = gamePackage,
            state = state,
            // `this.packageName` — Lunio's own. The parameter used to be called
            // `packageName` too, so `selfPackage = packageName` silently passed
            // the **game's** package as ours: `isProtected` then saw
            // `packageName == selfPackage`, decided the game was Lunio itself,
            // and returned Allow. The eviction never fired.
            //
            // The symptom was precise and misleading: play time ran out and
            // nothing happened, but leaving and re-entering the game blocked it
            // immediately — because that path goes through
            // `onAccessibilityEvent`, where `packageName` really is ours.
            //
            // The parameter is renamed rather than qualified, so the shadowing
            // cannot come back by someone shortening `this.packageName`.
            selfPackage = this.packageName,
            systemCriticalPackages = BlockingStore.critical(this),
        )
        if (decision is BlockDecision.Block) {
            // Cleared so the debounce cannot swallow this: the child never left
            // the app, so `lastBlockedPackage` may still name it from earlier.
            lastBlockedPackage = null
            enforce(decision, state, SystemClock.uptimeMillis())
        }
    }

    override fun onInterrupt() {
        // Required by the base class. Nothing to interrupt: we produce no feedback
        // to a user of an accessibility feature.
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        // The parent revoked the permission, or the OEM's battery manager killed us.
        // Either way the block card must not be left on top of whatever is running.
        overlay?.hide("service unbound")
        overlay = null
        playTimer?.hide()
        playTimer = null
        live = null
        playClock?.stop("service unbound")
        playClock = null
        runCatching { unregisterReceiver(screenReceiver) }
        Log.w(TAG, "unbound — tier 1 is down")
        return super.onUnbind(intent)
    }

    companion object {
        const val TAG = "LNO_BLOCKING"

        /**
         * The live service, for [PlayDeadline] to poke when its alarm fires.
         *
         * A static reference to a service is normally a leak waiting to happen;
         * it is safe here because it is cleared in `onUnbind`, and because the
         * alternative — having the alarm receiver perform the eviction itself —
         * would put the enforcement path in two places. Only an
         * AccessibilityService can call `performGlobalAction`, so the receiver
         * has to reach one anyway.
         */
        @Volatile
        private var live: LunioAccessibilityService? = null

        /** Wake the clock after an alarm. Does nothing if the service is gone. */
        fun nudge() {
            live?.playClock?.catchUpIfStalled()
        }

        /**
         * One window transition can emit several events. 700 ms swallows the burst
         * without being long enough for a child to slip back into the game.
         */
        private const val DEBOUNCE_MS = 700L
    }
}
