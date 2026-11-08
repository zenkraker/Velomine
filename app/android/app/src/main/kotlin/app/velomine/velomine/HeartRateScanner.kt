package app.velomine.velomine

import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.ParcelUuid
import android.util.Log
import java.util.UUID

/** A strap seen while scanning. [address] is Android's device address and stays on the phone. */
data class SensorInfo(val address: String, val name: String, val rssi: Int?) {
    fun toMap(): Map<String, Any?> = mapOf(
        "address" to address,
        "name" to name,
        "rssi" to rssi,
    )
}

/**
 * Finds straps that advertise the standard Heart Rate service (0x180D).
 *
 * Scanning is foreground work: the member taps Pair, this runs for a few seconds, then the list is returned. The
 * connection itself belongs to [RecorderService] so it survives the screen being off.
 */
class HeartRateScanner(context: Context) {
    private val adapter = context.getSystemService(BluetoothManager::class.java)?.adapter
    private val found = LinkedHashMap<String, SensorInfo>()
    private var callback: ScanCallback? = null
    private val debug = (context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0

    /** Null when the scan started, otherwise a code the channel reports to Flutter. */
    @SuppressLint("MissingPermission")
    fun start(): String? {
        val adapter = adapter ?: return "unsupported"
        if (!adapter.isEnabled) return "bluetooth_off"
        val scanner = adapter.bluetoothLeScanner ?: return "bluetooth_off"

        stop()
        found.clear()
        val scan = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                val device = result.device ?: return
                val name = runCatching { result.scanRecord?.deviceName ?: device.name }.getOrNull()
                val label = name?.takeIf { it.isNotBlank() }
                    ?: "Heart-rate strap ${device.address.takeLast(5)}"
                val info = SensorInfo(device.address, label, result.rssi)
                if (found.put(info.address, info) == null) {
                    log("found ${info.name} ${info.address} rssi=${info.rssi}")
                }
            }

            override fun onScanFailed(errorCode: Int) {
                log("scan failed: $errorCode")
            }
        }
        callback = scan

        val filter = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid(HEART_RATE_SERVICE))
            .build()
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()
        return try {
            scanner.startScan(listOf(filter), settings, scan)
            log("scanning for heart-rate straps")
            null
        } catch (_: SecurityException) {
            callback = null
            "bluetooth_denied"
        }
    }

    /** Stops the radio and returns what was found, strongest first. */
    @SuppressLint("MissingPermission")
    fun stop(): List<SensorInfo> {
        val scan = callback ?: return emptyList()
        callback = null
        try {
            adapter?.bluetoothLeScanner?.stopScan(scan)
        } catch (_: SecurityException) {
            // The permission was revoked while scanning; there is nothing left to stop.
        }
        return found.values.sortedByDescending { it.rssi ?: Int.MIN_VALUE }
    }

    private fun log(message: String) {
        if (debug) Log.d(TAG, message)
    }

    private companion object {
        const val TAG = "VelomineRecorder"
        val HEART_RATE_SERVICE: UUID = UUID.fromString("0000180d-0000-1000-8000-00805f9b34fb")
    }
}
