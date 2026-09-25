package dz.lunio.blocking

/**
 * What the blocking engine knows about the world right now.
 *
 * Supplied by the app layer and refreshed whenever it changes. Deliberately a
 * value: the service reads it on every window event, thousands of times a day, and
 * a snapshot it can read without locking or querying is the difference between an
 * eviction inside Article 11.2's two seconds and one that misses it.
 */
data class BlockingState(
    /** Article 15.2 — off until the parent opts in during setup. */
    val enabled: Boolean = false,

    /** Package names the parent marked as games or distracting apps (D-9). */
    val blockedPackages: Set<String> = emptySet(),

    /**
     * Seconds of play the child can still spend, from `lunio_stars`.
     *
     * The engine never computes this. Article 5 and 6 live in the pure Dart
     * package with 89 tests on them, and re-deriving any of it here would create a
     * second implementation of the contract that could disagree with the first.
     */
    val remainingPlaySeconds: Int = 0,

    /** Appendix §4 — the parent can suspend play without destroying the balance. */
    val playPaused: Boolean = false,

    /**
     * What a locked app costs right now, for the block card. Display only.
     */
    val priceInStars: String = "",

    /**
     * Ask for the parent's PIN before Lunio can be uninstalled or wiped.
     *
     * Client request, 2026-09-25. Off by default and set by the parent, because
     * a control that interrupts the system Settings of somebody's own phone is
     * not one to switch on for them. See [UninstallGuard] for what it can and
     * cannot actually stop.
     */
    val uninstallGuard: Boolean = false,

    /**
     * Uptime past which the guard fires again, set when the PIN was accepted.
     *
     * Uptime rather than wall time on purpose: the parent's clock is untrusted
     * (Art. 6.8), and a grace window keyed to it could be extended indefinitely
     * by a child who moves the date back.
     */
    val guardUnlockedUntilMs: Long = 0,
)

/**
 * What to do about a package that just came to the foreground.
 */
sealed interface BlockDecision {
    /** Nothing to do. The overwhelmingly common case, and it must be cheap. */
    data object Allow : BlockDecision

    /**
     * Evict and show the block card.
     *
     * [reason] is carried so the card can say the right thing — "play time is
     * over" and "your parent paused play" are different messages, and a child who
     * is told the wrong one learns the app is unreliable.
     */
    data class Block(val packageName: String, val reason: BlockReason) : BlockDecision
}

enum class BlockReason {
    /** Article 4.7 — the balance ran out. */
    NoPlayTimeLeft,

    /** Appendix §4 — the parent paused play. */
    ParentPaused,
}

/**
 * The decision, as pure Kotlin.
 *
 * **No Android type appears in this file**, which is the point: the twelve
 * scenarios of Article 12 are expensive to run on hardware and this part of them
 * is free to run on the JVM. What hardware then has to answer is narrower and
 * honest — does the event arrive, does the eviction land, and how fast — rather
 * than "is the logic right", which is settled here.
 *
 * The ordering below is deliberate and each step is a contract clause:
 *
 * 1. **Blocking off** — Article 15.2 makes it opt-in, and the app must be fully
 *    usable with it off. This is checked first because it is the state the twelve
 *    Play testers are in.
 * 2. **Never blockable** — Lunio itself, Settings, the dialer, the launcher, the
 *    IME (D-9). A parental-control app that can lock the parent out of Settings
 *    has bricked the phone, and the check comes before the parent's own list so
 *    that no configuration can reach it.
 * 3. **Not on the parent's list** — allowed.
 * 4. **Parent paused** — appendix §4.
 * 5. **No play time left** — Article 4.7.
 */
object BlockPolicy {

    /**
     * Packages that can never be blocked, whatever the parent's list says.
     *
     * Held as a set of exact package names plus a caller-supplied set for the
     * things that vary per device: the current launcher and the active input
     * method. Blocking the keyboard would leave a phone on which nothing can be
     * typed, including the parent's PIN.
     */
    fun isProtected(
        packageName: String,
        selfPackage: String,
        systemCriticalPackages: Set<String>,
    ): Boolean {
        if (packageName == selfPackage) return true
        if (packageName in systemCriticalPackages) return true
        return packageName in ALWAYS_ALLOWED
    }

