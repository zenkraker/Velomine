package app.velomine.velomine

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.UUID

/**
 * Keeps one heart-rate strap connected while a ride is being recorded.
 *
 * The connection belongs to the recorder foreground service, not to the Flutter screen: the service starts it when a
 * ride starts and closes it when the ride stops. `autoConnect` makes Android reconnect whenever the strap is back in
 * range, which is what the member expects after pairing once.
 */
class HeartRateSensor(context: Context, private val listener: Listener) {
    interface Listener {
        /** One of "connecting", "connected", "off", "denied", "none". */
        fun onSensorStatus(status: String)
        fun onHeartRate(bpm: Int)
    }

    private val appContext = context.applicationContext
    private val adapter = appContext.getSystemService(BluetoothManager::class.java)?.adapter
    private val main = Handler(Looper.getMainLooper())
    private val debug = (context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0

    private var gatt: BluetoothGatt? = null
    private var address: String? = null
    private var name: String? = null
    private var shouldRun = false
    private var reconnectAttempt = 0
    private var reconnect: Runnable? = null

    @Volatile
    var connected: Boolean = false
        private set

    fun connect(address: String, name: String?) {
        this.address = address
        this.name = name
        shouldRun = true
        open()
    }

    /** Closes the GATT client and cancels any pending reconnect. Safe to call more than once. */
    fun close() {
        shouldRun = false
        reconnect?.let(main::removeCallbacks)
        reconnect = null
        connected = false
        gatt?.let(::release)
        gatt = null
        listener.onSensorStatus("none")
    }

    @SuppressLint("MissingPermission")
    private fun open() {
        if (!shouldRun || connected) return
        val target = address ?: return
        val adapter = adapter
        if (adapter == null) {
            log("this phone has no Bluetooth adapter")
            listener.onSensorStatus("off")
            shouldRun = false
            return
        }

        // A previous autoConnect may still be pending; close it before opening a fresh client.
        gatt?.let(::release)
        gatt = null

        val device = try {
            adapter.getRemoteDevice(target)
        } catch (_: IllegalArgumentException) {
            log("saved strap address is no longer valid: $target")
            null
        }
        if (device == null) {
            listener.onSensorStatus("off")
            shouldRun = false
            return
        }
        if (!adapter.isEnabled) {
            log("Bluetooth is off; the strap connects when it comes back")
            listener.onSensorStatus("off")
            scheduleReconnect()
            return
        }

        listener.onSensorStatus("connecting")
        gatt = try {
            device.connectGatt(appContext, true, callback, BluetoothDevice.TRANSPORT_LE)
        } catch (_: SecurityException) {
            listener.onSensorStatus("denied")
            // The member can grant nearby devices again from the next pairing; retrying now would not help.
            shouldRun = false
            null
        }
        if (gatt == null && shouldRun) {
            listener.onSensorStatus("connecting")
            scheduleReconnect()
        }
    }

    private val callback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            if (!shouldRun) return
            if (status != BluetoothGatt.GATT_SUCCESS) {
                log("strap connection failed: status=$status state=$newState")
                release(gatt)
                connected = false
                listener.onSensorStatus("connecting")
                scheduleReconnect()
                return
            }
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    connected = true
                    reconnectAttempt = 0
                    log("strap connected: ${name ?: address}")
                    listener.onSensorStatus("connected")
                    gatt.discoverServices()
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    connected = false
                    log("strap disconnected")
                    listener.onSensorStatus("connecting")
                    // autoConnect keeps waiting; this fallback covers phones whose stack gives up.
                    scheduleReconnect(waitMs = 60_000L)
                }
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                log("service discovery failed: $status")
                release(gatt)
                listener.onSensorStatus("connecting")
                scheduleReconnect()
                return
            }
            val characteristic = gatt.getService(HEART_RATE_SERVICE)
                ?.getCharacteristic(HEART_RATE_MEASUREMENT)
            val descriptor = characteristic?.getDescriptor(CLIENT_CHARACTERISTIC_CONFIG)
            if (characteristic == null || descriptor == null) {
                log("strap has no heart-rate subscription")
                release(gatt)
                listener.onSensorStatus("connecting")
                scheduleReconnect()
                return
            }
            gatt.setCharacteristicNotification(characteristic, true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                gatt.writeDescriptor(descriptor, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
            } else {
                @Suppress("DEPRECATION")
                descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                @Suppress("DEPRECATION")
                gatt.writeDescriptor(descriptor)
            }
            log("subscribed to heart rate")
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int,
        ) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                log("could not subscribe to heart rate: $status")
            }
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
        ) {
            deliver(characteristic.uuid, value)
        }

        @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
        ) {
            deliver(characteristic.uuid, characteristic.value ?: return)
        }
    }

    private fun deliver(uuid: UUID, value: ByteArray) {
        if (uuid != HEART_RATE_MEASUREMENT) return
        val measurement = HeartRateMeasurement.parse(value) ?: return
        log("heart rate ${measurement.bpm} bpm (rr=${measurement.rrMs.size})")
        main.post { listener.onHeartRate(measurement.bpm) }
    }

    private fun scheduleReconnect(waitMs: Long? = null) {
        if (!shouldRun) return
        connected = false
        if (reconnect != null) return
        val delayMs = waitMs ?: minOf(30_000L, 2_000L shl minOf(reconnectAttempt, 4))
        if (waitMs == null) reconnectAttempt++
        val runnable = Runnable {
            reconnect = null
            open()
        }
        reconnect = runnable
        main.postDelayed(runnable, delayMs)
    }

    private fun release(gatt: BluetoothGatt) {
        runCatching { gatt.close() }
        if (this.gatt === gatt) this.gatt = null
    }

    private fun log(message: String) {
        if (debug) Log.d(TAG, message)
    }

    private companion object {
        const val TAG = "VelomineRecorder"
        val HEART_RATE_SERVICE: UUID = UUID.fromString("0000180d-0000-1000-8000-00805f9b34fb")
        val HEART_RATE_MEASUREMENT: UUID = UUID.fromString("00002a37-0000-1000-8000-00805f9b34fb")
        val CLIENT_CHARACTERISTIC_CONFIG: UUID =
            UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }
}
