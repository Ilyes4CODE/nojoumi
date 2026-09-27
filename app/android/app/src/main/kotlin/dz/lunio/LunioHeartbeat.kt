package dz.lunio

import android.content.Context
import android.util.Log
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit

/**
 * "Lunio is still installed on this phone", said to the server every six hours.
 *
 * Client request, 2026-09-27: a parent should learn when the child deletes the
 * app. An app may not *prevent* its own removal — that was built, and Play
 * Protect refused the whole app for it (D-96). What is allowed everywhere is
 * this: the server notices when a phone stops saying it is here, and emails the
 * parent (`alert_silent_devices`).
 *
 * **In the background, whether or not Lunio is opened.** That is the entire
 * design. A signal sent only when the app is open cannot tell "deleted" from
 * "not used this weekend", and a parent woken by a false alarm stops believing
 * the real one.
 *
 * **It sends one thing: the install id.** No account, no token, nothing about
 * the child, nothing about what the phone is doing. The privacy policy says so
 * in those words.
 */
object LunioHeartbeat {
    private const val TAG = "LunioHeartbeat"
    private const val PREFS = "lunio_heartbeat"
    private const val KEY_API = "api_base"
    private const val KEY_INSTALL = "install_id"
    private const val WORK = "lunio-heartbeat"

    /**
     * How often. Six hours against a forty-eight-hour threshold on the server,
     * so eight must be missed in a row before anyone is told. ColorOS and its
     * kin delay background work hard; the margin is for them, not for us.
     */
    private const val EVERY_HOURS = 6L

    /**
     * Remember where to send it and what to send, then make sure it is scheduled.
     *
     * Called from Dart at every start. `KEEP` means an existing schedule is left
     * alone rather than restarted, so opening the app ten times does not push the
     * next ping ten times further away.
     */
    fun configure(context: Context, apiBase: String, installId: String) {
        if (apiBase.isBlank() || installId.isBlank()) return

        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_API, apiBase.trimEnd('/'))
            .putString(KEY_INSTALL, installId)
            .apply()

        val request = PeriodicWorkRequestBuilder<Worker>(EVERY_HOURS, TimeUnit.HOURS)
            .setConstraints(
                Constraints.Builder()
                    // No point waking to fail. WorkManager holds the job until
                    // there is a network, which is exactly the retry we want.
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build(),
            )
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
        Log.i(TAG, "heartbeat scheduled every ${EVERY_HOURS}h")
    }

    class Worker(context: Context, params: WorkerParameters) :
        CoroutineWorker(context, params) {

        override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
            val prefs = applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val api = prefs.getString(KEY_API, null)
            val install = prefs.getString(KEY_INSTALL, null)
            if (api.isNullOrBlank() || install.isNullOrBlank()) {
                // Not configured yet. Success rather than retry: there is nothing
                // to send until Dart has run once, and retrying would burn battery
                // on a question with no answer.
                return@withContext Result.success()
            }

            try {
                val connection = URL("$api/api/devices/heartbeat/").openConnection()
                    as HttpURLConnection
                connection.requestMethod = "POST"
                connection.connectTimeout = 15_000
                connection.readTimeout = 15_000
                connection.doOutput = true
                connection.setRequestProperty("Content-Type", "application/json")
                connection.outputStream.use {
                    it.write(body(install).toByteArray(Charsets.UTF_8))
                }
                val code = connection.responseCode
                connection.disconnect()

                // 2xx is done. A 5xx is the server's bad moment: retry with
                // WorkManager's backoff. Anything else (a 4xx, a throttle) will
                // not improve by retrying, and the next scheduled run is soon.
                when {
                    code in 200..299 -> Result.success()
                    code >= 500 -> Result.retry()
                    else -> Result.success()
                }
            } catch (error: Exception) {
                // No route, DNS, a captive portal. Retry; the next run is at most
                // six hours away anyway.
                Log.w(TAG, "heartbeat failed: ${error.message}")
                Result.retry()
            }
        }
    }

    /**
     * The whole payload. Built by hand rather than with a JSON library for one
     * field, and the id is a UUID — hex digits and hyphens — so there is nothing
     * in it that needs escaping.
     */
    internal fun body(installId: String): String = """{"install_id":"$installId"}"""
}
