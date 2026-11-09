package app.velomine.velomine

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RecorderModelsTest {
    @Test
    fun RawSample_ShouldKeepItsPosition_WhenAccuracyIsGood() {
        val sample = sample(accuracy = 30.0)

        assertTrue(sample.hasReliablePosition())
        assertEquals(sample.latitude, sample.withoutUnreliablePosition().latitude)
    }

    @Test
    fun RawSample_ShouldDropItsPosition_WhenAccuracyIsPoor() {
        val sample = sample(accuracy = 30.1)

        assertFalse(sample.hasReliablePosition())
        assertNull(sample.withoutUnreliablePosition().latitude)
    }

    @Test
    fun RawRide_ShouldIgnoreDistance_WhenEitherEndOfAStepIsPoor() {
        val ride = ride(
            sample(0, 46.0, 11.0, accuracy = 96.0),
            sample(1_000, 46.001, 11.0, accuracy = 24.0),
        )

        assertEquals(0.0, ride.distanceM)
    }

    @Test
    fun RawRide_ShouldCountDistance_WhenBothEndsAreGood() {
        val ride = ride(
            sample(0, 46.0, 11.0, accuracy = 24.0),
            sample(1_000, 46.001, 11.0, accuracy = 24.0),
        )

        assertTrue(ride.distanceM > 100)
    }

    private fun sample(
        timeMs: Long = 0,
        latitude: Double = 46.0,
        longitude: Double = 11.0,
        accuracy: Double?,
    ) = RawSample(
        timeMs = timeMs,
        latitude = latitude,
        longitude = longitude,
        altitude = null,
        speed = null,
        accuracy = accuracy,
    )

    private fun ride(vararg samples: RawSample) = RawRide(
        startMs = samples.first().timeMs,
        endMs = samples.last().timeMs,
        offsetMinutes = 0,
        samples = samples.toList(),
        events = emptyList(),
    )
}
