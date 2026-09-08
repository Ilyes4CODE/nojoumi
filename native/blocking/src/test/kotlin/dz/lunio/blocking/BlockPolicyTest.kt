package dz.lunio.blocking

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The blocking decision, on the JVM, with no device.
 *
 * Article 12's twelve scenarios cost real time on real hardware, and every one of
 * them mixes two questions: *did the event arrive and did the eviction land*, and
 * *was the decision right*. The second is settled here, for free, on every build.
 * What hardware then has to answer is the first — which is narrower, honest, and
 * the only part an emulator or a JVM genuinely cannot speak to.
 */
class BlockPolicyTest {

    private val self = "dz.lunio"
    private val game = "com.example.game"

    private fun state(
        enabled: Boolean = true,
        blocked: Set<String> = setOf(game),
        seconds: Int = 0,
        paused: Boolean = false,
    ) = BlockingState(
        enabled = enabled,
        blockedPackages = blocked,
        remainingPlaySeconds = seconds,
        playPaused = paused,
    )

    private fun decide(pkg: String, s: BlockingState, critical: Set<String> = emptySet()) =
        BlockPolicy.decide(pkg, s, self, critical)

    // --- Article 15.2 --------------------------------------------------------

    @Test
    fun `blocking off allows everything`() {
        // The state the twelve Play testers are in, and the state the app must be
        // fully usable in.
        assertEquals(BlockDecision.Allow, decide(game, state(enabled = false)))
    }

    // --- Article 4.7 ---------------------------------------------------------

    @Test
    fun `a blocked game with no play time left is blocked`() {
        val decision = decide(game, state(seconds = 0))
        assertTrue(decision is BlockDecision.Block)
        assertEquals(
            BlockReason.NoPlayTimeLeft,
            (decision as BlockDecision.Block).reason,
        )
    }

    @Test
    fun `a blocked game with time remaining is allowed`() {
        assertEquals(BlockDecision.Allow, decide(game, state(seconds = 120)))
    }

    @Test
    fun `one second left is still time`() {
        assertEquals(BlockDecision.Allow, decide(game, state(seconds = 1)))
    }

    @Test
    fun `an app the parent never marked is allowed even at zero`() {
        assertEquals(
            BlockDecision.Allow,
            decide("com.example.calculator", state(seconds = 0)),
        )
    }

    // --- appendix §4 ---------------------------------------------------------

    @Test
    fun `a parent pause blocks even with time in the balance`() {
        val decision = decide(game, state(seconds = 600, paused = true))
        assertTrue(decision is BlockDecision.Block)
        assertEquals(
            BlockReason.ParentPaused,
            (decision as BlockDecision.Block).reason,
            // The card says different things for the two reasons. A child told
            // "play time is over" when their parent paused play learns the app
            // is unreliable, and the balance on screen contradicts the message.
        )
    }

    @Test
    fun `pause outranks an empty balance, so the message is the truthful one`() {
        val decision = decide(game, state(seconds = 0, paused = true))
        assertEquals(
            BlockReason.ParentPaused,
            (decision as BlockDecision.Block).reason,
        )
    }

    // --- D-9, the permanent allowlist ---------------------------------------

    @Test
    fun `Lunio can never block itself`() {
        assertEquals(BlockDecision.Allow, decide(self, state(blocked = setOf(self))))
    }

    @Test
    fun `Settings can never be blocked, whatever the parent's list says`() {
        // A parental-control app that can lock the parent out of Settings has
        // bricked the phone. This is why the check precedes the parent's list.
        for (settings in listOf("com.android.settings", "com.samsung.android.settings")) {
            assertEquals(
                BlockDecision.Allow,
                decide(settings, state(blocked = setOf(settings))),
            )
        }
    }

    @Test
    fun `the dialer and emergency can never be blocked`() {
        for (pkg in listOf(
            "com.android.dialer",
            "com.google.android.dialer",
            "com.android.emergency",
            "com.android.server.telecom",
        )) {
            assertEquals(BlockDecision.Allow, decide(pkg, state(blocked = setOf(pkg))))
        }
    }

    @Test
    fun `the system UI and the package installer can never be blocked`() {
        for (pkg in listOf("com.android.systemui", "com.android.packageinstaller")) {
            assertEquals(BlockDecision.Allow, decide(pkg, state(blocked = setOf(pkg))))
        }
    }

    @Test
    fun `the current launcher and keyboard are protected by the caller`() {
        // These vary per device, so they arrive as a set rather than a constant.
        // Blocking the keyboard leaves a phone on which nothing can be typed —
        // including the parent's PIN.
        val critical = setOf("com.example.launcher", "com.example.keyboard")
        for (pkg in critical) {
            assertEquals(
                BlockDecision.Allow,
                decide(pkg, state(blocked = critical), critical),
            )
        }
    }

    @Test
    fun `isProtected agrees with decide`() {
        assertTrue(BlockPolicy.isProtected("com.android.settings", self, emptySet()))
        assertTrue(BlockPolicy.isProtected(self, self, emptySet()))
        assertTrue(BlockPolicy.isProtected("com.x.ime", self, setOf("com.x.ime")))
        assertFalse(BlockPolicy.isProtected(game, self, emptySet()))
    }

    // --- edges that reach the service in practice ---------------------------

    @Test
    fun `a blank package name is never blocked`() {
        // Accessibility events arrive with a null or empty package more often than
        // one expects — a system dialog, a transient window. Evicting on one would
        // send the child to the home screen for no reason they can see.
        assertEquals(BlockDecision.Allow, decide("", state()))
    }

