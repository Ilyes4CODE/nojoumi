package dz.lunio.blocking

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log

/**
 * Counts play time down while a blocked app is actually in front of the child,
 * and evicts the moment it reaches zero.
 *
 * **This is the half of Article 4.7 that tier 1 cannot do on its own.**
 * `LunioAccessibilityService` is event-driven, and no window event fires while a
 * child sits inside one game. Without a clock, the balance would be checked when
 * the game opened and never again: a child with one minute left could play for an
 * hour, and the counter on the home screen would still read one minute. That was
 * H10.5 in the verification script, written down in advance as the step expected
 * to fail.
 *
 * ### What it measures, and why it is not simply a timer
 *
 * The appendix is explicit that «الطفل لا يخسر دقائق وهو لا يلعب» — the child does
 * not lose minutes while not playing. So the clock runs only while all of these
 * hold, and stops the instant any of them stops:
 *
 *  * a package on the parent's blocked list is the foreground window;
 *  * blocking is on and play is not paused;
 *  * the screen is on. A phone in a pocket must not drain the balance, and this
 *    is the case a naive `postDelayed(remaining)` gets wrong by an hour.
 *
 * It measures with `SystemClock.elapsedRealtime()` rather than by counting its own
 * ticks. A Handler tick is a request, not a promise: under memory pressure or in
 * a doze window ticks are dropped, and a counter that trusts them under-charges
 * exactly when the child is playing hardest. Elapsed time between ticks is the
 * truth, whatever the scheduler did.
 *
 * ### Who owns the balance
 *
 * Not this class. Articles 5 and 6 live in `packages/lunio_stars` with tests on
 * every clause, and the ledger is append-only (AD-4). What happens here is a
 * *copy* being decremented for enforcement, plus a tally of seconds actually
 * spent. Dart drains that tally and writes it to the ledger through
 * `StarRepository.consumePlay`, then pushes the authoritative remaining back —
 * which overwrites this copy with the same number it had reached. No second
 * implementation of the contract, and no double counting.
 *
 * Logcat: `adb logcat -s LNO_PLAY`
 */
internal class PlayClock(
    private val context: Context,
    private val onExhausted: (String) -> Unit,
    /**
     * Called every second while play is running, with the seconds left.
     *
     * Counting correctly and *showing* the count are different problems. While a
     * child is inside a game, Lunio has no screen and no Flutter engine, so the
     * only surfaces that can carry a live number are the foreground-service
     * notification and — the moment the child comes back — the app itself.
     */
    private val onTick: (String, Int) -> Unit = { _, _ -> },
    /**
     * Called whenever the clock stops for any reason — leaving the game, the
     * screen going off, a parent pausing, the balance running out, the service
     * unbinding.
     *
     * One callback for all of them on purpose: every caller so far wants to take
     * the countdown *down*, and a per-reason set of hooks would be five places
     * to forget one.
     */
    private val onStopped: () -> Unit = {},
) {

    private val handler = Handler(Looper.getMainLooper())

    /** The blocked package currently being played, or null. */
    private var playing: String? = null

    /** `elapsedRealtime` at the last tick. Not a tick count — see the class doc. */
    private var lastTickAt: Long = 0L

    private var screenOn: Boolean = true

    private val tick = Runnable { fireTick() }

    /**
     * A blocked app came to the foreground and was allowed. Start charging.
     *
     * Idempotent for the package already running, because a single window
     * transition can emit several events and restarting the clock on each one
     * would discard the fraction of a second since the last tick.
     */
    fun start(packageName: String) {
        if (playing == packageName) return
        stop("switched")

        playing = packageName
        lastTickAt = SystemClock.elapsedRealtime()
        val remaining = BlockingStore.state(context).remainingPlaySeconds
        onTick(packageName, remaining)
        // The backstop, for when this process is frozen and the Handler below
        // never runs. See PlayDeadline.
        PlayDeadline.arm(context, remaining)
        schedule()
        Log.i(
            TAG,
            "play start pkg=" + packageName +
                " remaining_s=" + BlockingStore.state(context).remainingPlaySeconds,
        )
    }

    /**
     * The child left the game, the screen went off, or the service is going away.
     *
     * Charges the partial second first: a child who plays for 40 seconds and
     * switches away must be billed those 40 seconds, not rounded down to the last
     * whole tick.
     */
    fun stop(why: String) {
        val current = playing ?: return
        charge()
        playing = null
        handler.removeCallbacks(tick)
        PlayDeadline.cancel(context)
        onStopped()
        Log.i(
            TAG,
            "play stop pkg=" + current + " why=" + why +
                " remaining_s=" + BlockingStore.state(context).remainingPlaySeconds,
        )
    }

    /**
     * Charge the time that passed while this process was not running.
     *
     * Called on every accessibility event, which is the cheapest reliable signal
     * that the process is awake again. ColorOS freezes background apps, and a
     * frozen process runs no Handler callbacks — so after a freeze the clock
     * would otherwise resume as if the interval had never happened, with the
     * child several minutes richer.
     *
     * The accounting is safe on its own because [charge] bills elapsed time, not
     * ticks. What this adds is **promptness**: without it the catch-up waits for
     * the next scheduled tick, and the eviction waits with it.
     */
    fun catchUpIfStalled() {
        if (playing == null) return
        val gap = SystemClock.elapsedRealtime() - lastTickAt
        if (gap < STALL_MS) return

        Log.w(TAG, "clock stalled for " + gap + "ms — catching up")
        fireTick()
    }

    /** The screen turned on or off. Off stops the clock; on does not start it —
     *  the next window event decides whether a game is really in front again. */
    fun setScreenOn(on: Boolean) {
        screenOn = on
        if (!on) stop("screen off")
    }

    val isRunning: Boolean get() = playing != null

    private fun schedule() {
        handler.removeCallbacks(tick)
        handler.postDelayed(tick, TICK_MS)
    }

    private fun fireTick() {
        val current = playing ?: return

        val state = charge()

        // The parent paused play from the dashboard while the child was inside
        // the game. Enforced here as well as on window events, because otherwise
        // nothing would happen until the child switched apps.
        if (state.playPaused || state.remainingPlaySeconds <= 0) {
            onTick(current, 0)
            stop(if (state.playPaused) "paused" else "exhausted")
            onExhausted(current)
            return
        }
        onTick(current, state.remainingPlaySeconds)
        schedule()
    }

    /**
     * Bill the elapsed time since the last tick, and return the new state.
     *
     * Whole seconds only: the remainder is left on the clock rather than
     * discarded, so a run of short sessions does not lose a second each time.
     */
    private fun charge(): BlockingState {
        val now = SystemClock.elapsedRealtime()
        val elapsedMs = now - lastTickAt
        val seconds = (elapsedMs / 1000L).toInt()
        if (seconds <= 0) return BlockingStore.state(context)

        lastTickAt = now - (elapsedMs % 1000L)
        return BlockingStore.spendPlaySeconds(context, seconds)
    }

    private companion object {
        const val TAG = "LNO_PLAY"

        /**
         * One second. It is a *display* cadence as much as an accounting one —
         * the child's balance on the home screen should visibly move — and the
         * accounting is elapsed-time based, so a dropped tick costs nothing.
         */
        const val TICK_MS = 1_000L

        /**
         * A gap this long means something stopped us — a freeze, a doze, a very
         * busy main thread. Three seconds is comfortably above normal jitter and
         * well below the point where a child notices free play.
         */
        const val STALL_MS = 3_000L
    }
}
