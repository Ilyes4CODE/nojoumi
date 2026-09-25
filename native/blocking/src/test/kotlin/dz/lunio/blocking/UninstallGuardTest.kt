package dz.lunio.blocking

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * When the PIN is demanded before the app can be removed, and when it is not.
 *
 * Two failures matter here and they pull in opposite directions. Firing too
 * rarely is the feature not working. Firing too often is a parent who cannot
 * uninstall anything on their own phone without typing a PIN, which is worse —
 * they will turn the whole thing off, and then nothing is protected.
 *
 * The third thing these pin down is the privacy claim: window text is examined
 * **only** for a handful of system packages, and every other window in the
 * system returns before it is looked at. The policy page says exactly that, so
 * a change here that widened the reading would quietly make a published
 * document false.
 */
class UninstallGuardTest {

    private val self = "dz.lunio"
    private val label = "Lunio"

    private fun decide(
        packageName: String = "com.android.settings",
        text: List<String> = listOf("Uninstall Lunio?"),
        enabled: Boolean = true,
        unlockedUntilMs: Long = 0,
        nowMs: Long = 1_000_000,
    ) = UninstallGuard.decide(
        packageName = packageName,
        windowText = text,
        appLabel = label,
        selfPackage = self,
        enabled = enabled,
        unlockedUntilMs = unlockedUntilMs,
        nowMs = nowMs,
    )

    // --- the cases it must catch --------------------------------------------

    @Test
    fun `the uninstall dialog asks for the pin`() {
        val decision = decide(
            packageName = "com.google.android.packageinstaller",
            text = listOf("Do you want to uninstall this app?", "Lunio"),
        )
        assertTrue(decision is UninstallGuard.Decision.AskForPin)
    }

    @Test
    fun `the arabic uninstall dialog asks too`() {
        // The phone's locale is the parent's choice, and a guard that only
        // works in English is off for most of this market.
        val decision = decide(text = listOf("إلغاء التثبيت", "Lunio"))
        assertTrue(decision is UninstallGuard.Decision.AskForPin)
    }

    @Test
    fun `clearing the app data asks too`() {
        // Clearing data is uninstalling by another name: it wipes the stars,
        // the lessons, the PIN and the install id, and mints a fresh device.
        val decision = decide(text = listOf("Clear data", "Lunio", "Storage"))
        assertTrue(decision is UninstallGuard.Decision.AskForPin)
    }

    @Test
    fun `the device admin list asks too`() {
        val decision = decide(text = listOf("Device admin apps", "Lunio", "Deactivate"))
        assertTrue(decision is UninstallGuard.Decision.AskForPin)
    }

    // --- the cases it must not catch ----------------------------------------

    @Test
    fun `uninstalling a different app is none of our business`() {
        // The one that makes a parent disable the feature. They are removing a
        // game, not Lunio, and being asked for a PIN is an insult to their own
        // phone.
        val decision = decide(text = listOf("Do you want to uninstall this app?", "Candy Smash"))
        assertEquals(UninstallGuard.Decision.Ignore, decision)
    }

    @Test
    fun `an ordinary app window is ignored without its text being read`() {
        // The privacy claim in one assertion: a window that is not one of the
        // gatekeeper packages returns before `windowText` is consulted, so the
        // text here is deliberately the most incriminating thing possible.
        val decision = decide(
            packageName = "com.whatsapp",
            text = listOf("uninstall Lunio", "clear data", "Lunio"),
        )
        assertEquals(UninstallGuard.Decision.Ignore, decision)
    }

    @Test
    fun `a settings screen that is not about removal is ignored`() {
        // Opening Lunio's app-info page to check its size or its permissions is
        // not an attack, and treating it as one trains the parent to ignore the
        // prompt.
        val decision = decide(text = listOf("Lunio", "App info", "Notifications", "Battery"))
        assertEquals(UninstallGuard.Decision.Ignore, decision)
    }

    @Test
    fun `our own windows never trigger it`() {
        val decision = decide(packageName = self, text = listOf("uninstall", "Lunio"))
        assertEquals(UninstallGuard.Decision.Ignore, decision)
    }

    @Test
    fun `it is off when the parent has not asked for it`() {
        assertEquals(UninstallGuard.Decision.Ignore, decide(enabled = false))
    }

    // --- the grace window ---------------------------------------------------

    @Test
    fun `after the pin is accepted the parent is left alone`() {
        // Without this the parent who just authorised the uninstall is thrown
        // back to the PIN screen by the very next window of the flow, and can
        // never actually finish.
        val decision = decide(nowMs = 1_000, unlockedUntilMs = 60_000)
        assertEquals(UninstallGuard.Decision.Ignore, decision)
    }

    @Test
    fun `the grace window expires`() {
        val decision = decide(nowMs = 61_000, unlockedUntilMs = 60_000)
        assertTrue(decision is UninstallGuard.Decision.AskForPin)
    }

    @Test
    fun `the grace window is long enough to finish but not to forget`() {
        // Two minutes: enough for a parent to read a confirmation dialog and
        // tap through it, short enough that a phone left on the sofa is not
        // unprotected for the rest of the afternoon.
        assertTrue(UninstallGuard.GRACE_MS in 30_000..5 * 60_000)
    }

    // --- shape --------------------------------------------------------------

    @Test
    fun `the reason names the word that matched`() {
        // So a support call can be answered from the log without guessing which
        // of a dozen phrases fired.
        val decision = decide(text = listOf("Uninstall Lunio?")) as UninstallGuard.Decision.AskForPin
        assertEquals("uninstall", decision.reason)
    }

    @Test
    fun `a blank window is ignored`() {
        assertEquals(UninstallGuard.Decision.Ignore, decide(text = emptyList()))
    }
}