    @Test
    fun `negative remaining seconds are treated as none`() {
        val decision = decide(game, state(seconds = -5))
        assertTrue(decision is BlockDecision.Block)
    }

    // --- Article 4.7's other half -------------------------------------------

    @Test
    fun `a game already in the foreground is evicted when the balance empties`() {
        // The child was legitimately playing and the counter reached zero while
        // they played. Without this the balance would hit zero and nothing would
        // happen until they switched apps.
        val decision = BlockPolicy.shouldEvictForeground(game, state(seconds = 0), self)
        assertTrue(decision is BlockDecision.Block)
    }

    @Test
    fun `nothing in the foreground is nothing to evict`() {
        assertEquals(
            BlockDecision.Allow,
            BlockPolicy.shouldEvictForeground(null, state(seconds = 0), self),
        )
    }
}

/**
 * Which windows mean the child left the game, and which merely floated over it.
 *
 * **The distinction the play clock lives on.** Reported 2026-08-30: the counter
 * did not work at all. The cause was not the OEM freeze that had been suspected
 * — it was that *every* window from another package stopped the clock, and a
 * child inside a game produces those constantly: the status bar, the volume
 * dialog, a toast, the keyboard. The countdown stopped a second after it
 * started, every time they touched anything.
 */
class TransientWindowTest {

    @Test
    fun `the status bar is not leaving the game`() {
        assertTrue(BlockPolicy.isTransientWindow("com.android.systemui", null))
    }

    @Test
    fun `the keyboard is not leaving the game`() {
        // A keyboard opening over a game is the child typing *in* the game.
        assertTrue(BlockPolicy.isTransientWindow("com.example.ime", "com.example.ime"))
    }

    @Test
    fun `a permission dialog is not leaving the game`() {
        assertTrue(
            BlockPolicy.isTransientWindow("com.android.permissioncontroller", null),
        )
    }

    @Test
    fun `a blank package is not leaving the game`() {
        // Events arrive with no package more often than one expects, and each one
        // would otherwise have stopped the clock.
        assertTrue(BlockPolicy.isTransientWindow("", null))
    }

    @Test
    fun `the launcher IS leaving the game`() {
        // Going to the home screen is a real departure — this is the case the
        // whole rule must not swallow, or play time would keep draining while
        // the child is nowhere near the game.
        assertFalse(BlockPolicy.isTransientWindow("com.example.launcher", null))
    }

    @Test
    fun `another app IS leaving the game`() {
        assertFalse(BlockPolicy.isTransientWindow("com.example.browser", null))
    }

    @Test
    fun `a different keyboard package is not treated as the IME`() {
        assertFalse(BlockPolicy.isTransientWindow("com.other.ime", "com.example.ime"))
    }
}

/**
 * Lunio's own windows are not the child leaving.
 *
 * Measured on the device 2026-08-30: the clock started and stopped 56 ms later,
 * every time, because `PlayTimerOverlay` adds a `TYPE_APPLICATION_OVERLAY` and
 * adding it fires a window-state event carrying *our* package. **The countdown
 * killed the thing that draws it.**
 */
class SelfWindowTest {

    private val self = "dz.lunio"

    @Test
    fun `our own overlay does not end the session`() {
        assertTrue(BlockPolicy.isTransientWindow(self, null, self))
    }

    @Test
    fun `without a self package the old behaviour is unchanged`() {
        // The parameter is optional, so a caller that forgets it fails loudly in
        // the same way it used to rather than silently changing meaning.
        assertFalse(BlockPolicy.isTransientWindow(self, null))
    }

    @Test
    fun `another app still ends the session`() {
        assertFalse(BlockPolicy.isTransientWindow("com.example.browser", null, self))
    }

    @Test
    fun `the launcher still ends the session`() {
        assertFalse(BlockPolicy.isTransientWindow("com.oppo.launcher", null, self))
    }
}

/**
 * The eviction that fires when play time runs out mid-game.
 *
 * Reported 2026-08-30: the balance reached zero while the child was playing and
 * nothing happened — but leaving the game and re-entering blocked it instantly.
 *
 * The cause was a shadowed name. `onPlayTimeExhausted(packageName: String)` took
 * the *game's* package in a parameter called `packageName`, which shadowed
 * `Context.getPackageName()`; `selfPackage = packageName` therefore told the
 * policy that the game **was Lunio**, and D-9's self-protection returned Allow.
 * The re-entry path worked because it runs in `onAccessibilityEvent`, where
 * `packageName` really is ours.
 */
class SelfPackageConfusionTest {

    private val game = "com.block.juggle"
    private val self = "dz.lunio"

    private val exhausted = BlockingState(
        enabled = true,
        blockedPackages = setOf(game),
        remainingPlaySeconds = 0,
    )

    @Test
    fun `a game whose time ran out is blocked`() {
        val decision = BlockPolicy.decide(game, exhausted, self)
        assertTrue(decision is BlockDecision.Block)
    }

    @Test
    fun `passing the game as selfPackage would wrongly allow it`() {
        // The bug, pinned so it cannot return quietly. If someone reintroduces
        // the shadowing, the test above starts failing — this one documents
        // exactly why Allow came back.
        assertEquals(BlockDecision.Allow, BlockPolicy.decide(game, exhausted, game))
    }
}
