package dz.lunio

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.app.NotificationManager
import dz.lunio.blocking.BlockingState
import dz.lunio.blocking.BlockingStore
import dz.lunio.blocking.PlayTicks
import dz.lunio.blocking.BlockingWatchdogService
import dz.lunio.blocking.LunioAccessibilityService
import java.io.ByteArrayOutputStream

/**
 * The one place Dart talks to the blocking engine.
 *
 * AD-7 says enforcement lives in Kotlin and Dart is a client of it, never a
 * dependency of it, and `native/blocking` holds to that literally: it contains no
 * Flutter type and would still compile with Flutter deleted. This class is the
 * membrane. It is a **writer** into [BlockingStore] and a **reader** of permission
 * state — it is never on the path of a blocking decision, and if this file and the
 * whole Flutter engine vanished at runtime, blocking would carry on unchanged.
 *
 * That is also why it lives in the app module rather than in a `native/bridge`
 * Gradle library, against the layout in docs/CONVENTIONS.md §5. The Flutter embedding
 * artifact is published per engine hash and resolved by the Flutter Gradle plugin;
 * a plain Android library that wanted `MethodChannel` would have to pin that hash
 * by hand and re-pin it on every Flutter upgrade, for no gain. The intent of AD-7
 * is that enforcement never depends on Dart, and that is preserved exactly.
 * Recorded as D-39.
 *
 * Logcat: `adb logcat -s LNO_BRIDGE`
 */
class LunioBlockingBridge(private val context: Context) {

    /**
     * What the parent still has to grant.
     *
     * Every one of these is a Settings screen the user must visit by hand — none
     * can be granted by a runtime dialog, and none can be granted by us. The parent
     * dashboard shows this so that "blocking is on" is never claimed while a
     * prerequisite is missing.
     */
    fun status(): Map<String, Any> = mapOf(
        "accessibilityEnabled" to isAccessibilityEnabled(),
        "overlayGranted" to Settings.canDrawOverlays(context),
        "notificationsGranted" to
            (context.getSystemService(NotificationManager::class.java)
                ?.areNotificationsEnabled() ?: false),
        "autostartScreenAvailable" to (autostartIntent() != null),
        "batteryUnrestricted" to isBatteryUnrestricted(),
        "manufacturer" to Build.MANUFACTURER,
        "sdkInt" to Build.VERSION.SDK_INT,
    )

    /**
     * Reads the system's own list of enabled services rather than a flag of ours.
     *
     * The parent can revoke this in Settings at any moment, and an OEM cleanup can
     * revoke it without telling anyone. A cached "we asked and they said yes" would
     * be stale the first time either happens, and a parental-control app that
     * believes it is guarding when it is not is worse than one that is honestly off.
     */
    private fun isAccessibilityEnabled(): Boolean {
        val expected = ComponentName(
            context.packageName,
            LunioAccessibilityService::class.java.name,
        ).flattenToString()

        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ).orEmpty()

