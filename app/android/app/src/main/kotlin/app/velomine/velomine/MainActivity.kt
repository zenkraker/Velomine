package app.velomine.velomine

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var permissionResult: MethodChannel.Result? = null
    private var sensorPermissionResult: MethodChannel.Result? = null
    private var sensorScanResult: MethodChannel.Result? = null
    private var sensorScanner: HeartRateScanner? = null
    private val sensorScanHandler = Handler(Looper.getMainLooper())
    private val sensorStore by lazy { SensorStore(applicationContext) }
    private var incomingChannel: MethodChannel? = null
    private val debug: Boolean
        get() = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sensorStore.read()?.let {
            if (!RecorderRuntime.isRunning) {
                RecorderRuntime.sensorName = it.name
                RecorderRuntime.sensorStatus = "paired"
            }
        }
        registerSecureStorage(flutterEngine)
        registerRecorder(flutterEngine)
        registerIncomingFiles(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // A recreated activity (rotation) still holds the intent it was started with; it was handled the first time.
        if (savedInstanceState == null) receiveFiles(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        receiveFiles(intent)
    }

    /** What other apps send: Share, and Open with. The app asks for the result with `take`. */
    private fun registerIncomingFiles(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "velomine/incoming")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "take" -> result.success(IncomingFiles.take())
                else -> result.notImplemented()
            }
        }
        incomingChannel = channel
    }

    /** Copies the files of a Share or Open with into the app's storage, then tells the app they arrived. */
    private fun receiveFiles(intent: Intent?) {
        if (!IncomingIntent.isIncoming(intent)) return
        val uris = IncomingIntent.uris(intent)
        // Handled once: the same intent comes back after a restart of the activity.
        intent?.action = Intent.ACTION_MAIN
        // A share of text carries no file; there is nothing to say.
        if (uris.isEmpty()) return
        val importer = RideImporter(applicationContext.contentResolver, RideStore(applicationContext))
        Thread {
            val outcome = try {
                importer.import(uris)
            } catch (e: Exception) {
                log("receiving files failed: $e")
                ImportOutcome(0, 0, emptyList())
            }
            IncomingFiles.record(outcome)
            log("received files: added=${outcome.added} alreadyHere=${outcome.alreadyHere} rejected=${outcome.rejected.size}")
            runOnUiThread { incomingChannel?.invokeMethod("arrived", null) }
        }.start()
    }

    private fun registerSecureStorage(flutterEngine: FlutterEngine) {
        val store = SecureTokenStore(applicationContext)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "velomine/secure_storage",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "readRefreshToken" -> result.success(store.read())
                "writeRefreshToken" -> {
                    val token = call.arguments as? String
                    if (token == null) {
                        result.error("bad_argument", "No token was sent.", null)
                    } else {
                        result.success(store.write(token))
                    }
                }
                "clear" -> {
                    store.clear()
                    result.success(null)
                }
                // The app refreshes the same single-use token the upload worker does; one waits for the other.
                // One non-blocking attempt per call: the app retries, so the main thread never sleeps.
                "lockRefresh" -> result.success(store.tryLock())
                "unlockRefresh" -> {
                    store.unlock()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun registerRecorder(flutterEngine: FlutterEngine) {
        val store = RideStore(applicationContext)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "velomine/recorder",
        ).setMethodCallHandler { call, result ->
            log("recorder call ${call.method} args=${call.arguments}")
            when (call.method) {
                "requestPermissions" -> requestRecorderPermissions(result)
                "start" -> {
                    val problem = recorderStartProblem()
                    if (problem != null) {
                        log("start refused: $problem")
                        result.error(problem, "The recorder cannot start.", null)
                        return@setMethodCallHandler
                    }
                    val args = call.arguments as? Map<*, *>
                    val autoPause = args?.get("autoPause") as? Boolean ?: true
                    val rideType = args?.get("rideType") as? String ?: "road"
                    val ebike = args?.get("ebike") as? Boolean ?: false
                    val accountId = args?.get("accountId") as? String
                    startRecorderService(
                        RecorderService.ACTION_START,
                        foreground = true,
                        autoPause = autoPause,
                        rideType = rideType,
                        ebike = ebike,
                        accountId = accountId,
                    )
                    result.success(true)
                }
                "pause" -> {
                    startRecorderService(RecorderService.ACTION_PAUSE, foreground = false)
                    result.success(null)
                }
                "resume" -> {
                    startRecorderService(RecorderService.ACTION_RESUME, foreground = false)
                    result.success(null)
                }
                "stop" -> {
                    startRecorderService(RecorderService.ACTION_STOP, foreground = false)
                    result.success(null)
                }
                "getState" -> result.success(RecorderRuntime.snapshot())
                "listRides" -> inBackground(result) {
                    store.list(claimFor = call.arguments as? String)
                }
                "readFit" -> {
                    val id = call.arguments as? String
                    if (id == null) {
                        result.error("bad_argument", "No ride was sent.", null)
                    } else {
                        inBackground(result) { store.readFit(id) }
                    }
                }
                "finalizeRide" -> {
                    val id = call.arguments as? String
                    if (id == null) {
                        result.error("bad_argument", "No ride was sent.", null)
                    } else {
                        inBackground(result) { store.finalize(id) }
                    }
                }
                "deleteRide" -> {
                    val id = call.arguments as? String
                    if (id == null) {
                        result.error("bad_argument", "No ride was sent.", null)
                    } else {
                        inBackground(result) { store.delete(id) }
                    }
                }
                "markUploadState" -> {
                    val args = call.arguments as? Map<*, *>
                    val id = args?.get("id") as? String
                    val state = args?.get("state") as? String
                    if (id == null || state == null) {
                        result.error("bad_argument", "No ride or state was sent.", null)
                    } else {
                        store.markUpload(
                            id,
                            state,
                            serverRideId = args["serverRideId"] as? String,
                            error = args["error"] as? String,
                            attempts = (args["attempts"] as? Number)?.toInt(),
                        )
                        result.success(null)
                    }
                }
                "scheduleUpload" -> {
                    val serverUrl = call.arguments as? String
                    if (serverUrl.isNullOrBlank()) {
                        result.success(null)
                    } else {
                        RideUploadScheduler.schedule(applicationContext, serverUrl)
                        result.success(null)
                    }
                }
                "requestSensorPermissions" -> requestSensorPermissions(result)
                "scanSensors" -> scanSensors(result)
                "pairSensor" -> pairSensor(call.arguments, result)
                "forgetSensor" -> forgetSensor(result)
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "velomine/recorder/events",
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    RecorderEvents.attach(events)
                    events.success(RecorderRuntime.snapshot())
                }

                override fun onCancel(arguments: Any?) {
                    RecorderEvents.detach()
                }
            },
        )
    }

    private fun requestSensorPermissions(result: MethodChannel.Result) {
        if (hasSensorPermissions()) {
            result.success(true)
            return
        }
        if (sensorPermissionResult != null) {
            result.error("busy", "A permission request is already open.", null)
            return
        }
        sensorPermissionResult = result
        requestPermissions(
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
            ),
            SENSOR_PERMISSION_REQUEST,
        )
    }

    private fun hasSensorPermissions(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            (
                checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) ==
                    PackageManager.PERMISSION_GRANTED &&
                    checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
                    PackageManager.PERMISSION_GRANTED
            )

    private fun scanSensors(result: MethodChannel.Result) {
        if (!hasSensorPermissions()) {
            result.error(
                "bluetooth_denied",
                "Allow nearby devices to find a heart-rate strap.",
                null,
            )
            return
        }
        if (sensorScanResult != null) {
            result.error("busy", "A scan is already running.", null)
            return
        }
        val scanner = HeartRateScanner(this)
        val problem = scanner.start()
        if (problem != null) {
            result.error(problem, sensorErrorText(problem), null)
            return
        }
        sensorScanner = scanner
        sensorScanResult = result
        sensorScanHandler.postDelayed({
            val found = scanner.stop().map { it.toMap() }
            sensorScanner = null
            val answer = sensorScanResult
            sensorScanResult = null
            log("sensor scan found ${found.size} strap(s)")
            answer?.success(found)
        }, SENSOR_SCAN_MS)
    }

    private fun pairSensor(arguments: Any?, result: MethodChannel.Result) {
        val args = arguments as? Map<*, *>
        val address = (args?.get("address") as? String)?.takeIf { it.isNotBlank() }
        val name = (args?.get("name") as? String)?.takeIf { it.isNotBlank() } ?: address
        if (address == null) {
            result.error("bad_argument", "No strap was sent.", null)
            return
        }
        sensorStore.save(PairedSensor(address, name ?: address))
        RecorderRuntime.sensorName = name ?: address
        RecorderRuntime.sensorStatus = "paired"
        RecorderRuntime.heartRateBpm = null
        RecorderEvents.emit()
        log("paired strap ${name ?: address} at $address")
        result.success(null)
    }

    private fun forgetSensor(result: MethodChannel.Result) {
        sensorStore.clear()
        RecorderRuntime.sensorName = null
        RecorderRuntime.sensorStatus = "none"
        RecorderRuntime.heartRateBpm = null
        RecorderEvents.emit()
        log("forgot the paired strap")
        result.success(null)
    }

    private fun sensorErrorText(code: String): String = when (code) {
        "bluetooth_off" -> "Turn on Bluetooth to find a heart-rate strap."
        "bluetooth_denied" -> "Allow nearby devices to find a heart-rate strap."
        "unsupported" -> "This phone has no Bluetooth LE."
        else -> "Could not search for a heart-rate strap."
    }

    private fun recorderStartProblem(): String? {
        if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return "permission"
        }
        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        if (!manager.isProviderEnabled(LocationManager.GPS_PROVIDER)) return "gps_off"
        return null
    }

    private fun startRecorderService(
        action: String,
        foreground: Boolean,
        autoPause: Boolean = true,
        rideType: String = "road",
        ebike: Boolean = false,
        accountId: String? = null,
    ) {
        log(
            "starting recorder service action=$action foreground=$foreground " +
                "autoPause=$autoPause rideType=$rideType ebike=$ebike account=$accountId",
        )
        val intent = Intent(this, RecorderService::class.java)
            .setAction(action)
            .putExtra(RecorderService.EXTRA_AUTO_PAUSE, autoPause)
            .putExtra(RecorderService.EXTRA_RIDE_TYPE, rideType)
            .putExtra(RecorderService.EXTRA_EBIKE, ebike)
        if (accountId != null) intent.putExtra(RecorderService.EXTRA_ACCOUNT_ID, accountId)
        if (foreground && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun requestRecorderPermissions(result: MethodChannel.Result) {
        val missing = buildList {
            if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                add(Manifest.permission.ACCESS_FINE_LOCATION)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }

        if (missing.isEmpty()) {
            result.success(true)
            return
        }
        if (permissionResult != null) {
            result.error("busy", "A permission request is already open.", null)
            return
        }

        permissionResult = result
        requestPermissions(missing.toTypedArray(), PERMISSION_REQUEST)
    }

    override fun onDestroy() {
        sensorScanner?.stop()
        sensorScanner = null
        sensorScanResult = null
        sensorPermissionResult = null
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SENSOR_PERMISSION_REQUEST) {
            val granted = hasSensorPermissions()
            log("sensor permission result granted=$granted")
            sensorPermissionResult?.success(granted)
            sensorPermissionResult = null
            return
        }
        if (requestCode != PERMISSION_REQUEST) return

        val locationGranted = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
        log("permission result locationGranted=$locationGranted")
        permissionResult?.success(locationGranted)
        permissionResult = null
    }

    /** File work can take a moment; the method channel answer goes back on the main thread. */
    private fun <T> inBackground(result: MethodChannel.Result, action: () -> T) {
        Thread {
            val value = try {
                action()
            } catch (e: Exception) {
                log("background action failed: $e")
                null
            }
            log("background result: $value")
            runOnUiThread { result.success(value) }
        }.start()
    }

    private fun log(message: String) {
        if (debug) Log.d(TAG, message)
    }

    private companion object {
        const val TAG = "VelomineRecorder"
        const val PERMISSION_REQUEST = 73
        const val SENSOR_PERMISSION_REQUEST = 74
        const val SENSOR_SCAN_MS = 8_000L
    }
}
