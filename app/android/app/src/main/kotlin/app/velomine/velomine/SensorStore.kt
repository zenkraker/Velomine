package app.velomine.velomine

import android.content.Context

/** A strap this phone remembers. Pairing is app-level: heart-rate straps need no operating-system bond. */
data class PairedSensor(val address: String, val name: String)

/** The one heart-rate strap kept for the next rides, on this phone only. */
class SensorStore(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun read(): PairedSensor? {
        val address = prefs.getString(KEY_ADDRESS, null) ?: return null
        val name = prefs.getString(KEY_NAME, null) ?: address
        return PairedSensor(address, name)
    }

    fun save(sensor: PairedSensor) {
        prefs.edit()
            .putString(KEY_ADDRESS, sensor.address)
            .putString(KEY_NAME, sensor.name)
            .apply()
    }

    fun clear() {
        prefs.edit().remove(KEY_ADDRESS).remove(KEY_NAME).apply()
    }

    private companion object {
        const val PREFS = "velomine_sensors"
        const val KEY_ADDRESS = "heart_rate_address"
        const val KEY_NAME = "heart_rate_name"
    }
}
