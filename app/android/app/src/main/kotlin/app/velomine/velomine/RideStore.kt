package app.velomine.velomine

import android.content.Context
import android.content.pm.ApplicationInfo
import android.util.Log
import org.json.JSONObject
import java.io.BufferedWriter
import java.io.File
import java.io.FileWriter
import java.util.UUID

/**
 * Local rides on the phone:
 *
 *   rides/<id>/ride.json   state and summary
 *   rides/<id>/raw.jsonl   samples and start/pause/resume/stop markers, flushed as they happen
 *   rides/<id>/ride.fit    assembled once the ride is finished
 *
 * Nothing here talks to the server; the upload queue is a later slice.
 */
class RideStore(context: Context) {
    private val ridesDir = File(context.noBackupFilesDir, "rides")
    private val debug = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    fun create(startedAt: Long = System.currentTimeMillis()): ActiveRide {
        val id = UUID.randomUUID().toString()
        val dir = File(ridesDir, id).apply { mkdirs() }
        val ride = ActiveRide(id, dir, startedAt, offsetMinutes(startedAt))
        log("create ride $id dir=${dir.absolutePath} startedAt=$startedAt offset=${ride.offsetMinutes}")
        ride.event("start", startedAt)
        save(ride, "recording", endedAt = null, error = null)
        return ride
    }

    fun save(
        ride: ActiveRide,
        state: String,
        endedAt: Long?,
        error: String?,
        distanceM: Double = ride.distanceM,
        movingMs: Long = ride.movingMs,
    ) {
        val json = JSONObject()
            .put("id", ride.id)
            .put("startedAt", ride.startedAt)
            .put("endedAt", endedAt)
            .put("state", state)
            .put("distanceM", distanceM)
            .put("movingS", movingMs / 1000.0)
            .put("timeZoneOffsetMinutes", ride.offsetMinutes)
            .put("error", error)
        log(
            "save ride ${ride.id} state=$state endedAt=$endedAt distance=$distanceM " +
                "movingMs=$movingMs error=$error",
        )
        writeSidecar(ride.dir, json)
    }

    fun interrupt(ride: ActiveRide) {
        log("interrupt ride ${ride.id}")
        ride.close()
        save(
            ride,
            "interrupted",
            endedAt = System.currentTimeMillis(),
            error = null,
        )
    }

    /** Finishes a ride from its raw file. Used at stop and to recover an interrupted ride. */
    fun finalize(id: String): Map<String, Any?> {
        log("finalize $id requested")
        val dir = rideDir(id) ?: return failed(id, "not_found")
        val sidecar = readSidecar(dir) ?: return failed(id, "not_found")
        if (RecorderRuntime.isRunning && RecorderRuntime.rideId == id) {
            log("finalize $id refused: still recording")
            return mapOf("id" to id, "state" to "recording", "error" to "still_recording")
        }

        val parsed = readRaw(dir)
        log(
            "finalize $id parsed samples=${parsed.samples.size} events=${parsed.events.size} " +
                "start=${parsed.startMs} end=${parsed.endMs}",
        )
        if (parsed.samples.size < 2) {
            log("finalize $id failed: too few samples")
            return writeFailed(dir, sidecar, "too_short")
        }

        val startedAt = parsed.startMs ?: sidecar.optLong("startedAt")
        val endedAt = parsed.endMs ?: parsed.samples.last().timeMs
        val ride = RawRide(
            startMs = startedAt,
            endMs = endedAt,
            offsetMinutes = sidecar.optInt("timeZoneOffsetMinutes", 0),
            samples = parsed.samples,
            events = parsed.events,
        )

        return try {
            File(dir, FIT_FILE).writeBytes(FitEncoder.encode(ride))
            log(
                "finalize $id wrote ${FIT_FILE} distance=${ride.distanceM} " +
                    "movingMs=${ride.movingMs} elapsedMs=${ride.elapsedMs}",
            )
            val map = sidecar(dir).apply {
                put("endedAt", endedAt)
                put("state", "ready")
                put("distanceM", ride.distanceM)
                put("movingS", ride.movingMs / 1000.0)
                put("error", null)
            }
            writeSidecar(dir, map)
            map.toMap()
        } catch (e: Exception) {
            log("finalize $id failed writing FIT: $e")
            writeFailed(dir, sidecar, "fit_failed")
        }
    }

