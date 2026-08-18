package dz.nojoumi

import android.content.Context
import android.os.SystemClock
import android.util.Log
import java.util.UUID
import kotlin.math.abs

/**
 * Supplies the three values `nojoumi_time` folds into a trusted instant.
 *
 * It computes no policy. Deciding whether the clock was tampered with belongs to
 * the pure Dart package, where it is covered by 21 tests that need no device
 * (AD-1, AD-2). This class only observes, and identifies the boot session.
 *
 * Verified framework behaviour this relies on — see docs/android-behaviour-notes.md V9:
 *  * `System.currentTimeMillis()` — "can be set by the user or the phone network,
 *    so the time may jump backwards or forwards unpredictably".
 *  * `SystemClock.elapsedRealtime()` — "milliseconds since boot, including time
 *    spent in sleep", and "guaranteed to be monotonic".
 *
 * UNVERIFIED-ON-HARDWARE.
 */
class NojoumiClock(context: Context) {

    private val prefs = context.applicationContext
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /**
     * One observation, with the boot token resolved.
     *
     * Reads the two clocks adjacently and in this order so that the pair is as
     * close to simultaneous as the platform allows; `ClockPolicy` absorbs the
     * remaining microseconds many times over.
     */
    fun read(): Map<String, Any> {
        val elapsed = SystemClock.elapsedRealtime()
        val wall = System.currentTimeMillis()
        val bootId = resolveBootToken(wall, elapsed)
        return mapOf(
            "wallClockMs" to wall,
            "elapsedRealtimeMs" to elapsed,
            "bootId" to bootId,
        )
    }

    /**
     * Called from the BOOT_COMPLETED receiver once one exists. Rotating here is
     * the cheap, certain signal; the two heuristics below are what cover the
     * case where the receiver never fired (OEM autostart restrictions, or the
     * app was installed after this boot).
     */
    fun rotateForBoot() {
        val elapsed = SystemClock.elapsedRealtime()
        val wall = System.currentTimeMillis()
        rotate(wall, elapsed, "boot_completed")
    }

    private fun resolveBootToken(wallMs: Long, elapsedMs: Long): String {
        val stored = prefs.getString(KEY_TOKEN, null)
        val highestElapsed = prefs.getLong(KEY_HIGHEST_ELAPSED, -1L)
        val storedBootInstant = prefs.getLong(KEY_BOOT_INSTANT, Long.MIN_VALUE)

        if (stored == null) return rotate(wallMs, elapsedMs, "first_run")

        // Signal 1 — elapsedRealtime is documented monotonic within a boot, so a
        // lower value than we have already seen proves the device rebooted.
        if (elapsedMs < highestElapsed) {
            return rotate(wallMs, elapsedMs, "elapsed_regressed")
        }

        // Signal 2 — the derived boot instant. Catches the reboot that signal 1
        // misses, where the new session has already been up longer than the old
        // one. It also fires on a plain user clock change, which is deliberate:
        // rotating costs trust and can never manufacture it.
        val bootInstant = wallMs - elapsedMs
        if (abs(bootInstant - storedBootInstant) > BOOT_INSTANT_TOLERANCE_MS) {
            return rotate(wallMs, elapsedMs, "boot_instant_moved")
        }

        if (elapsedMs > highestElapsed) {
            prefs.edit().putLong(KEY_HIGHEST_ELAPSED, elapsedMs).apply()
        }
        return stored
    }

    private fun rotate(wallMs: Long, elapsedMs: Long, why: String): String {
        val token = UUID.randomUUID().toString()
        prefs.edit()
            .putString(KEY_TOKEN, token)
            .putLong(KEY_HIGHEST_ELAPSED, elapsedMs)
            .putLong(KEY_BOOT_INSTANT, wallMs - elapsedMs)
            .apply()
        // No timestamps in the log line: it would be the one place a wall-clock
        // value could be mistaken for evidence. The reason is what matters.
        Log.i(TAG, "boot token rotated: $why")
        return token
    }

    companion object {
        const val TAG = "NJM_CLOCK"

        private const val PREFS = "dz.nojoumi.clock"
        private const val KEY_TOKEN = "boot_token"
        private const val KEY_HIGHEST_ELAPSED = "highest_elapsed"
        private const val KEY_BOOT_INSTANT = "boot_instant"

        /**
         * How far the derived boot instant may drift before it counts as a new
         * session. It moves a little on its own as NTP nudges the wall clock, so
         * a tight bound would rotate the token on an ordinary network sync and
         * force a needless re-anchor. Ten seconds is far above NTP correction
         * and far below any clock change a person makes by hand.
         */
        private const val BOOT_INSTANT_TOLERANCE_MS = 10_000L
    }
}
