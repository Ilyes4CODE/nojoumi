package dz.nojoumi

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter host.
 *
 * AD-7 puts enforcement logic in independent Gradle modules under `native/`,
 * with `native/bridge` owning the channels, precisely because blocking must keep
 * working while the Flutter engine is dead. The clock channel is the one piece
 * that is genuinely the opposite: it exists only to answer the Dart layer, has
 * no lifecycle of its own, and nothing enforces anything through it. It lives
 * here until `native/bridge` is scaffolded, and it moves there with the rest.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val clock = NojoumiClock(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CLOCK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "read" -> result.success(clock.read())
                    else -> result.notImplemented()
                }
            }
    }

    private companion object {
        const val CLOCK_CHANNEL = "dz.nojoumi/clock"
    }
}
