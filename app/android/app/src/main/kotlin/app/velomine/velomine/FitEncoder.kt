package app.velomine.velomine

import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import kotlin.math.roundToInt
import kotlin.math.roundToLong

/**
 * Writes the small FIT subset a phone ride needs: file id, timer events, records, one session and one activity.
 *
 * Deliberately no speed or distance fields: the server works speed out from the positions and records the source as
 * GPS. Power, cadence and heart rate are added by later recorder slices.
 */
object FitEncoder {
    private const val FIT_EPOCH_OFFSET_S = 631_065_600L
    private const val PROFILE_VERSION = 21_158
    private const val PROTOCOL_VERSION = 0x10

    private const val ENUM = 0x00
    private const val SINT32 = 0x85
    private const val UINT8 = 0x02
    private const val UINT16 = 0x84
    private const val UINT32 = 0x86
    private const val UINT32Z = 0x8C

    private const val INVALID_U8 = 0xFF
    private const val INVALID_U16 = 0xFFFF
    private const val INVALID_I32 = 0x7FFFFFFF

    private data class Field(val number: Int, val size: Int, val baseType: Int)

    private data class Definition(
        val localType: Int,
        val globalMessage: Int,
        val fields: List<Field>,
    )

    private val fileId = Definition(
        0,
        0,
        listOf(
            Field(0, 1, ENUM), // type
            Field(1, 2, UINT16), // manufacturer
            Field(2, 2, UINT16), // product
            Field(3, 4, UINT32Z), // serial number
            Field(4, 4, UINT32), // time created
        ),
    )

    private val event = Definition(
        4,
        21,
        listOf(
            Field(253, 4, UINT32), // timestamp
            Field(0, 1, ENUM), // event
            Field(1, 1, ENUM), // event type
            Field(4, 1, UINT8), // event group
            Field(6, 1, ENUM), // timer trigger
        ),
    )

    // No speed or distance: the server derives GPS speed and distance from the positions.
    private val record = Definition(
        1,
        20,
        listOf(
            Field(253, 4, UINT32), // timestamp
            Field(0, 4, SINT32), // position lat
            Field(1, 4, SINT32), // position long
            Field(2, 2, UINT16), // altitude, 5 m offset 500
            Field(3, 1, UINT8), // heart rate
        ),
    )

    private val session = Definition(
        2,
        18,
        listOf(
            Field(253, 4, UINT32), // timestamp
            Field(2, 4, UINT32), // start time
            Field(5, 1, ENUM), // sport
            Field(6, 1, ENUM), // sub sport
            Field(7, 4, UINT32), // total elapsed time, scale 1000
            Field(8, 4, UINT32), // total timer time, scale 1000
        ),
    )

    private val activity = Definition(
        3,
        34,
        listOf(
            Field(253, 4, UINT32), // timestamp
            Field(1, 2, UINT16), // number of sessions
            Field(2, 1, ENUM), // type
            Field(5, 4, UINT32), // local timestamp, for the UTC offset
        ),
    )

    fun encode(ride: RawRide): ByteArray {
        require(ride.samples.size >= 2) { "A FIT ride needs at least two samples." }

        val data = ByteArrayOutputStream()
        val out = DataOutputStream(data)

        writeDefinition(out, fileId)
        out.writeByte(fileId.localType)
        out.writeByte(4) // activity
        out.u16(255) // development manufacturer
        out.u16(1) // product
        out.u32(1L) // serial number
        out.u32(fitSeconds(ride.startMs))

        val events = normalizedEvents(ride)
        writeDefinition(out, event)
        for (item in events) {
            out.writeByte(event.localType)
            out.u32(fitSeconds(item.timeMs))
            out.writeByte(0) // timer
            out.writeByte(eventType(item.kind))
            out.writeByte(0) // event group
            out.writeByte(1) // manual trigger
        }

        writeDefinition(out, record)
        for (sample in ride.samples) {
            out.writeByte(record.localType)
            out.u32(fitSeconds(sample.timeMs))
            out.i32(semicircles(sample.latitude))
            out.i32(semicircles(sample.longitude))
            out.u16(altitude(sample.altitude))
            out.writeByte(sample.heartRate?.coerceIn(1, INVALID_U8 - 1) ?: INVALID_U8)
        }

        writeDefinition(out, session)
        out.writeByte(session.localType)
        out.u32(fitSeconds(ride.endMs))
        out.u32(fitSeconds(ride.startMs))
        out.writeByte(if (ride.ebike) 21 else 2) // sport: e-biking or cycling
        out.writeByte(subSport(ride.rideType))
        out.u32(ride.elapsedMs.coerceAtLeast(0))
        out.u32(ride.movingMs.coerceAtLeast(0))

        writeDefinition(out, activity)
        out.writeByte(activity.localType)
        out.u32(fitSeconds(ride.endMs))
        out.u16(1) // sessions
        out.writeByte(0) // manual
        out.u32(fitSeconds(ride.endMs) + ride.offsetMinutes.toLong() * 60)

        val body = data.toByteArray()
        val header = ByteArray(14)
        header[0] = 14
        header[1] = PROTOCOL_VERSION.toByte()
        putU16(header, 2, PROFILE_VERSION)
        putU32(header, 4, body.size.toLong())
        header[8] = '.'.code.toByte()
        header[9] = 'F'.code.toByte()
        header[10] = 'I'.code.toByte()
        header[11] = 'T'.code.toByte()
        putU16(header, 12, crc16(header, 0, 12))

        val file = ByteArray(header.size + body.size + 2)
        header.copyInto(file, 0)
        body.copyInto(file, header.size)
        val crc = crc16(file, 0, header.size + body.size)
        file[file.size - 2] = (crc and 0xFF).toByte()
        file[file.size - 1] = ((crc ushr 8) and 0xFF).toByte()
        return file
    }

