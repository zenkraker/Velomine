package app.velomine.velomine

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.util.Log

/**
 * Records a ride with the phone's GNSS, even while the screen is off.
 *
 * The service owns the raw file and assembles the FIT at stop. The Flutter screen only sends start/pause/resume/stop
 * and reads the live snapshot.
 */
class RecorderService : Service(), LocationListener {
    private lateinit var store: RideStore
    private var active: ActiveRide? = null
    private var state = STATE_IDLE
    private var segmentStartedAt = 0L
    private var accumulatedMovingMs = 0L
    private var lastSampleTime = 0L
    private var lastLocation: Location? = null
    private var locationManager: LocationManager? = null
    private var lastNotificationAt = 0L
    private var autoPauseActive = false
    private var autoPauseEnabled = true
    private val autoPause = AutoPauseDecider()
    private val debug: Boolean
        get() = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    override fun onCreate() {
        super.onCreate()
        log("service created")
        store = RideStore(this)
        createNotificationChannel()
        RecorderRuntime.isRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == ACTION_START) {
            autoPauseEnabled = intent?.getBooleanExtra(EXTRA_AUTO_PAUSE, true) ?: true
        }
        log(
            "onStartCommand action=$action active=${active?.id} state=$state " +
                "autoPause=$autoPauseEnabled",
        )
        if (active == null && action != ACTION_START) {
            log("no active ride for action=$action; stopping")
            RecorderRuntime.isRunning = false
            stopSelf()
            return START_NOT_STICKY
        }
        when (action) {
            ACTION_START -> startRide()
            ACTION_PAUSE -> pauseRide()
            ACTION_RESUME -> resumeRide()
            ACTION_STOP -> stopRide()
            else -> {
                RecorderRuntime.isRunning = false
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        log("service destroying active=${active?.id} state=$state")
        stopLocation()
        val ride = active
        if (ride != null) {
            if (state == STATE_RECORDING || state == STATE_PAUSED) {
                log("service destroyed mid-ride; marking ${ride.id} interrupted")
                store.interrupt(ride)
            } else {
                ride.close()
            }
        }
        active = null
        autoPauseActive = false
        autoPause.reset()
        RecorderRuntime.isRunning = false
        RecorderRuntime.reset()
        RecorderEvents.emit()
        super.onDestroy()
    }

    private fun startRide() {
        if (active != null) {
            log("start ignored: already recording ${active?.id}")
            emit()
            return
        }

        if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            log("start failed: location permission missing")
            fail("permission")
            return
        }
        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        if (!manager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
            log("start failed: GPS provider disabled")
            fail("gps_off")
            return
        }

        val ride = store.create()
        log("start ride ${ride.id} file=${ride.dir.absolutePath} startedAt=${ride.startedAt}")
        active = ride
        state = STATE_RECORDING
        segmentStartedAt = System.currentTimeMillis()
        accumulatedMovingMs = 0L
        lastSampleTime = 0L
        lastLocation = null
        autoPauseActive = false
        autoPause.reset()

        RecorderRuntime.rideId = ride.id
        RecorderRuntime.startedAt = ride.startedAt
        RecorderRuntime.endedAt = null
        RecorderRuntime.distanceM = 0.0
        RecorderRuntime.movingMs = 0L
        RecorderRuntime.speedMs = null
        RecorderRuntime.accuracyM = null
        RecorderRuntime.error = null
        RecorderRuntime.autoPaused = false
        RecorderRuntime.state = STATE_RECORDING

        startForegroundNotification()
        startLocation(manager)
        store.save(ride, STATE_RECORDING, endedAt = null, error = null)
        log("recording started, foreground notification shown")
        emit()
    }

