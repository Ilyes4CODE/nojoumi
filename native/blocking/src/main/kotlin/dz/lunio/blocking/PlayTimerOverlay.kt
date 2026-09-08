package dz.lunio.blocking

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.TextView

/**
 * The countdown the child can see **while they are inside the game**.
 *
 * A small pill floating over whatever is running, counting the play balance down
 * once a second. It disappears the moment play stops — leaving the game, the
 * screen going off, a parent pausing — because a timer that keeps ticking while
 * nothing is being spent is worse than no timer: it teaches the child that the
 * number lies.
 *
 * ### Why this is not a WebSocket, asked and answered
 *
 * The obvious shape is a socket to the Django server pushing the remaining
 * seconds. It cannot work and would not help. **While the child is in a game
 * there is no Flutter engine running** — that is the entire reason `PlayClock`
 * lives in Kotlin — so nothing exists to hold a connection open at exactly the
 * moment it would need to. And the server has nothing to say: the balance is
 * Article 5 arithmetic over data that never leaves the phone (Art. 14), so a
 * round trip to Algiers would add latency, a network dependency and a privacy
 * surface to a number already in memory a few microseconds away.
 *
 * The number is local, the clock is local, and so is the transport.
 *
 * ### The flag that matters most
 *
 * `FLAG_NOT_TOUCHABLE`. This window sits on top of a game a child is playing,
 * and a floating pill that swallowed taps would make the game unplayable — while
 * looking like the game itself was broken. Every touch passes straight through.
 *
 * Logcat: `adb logcat -s LNO_PLAY`
 */
internal class PlayTimerOverlay(private val context: Context) {

    private val handler = Handler(Looper.getMainLooper())
    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    private var view: TextView? = null

    /** Last text drawn, so a tick that changes nothing does no layout work. */
    private var lastText: String? = null

    /**
     * Show the pill, or update it in place.
     *
     * Called once a second from [PlayClock], so it must be cheap: after the first
     * call this is a `setText` on an existing view, not a new window.
     */
    fun show(remainingSeconds: Int) {
        if (!Settings.canDrawOverlays(context)) return

        val text = format(remainingSeconds)
        val existing = view
        if (existing != null) {
            if (text != lastText) {
                existing.text = text
                existing.background = pill(remainingSeconds)
                lastText = text
            }
            return
        }

        runCatching {
            val pill = build(text, remainingSeconds)
            windowManager.addView(pill, layoutParams())
            view = pill
            lastText = text
        }.onFailure {
            Log.w(TAG, "timer overlay failed: " + it.javaClass.simpleName)
            view = null
        }
    }

    fun hide() {
        val current = view ?: return
        view = null
        lastText = null
        handler.post {
            runCatching { windowManager.removeView(current) }
        }
    }

    private fun layoutParams() = WindowManager.LayoutParams(
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
        // NOT_TOUCHABLE is the important one — see the class doc. NOT_FOCUSABLE
        // keeps it out of the IME and the back key.
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
        PixelFormat.TRANSLUCENT,
    ).apply {
        // Top centre: out of the way of the thumbs at the bottom of a phone game,
        // and clear of the notch on most devices once the top margin is applied.
        gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        y = dp(48f).toInt()
    }

    private fun build(text: String, remaining: Int) = TextView(context).apply {
        this.text = text
        setTextColor(Color.WHITE)
        typeface = face()
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        gravity = Gravity.CENTER
        background = pill(remaining)
        setPadding(dp(18f).toInt(), dp(8f).toInt(), dp(18f).toInt(), dp(8f).toInt())
        // The clock is always a Latin-digit reading of minutes and seconds, so it
        // is pinned LTR — an RTL locale would otherwise render "4:32" reversed.
        textDirection = View.TEXT_DIRECTION_LTR
    }

    /**
     * Violet normally, warm orange in the last minute.
     *
     * The change of colour is the warning — no sound, no vibration, no dialog.
     * A child deep in a game should be told that time is short in a way that
     * does not yank them out of it, because the eviction one minute later is
     * jarring enough on its own.
     */
    private fun pill(remainingSeconds: Int) = GradientDrawable().apply {
        setColor(if (remainingSeconds <= 60) WARNING else NORMAL)
        cornerRadius = dp(22f)
    }

    private fun face(): Typeface = runCatching {
        Typeface.createFromAsset(context.assets, "fonts/Tajawal-Bold.ttf")
    }.getOrElse { Typeface.DEFAULT_BOLD }

    private fun format(seconds: Int): String {
        val safe = seconds.coerceAtLeast(0)
        return "%d:%02d".format(safe / 60, safe % 60)
    }

    private fun dp(value: Float): Float = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        value,
        context.resources.displayMetrics,
    )

    private companion object {
        const val TAG = "LNO_PLAY"
        val NORMAL = Color.argb(235, 91, 63, 217)
        val WARNING = Color.argb(240, 255, 122, 89)
    }
}
