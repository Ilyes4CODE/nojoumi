package dz.lunio.blocking

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.provider.Settings

/**
 * Where [BlockingState] lives between events, and why it lives outside Dart.
 *
 * AD-7 in one sentence: **blocking must keep working while the Flutter engine is
 * dead.** The child force-stops Lunio from the recents screen, or Android reclaims
 * the process, and the accessibility service is still connected and still receiving
 * window events — but there is no Dart to ask. So the state the service needs is
 * mirrored into `SharedPreferences` by the bridge whenever it changes, and read
 * from there afterwards, with no round trip and no engine.
 *
 * Held in a `@Volatile` field as well as on disk because [LunioAccessibilityService]
 * reads it on every window transition. Article 11.2 allows two seconds from the game
 * appearing to the block landing, and a disk read on that path — thousands of times
 * a day — is a cost with no reason behind it.
 *
 * **The engine never computes any of these values.** Articles 5 and 6 live in
 * `packages/lunio_stars` with tests on every clause; re-deriving the balance here
 * would create a second implementation of the contract that could disagree with the
 * first, and the one on the child's screen would be the one that is wrong.
 */
object BlockingStore {

    private const val PREFS = "lunio_blocking"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_PACKAGES = "blocked_packages"
    private const val KEY_SECONDS = "remaining_play_seconds"
    private const val KEY_PAUSED = "play_paused"
    private const val KEY_PRICE = "price_in_stars"

    /**
     * Seconds of play actually spent since Dart last drained this.
     *
     * The engine counts them down; the **ledger** is Dart's (AD-4), so this is a
     * tally waiting to be collected rather than a balance. `LunioBlockingBridge`
     * drains it and `StarRepository.consumePlay` writes it, which is what keeps
     * Articles 5 and 6 with exactly one implementation.
     */
    private const val KEY_CONSUMED = "consumed_play_seconds"

    @Volatile
    private var cached: BlockingState? = null

    /**
     * Packages that vary per device and must never be blocked: the current home
     * app and the active keyboard.
     *
     * Resolved once per process rather than per event. They can change — the parent
     * switches launcher, the child installs a keyboard — so [refreshCritical] exists
     * and the service calls it on connect. A stale entry here can only ever *allow*
     * something, never block it, which is the safe direction for a mistake to fall.
     */
    @Volatile
    private var criticalCache: Set<String> = emptySet()

    /**
     * The active keyboard, on its own.
     *
     * Needed separately from [criticalCache] because the two questions are
     * different: "may this be blocked?" (no, or the parent cannot type their
     * PIN) versus "does this window mean the child left the game?" (also no — a
     * keyboard opening over a game is the child typing *in* the game).
     */
    @Volatile
    private var imeCache: String? = null

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun state(context: Context): BlockingState {
        cached?.let { return it }
        val p = prefs(context)
        val loaded = BlockingState(
            enabled = p.getBoolean(KEY_ENABLED, false),
            blockedPackages = p.getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet(),
            remainingPlaySeconds = p.getInt(KEY_SECONDS, 0),
            playPaused = p.getBoolean(KEY_PAUSED, false),
            priceInStars = p.getString(KEY_PRICE, "") ?: "",
        )
        cached = loaded
        return loaded
    }

    /**
     * Bill [seconds] of play: down from the remaining, up on the tally.
     *
     * Clamped at zero rather than allowed to go negative. A negative remaining
     * would still block correctly — `BlockPolicy` tests `<= 0` — but it would be
     * a number the parent could see on a debug screen and could not explain, and
     * a bug that produced a large negative would hide itself as "still blocking".
     */
    @Synchronized
    fun spendPlaySeconds(context: Context, seconds: Int): BlockingState {
        if (seconds <= 0) return state(context)

        val current = state(context)
        val next = current.copy(
            remainingPlaySeconds = (current.remainingPlaySeconds - seconds).coerceAtLeast(0),
        )
        cached = next

        val p = prefs(context)
        p.edit()
            .putInt(KEY_SECONDS, next.remainingPlaySeconds)
            .putInt(KEY_CONSUMED, p.getInt(KEY_CONSUMED, 0) + seconds)
            // `commit`, not `apply`. This is written once a second while a child
            // is inside a game, and the process may be killed by an OEM battery
            // manager at any moment between two of them. `apply` is asynchronous
            // and would drop the pending write, handing the child back the time
            // they had just spent.
            .commit()

        return next
    }

    /**
     * Take the accumulated seconds and reset the tally, atomically.
     *
     * Read-and-clear in one step because the engine keeps adding while Dart
     * reads: a read followed by a separate write would silently discard whatever
     * accrued in between, and the child would be given those seconds for free
     * once per drain.
     */
    @Synchronized
    fun drainConsumedSeconds(context: Context): Int {
        val p = prefs(context)
        val consumed = p.getInt(KEY_CONSUMED, 0)
        if (consumed != 0) p.edit().putInt(KEY_CONSUMED, 0).commit()
        return consumed
    }

    /** Called by the bridge whenever Dart's view of the world changes. */
    @Synchronized
    fun write(context: Context, state: BlockingState) {
        cached = state
        prefs(context).edit()
            .putBoolean(KEY_ENABLED, state.enabled)
            .putStringSet(KEY_PACKAGES, state.blockedPackages)
            .putInt(KEY_SECONDS, state.remainingPlaySeconds)
            .putBoolean(KEY_PAUSED, state.playPaused)
            .putString(KEY_PRICE, state.priceInStars)
            .apply()
    }

    fun critical(context: Context): Set<String> {
        if (criticalCache.isEmpty()) refreshCritical(context)
        return criticalCache
    }

    /** The active keyboard's package, or null. See [imeCache]. */
    fun ime(context: Context): String? {
        if (criticalCache.isEmpty()) refreshCritical(context)
        return imeCache
    }

    /**
     * Resolves the current home app and the active input method.
     *
     * Blocking the keyboard leaves a phone on which nothing can be typed —
     * including the parent's own PIN, which is the only way back into the settings
     * that would undo it. That is why these are computed rather than guessed from a
     * table of package names.
     */
    fun refreshCritical(context: Context) {
        val app = context.applicationContext
        val found = mutableSetOf<String>()

        val home = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        app.packageManager.resolveActivity(home, 0)
            ?.activityInfo?.packageName
            ?.let(found::add)

        // "com.example.ime/.LatinIME" -> "com.example.ime". Null on a device with no
        // keyboard selected yet, which is a real state on first boot.
        val ime = Settings.Secure
            .getString(app.contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD)
            ?.substringBefore('/')
            ?.takeIf { it.isNotBlank() }
        imeCache = ime
        ime?.let(found::add)

        criticalCache = found
    }

    /** Test seam and process-death simulation. Not called in production. */
    fun invalidate() {
        cached = null
        criticalCache = emptySet()
        imeCache = null
    }
}
