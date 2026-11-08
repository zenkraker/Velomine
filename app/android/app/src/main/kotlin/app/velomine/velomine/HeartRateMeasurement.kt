package app.velomine.velomine

/**
 * One reading from the standard Heart Rate Measurement characteristic (0x2A37).
 *
 * The layout is the Bluetooth SIG profile, not a Polar format: flags, then the beats-per-minute value (8 or 16
 * bits), optionally energy expended, optionally R-R intervals. Every heart-rate strap that advertises 0x180D uses it.
 */
data class HeartRateMeasurement(val bpm: Int, val rrMs: List<Int> = emptyList()) {
    companion object {
        private const val WIDE_VALUE = 0x01
        private const val ENERGY_EXPENDED = 0x08
        private const val RR_PRESENT = 0x10

        /** Null when the packet is too short or says the sensor has no contact (0 bpm). */
        fun parse(value: ByteArray): HeartRateMeasurement? {
            if (value.isEmpty()) return null
            val flags = value[0].toInt() and 0xFF
            val wide = flags and WIDE_VALUE != 0

            var offset = 1
            val bpm = if (wide) {
                if (value.size < 3) return null
                (value[1].toInt() and 0xFF) or ((value[2].toInt() and 0xFF) shl 8)
            } else {
                if (value.size < 2) return null
                value[1].toInt() and 0xFF
            }
            offset += if (wide) 2 else 1
            if (bpm == 0) return null

            if (flags and ENERGY_EXPENDED != 0) offset += 2

            val rr = mutableListOf<Int>()
            if (flags and RR_PRESENT != 0) {
                while (offset + 1 < value.size) {
                    rr += (value[offset].toInt() and 0xFF) or ((value[offset + 1].toInt() and 0xFF) shl 8)
                    offset += 2
                }
            }
            return HeartRateMeasurement(bpm, rr)
        }
    }
}
