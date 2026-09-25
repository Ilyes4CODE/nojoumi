package dz.lunio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter host, and the only class in the project that knows about both worlds.
 *
 * Both channels below are **queries and writes, never enforcement**. AD-7 puts the
 * blocking engine in an independent Gradle library precisely so it keeps working
 * while the Flutter engine is dead: `native/blocking` contains no Flutter type, and
 * deleting this file would not stop a single game from being blocked.
 *
 * D-39 records why the channel handlers live here rather than in a `native/bridge`
 * module — the Flutter embedding artifact is versioned by engine hash and resolved
 * by the Flutter Gradle plugin, so a plain Android library would have to pin that
 * hash by hand and re-pin it on every upgrade, buying nothing.
 */
class MainActivity : FlutterActivity() {

    /**
     * Why the uninstall guard interrupted, or null.
     *
     * Set from the launch intent and cleared when Dart reads it. Held on the
     * activity rather than in preferences because it is a single interruption,
     * not a state: surviving a process death would mean a PIN prompt appearing
     * on an unrelated launch hours later.
     */
    private var pendingPinReason: String? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        readPinRequest(intent)
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        // The common path: the activity is already alive behind Settings, so
        // the service's launch arrives here rather than through onCreate.
        setIntent(intent)
        readPinRequest(intent)
    }

    private fun readPinRequest(intent: android.content.Intent?) {
        intent?.getStringExtra(dz.lunio.blocking.UninstallGuard.EXTRA_REQUIRE_PIN)
            ?.let { pendingPinReason = it }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        val clock = LunioClock(applicationContext)
        MethodChannel(messenger, CLOCK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "read" -> result.success(clock.read())
                else -> result.notImplemented()
            }
        }

        // Application context, not the activity: `setState` is called while the
        // parent edits settings, and holding the activity would leak it across a
        // rotation for no reason.
        val blocking = LunioBlockingBridge(applicationContext)
        MethodChannel(messenger, BLOCKING_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> result.success(blocking.status())

                // The accessibility service launches this activity with an
                // extra when somebody opens Lunio's uninstall screen. Dart asks
                // for it on resume; reading it clears it, so one interruption
                // produces one PIN prompt rather than one on every resume
                // afterwards.
                "consumePendingPinRequest" -> {
                    val reason = pendingPinReason
                    pendingPinReason = null
                    result.success(reason)
                }

                // Called once the PIN has been accepted, so the parent can
                // finish the removal they just authorised.
                "openGuardGrace" -> {
                    dz.lunio.blocking.BlockingStore.openGuardGrace(
                        applicationContext,
                        android.os.SystemClock.uptimeMillis(),
                    )
                    result.success(null)
                }

                "drainConsumedSeconds" ->
                    result.success(blocking.drainConsumedSeconds())

                "setState" -> {
                    blocking.setState(
                        enabled = call.argument<Boolean>("enabled") ?: false,
                        blockedPackages =
                            call.argument<List<String>>("blockedPackages") ?: emptyList(),
                        remainingPlaySeconds =
                            call.argument<Int>("remainingPlaySeconds") ?: 0,
                        playPaused = call.argument<Boolean>("playPaused") ?: false,
                        priceInStars = call.argument<String>("priceInStars") ?: "",
                        uninstallGuard =
                            call.argument<Boolean>("uninstallGuard") ?: false,
                    )
                    result.success(null)
                }

                // Icons are optional because the payload is a few hundred kilobytes
                // on a phone with sixty apps, and only the picker screen needs them.
                "launchableApps" -> result.success(
                    blocking.launchableApps(
                        includeIcons = call.argument<Boolean>("includeIcons") ?: false,
                    ),
                )

                "openUrl" -> result.success(
                    blocking.openUrl(call.argument<String>("url") ?: ""),
                )

                "openAccessibilitySettings" ->
                    result.success(blocking.openAccessibilitySettings())

                "openOverlaySettings" -> result.success(blocking.openOverlaySettings())

                "openBatterySettings" -> result.success(blocking.openBatterySettings())

                "requestBatteryExemption" ->
                    result.success(blocking.requestBatteryExemption())

                "openAutostartSettings" ->
                    result.success(blocking.openAutostartSettings())

                else -> result.notImplemented()
            }
        }

        // The live play-time countdown.
        //
        // An **EventChannel**, not a WebSocket. Nothing about play time involves
        // the server: the balance is Article 5 arithmetic over data that never
        // leaves the phone (Art. 14), so a round trip would add latency, a
        // network dependency and a privacy surface to a number already in
        // memory. And it could not work anyway — while a child is inside a game
        // there is no Flutter engine alive to hold a socket, which is the whole
        // reason the clock lives in Kotlin.
        EventChannel(messenger, PLAY_TICKS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                private val main = Handler(Looper.getMainLooper())

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    blocking.listenToPlayTicks { remaining ->
                        // The clock ticks on its own handler; Flutter's sink must
                        // be touched from the main thread.
                        main.post { events?.success(remaining) }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    blocking.stopListeningToPlayTicks()
                }
            },
        )
    }

    private companion object {
        const val CLOCK_CHANNEL = "dz.lunio/clock"
        const val BLOCKING_CHANNEL = "dz.lunio/blocking"
        const val PLAY_TICKS_CHANNEL = "dz.lunio/play_ticks"
    }
}
