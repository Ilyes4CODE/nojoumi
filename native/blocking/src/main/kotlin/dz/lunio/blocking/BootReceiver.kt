package dz.lunio.blocking

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Article 12 scenario 11 — the phone restarts and blocking comes back with no
 * parent action.
 *
 * This is the scenario most likely to fail on an OEM skin, and it fails **silently**:
 * ColorOS's startup manager, One UI's "Sleeping apps" and MIUI's autostart list all
 * withhold `BOOT_COMPLETED` from apps the user has not explicitly permitted, and
 * nothing anywhere reports that it was withheld. Notes V4 records this as a device
 * fact rather than a documentation fact, which is another way of saying the only
 * way to know is to reboot a real phone and look.
 *
 * So this receiver logs on entry, before it does anything. If the log line is absent
 * after a reboot, the receiver never ran and the problem is the OEM, not our code —
 * and the fix is a setup-wizard step that walks the parent to the autostart screen,
 * not a change here.
 *
 * **`ACTION_BOOT_COMPLETED` only, not `LOCKED_BOOT_COMPLETED`.** The locked variant
 * arrives before the user unlocks, when only device-protected storage is readable,
 * and [BlockingStore] lives in ordinary credential-protected preferences. Starting
 * then would read an empty state and conclude blocking was off. Between boot and
 * unlock the child cannot reach a game anyway.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED) return

        val state = BlockingStore.state(context)
        Log.i(TAG, "boot received enabled=" + state.enabled)

        // Article 15.2 again — nothing starts when the parent never opted in.
        if (!state.enabled) return

        // The launcher and the keyboard can have changed while the phone was off,
        // and a stale entry would let something through that should be protected.
        BlockingStore.refreshCritical(context)
        BlockingWatchdogService.start(context)

        // Note what this receiver deliberately does **not** do: it cannot re-enable
        // the accessibility service. That is a user grant held by the system, and it
        // survives reboot on its own or not at all. If tier 1 is down after a
        // restart, no code of ours can bring it back — the app has to notice and
        // tell the parent, which is the status check on the parent dashboard.
    }

    private companion object {
        const val TAG = LunioAccessibilityService.TAG
    }
}
