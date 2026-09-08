package dz.lunio.blocking

/**
 * The countdown, offered to whoever is listening.
 *
 * **Why this is not a WebSocket.** A socket to the Django server was the obvious
 * shape to reach for and it is the wrong one twice over. Nothing about play time
 * involves the server — the balance is Article 5 arithmetic on data that never
 * leaves the phone (Art. 14) — so a round trip to Algiers to learn how many
 * seconds are left on this device would add latency, a network dependency and a
 * privacy surface to a number that is already in memory. And it could not work
 * anyway: while the child is inside a game there is no Flutter engine running to
 * hold a socket open, which is the exact reason `PlayClock` lives in Kotlin.
 *
 * This is the in-process equivalent, and it is what an `EventChannel` needs: a
 * single nullable sink, set when Dart subscribes and cleared when it goes away.
 * When nothing is listening — the overwhelmingly common case, because the app is
 * usually not on screen while a game is — emitting costs a null check.
 *
 * Public, unlike the rest of the module's internals, because it is deliberately
 * part of the seam: `LunioBlockingBridge` in the app module attaches Flutter's
 * `EventChannel` sink here. That is the only thing outside this module that may
 * touch it.
 */
object PlayTicks {

    /** Set by the bridge while Dart has a listener, null otherwise. */
    @Volatile
    var sink: ((Int) -> Unit)? = null

    fun emit(remainingSeconds: Int) {
        sink?.invoke(remainingSeconds)
    }
}