    fun list(): List<Map<String, Any?>> {
        val dirs = ridesDir.listFiles()?.filter { it.isDirectory } ?: emptyList()
        val rides = dirs
            .mapNotNull { dir ->
                readSidecar(dir)?.let { map ->
                    // A recording state is only live while the service is running. Otherwise it was interrupted.
                    if (!RecorderRuntime.isRunning &&
                        (map.optString("state") == "recording" || map.optString("state") == "paused")
                    ) {
                        map.put("state", "interrupted")
                    }
                    readUpload(dir)?.let { upload ->
                        map.put("uploadState", upload.optString("state"))
                        map.put(
                            "serverRideId",
                            if (upload.isNull("serverRideId")) null else upload.getString("serverRideId"),
                        )
                        map.put(
                            "uploadError",
                            if (upload.isNull("error")) null else upload.getString("error"),
                        )
                        map.put("uploadAttempts", upload.optInt("attempts", 0))
                    }
                    map.toMap()
                }
            }
            .sortedByDescending { (it["startedAt"] as? Number)?.toLong() ?: 0L }
        log("list: ${rides.size} ride(s) running=${RecorderRuntime.isRunning}")
        for (ride in rides) {
            log(
                "list: id=${ride["id"]} state=${ride["state"]} " +
                    "startedAt=${ride["startedAt"]} endedAt=${ride["endedAt"]} " +
                    "distance=${ride["distanceM"]} moving=${ride["movingS"]}",
            )
        }
        return rides
    }

    fun delete(id: String): Boolean {
        log("delete $id requested")
        val dir = rideDir(id) ?: return false
        if (RecorderRuntime.isRunning && RecorderRuntime.rideId == id) {
            log("delete $id refused: still recording")
            return false
        }
        val deleted = dir.deleteRecursively()
        log("delete $id -> $deleted")
        return deleted
    }

    fun read(id: String): Map<String, Any?>? {
        val dir = rideDir(id) ?: return null
        return readSidecar(dir)?.toMap()
    }

    /** The finished FIT, for the upload queue. */
    fun readFit(id: String): ByteArray? {
        val dir = rideDir(id) ?: return null
        val file = File(dir, FIT_FILE)
        if (!file.exists()) {
            log("readFit $id: no FIT file")
            return null
        }
        val bytes = file.readBytes()
        log("readFit $id: ${bytes.size} bytes")
        return bytes
    }

    /**
     * Where the upload got to. Kept in a separate file so the recording sidecar can be rewritten while a ride is
     * uploading. The Dart queue and the background worker both update it.
     */
    fun markUpload(
        id: String,
        state: String,
        serverRideId: String? = null,
        error: String? = null,
        attempts: Int? = null,
    ) {
        val dir = rideDir(id) ?: return
        val json = readUpload(dir) ?: JSONObject()
        json.put("state", state)
        if (serverRideId != null) json.put("serverRideId", serverRideId)
        if (error != null) json.put("error", error) else json.remove("error")
        if (attempts != null) json.put("attempts", attempts)
        writeUpload(dir, json)
        log("upload state $id -> $state server=$serverRideId error=$error attempts=$attempts")
    }

    private fun failed(id: String, error: String): Map<String, Any?> =
        mapOf("id" to id, "state" to "failed", "error" to error)

    private fun writeFailed(dir: File, sidecar: JSONObject, error: String): Map<String, Any?> {
        val map = sidecar.apply {
            put("state", "failed")
            put("error", error)
        }
        writeSidecar(dir, map)
        return map.toMap()
    }

    private fun writeSidecar(dir: File, json: JSONObject) {
        val target = File(dir, SIDECAR)
        val temporary = File(dir, "$SIDECAR.tmp")
        temporary.writeText(json.toString())
        if (!temporary.renameTo(target)) {
            target.writeText(json.toString())
            temporary.delete()
        }
    }

    private fun sidecar(dir: File) = readSidecar(dir) ?: JSONObject()

    private fun readSidecar(dir: File): JSONObject? = try {
        val file = File(dir, SIDECAR)
        if (file.exists()) JSONObject(file.readText()) else null
    } catch (_: Exception) {
        null
    }

    private fun readUpload(dir: File): JSONObject? = try {
        val file = File(dir, UPLOAD_FILE)
        if (file.exists()) JSONObject(file.readText()) else null
    } catch (_: Exception) {
        null
    }

    private fun writeUpload(dir: File, json: JSONObject) {
        val target = File(dir, UPLOAD_FILE)
        val temporary = File(dir, "$UPLOAD_FILE.tmp")
        temporary.writeText(json.toString())
        if (!temporary.renameTo(target)) {
            target.writeText(json.toString())
            temporary.delete()
        }
    }