    private fun pauseRide() {
        val ride = active ?: return
        if (state != STATE_RECORDING) return

        log("pause ride ${ride.id}")
        val now = System.currentTimeMillis()
        ride.event("pause", now)
        accumulatedMovingMs += (now - segmentStartedAt).coerceAtLeast(0)
        ride.movingMs = accumulatedMovingMs
        state = STATE_PAUSED
        autoPauseActive = false
        autoPause.reset()
        stopLocation()
        lastLocation = null

        RecorderRuntime.state = STATE_PAUSED
        RecorderRuntime.autoPaused = false
        RecorderRuntime.movingMs = accumulatedMovingMs
        RecorderRuntime.speedMs = null
        store.save(ride, STATE_PAUSED, endedAt = null, error = null)
        updateNotification()
        emit()
    }

    private fun resumeRide() {
        val ride = active ?: return
        if (state != STATE_PAUSED) return

        log("resume ride ${ride.id}")
        val now = System.currentTimeMillis()
        ride.event("resume", now)
        segmentStartedAt = now
        state = STATE_RECORDING
        autoPauseActive = false
        autoPause.reset()
        lastLocation = null

        RecorderRuntime.state = STATE_RECORDING
        RecorderRuntime.autoPaused = false
        RecorderRuntime.error = null
        startLocation(getSystemService(Context.LOCATION_SERVICE) as LocationManager)
        store.save(ride, STATE_RECORDING, endedAt = null, error = null)
        updateNotification()
        emit()
    }

    private fun stopRide() {
        val ride = active ?: return

        log("stop ride ${ride.id} state=$state samplesWritten=${ride.distanceM}")
        val now = System.currentTimeMillis()
        ride.event("stop", now)
        if (state == STATE_RECORDING) {
            accumulatedMovingMs += (now - segmentStartedAt).coerceAtLeast(0)
        }
        ride.movingMs = accumulatedMovingMs
        state = STATE_STOPPED
        autoPauseActive = false
        autoPause.reset()
        stopLocation()
        ride.close()

        // Let finalize accept the ride even though the service is still alive for a moment.
        RecorderRuntime.isRunning = false
        val result = store.finalize(ride.id)
        log("stop finalize ${ride.id} -> ${result["state"]} distance=${result["distanceM"]} moving=${result["movingS"]}")
        RecorderRuntime.endedAt = now
        RecorderRuntime.movingMs = ((result["movingS"] as? Number)?.toDouble() ?: 0.0)
            .times(1000).toLong()
        RecorderRuntime.distanceM = (result["distanceM"] as? Number)?.toDouble() ?: 0.0

        active = null
        RecorderRuntime.isRunning = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        RecorderRuntime.reset()
        RecorderEvents.emit()
        stopSelf()
    }

    private fun autoPauseRide(atMs: Long, speedKmh: Double?) {
        val ride = active ?: return
        val now = System.currentTimeMillis()
        // Use the location's timestamp for the marker, so the sample at the boundary is not counted as paused.
        ride.event("pause", atMs)
        accumulatedMovingMs += (now - segmentStartedAt).coerceAtLeast(0)
        ride.movingMs = accumulatedMovingMs
        state = STATE_PAUSED
        autoPauseActive = true
        lastLocation = null

        RecorderRuntime.state = STATE_PAUSED
        RecorderRuntime.autoPaused = true
        RecorderRuntime.movingMs = accumulatedMovingMs
        RecorderRuntime.speedMs = speedKmh?.div(3.6)
        store.save(ride, STATE_PAUSED, endedAt = null, error = null)
        updateNotification()
        log("auto-paused at ${speedKmh}km/h (location time $atMs)")
        emit()
    }

    private fun autoResume(atMs: Long, speedKmh: Double?) {
        val ride = active ?: return
        val now = System.currentTimeMillis()
        ride.event("resume", atMs)
        segmentStartedAt = now
        state = STATE_RECORDING
        autoPauseActive = false
        autoPause.reset()
        lastLocation = null

        RecorderRuntime.state = STATE_RECORDING
        RecorderRuntime.autoPaused = false
        RecorderRuntime.speedMs = speedKmh?.div(3.6)
        RecorderRuntime.error = null
        store.save(ride, STATE_RECORDING, endedAt = null, error = null)
        updateNotification()
        log("auto-resumed at ${speedKmh}km/h (location time $atMs)")
        emit()
    }

