package app.velomine.velomine

/** One position sample as it was recorded by the phone. Times are Unix epoch milliseconds. */
data class RawSample(
    val timeMs: Long,
    val latitude: Double?,
    val longitude: Double?,
    val altitude: Double?,
    val speed: Double?,
    val accuracy: Double?,
)

/** A pause, resume, start or stop marker in the raw file. */
data class RawEvent(val kind: String, val timeMs: Long)

/** Everything needed to turn a raw recording into a FIT file. */
data class RawRide(
    val startMs: Long,
    val endMs: Long,
    val offsetMinutes: Int,
    val samples: List<RawSample>,
    val events: List<RawEvent>,
) {
    val elapsedMs: Long
        get() = (endMs - startMs).coerceAtLeast(0)

    /** Recording time without the paused intervals. */
    val movingMs: Long
        get() {
            if (events.isEmpty()) return elapsedMs

            var moving = 0L
            var segmentStart: Long? = null
            for (event in events.sortedBy { it.timeMs }) {
                when (event.kind) {
                    "start", "resume" -> if (segmentStart == null) segmentStart = event.timeMs
                    "pause", "stop" -> {
                        segmentStart?.let { moving += (event.timeMs - it).coerceAtLeast(0) }
                        segmentStart = null
                    }
                }
            }
            segmentStart?.let { moving += (endMs - it).coerceAtLeast(0) }
            return moving.coerceIn(0, elapsedMs)
        }

    /** Distance between accepted samples, skipping the jumps across a pause. */
    val distanceM: Double
        get() {
            if (samples.size < 2) return 0.0
            val pauses = pauseIntervals()
            var total = 0.0
            for (i in 1 until samples.size) {
                val before = samples[i - 1]
                val after = samples[i]
                if (before.latitude == null || before.longitude == null ||
                    after.latitude == null || after.longitude == null
                ) {
                    continue
                }
                if (pauses.any { it.first < after.timeMs && it.second > before.timeMs }) continue
                if (after.timeMs - before.timeMs > MAX_DISTANCE_GAP_MS) continue
                if (after.accuracy != null && after.accuracy > MAX_DISTANCE_ACCURACY_M) continue
                total += haversine(
                    before.latitude,
                    before.longitude,
                    after.latitude,
                    after.longitude,
                )
            }
            return total
        }

    private fun pauseIntervals(): List<Pair<Long, Long>> {
        val intervals = mutableListOf<Pair<Long, Long>>()
        var pausedAt: Long? = null
        for (event in events.sortedBy { it.timeMs }) {
            when (event.kind) {
                "pause" -> if (pausedAt == null) pausedAt = event.timeMs
                "resume", "stop" -> {
                    pausedAt?.let { intervals += it to event.timeMs }
                    pausedAt = null
                }
            }
        }
        pausedAt?.let { intervals += it to endMs }
        return intervals
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

    private companion object {
        const val MAX_DISTANCE_GAP_MS = 30_000L
        const val MAX_DISTANCE_ACCURACY_M = 70.0
    }
}
