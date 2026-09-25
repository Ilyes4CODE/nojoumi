package dz.lunio.blocking

/**
 * Should this window be interrupted and the parent's PIN asked for?
 *
 * **What Android actually allows.** An ordinary app cannot prevent its own
 * removal. There is no permission for it and no API for it; `DeviceAdmin` can
 * hide the uninstall button, but Play restricts it sharply outside enterprise
 * use and pairing it with an accessibility service is a documented cause of
 * rejection — which is the risk Article 7.2's whole structure exists to avoid.
 * So this is deliberately the weaker mechanism the client chose on 2026-09-25:
 * notice the screen, and ask for the PIN.
 *
 * It stops a child who taps *uninstall*. It does not stop a determined
 * teenager who boots into safe mode, where accessibility services do not run.
 * **That difference must be described to the client in those words** — a
 * parental control sold as unremovable and then removed is worse than one that
 * never claimed it.
 *
 * ## Why it reads a little screen text, and how little
 *
 * The system's uninstall dialog and the device-admin list are *Settings*
 * windows. Their package name is the same whichever app they are about, so the
 * only way to know that this one concerns Lunio is to look at the words on it.
 *
 * That is the one place this project reads screen content, and the privacy
 * policy says so in those terms. It is scoped as narrowly as the mechanism
 * allows: only on windows belonging to the installer or settings packages,
 * only comparing against the app's own name, never stored, never transmitted,
 * and every other window in the system short-circuits on the first check below
 * without its text being looked at at all.
 *
 * All of this is a pure function over values so it can be tested without a
 * device, which is the same reason [BlockPolicy] is shaped this way.
 */
object UninstallGuard {

    /** Packages whose windows can be an uninstall prompt or the admin list. */
    private val GATEKEEPER_PACKAGES = setOf(
        "com.android.packageinstaller",
        "com.google.android.packageinstaller",
        "com.android.settings",
        // Samsung, which routes both through its own Settings implementation.
        "com.samsung.android.packageinstaller",
        "com.sec.android.app.launcher",
    )

    /**
     * Words that mark a window as being about removing or disabling something.
     *
     * Both languages, because the phone's locale is the parent's choice and a
     * guard that only works in Arabic is a guard that is off for half the
     * market. Matched case-insensitively against the window's text.
     */
    private val REMOVAL_WORDS = listOf(
        "uninstall", "إلغاء التثبيت", "إزالة التثبيت", "حذف التطبيق",
        "désinstaller", "device admin", "مشرف الجهاز", "مشرفو الجهاز",
        "deactivate", "إلغاء تنشيط", "force stop", "فرض الإيقاف",
        "clear data", "مسح البيانات", "clear storage", "مسح التخزين",
    )

    /**
     * Could a window from this package ever be an uninstall prompt?
     *
     * Exposed so the service can answer it **before** reading any screen text.
     * `decide` checks it too, so the guarantee does not depend on a caller
     * remembering — but the caller that forgets would still have read the tree,
     * which is the thing the privacy policy promises does not happen.
     */
    fun handles(packageName: String): Boolean =
        packageName in GATEKEEPER_PACKAGES

    sealed interface Decision {
        /** Nothing to do. The overwhelmingly common answer. */
        data object Ignore : Decision

        /** Interrupt and ask for the PIN. */
        data class AskForPin(val reason: String) : Decision
    }

    /**
     * @param packageName the window's own package.
     * @param windowText every string the window is showing, already flattened.
     *   Only read when [packageName] is a gatekeeper — see the class note.
     * @param appLabel this app's display name, to recognise a window about us.
     * @param selfPackage this app's package name.
     * @param enabled the parent's setting; off means this never fires.
     * @param unlockedUntilMs a grace deadline set when the PIN was accepted,
     *   compared against [nowMs]. Without it the parent cannot finish the
     *   uninstall they just authorised — they would be thrown back to the PIN
     *   screen on every window the flow opens, for ever.
     */
    fun decide(
        packageName: String,
        windowText: List<String>,
        appLabel: String,
        selfPackage: String,
        enabled: Boolean,
        unlockedUntilMs: Long,
        nowMs: Long,
    ): Decision {
        if (!enabled) return Decision.Ignore
        if (nowMs < unlockedUntilMs) return Decision.Ignore

        // The short circuit that keeps this off the hot path and keeps the
        // privacy claim true: for every window that is not one of a handful of
        // system packages, the text is never examined.
        if (packageName !in GATEKEEPER_PACKAGES) return Decision.Ignore

        // Our own windows are not a threat, and asking for the PIN on top of
        // Lunio's own settings screen would be a loop.
        if (packageName == selfPackage) return Decision.Ignore

        val haystack = windowText.joinToString(" ") { it.lowercase() }
        if (haystack.isBlank()) return Decision.Ignore

        val mentionsUs =
            haystack.contains(appLabel.lowercase()) ||
                haystack.contains(selfPackage.lowercase())
        if (!mentionsUs) return Decision.Ignore

        val word = REMOVAL_WORDS.firstOrNull { haystack.contains(it.lowercase()) }
            ?: return Decision.Ignore

        return Decision.AskForPin(reason = word)
    }

    /** How long the parent gets to finish, once the PIN is accepted. */
    const val GRACE_MS: Long = 2 * 60 * 1000

    /** Intent extra naming why the PIN is being asked for. */
    const val EXTRA_REQUIRE_PIN = "dz.lunio.REQUIRE_PIN"
}