    fun decide(
        packageName: String,
        state: BlockingState,
        selfPackage: String,
        systemCriticalPackages: Set<String> = emptySet(),
    ): BlockDecision {
        if (!state.enabled) return BlockDecision.Allow
        if (packageName.isBlank()) return BlockDecision.Allow
        if (isProtected(packageName, selfPackage, systemCriticalPackages)) {
            return BlockDecision.Allow
        }
        if (packageName !in state.blockedPackages) return BlockDecision.Allow

        if (state.playPaused) {
            return BlockDecision.Block(packageName, BlockReason.ParentPaused)
        }
        if (state.remainingPlaySeconds <= 0) {
            return BlockDecision.Block(packageName, BlockReason.NoPlayTimeLeft)
        }
        return BlockDecision.Allow
    }

    /**
     * Whether an already-running blocked app must now be evicted.
     *
     * The other half of Article 4.7: the child was legitimately playing, and the
     * balance reached zero **while they played**. Without this the counter would
     * hit zero and nothing would happen until they switched apps.
     */
    fun shouldEvictForeground(
        foregroundPackage: String?,
        state: BlockingState,
        selfPackage: String,
        systemCriticalPackages: Set<String> = emptySet(),
    ): BlockDecision {
        val current = foregroundPackage ?: return BlockDecision.Allow
        return decide(current, state, selfPackage, systemCriticalPackages)
    }

    /**
     * Windows that appear *over* a running app without the child leaving it.
     *
     * **This is the difference between a play clock that works and one that
     * looks broken.** A child inside a game pulls the status bar, changes the
     * volume, dismisses a toast, taps a text field — every one of those is a
     * `TYPE_WINDOW_STATE_CHANGED` from SystemUI or the keyboard, and treating it
     * as "left the game" stops the countdown a second after it started. Reported
     * from the device on 2026-08-30 as the counter not working at all.
     *
     * It is the same mistake the block card made in a different costume: a
     * transient window from another package is not a foreground app change.
     *
     * The launcher is deliberately **not** here. Going to the home screen really
     * is leaving.
     */
    fun isTransientWindow(
        packageName: String,
        imePackage: String?,
        selfPackage: String? = null,
    ): Boolean {
        if (packageName.isBlank()) return true
        // **Our own windows, and this is the one that actually bit.**
        //
        // The play-timer pill is a `TYPE_APPLICATION_OVERLAY` owned by Lunio, and
        // adding it fires a window-state event with *our* package. So the clock
        // started, drew the pill, and the pill's own arrival was read as the
        // child leaving the game — 56 ms later, every single time, measured on
        // the device on 2026-08-30:
        //
        //     play start pkg=com.block.juggle remaining_s=599
        //     play stop  pkg=com.block.juggle why=left the game
        //
        // The countdown killed the thing that draws it. Third time this exact
        // shape has appeared — the block card flashing, transient system
        // windows, and now us — which is why the rule is a named function with
        // tests rather than a condition inline in the service.
        if (selfPackage != null && packageName == selfPackage) return true
        if (imePackage != null && packageName == imePackage) return true
        return packageName in TRANSIENT
    }

    /**
     * System windows that float over whatever is running.
     *
     * SystemUI covers the status bar, the shade, the volume dialog, the recents
     * animation and most toasts. The rest are the permission and install dialogs
     * — a child answering one has not gone anywhere.
     */
    val TRANSIENT: Set<String> = setOf(
        "com.android.systemui",
        "com.android.permissioncontroller",
        "com.google.android.permissioncontroller",
        "com.android.packageinstaller",
        "com.google.android.packageinstaller",
    )

    /**
     * The permanent allowlist of D-9.
     *
     * Android's own package names, not ours. A phone where the dialer can be
     * blocked is a phone that cannot call an ambulance, and a phone where Settings
     * can be blocked is a phone the parent cannot recover — which is why this is
     * a constant rather than a setting.
     */
    val ALWAYS_ALLOWED: Set<String> = setOf(
        // Settings, on stock and on the common OEM skins.
        "com.android.settings",
        "com.samsung.android.settings",
        // Dialer and emergency.
        "com.android.dialer",
        "com.google.android.dialer",
        "com.samsung.android.dialer",
        "com.android.server.telecom",
        "com.android.emergency",
        // Messaging.
        "com.android.mms",
        "com.google.android.apps.messaging",
        "com.samsung.android.messaging",
        // The system UI itself. Blocking it would be blocking the status bar.
        "com.android.systemui",
        // The package installer, or an uninstall dialog becomes unreachable.
        "com.android.packageinstaller",
        "com.google.android.packageinstaller",
        "com.android.permissioncontroller",
    )
}