    /// The FIT sub-sport for the type chosen on the phone. Values come from the FIT profile.
    private fun subSport(rideType: String): Int = when (rideType) {
        "gravel" -> 46
        "mountain" -> 8
        "track" -> 13
        "indoor" -> 6
        "virtual" -> 58
        "commute" -> 48
        else -> 7 // road
    }

    private fun normalizedEvents(ride: RawRide): List<RawEvent> {
        val events = ride.events.toMutableList()
        if (events.none { it.kind == "start" }) {
            events += RawEvent("start", ride.startMs)
        }
        if (events.none { it.kind == "stop" }) {
            events += RawEvent("stop", ride.endMs)
        }
        return events.sortedBy { it.timeMs }
    }

    private fun eventType(kind: String): Int = when (kind) {
        "resume" -> 0 // start
        "pause" -> 1 // stop
        "stop" -> 4 // stop all
        else -> 0 // start
    }

    private fun writeDefinition(out: DataOutputStream, definition: Definition) {
        out.writeByte(0x40 or definition.localType)
        out.writeByte(0) // reserved
        out.writeByte(0) // little endian
        out.u16(definition.globalMessage)
        out.writeByte(definition.fields.size)
        for (field in definition.fields) {
            out.writeByte(field.number)
            out.writeByte(field.size)
            out.writeByte(field.baseType)
        }
    }

    private fun fitSeconds(epochMillis: Long): Long = epochMillis / 1000 - FIT_EPOCH_OFFSET_S

    private fun semicircles(degrees: Double?): Int {
        if (degrees == null || degrees.isNaN()) return INVALID_I32
        return (degrees / 180.0 * 2_147_483_648.0).roundToLong().toInt()
    }

    private fun altitude(metres: Double?): Int {
        if (metres == null || metres.isNaN()) return INVALID_U16
        return ((metres + 500.0) * 5.0).roundToInt().coerceIn(0, INVALID_U16 - 1)
    }

    private fun DataOutputStream.u16(value: Int) {
        writeByte(value and 0xFF)
        writeByte((value ushr 8) and 0xFF)
    }

    private fun DataOutputStream.u32(value: Long) {
        writeByte((value and 0xFF).toInt())
        writeByte(((value ushr 8) and 0xFF).toInt())
        writeByte(((value ushr 16) and 0xFF).toInt())
        writeByte(((value ushr 24) and 0xFF).toInt())
    }

    private fun DataOutputStream.i32(value: Int) = u32(value.toLong() and 0xFFFFFFFFL)

    private fun putU16(bytes: ByteArray, offset: Int, value: Int) {
        bytes[offset] = (value and 0xFF).toByte()
        bytes[offset + 1] = ((value ushr 8) and 0xFF).toByte()
    }

    private fun putU32(bytes: ByteArray, offset: Int, value: Long) {
        bytes[offset] = (value and 0xFF).toByte()
        bytes[offset + 1] = ((value ushr 8) and 0xFF).toByte()
        bytes[offset + 2] = ((value ushr 16) and 0xFF).toByte()
        bytes[offset + 3] = ((value ushr 24) and 0xFF).toByte()
    }

    // The 16-entry CRC table from the FIT SDK. The simple bit-by-bit CRC used by some other protocols is not the
    // same polynomial and makes the Garmin decoder reject the file.
    private val crcTable = intArrayOf(
        0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401,
        0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400,
    )

    private fun crc16(bytes: ByteArray, offset: Int, count: Int): Int {
        var crc = 0
        for (i in offset until offset + count) {
            val byte = bytes[i].toInt() and 0xFF
            var tmp = crcTable[crc and 0xF]
            crc = (crc ushr 4) and 0x0FFF
            crc = crc xor tmp xor crcTable[byte and 0xF]

            tmp = crcTable[crc and 0xF]
            crc = (crc ushr 4) and 0x0FFF
            crc = crc xor tmp xor crcTable[(byte ushr 4) and 0xF]
        }
        return crc and 0xFFFF
    }
}