    private fun startLocation(manager: LocationManager) {
        locationManager = manager
        log("requesting GPS updates every ${SAMPLE_INTERVAL_MS}ms")
        try {
            manager.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                SAMPLE_INTERVAL_MS,
                0f,
                this,
                Looper.getMainLooper(),
            )
        } catch (_: SecurityException) {
            log("location permission refused by the system")
            fail("permission")
        } catch (e: Exception) {
            log("could not start location updates: $e")
            fail("location")
        }
    }

    private fun log(message: String) {
        if (debug) Log.d(TAG, message)
    }

    private fun stopLocation() {
        try {
            locationManager?.removeUpdates(this)
        } catch (_: Exception) {
            // Already stopped.
        }
        locationManager = null
    }

    private fun fail(code: String) {
        log("fail code=$code active=${active?.id}")
        autoPauseActive = false
        autoPause.reset()
        active?.let { store.interrupt(it) }
        active = null
        state = STATE_IDLE
        stopLocation()
        RecorderRuntime.isRunning = false
        RecorderRuntime.reset()
        RecorderRuntime.error = code
        stopForeground(STOP_FOREGROUND_REMOVE)
        RecorderEvents.emit()
        stopSelf()
    }

    override fun onLocationChanged(location: Location) {
        val speedKmh = if (location.hasSpeed()) location.speed * 3.6 else null
        val monotonicNow = SystemClock.elapsedRealtime()

        if (state == STATE_PAUSED) {
            if (!autoPauseActive) return
            when (autoPause.update(speedKmh, monotonicNow, autoPaused = true)) {
                AutoPauseAction.Resume -> autoResume(location.time, speedKmh)
                else -> return
            }
        }

        if (state != STATE_RECORDING) return

        if (!autoPauseEnabled) {
            autoPause.reset()
        } else {
            when (autoPause.update(speedKmh, monotonicNow, autoPaused = false)) {
                AutoPauseAction.Pause -> {
                    autoPauseRide(location.time, speedKmh)
                    return
                }
                else -> Unit
            }
        }

        val ride = active ?: return
        if (location.time <= lastSampleTime) return
        lastSampleTime = location.time

        val sample = RawSample(
            timeMs = location.time,
            latitude = location.latitude,
            longitude = location.longitude,
            altitude = if (location.hasAltitude()) location.altitude else null,
            speed = if (location.hasSpeed()) location.speed.toDouble() else null,
            accuracy = if (location.hasAccuracy()) location.accuracy.toDouble() else null,
        )
        ride.sample(sample)
        log(
            "sample time=${sample.timeMs} lat=${sample.latitude} lon=${sample.longitude} " +
                "speed=${sample.speed} accuracy=${sample.accuracy} speedKmh=$speedKmh",
        )

        val previous = lastLocation
        if (previous != null && location.time - previous.time in 1..MAX_DISTANCE_GAP_MS) {
            val accurateEnough = !location.hasAccuracy() || location.accuracy <= MAX_DISTANCE_ACCURACY_M
            if (accurateEnough) {
                ride.distanceM += haversine(
                    previous.latitude,
                    previous.longitude,
                    location.latitude,
                    location.longitude,
                )
            }
        }
        lastLocation = location

        val now = System.currentTimeMillis()
        RecorderRuntime.distanceM = ride.distanceM
        RecorderRuntime.movingMs = accumulatedMovingMs + (now - segmentStartedAt).coerceAtLeast(0)
        RecorderRuntime.speedMs = if (location.hasSpeed()) location.speed.toDouble() else null
        RecorderRuntime.accuracyM = if (location.hasAccuracy()) location.accuracy.toDouble() else null
        RecorderRuntime.error = null

        if (now - lastNotificationAt >= NOTIFICATION_UPDATE_MS) {
            lastNotificationAt = now
            store.save(ride, STATE_RECORDING, endedAt = null, error = null)
            updateNotification()
        }
        emit()
    }

    override fun onProviderEnabled(provider: String) {
        RecorderRuntime.error = null
        emit()
    }

    override fun onProviderDisabled(provider: String) {
        if (provider == LocationManager.GPS_PROVIDER) {
            RecorderRuntime.error = "gps_off"
            emit()
        }
    }

    @Deprecated("Deprecated by Android, still part of the listener.")
    override fun onStatusChanged(provider: String?, status: Int, extras: android.os.Bundle?) = Unit

    private fun emit() = RecorderEvents.emit()

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Ride recording",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shows while the phone is recording a ride."
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun startForegroundNotification() {
        val notification = notification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        lastNotificationAt = System.currentTimeMillis()
    }

    private fun updateNotification() {
        if (active == null) return
        getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID, notification())
    }

    private fun notification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }

        val recording = state == STATE_RECORDING
        val distance = RecorderRuntime.distanceM
        builder
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentTitle("Velomine")
            .setContentText(
                if (recording) {
                    "Recording · ${if (distance >= 1000) "%.1f km".format(distance / 1000) else "${distance.toInt()} m"}"
                } else if (RecorderRuntime.autoPaused) {
                    "Auto-paused"
                } else {
                    "Paused"
                },
            )
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(recording)

        if (recording) {
            builder.setUsesChronometer(true).setWhen(RecorderRuntime.startedAt ?: System.currentTimeMillis())
        } else {
            builder.setUsesChronometer(false)
        }

        val pause = PendingIntent.getService(
            this,
            1,
            Intent(this, RecorderService::class.java)
                .setAction(if (recording) ACTION_PAUSE else ACTION_RESUME),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val stop = PendingIntent.getService(
            this,
            2,
            Intent(this, RecorderService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        builder.addAction(
            Notification.Action.Builder(
                if (recording) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
                if (recording) "Pause" else "Resume",
                pause,
            ).build(),
        )
        builder.addAction(
            Notification.Action.Builder(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stop).build(),
        )

        val launch = packageManager.getLaunchIntentForPackage(packageName)
        if (launch != null) {
            builder.setContentIntent(
                PendingIntent.getActivity(
                    this,
                    0,
                    launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
        }
        return builder.build()
    }

    private fun haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val earthRadiusM = 6_371_000.0
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val a = kotlin.math.sin(dLat / 2) * kotlin.math.sin(dLat / 2) +
            kotlin.math.cos(Math.toRadians(lat1)) * kotlin.math.cos(Math.toRadians(lat2)) *
            kotlin.math.sin(dLon / 2) * kotlin.math.sin(dLon / 2)
        return 2 * earthRadiusM * kotlin.math.asin(kotlin.math.sqrt(a))
    }

    companion object {
        private const val TAG = "VelomineRecorder"

        const val ACTION_START = "app.velomine.velomine.recorder.START"
        const val ACTION_PAUSE = "app.velomine.velomine.recorder.PAUSE"
        const val ACTION_RESUME = "app.velomine.velomine.recorder.RESUME"
        const val ACTION_STOP = "app.velomine.velomine.recorder.STOP"

        const val EXTRA_AUTO_PAUSE = "autoPause"

        private const val CHANNEL_ID = "velomine_recording"
        private const val NOTIFICATION_ID = 41
        private const val SAMPLE_INTERVAL_MS = 1_000L
        private const val MAX_DISTANCE_GAP_MS = 30_000L
        private const val MAX_DISTANCE_ACCURACY_M = 70f
        private const val NOTIFICATION_UPDATE_MS = 5_000L

        private const val STATE_IDLE = "idle"
        private const val STATE_RECORDING = "recording"
        private const val STATE_PAUSED = "paused"
        private const val STATE_STOPPED = "stopped"
    }
}
