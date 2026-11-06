package app.velomine.velomine

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var permissionResult: MethodChannel.Result? = null
    private val debug: Boolean
        get() = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerSecureStorage(flutterEngine)
        registerRecorder(flutterEngine)
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
                    val autoPause = (call.arguments as? Map<*, *>)?.get("autoPause") as? Boolean ?: true
                    startRecorderService(
                        RecorderService.ACTION_START,
                        foreground = true,
                        autoPause = autoPause,
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
                "listRides" -> inBackground(result) { store.list() }
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
    ) {
        log("starting recorder service action=$action foreground=$foreground autoPause=$autoPause")
        val intent = Intent(this, RecorderService::class.java)
            .setAction(action)
            .putExtra(RecorderService.EXTRA_AUTO_PAUSE, autoPause)
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

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
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
    }
}
