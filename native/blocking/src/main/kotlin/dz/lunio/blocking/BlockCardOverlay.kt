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
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Tier 3 of AD-8 — the visible surface of a blocking decision.
 *
 * Built as a `TYPE_APPLICATION_OVERLAY` window rather than an activity because
 * notes V2 rules out starting an activity from the background: an
 * AccessibilityService is not on the documented exemption list, and a design that
 * needs `startActivity` from there fails silently on modern Android. The overlay
 * permission, by contrast, *is* on that list, which is what makes this the tier
 * that actually works.
 *
 * The views are built in code rather than inflated from XML. It keeps the module
 * free of resource coupling to the app, and the block card is one screen with four
 * widgets — an XML file would be indirection, not structure.
 *
 * **Two safety rules govern this class,** because a full-screen opaque overlay that
 * fails to come down is a bricked phone:
 *
 *  * it auto-dismisses on a timer, whatever else happens;
 *  * every `WindowManager` call is wrapped, and a failure degrades to
 *    eviction-without-a-card rather than to a crash inside the service.
 */
internal class BlockCardOverlay(private val context: Context) {

    private val handler = Handler(Looper.getMainLooper())
    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    private var view: View? = null
    private var shownAt: Long = 0L
    private var regularFace: Typeface? = null
    private var boldFace: Typeface? = null
    private val dismiss = Runnable { hide("timer") }

    /**
     * Puts the card up. Returns whether it actually appeared.
     *
     * A `false` here is the single most useful line in the logs when a parent
     * reports "it goes home but says nothing": it means the overlay permission was
     * never granted, or the OEM revoked it, and the fix is a settings screen rather
     * than a code change.
     */
    fun show(reason: BlockReason, priceInStars: String): Boolean {
        if (!Settings.canDrawOverlays(context)) {
            Log.w(TAG, "overlay permission not granted - evicting without a card")
            return false
        }
        hide("replaced")

        return try {
            val card = build(reason, priceInStars)
            windowManager.addView(card, layoutParams())
            view = card
            shownAt = android.os.SystemClock.uptimeMillis()
            handler.postDelayed(dismiss, VISIBLE_MS)
            true
        } catch (t: Throwable) {
            // Includes the case where the permission was granted a moment ago and
            // the window token is still refused. Never let this reach the service.
            Log.e(TAG, "overlay failed: " + t.javaClass.simpleName)
            view = null
            false
        }
    }

    /**
     * Takes the card down, and says who took it.
     *
     * [why] is logged because the first hardware run produced a card that
     * flashed for about a second, and from outside the process a card dismissed
     * by its timer, by the child's tap, and by a bug look identical. One word in
     * logcat is the difference between measuring the problem and guessing at it.
     */
    fun hide(why: String) {
        handler.removeCallbacks(dismiss)
        val current = view ?: return
        view = null
        val visibleMs = android.os.SystemClock.uptimeMillis() - shownAt
        Log.i(TAG, "card down why=" + why + " visible_ms=" + visibleMs)
        runCatching { windowManager.removeView(current) }
            .onFailure { Log.w(TAG, "overlay remove failed: " + it.javaClass.simpleName) }
    }

    private fun layoutParams() = WindowManager.LayoutParams(
        WindowManager.LayoutParams.MATCH_PARENT,
        WindowManager.LayoutParams.MATCH_PARENT,
        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
        // Focusable would steal the IME and swallow the back key from whatever is
        // underneath. The card is touchable - taps must not fall through to the
        // game - but it does not take focus.
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
        PixelFormat.TRANSLUCENT,
    ).apply {
        gravity = Gravity.CENTER
    }

    private fun build(reason: BlockReason, priceInStars: String): View {
        val res = context.resources

        val scrim = FrameLayout(context).apply {
            setBackgroundColor(SCRIM)
            layoutDirection = View.LAYOUT_DIRECTION_LOCALE
            // Swallows every touch that misses the card, so the game underneath
            // receives nothing at all.
            isClickable = true
        }

        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            background = GradientDrawable().apply {
                setColor(CANVAS)
                cornerRadius = dp(28f)
            }
            setPadding(dp(24f).toInt(), dp(28f).toInt(), dp(24f).toInt(), dp(20f).toInt())
        }