        return enabled.split(':').any { it.equals(expected, ignoreCase = true) }
    }

    /**
     * Mirrors Dart's view of the world into the store the service reads.
     *
     * Article 15.2 lives on the first line: with `enabled` false the watchdog stands
     * down and the notification disappears, because the app must be fully usable —
     * and unobtrusive — with blocking off. That is the state the twelve Play testers
     * will be in for fourteen days.
     */
    fun setState(
        enabled: Boolean,
        blockedPackages: List<String>,
        remainingPlaySeconds: Int,
        playPaused: Boolean,
        priceInStars: String,
        uninstallGuard: Boolean,
    ) {
        // The grace deadline is carried over rather than taken from Dart. It is
        // set by the PIN flow in uptime milliseconds, and Dart pushes state on
        // every settings change — overwriting it here would re-arm the guard in
        // the middle of the uninstall the parent just authorised.
        val carried = BlockingStore.state(context).guardUnlockedUntilMs
        BlockingStore.write(
            context,
            BlockingState(
                enabled = enabled,
                blockedPackages = blockedPackages.toSet(),
                remainingPlaySeconds = remainingPlaySeconds,
                playPaused = playPaused,
                priceInStars = priceInStars,
                uninstallGuard = uninstallGuard,
                guardUnlockedUntilMs = carried,
            ),
        )
        Log.i(
            TAG,
            "state enabled=$enabled blocked=${blockedPackages.size} " +
                "remaining_s=$remainingPlaySeconds paused=$playPaused",
        )
        if (enabled) {
            BlockingStore.refreshCritical(context)
            BlockingWatchdogService.start(context)
        } else {
            BlockingWatchdogService.stop(context)
        }
    }

    /**
     * Start and stop the live countdown stream.
     *
     * The engine already ticks once a second while a game is in front of the
     * child; this simply lets Dart listen when it happens to be on screen —
     * launcher mode, or the instant the child comes back. Nothing is kept alive
     * for it: when no one is listening the sink is null and emitting costs a
     * null check.
     */
    fun listenToPlayTicks(onTick: (Int) -> Unit) {
        PlayTicks.sink = onTick
    }

    fun stopListeningToPlayTicks() {
        PlayTicks.sink = null
    }

    /**
     * Collect the play seconds the engine has counted, and reset its tally.
     *
     * The engine counts down a *copy* of the balance so it can enforce without
     * Dart; the ledger stays Dart's (AD-4, Articles 5 and 6 have exactly one
     * implementation). So the seconds have to come back across, and this is the
     * only way they do.
     *
     * Read-and-clear is atomic on the store side. A read followed by a separate
     * clear would discard whatever the child spent in between — once per drain,
     * silently, in the child's favour.
     */
    fun drainConsumedSeconds(): Int {
        val seconds = BlockingStore.drainConsumedSeconds(context)
        if (seconds > 0) Log.i(TAG, "drained play seconds=" + seconds)
        return seconds
    }

    /**
     * The apps the parent can choose from.
     *
     * Resolved through a `MAIN`/`LAUNCHER` query, which needs only a `<queries>`
     * declaration in the manifest — **not** `QUERY_ALL_PACKAGES`. That permission is
     * one of the most rejection-prone on Play and we would be asking for it to build
     * a list of things the user can already see on their home screen.
     *
     * System apps are dropped unless they were updated by the user, so the list is
     * things a child recognises rather than sixty framework packages. Lunio itself
     * is dropped because it can never be blocked (D-9), and offering it would invite
     * a parent to try.
     */
    fun launchableApps(includeIcons: Boolean): List<Map<String, Any>> {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)

        return pm.queryIntentActivities(intent, 0)
            .mapNotNull { it.activityInfo?.applicationInfo }
            .distinctBy { it.packageName }
            .filter { it.packageName != context.packageName }
            .filter { isUserVisible(it) }
            .map { info ->
                buildMap<String, Any> {
                    put("packageName", info.packageName)
                    put("label", pm.getApplicationLabel(info).toString())
                    if (includeIcons) {
                        iconBytes(pm.getApplicationIcon(info))?.let { put("icon", it) }
                    }
                }
            }
            .sortedBy { it["label"] as String }
    }

    private fun isUserVisible(info: ApplicationInfo): Boolean {
        val system = info.flags and ApplicationInfo.FLAG_SYSTEM != 0
        val updated = info.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP != 0
        return !system || updated
    }

    /** 96 px PNG. A picker without icons is a list of package labels, which is not
     *  something a parent can scan. */
    private fun iconBytes(drawable: Drawable): ByteArray? = runCatching {
        val size = 96
        val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            Bitmap.createScaledBitmap(drawable.bitmap, size, size, true)
        } else {
            Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888).also {
                val canvas = Canvas(it)
                drawable.setBounds(0, 0, size, size)
                drawable.draw(canvas)
            }
        }
        ByteArrayOutputStream().use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            out.toByteArray()
        }
    }.getOrNull()

    // --- the Settings screens we can only point at ---------------------------

    /**
     * Is Lunio exempt from battery optimisation?
     *
     * **The single most load-bearing permission for the play clock**, and it is
     * not obvious why. While a child is inside a game, Lunio is a *background*
     * process — and ColorOS, One UI and MIUI all freeze background processes.
     * A frozen process runs no `Handler` callbacks, so the countdown stops and,
     * far worse, the tick that would notice the balance reaching zero never
     * fires. Reported from the device on 2026-08-29 as «المؤقت يحبس».
     *
     * `PlayDeadline` is the backstop for when this is not granted. This is the
     * fix for the cause.
     */
    private fun isBatteryUnrestricted(): Boolean {
        val power = context.getSystemService(PowerManager::class.java) ?: return false
        return runCatching {
            power.isIgnoringBatteryOptimizations(context.packageName)
        }.getOrDefault(false)
    }

    /**
     * Ask for that exemption.
     *
     * `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` shows a system dialog, which
     * is far better than sending a parent into a settings tree that is different
     * on every OEM skin. Play restricts this to apps whose core function genuinely
     * breaks without it — a parental-control timer that stops counting is exactly
     * that case, and the Play Console declaration will say so in those words.
     *
     * Falls back to the app's battery settings screen if the dialog is refused
     * outright, so the parent is never left with a button that does nothing.
     */
    fun requestBatteryExemption(): Boolean {
        if (isBatteryUnrestricted()) return true
        val asked = open(
            Intent(
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                Uri.parse("package:" + context.packageName),
            ),
        )
        return if (asked) true else openBatterySettings()
    }

    fun openAccessibilitySettings() =
        open(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))

    fun openOverlaySettings() = open(
        Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${context.packageName}"),
        ),
    )

    fun openBatterySettings() = open(
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.parse("package:${context.packageName}")),
    )

    /**
     * The OEM autostart screen, which is where Article 12 scenario 11 is actually
     * won or lost.
     *
     * ColorOS, One UI and MIUI each withhold `BOOT_COMPLETED` from apps the user has
     * not permitted, and none of them reports that it was withheld — the reboot
     * simply produces no log line. There is no public API for this, so what follows
     * is a list of activity names observed on those skins, tried in order.
     *
     * **This is best-effort by construction.** The names are not documented, they
     * change between skin versions, and a wrong one throws rather than returning
     * false. When none resolves, the parent dashboard falls back to text
     * instructions — which is why [status] reports whether a screen was found at all
     * rather than pretending the button always works.
     */
    fun openAutostartSettings(): Boolean {
        val intent = autostartIntent() ?: return false
        return open(intent)
    }

    private fun autostartIntent(): Intent? = AUTOSTART_COMPONENTS
        .map { Intent().setComponent(ComponentName.unflattenFromString(it)!!) }
        .firstOrNull {
            context.packageManager.resolveActivity(it, 0) != null
        }

    /**
     * Open a URL in the parent's browser.
     *
     * Added 2026-08-29 for the payment page, at the client's explicit direction
     * and **against Article 7.2** — see `subscription_screen.dart` for the full
     * record and the risk that was put in writing before it was built.
     *
     * `ACTION_VIEW` into the browser, never a WebView. A payment page rendered
     * inside the app is unambiguously an in-app purchase flow; handing the URL
     * to the system browser at least keeps the transaction visibly outside
     * Lunio, with the address bar and the padlock the parent knows how to read.
     */
    fun openUrl(url: String): Boolean {
        if (url.isBlank()) return false
        return open(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    }

    private fun open(intent: Intent): Boolean = runCatching {
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    }.getOrElse {
        Log.w(TAG, "cannot open ${intent.action ?: intent.component}: ${it.javaClass.simpleName}")
        false
    }

    private companion object {
        const val TAG = "LNO_BRIDGE"

        /**
         * Observed autostart / startup-manager screens, most specific first.
         * ColorOS (Oppo/Realme) leads the list because it is the harshest of the
         * three and the first device this is being tested on runs it.
         */
        val AUTOSTART_COMPONENTS = listOf(
            "com.coloros.safecenter/.permission.startup.StartupAppListActivity",
            "com.coloros.safecenter/.startupapp.StartupAppListActivity",
            "com.oppo.safe/.permission.startup.StartupAppListActivity",
            "com.samsung.android.lool/.battery.ui.BatteryActivity",
            "com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity",
            "com.huawei.systemmanager/.startupmgr.ui.StartupNormalAppListActivity",
            "com.letv.android.letvsafe/.AutobootManageActivity",
            "com.vivo.permissionmanager/.activity.BgStartUpManagerActivity",
        )
    }
}
