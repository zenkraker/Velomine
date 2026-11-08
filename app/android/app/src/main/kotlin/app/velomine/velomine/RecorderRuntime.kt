package app.velomine.velomine

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/** What the recording screen reads: the live state of the foreground service, or idle. */
object RecorderRuntime {
    @Volatile
    var isRunning: Boolean = false

    @Volatile
    var state: String = "idle"

    @Volatile
    var rideId: String? = null

    @Volatile
    var startedAt: Long? = null

    @Volatile
    var endedAt: Long? = null

    @Volatile
    var distanceM: Double = 0.0

    @Volatile
    var movingMs: Long = 0L

    @Volatile
    var speedMs: Double? = null

    @Volatile
    var accuracyM: Double? = null

    @Volatile
    var error: String? = null

    /// The pause is automatic because the speed stayed at zero.
    @Volatile
    var autoPaused: Boolean = false

    /// The strap this phone remembers, if any. The connection itself is owned by the recorder service.
    @Volatile
    var sensorName: String? = null

    /// "none", "paired" (remembered, not connected), "connecting", "connected", "off" (Bluetooth disabled) or "denied".
    @Volatile
    var sensorStatus: String = "none"

    @Volatile
    var heartRateBpm: Int? = null

    fun snapshot(): Map<String, Any?> {
        val start = startedAt
        val elapsed = if (start == null) {
            0.0
        } else {
            ((endedAt ?: System.currentTimeMillis()) - start).coerceAtLeast(0) / 1000.0
        }
        return mapOf(
            "state" to state,
            "rideId" to rideId,
            "startedAt" to start,
            "elapsedS" to elapsed,
            "movingS" to movingMs / 1000.0,
            "distanceM" to distanceM,
            "speedMs" to speedMs,
            "accuracyM" to accuracyM,
            "error" to error,
            "autoPaused" to autoPaused,
            "sensorName" to sensorName,
            "sensorStatus" to sensorStatus,
            "heartRateBpm" to heartRateBpm,
        )
    }

    fun reset() {
        state = "idle"
        rideId = null
        startedAt = null
        endedAt = null
        distanceM = 0.0
        movingMs = 0L
        speedMs = null
        accuracyM = null
        error = null
        autoPaused = false
        heartRateBpm = null
        sensorStatus = if (sensorName == null) "none" else "paired"
    }
}

/** One event stream for the recording screen. The service calls [emit] after every sample and state change. */
object RecorderEvents {
    private val main = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null

    fun attach(newSink: EventChannel.EventSink) {
        sink = newSink
    }

    fun detach() {
        sink = null
    }

    fun emit() {
        main.post {
            sink?.success(RecorderRuntime.snapshot())
        }
    }
}
