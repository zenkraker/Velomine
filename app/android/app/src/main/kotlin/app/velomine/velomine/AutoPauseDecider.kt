package app.velomine.velomine

enum class AutoPauseAction { None, Pause, Resume }

/**
 * The small speed rule from the recorder plan: pause after three seconds at or below 0.1 km/h, resume after two
 * seconds above it. It does not decide what to do with the raw file; the service writes the timer events.
 *
 * Times are monotonic milliseconds, so a clock change cannot pause or resume a ride.
 */
class AutoPauseDecider(
    private val pauseAfterMs: Long = 3_000,
    private val resumeAfterMs: Long = 2_000,
    private val thresholdKmh: Double = 0.1,
) {
    private var stoppedSince: Long? = null
    private var movingSince: Long? = null

    fun update(speedKmh: Double?, nowMs: Long, autoPaused: Boolean): AutoPauseAction {
        if (speedKmh == null || speedKmh.isNaN()) {
            stoppedSince = null
            movingSince = null
            return AutoPauseAction.None
        }

        if (autoPaused) {
            stoppedSince = null
            if (speedKmh > thresholdKmh) {
                val since = movingSince ?: nowMs.also { movingSince = it }
                return if (nowMs - since >= resumeAfterMs) {
                    movingSince = null
                    AutoPauseAction.Resume
                } else {
                    AutoPauseAction.None
                }
            }
            movingSince = null
            return AutoPauseAction.None
        }

        movingSince = null
        if (speedKmh <= thresholdKmh) {
            val since = stoppedSince ?: nowMs.also { stoppedSince = it }
            return if (nowMs - since >= pauseAfterMs) {
                stoppedSince = null
                AutoPauseAction.Pause
            } else {
                AutoPauseAction.None
            }
        }

        stoppedSince = null
        return AutoPauseAction.None
    }

    fun reset() {
        stoppedSince = null
        movingSince = null
    }
}
