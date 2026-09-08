package dz.lunio.blocking

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log

/**
 * The thing that keeps the process alive, so that tier 1 keeps receiving events.
 *
 * An AccessibilityService is bound by the system and survives a great deal on its
 * own. What it does not reliably survive is an OEM battery manager deciding the app
 * is idle — One UI's "Sleeping apps", ColorOS's startup manager, MIUI's autostart.
 * A foreground service with a visible notification is the strongest documented
 * signal an ordinary app can give that it is doing work the user asked for.
 *
 * **Type `specialUse`, deliberately** (notes V4). Since Android 14 a foreground
 * service must declare a type, and `specialUse` is the honest one for parental
 * control. Two consequences were checked before choosing it:
 *
 *  * apps targeting Android 15+ may not start `dataSync`, `camera`, `mediaPlayback`,
 *    `phoneCall`, `mediaProjection` or `microphone` services from a `BOOT_COMPLETED`
 *    receiver — and `specialUse` is **not** on that prohibition list, which is
 *    exactly what Article 12 scenario 11 needs;
 *  * `systemExempted` would technically fit (we are a Device Admin, which is on the
 *    documented eligibility list) but it is reserved for system integrations and
 *    claiming it invites a Play rejection on an app already carrying two
 *    rejection-prone permissions.
 *
 * On Android 10 — the floor this project actually tests on — service types did not
 * yet exist, so the declared type is inert there and the service simply runs. That
 * difference is why the boot path has to be verified on **both** the API 29 device
 * and the Article 13 reference device: they take different branches inside the
 * framework, and passing on one says nothing about the other.
 *
 * Logcat: `adb logcat -s LNO_BLOCKING`
 */
class BlockingWatchdogService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createChannel()
        startForeground(NOTIFICATION_ID, buildNotification())

        val state = BlockingStore.state(this)
        Log.i(
            TAG,
            "watchdog up enabled=" + state.enabled +
                " blocked=" + state.blockedPackages.size +
                " remaining_s=" + state.remainingPlaySeconds +
                " paused=" + state.playPaused,
        )

        // Article 15.2 — with blocking off, the app must be fully usable and must
        // not sit in the notification shade claiming to guard anything. The twelve
        // Play testers are in exactly this state.
        if (!state.enabled) {
            Log.i(TAG, "blocking disabled - watchdog standing down (Art. 15.2)")
            stopSelf()
            return START_NOT_STICKY
        }

        // START_STICKY so that a process kill is followed by a restart with a null
        // intent, which this method handles by reading the store again.
        return START_STICKY
    }

    private fun createChannel() {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                getString(R.string.lunio_watchdog_channel),
                // LOW: no sound, no heads-up. The notification is a requirement of
                // the foreground service, not a message to anybody.
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = getString(R.string.lunio_watchdog_channel_body)
                setShowBadge(false)
            },
        )
    }

    private fun buildNotification(): Notification =
        buildNotification(this, getString(R.string.lunio_watchdog_body))

    override fun onDestroy() {
        Log.w(TAG, "watchdog stopped")
        super.onDestroy()
    }

    companion object {
        private const val TAG = LunioAccessibilityService.TAG
        private const val CHANNEL_ID = "lunio_blocking"
        private const val NOTIFICATION_ID = 4201

        /**
         * Put the remaining play time on the ongoing notification.
         *
         * **The one surface a child can see while they are playing.** Lunio has
         * no screen at that moment and no Flutter engine, so a countdown that
         * lives only inside the app is a countdown nobody sees when it matters.
         * The notification is already required by the platform for a foreground
         * service; carrying the number costs nothing and turns an obligation
         * into the thing that was asked for.
         *
         * `setOnlyAlertOnce` and reusing [NOTIFICATION_ID] make this an update
         * rather than a new notification — no sound, no stacking, once a second.
         */
        fun showRemaining(context: Context, seconds: Int) {
            val manager =
                context.getSystemService(NotificationManager::class.java) ?: return
            val text = if (seconds > 0) {
                context.getString(
                    R.string.lunio_watchdog_playing,
                    seconds / 60,
                    seconds % 60,
                )
            } else {
                context.getString(R.string.lunio_watchdog_body)
            }
            runCatching {
                manager.notify(NOTIFICATION_ID, buildNotification(context, text))
            }.onFailure { Log.w(TAG, "notification update failed") }
        }

        /**
         * The launch intent is resolved through the package manager rather than
         * by naming the app's activity class, so this module stays independent
         * of the app module (AD-7). A null intent is survivable: the
         * notification is simply not tappable.
         */
        internal fun buildNotification(context: Context, text: String): Notification {
            val launch =
                context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pending = launch?.let {
                PendingIntent.getActivity(
                    context,
                    0,
                    it,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                )
            }
            return Notification.Builder(context, CHANNEL_ID)
                .setContentTitle(context.getString(R.string.lunio_watchdog_title))
                .setContentText(text)
                .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
                .setOngoing(true)
                .setShowWhen(false)
                .setOnlyAlertOnce(true)
                .apply { pending?.let(::setContentIntent) }
                .build()
        }

        /**
         * Starts the watchdog, from wherever.
         *
         * `startForegroundService` from Android 8 onward, with the five-second
         * contract to call `startForeground` that [onStartCommand] honours on its
         * first line. Wrapped because a background start can be refused outright —
         * on Android 12+ from the background, and on any version by an OEM that has
         * decided we are asleep. A refusal here is a logged failure of tier 1's
         * liveness, not a crash.
         */
        fun start(context: Context) {
            val intent = Intent(context, BlockingWatchdogService::class.java)
            runCatching {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            }.onFailure {
                Log.e(TAG, "watchdog start refused: " + it.javaClass.simpleName)
            }
        }

        fun stop(context: Context) {
            runCatching {
                context.stopService(Intent(context, BlockingWatchdogService::class.java))
            }
        }
    }
}