    private fun rideDir(id: String): File? {
        if (id.isBlank() || id.contains('/') || id.contains('\\')) return null
        val dir = File(ridesDir, id)
        return if (dir.isDirectory && dir.parentFile == ridesDir) dir else null
    }

    private data class Parsed(
        val startMs: Long?,
        val endMs: Long?,
        val samples: List<RawSample>,
        val events: List<RawEvent>,
    )

    private fun readRaw(dir: File): Parsed {
        val file = File(dir, RAW_FILE)
        if (!file.exists()) return Parsed(null, null, emptyList(), emptyList())

        val samples = mutableListOf<RawSample>()
        val events = mutableListOf<RawEvent>()
        var startMs: Long? = null
        var endMs: Long? = null

        file.forEachLine { line ->
            if (line.isBlank()) return@forEachLine
            try {
                val json = JSONObject(line)
                val time = json.optLong("t")
                when (json.optString("type")) {
                    "sample" -> samples += RawSample(
                        timeMs = time,
                        latitude = json.doubleOrNull("lat"),
                        longitude = json.doubleOrNull("lon"),
                        altitude = json.doubleOrNull("alt"),
                        speed = json.doubleOrNull("speed"),
                        accuracy = json.doubleOrNull("accuracy"),
                        heartRate = json.intOrNull("hr"),
                    )
                    "start", "pause", "resume", "stop" -> {
                        val kind = json.optString("type")
                        events += RawEvent(kind, time)
                        if (kind == "start") startMs = time
                        if (kind == "stop") endMs = time
                    }
                }
            } catch (_: Exception) {
                // Skip one damaged line rather than losing the whole ride.
            }
        }

        val lastTime = maxOf(
            samples.lastOrNull()?.timeMs ?: 0L,
            events.lastOrNull()?.timeMs ?: 0L,
        )
        return Parsed(
            startMs = startMs,
            endMs = endMs ?: lastTime.takeIf { it > 0 },
            samples = samples.sortedBy { it.timeMs },
            events = events.sortedBy { it.timeMs },
        )
    }

    private fun JSONObject.doubleOrNull(key: String): Double? =
        if (isNull(key)) null else getDouble(key)

    private fun JSONObject.intOrNull(key: String): Int? =
        if (!has(key) || isNull(key)) null else getInt(key)

    private fun offsetMinutes(epochMillis: Long): Int =
        java.util.TimeZone.getDefault().getOffset(epochMillis) / 60_000

    private fun log(message: String) {
        if (debug) Log.d(TAG, message)
    }

    private fun JSONObject.toMap(): Map<String, Any?> {
        val result = mutableMapOf<String, Any?>()
        for (key in keys()) {
            // `get` must be called on the JSONObject, not on the result map.
            result[key] = if (isNull(key)) null else get(key)
        }
        return result
    }

    companion object {
        private const val TAG = "VelomineRecorder"
        private const val SIDECAR = "ride.json"
        private const val UPLOAD_FILE = "upload.json"
        private const val RAW_FILE = "raw.jsonl"
        private const val FIT_FILE = "ride.fit"
    }
}

/** A ride that is being recorded. Its writer is flushed after every line so a crash loses at most one sample. */
class ActiveRide(
    val id: String,
    val dir: File,
    val startedAt: Long,
    val offsetMinutes: Int,
) {
    private val writer = BufferedWriter(FileWriter(File(dir, "raw.jsonl"), true))

    @Volatile
    var distanceM: Double = 0.0

    @Volatile
    var movingMs: Long = 0L

    @Synchronized
    fun sample(sample: RawSample) {
        val json = JSONObject()
            .put("type", "sample")
            .put("t", sample.timeMs)
            .put("lat", sample.latitude ?: JSONObject.NULL)
            .put("lon", sample.longitude ?: JSONObject.NULL)
            .put("alt", sample.altitude ?: JSONObject.NULL)
            .put("speed", sample.speed ?: JSONObject.NULL)
            .put("accuracy", sample.accuracy ?: JSONObject.NULL)
            .put("hr", sample.heartRate ?: JSONObject.NULL)
        write(json)
    }

    @Synchronized
    fun event(kind: String, timeMs: Long) {
        write(JSONObject().put("type", kind).put("t", timeMs))
    }

    @Synchronized
    fun close() {
        runCatching { writer.flush() }
        runCatching { writer.close() }
    }

    private fun write(json: JSONObject) {
        writer.write(json.toString())
        writer.newLine()
        writer.flush()
    }
}
