package dz.lunio.blocking

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.util.Log

/**
 * A wake-up scheduled for the moment play time runs out.
 *
 * ### The problem this exists for
 *
 * `PlayClock` counts with a `Handler` on the service's main thread. That works
 * while the process is running — and while a child is inside a game, **Lunio is
 * a background process**, which on ColorOS means `ColorHansManager` is entitled
 * to freeze it. A frozen process runs no Handler callbacks at all, so the
 * countdown stops on screen and, far worse, **the tick that would have noticed
 * the balance reaching zero never fires.** The child keeps playing.
 *
 * Reported from the device on 2026-08-29 as «المؤقت في بعض الأحيان يحبس», which
 * is exactly the shape of an OEM freeze: not slow, not wrong — stopped, then
 * resuming later as if nothing happened.
 *
 * The accounting was already safe: `PlayClock` bills elapsed time between ticks
 * rather than counting them, so a frozen minute is still charged when the
 * process wakes. What was *not* safe is the enforcement, and Article 4.7 is
 * about enforcement.
 *
 * ### What it does
 *
 * One alarm, set for the second the balance is due to reach zero. An alarm is
 * delivered by the system rather than by our own thread, and delivering it
 * **wakes the process** — which resumes the clock, which charges the elapsed
 * time, sees zero, and evicts.
 *
 * `setAndAllowWhileIdle` rather than an exact alarm, deliberately. Exact alarms
 * need `SCHEDULE_EXACT_ALARM`, which on Android 13+ is a user grant and on Play
 * is scrutinised — it is meant for alarm clocks and calendars, and claiming it
 * for a parental-control app invites the rejection that Article 15's permission
 * budget is already close to. The inexact form fires within a short window while
 * the screen is on, which is the only situation this matters in: the clock stops
 * itself when the screen goes off.
 *
 * It is a **backstop, not the mechanism**. When nothing freezes, the Handler
 * fires first and the alarm is cancelled unused.
 *
 * Logcat: `adb logcat -s LNO_PLAY`
 */
internal object PlayDeadline {

    private const val TAG = "LNO_PLAY"
    private const val ACTION = "dz.lunio.blocking.PLAY_DEADLINE"
    private const val REQUEST = 4202

    fun arm(context: Context, remainingSeconds: Int) {
        val manager = context.getSystemService(AlarmManager::class.java) ?: return
        if (remainingSeconds <= 0) return

        // A second of slack so the alarm lands just *after* the clock would have
        // reached zero on its own. Racing the Handler would mean two evictions
        // for one expiry, and the debounce is 700 ms.
        val at = SystemClock.elapsedRealtime() + (remainingSeconds + 1) * 1000L

        runCatching {
            manager.setAndAllowWhileIdle(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                at,
                pending(context),
            )
            Log.i(TAG, "deadline armed in " + remainingSeconds + "s")
        }.onFailure { Log.w(TAG, "deadline could not be armed: " + it.javaClass.simpleName) }
    }

    fun cancel(context: Context) {
        val manager = context.getSystemService(AlarmManager::class.java) ?: return
        runCatching { manager.cancel(pending(context)) }
    }

    private fun pending(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        REQUEST,
        Intent(ACTION).setPackage(context.packageName),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    /**
     * The alarm arriving.
     *
     * It does not evict by itself — only an AccessibilityService can perform a
     * global action, and the enforcement path should stay in one place. What it
     * does is **wake the process and poke the clock**, which is the whole point:
     * a woken clock charges the time that passed while it was frozen and then
     * takes the ordinary path to eviction.
     */
    class Receiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != ACTION) return
            Log.i(TAG, "deadline fired")
            LunioAccessibilityService.nudge()
        }
    }
}
