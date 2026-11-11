package app.velomine.velomine

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Reads the bytes [FitEncoder] produced, the way another program would: header, CRC, definitions, then the record
 * and session messages. The server only ever sees these bytes, so this is the check that a ride leaves the phone in a
 * file a FIT reader accepts.
 */
class FitEncoderTest {
    private val startMs = 1_700_000_000_000L
    private val endMs = startMs + 60_000

    private fun ride() = RawRide(
        startMs = startMs,
        endMs = endMs,
        offsetMinutes = 60,
        samples = listOf(
            sample(0, 46.0, 11.0, altitude = 250.0, heartRate = 120),
            sample(60_000, 46.001, 11.001, altitude = 252.0, heartRate = 130),
        ),
        events = emptyList(),
        rideType = "road",
    )

    private fun sample(
        offsetMs: Long,
        latitude: Double,
        longitude: Double,
        altitude: Double?,
        heartRate: Int?,
    ) = RawSample(
        timeMs = startMs + offsetMs,
        latitude = latitude,
        longitude = longitude,
        altitude = altitude,
        speed = null,
        accuracy = 5.0,
        heartRate = heartRate,
    )

    @Test
    fun FitEncoder_ShouldWriteAValidHeader_WhenTheRideIsTwoSamples() {
        val fit = FitEncoder.encode(ride())

        assertEquals(14, fit[0].toInt())
        assertEquals(0x10, fit[1].toInt() and 0xFF)
        assertEquals(fit.size - 16, u16(fit, 4))
        assertEquals(".FIT", String(fit, 8, 4))
        assertEquals(crc16(fit, 0, 12), u16(fit, 12))
        assertEquals(crc16(fit, 0, fit.size - 2), u16(fit, fit.size - 2))
    }

    @Test
    fun FitEncoder_ShouldWriteBothSamples_WhenTheRideHasTwo() {
        val messages = messages(FitEncoder.encode(ride()))
        val records = messages.filter { it.global == 20 }

        assertEquals(2, records.size)
        assertEquals(fitSeconds(startMs), u32(records[0].body, 0))
        assertEquals(semicircles(46.0), u32(records[0].body, 4).toInt())
        assertEquals(semicircles(11.0), u32(records[0].body, 8).toInt())
        assertEquals(altitude(250.0), u16(records[0].body, 12))
        assertEquals(120, records[0].body[14].toInt() and 0xFF)
        assertEquals(130, records[1].body[14].toInt() and 0xFF)
    }

    @Test
    fun FitEncoder_ShouldWriteTheSessionAndActivity_WhenTheRideIsFinished() {
        val messages = messages(FitEncoder.encode(ride()))
        val session = messages.single { it.global == 18 }
        val activity = messages.single { it.global == 34 }

        assertEquals(fitSeconds(startMs), u32(session.body, 4))
        assertEquals(60_000, u32(session.body, 10).toInt()) // total elapsed, scale 1000
        assertEquals(60_000, u32(session.body, 14).toInt()) // total timer, scale 1000
        assertEquals(1, u16(activity.body, 4)) // number of sessions
        assertEquals(3600, (u32(activity.body, 7) - fitSeconds(endMs)).toInt()) // local timestamp carries the offset
    }

    @Test
    fun FitEncoder_ShouldWriteTimerStartAndStop_WhenTheRideHasNoEvents() {
        val messages = messages(FitEncoder.encode(ride()))
        val events = messages.filter { it.global == 21 }

        assertEquals(listOf(0, 4), events.map { it.body[5].toInt() })
        assertTrue(events[0].body[4].toInt() == 0 && events[1].body[4].toInt() == 0)
    }

    private data class Message(val global: Int, val body: ByteArray)

    /** Walks the FIT messages: a definition sets the field layout, a data message carries the bytes. */
    private fun messages(fit: ByteArray): List<Message> {
        val definitions = mutableMapOf<Int, Pair<Int, Int>>() // local type -> global message, body size
        val result = mutableListOf<Message>()
        var at = 14
        val end = fit.size - 2
        while (at < end) {
            val header = fit[at].toInt() and 0xFF
            if (header and 0x80 != 0) {
                error("Compressed FIT definitions are not written by the encoder.")
            }

            val localType = header and 0x0F
            if (header and 0x40 != 0) {
                val global = u16(fit, at + 3)
                val fieldCount = fit[at + 5].toInt() and 0xFF
                var size = 0
                for (field in 0 until fieldCount) {
                    size += fit[at + 6 + field * 3 + 1].toInt() and 0xFF
                }
                definitions[localType] = global to size
                at += 6 + fieldCount * 3
            } else {
                val (global, size) = definitions[localType] ?: error("No definition for local type $localType.")
                at += 1
                result += Message(global, fit.copyOfRange(at, at + size))
                at += size
            }
        }
        assertEquals(end, at)
        return result
    }

    private fun u16(bytes: ByteArray, at: Int): Int =
        (bytes[at].toInt() and 0xFF) or ((bytes[at + 1].toInt() and 0xFF) shl 8)

    private fun u32(bytes: ByteArray, at: Int): Long =
        ((bytes[at].toLong() and 0xFF) or
            ((bytes[at + 1].toLong() and 0xFF) shl 8) or
            ((bytes[at + 2].toLong() and 0xFF) shl 16) or
            ((bytes[at + 3].toLong() and 0xFF) shl 24))

    private fun fitSeconds(epochMillis: Long): Long = epochMillis / 1000 - 631_065_600L

    private fun semicircles(degrees: Double): Int = Math.round(degrees / 180.0 * 2_147_483_648.0).toInt()

    private fun altitude(metres: Double): Int = Math.round((metres + 500.0) * 5.0).toInt()

    /** The FIT SDK's 16-entry CRC table, written again here so the encoder cannot agree with its own mistake. */
    private fun crc16(bytes: ByteArray, offset: Int, count: Int): Int {
        val table = intArrayOf(
            0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401,
            0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400,
        )
        var crc = 0
        for (i in offset until offset + count) {
            val byte = bytes[i].toInt() and 0xFF
            var tmp = table[crc and 0xF]
            crc = (crc ushr 4) and 0x0FFF
            crc = crc xor tmp xor table[byte and 0xF]

            tmp = table[crc and 0xF]
            crc = (crc ushr 4) and 0x0FFF
            crc = crc xor tmp xor table[(byte ushr 4) and 0xF]
        }
        return crc and 0xFFFF
    }
}