        val titleId = when (reason) {
            BlockReason.NoPlayTimeLeft -> R.string.lunio_block_title_no_time
            BlockReason.ParentPaused -> R.string.lunio_block_title_paused
        }
        val bodyId = when (reason) {
            BlockReason.NoPlayTimeLeft -> R.string.lunio_block_body_no_time
            BlockReason.ParentPaused -> R.string.lunio_block_body_paused
        }

        card.addView(
            TextView(context).apply {
                text = "🔒"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 40f)
                gravity = Gravity.CENTER
            },
        )
        card.addView(
            TextView(context).apply {
                text = res.getString(titleId)
                setTextColor(INK)
                typeface(bold = true)?.let { typeface = it }
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
                gravity = Gravity.CENTER
                setPadding(0, dp(12f).toInt(), 0, 0)
            },
        )
        card.addView(
            TextView(context).apply {
                text = res.getString(bodyId)
                setTextColor(INK_SOFT)
                typeface(bold = false)?.let { typeface = it }
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                gravity = Gravity.CENTER
                setPadding(0, dp(8f).toInt(), 0, 0)
            },
        )

        // Article 1 calls this a motivation tool. The card tells the child what the
        // way back in costs, so the message is "here is how", not only "no".
        if (priceInStars.isNotBlank() && reason == BlockReason.NoPlayTimeLeft) {
            card.addView(
                TextView(context).apply {
                    text = res.getString(R.string.lunio_block_price, priceInStars)
                    setTextColor(STAR_INK)
                    typeface(bold = true)?.let { typeface = it }
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                    gravity = Gravity.CENTER
                    setPadding(0, dp(14f).toInt(), 0, 0)
                },
            )
        }

        card.addView(
            Button(context).apply {
                text = res.getString(R.string.lunio_block_dismiss)
                setTextColor(Color.WHITE)
                typeface(bold = true)?.let { typeface = it }
                isAllCaps = false
                background = GradientDrawable().apply {
                    setColor(PURPLE)
                    cornerRadius = dp(18f)
                }
                setOnClickListener { hide("tapped") }
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dp(48f).toInt(),
                ).apply { topMargin = dp(20f).toInt() }
            },
        )

        scrim.addView(
            card,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
            ).apply {
                gravity = Gravity.CENTER
                marginStart = dp(28f).toInt()
                marginEnd = dp(28f).toInt()
            },
        )
        return scrim
    }

    /**
     * Tajawal, loaded from **this module's own assets**.
     *
     * The Flutter side bundles the same family, and reaching into
     * `flutter_assets/` from here would have saved 120 KB — at the cost of AD-7,
     * which says the blocking engine keeps working with the Flutter engine dead
     * and therefore must not depend on how Flutter packages itself. A duplicated
     * font file is a cheap price for a module that still compiles with Flutter
     * deleted.
     *
     * Wrapped and cached: a missing or corrupt file falls back to the system
     * face, because the card carrying the right message in the wrong typeface is
     * a far better outcome than an exception inside the accessibility service.
     */
    private fun typeface(bold: Boolean): Typeface? {
        val cached = if (bold) boldFace else regularFace
        if (cached != null) return cached
        val name = if (bold) "fonts/Tajawal-Bold.ttf" else "fonts/Tajawal-Regular.ttf"
        val loaded = runCatching { Typeface.createFromAsset(context.assets, name) }
            .onFailure { Log.w(TAG, "font load failed: " + it.javaClass.simpleName) }
            .getOrNull()
        if (bold) boldFace = loaded else regularFace = loaded
        return loaded
    }

    private fun dp(value: Float): Float = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        value,
        context.resources.displayMetrics,
    )

    private companion object {
        const val TAG = LunioAccessibilityService.TAG

        /**
         * Long enough to read, short enough that a stuck card is an annoyance and
         * not a dead phone. The eviction has already happened by the time this
         * expires, so dismissal returns the child to the home screen, not the game.
         */
        const val VISIBLE_MS = 6_000L

        val SCRIM = Color.argb(190, 30, 36, 54)
        val CANVAS = Color.parseColor("#F8F7FC")
        val INK = Color.parseColor("#1E2436")
        val INK_SOFT = Color.parseColor("#5A6178")
        val PURPLE = Color.parseColor("#5B3FD9")
        val STAR_INK = Color.parseColor("#8A6A00")
    }
}
