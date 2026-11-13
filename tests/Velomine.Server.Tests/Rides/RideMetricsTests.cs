using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Tests.Rides;

public sealed class RideMetricsTests
{
    private static Sample[] Series(int seconds, Func<int, Sample> at) => [.. Enumerable.Range(0, seconds).Select(at)];

    [Fact]
    public void NormalizedPower_ShouldReturnThatPower_WhenPowerIsSteady()
    {
        var power = Enumerable.Repeat(200.0, 120).ToArray();

        Assert.Equal(200, RideMetrics.NormalizedPower(power));
    }

    [Fact]
    public void NormalizedPower_ShouldUseA30SecondRollingAverage_WhenPowerIsVariable()
    {
        // 60 s at 100 W then 60 s at 300 W.
        var power = Enumerable.Range(0, 120).Select(i => i < 60 ? 100.0 : 300.0).ToArray();

        // Worked out the slow way: the mean of every full 30 s window, to the 4th power, averaged, 4th root.
        var windows = Enumerable.Range(0, power.Length - 29).Select(start => power.Skip(start).Take(30).Average()).ToArray();
        var expected = (int)Math.Round(Math.Pow(windows.Average(w => Math.Pow(w, 4)), 0.25));
        var rawFourthPowerMean = Math.Pow(power.Average(p => Math.Pow(p, 4)), 0.25); // 253: what skipping the rolling average gives

        var np = RideMetrics.NormalizedPower(power);

        Assert.Equal(expected, np);
        Assert.True(np < rawFourthPowerMean - 5, $"NP {np} should be below the unsmoothed {rawFourthPowerMean:F0}");
        Assert.True(np > 200, "NP is above the plain average of 200 W for variable power");
    }

    [Fact]
    public void NormalizedPower_ShouldReturnNull_WhenShorterThan30Seconds() =>
        Assert.Null(RideMetrics.NormalizedPower(Enumerable.Repeat(250.0, 29).ToArray()));

    [Fact]
    public void RobustMax_ShouldIgnoreASingleGlitch_WhenOneSampleSpikes()
    {
        var speeds = Enumerable.Repeat(8f, 40).ToArray();
        speeds[20] = 55f;

        Assert.Equal(8, RideMetrics.RobustMax(speeds));
    }

    [Fact]
    public void RobustMax_ShouldKeepTheMaximum_WhenTheSurgeIsSustained()
    {
        // 32 -> 54 km/h in 1.5 s: a sprint, then held.
        float[] speeds = [.. Enumerable.Repeat(8.9f, 20), .. Enumerable.Range(1, 6).Select(i => 8.9f + 1.5f * i), .. Enumerable.Repeat(15f, 14)];

        Assert.Equal(15, RideMetrics.RobustMax(speeds), 1);
    }

    private const double DegreesPerMeter = 1 / 111_195.0;

    /// <summary>One sample a second moving north at the given speeds; the first speed is where it starts.</summary>
    private static Sample[] Shuttle(params double[] speedsMs)
    {
        var north = 0.0;
        return Series(speedsMs.Length, i =>
        {
            if (i > 0) north += speedsMs[i - 1];
            return new Sample(i, Latitude: north * DegreesPerMeter, Longitude: 0);
        });
    }

    [Fact]
    public void MaxSpeed_ShouldIgnoreTheGlitch_WhenFiveConsecutiveSamplesSpike()
    {
        // A tunnel: 4.5 m/s, then five positions that jump up to 39 m/s and back, then 4.5 m/s again.
        var samples = Shuttle([4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 39.3, 34.4, 26.6, 26.6, 40, 34.7, 24.7, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5]);

        var m = RideMetrics.Compute(samples);

        Assert.InRange(m.MaxSpeedMs!.Value, 4.4, 4.6);
    }

    [Fact]
    public void MaxSpeed_ShouldKeepTheMaximum_WhenTheRiderSprints()
    {
        // 30 -> 40 km/h over three seconds, held, then a hard stop from 40 to 30 km/h in one second.
        var samples = Shuttle([8.3, 8.3, 8.3, 9.2, 10.1, 11.1, 11.1, 11.1, 11.1, 11.1, 8.3, 8.3, 8.3, 8.3]);

        var m = RideMetrics.Compute(samples);

        Assert.InRange(m.MaxSpeedMs!.Value, 10.9, 11.2);
    }

    [Fact]
    public void SpeedSeries_ShouldKeepASpeedAfterAnUnknownSample_WhenTheFileLeavesThatSampleBlank()
    {
        Sample[] samples =
        [
            new(0, Speed: 5), new(1, Speed: 5), new(2), new(3), new(4, Speed: 0.2f), new(5, Speed: 5), new(6, Speed: 5),
        ];

        var speeds = RideMetrics.SpeedSeries(samples, out _);

        Assert.Equal([5f, 5f, null, null, 0.2f, 5f, 5f], speeds);
    }

    [Fact]
    public void ElevationChange_ShouldCountARealClimb_WhenTheSignalHasNoise()
    {
        // 100 m of climbing, 1 m per sample, with +-0.8 m of measurement noise.
        var climb = Enumerable.Range(0, 101).Select(i => (float?)(i + (i % 2 == 0 ? 0.8 : -0.8))).ToArray();
        var (gain, loss) = RideMetrics.ElevationChange(climb);
        Assert.InRange(gain!.Value, 95, 105);
        Assert.InRange(loss!.Value, 0, 5);

        // Flat road, +-1 m of noise.
        var flat = Enumerable.Range(0, 200).Select(i => (float?)(100 + (i % 2 == 0 ? 1 : -1))).ToArray();
        Assert.Equal((0.0, 0.0), RideMetrics.ElevationChange(flat));
    }

    [Fact]
    public void ElevationChange_ShouldReturnUnknown_WhenThereIsNoAltitude() =>
        Assert.Equal((null, null), RideMetrics.ElevationChange([null, null, null]));

    [Fact]
    public void Haversine_ShouldReturn111Km_WhenGivenOneDegreeOfLatitude() =>
        Assert.InRange(RideMetrics.Haversine(0, 0, 1, 0), 111_100, 111_300);

    [Fact]
    public void TotalDistance_ShouldUsePositions_WhenThereIsNoCumulativeDistance()
    {
        var samples = Series(2, i => new Sample(i * 3600, Latitude: i, Longitude: 0));

        Assert.InRange(RideMetrics.TotalDistance(samples), 111_100, 111_300);
    }

    [Fact]
    public void TotalDistance_ShouldPreferTheDevicesDistance_WhenItIsPresent()
    {
        var samples = Series(5, i => new Sample(i, Latitude: i * 0.001, Longitude: 0, Distance: 100 + i * 10));

        Assert.Equal(40, RideMetrics.TotalDistance(samples));
    }

    [Fact]
    public void Compute_ShouldSkipPausesAndStops_WhenTheRideHasPausesAndStops()
    {
        // 60 s riding at 5 m/s, a 5 minute pause with no samples, 30 s standing still, 60 s riding.
        var samples = new List<Sample>();
        for (var t = 0; t <= 59; t++) samples.Add(new Sample(t, Speed: 5));
        for (var t = 360; t <= 389; t++) samples.Add(new Sample(t, Speed: 0));
        for (var t = 390; t <= 449; t++) samples.Add(new Sample(t, Speed: 5));

        var m = RideMetrics.Compute(samples);

        Assert.Equal(449, m.ElapsedS);
        Assert.InRange(m.MovingS, 117, 120); // ~59 + ~60 seconds of riding, not the pause and not the stop
        Assert.Equal(SpeedSource.Device, m.SpeedSource);
    }

    [Fact]
    public void Compute_ShouldWorkOutSpeedFromPositions_WhenSamplesHaveNoSpeed()
    {
        // Moving north at 10 m/s: 1 s apart, 10 m apart.
        const double degreesPerMeter = 1 / 111_195.0;
        var samples = Series(60, i => new Sample(i, Latitude: i * 10 * degreesPerMeter, Longitude: 0));

        var m = RideMetrics.Compute(samples);

        Assert.Equal(SpeedSource.Gps, m.SpeedSource);
        Assert.InRange(m.MaxSpeedMs!.Value, 9.9, 10.1);
        Assert.InRange(m.AvgSpeedMs!.Value, 9.7, 10.3);
    }

    [Fact]
    public void Compute_ShouldAveragePowerHeartRateAndCadence_WhenSamplesIncludeCoasting()
    {
        var samples = Series(120, i => new Sample(i, Speed: 7, Power: (short)(i % 2 == 0 ? 100 : 300), HeartRate: 140, Cadence: (short)(i < 60 ? 0 : 90)));

        var m = RideMetrics.Compute(samples);

        Assert.InRange(m.AvgPowerW!.Value, 199, 201);
        Assert.Equal(300, m.MaxPowerW);
        Assert.Equal(140, m.AvgHeartRate);
        Assert.Equal(140, m.MaxHeartRate);
        Assert.Equal(90, m.AvgCadence); // the 60 s of 0 rpm is coasting, not pedalling
    }

    [Fact]
    public void Compute_ShouldPreferTheDevicesNormalizedPower_WhenTheDeviceSuppliesIt()
    {
        var samples = Series(120, i => new Sample(i, Speed: 7, Power: 200));

        Assert.Equal(231, RideMetrics.Compute(samples, deviceNormalizedPowerW: 231).NormalizedPowerW);
        Assert.Equal(200, RideMetrics.Compute(samples).NormalizedPowerW);
    }

    [Fact]
    public void Compute_ShouldExcludePausesFromTimeAndAverages_WhenTheRideHasPauses()
    {
        const double degreesPerMeter = 1 / 111_195.0;
        var samples = new List<Sample>();
        for (var t = 0; t <= 9; t++)
            samples.Add(new Sample(t, Latitude: t * 10 * degreesPerMeter, Longitude: 0, Power: 200));
        // The rider moved while the timer was stopped; that jump must not become distance or speed.
        for (var t = 20; t <= 29; t++)
            samples.Add(new Sample(t, Latitude: (1000 + (t - 20) * 10) * degreesPerMeter, Longitude: 0, Power: 100));

        var pauses = new[] { new PauseInterval(9.5, 19.5) };
        var m = RideMetrics.Compute(
            samples,
            deviceElapsedS: 30,
            deviceMovingS: 20,
            pauses: pauses);

        Assert.Equal(30, m.ElapsedS);
        Assert.Equal(20, m.MovingS);
        Assert.InRange(m.DistanceM, 170, 190); // two 90 m stretches, not the 900 m jump across the pause
        Assert.InRange(m.AvgSpeedMs!.Value, 8.5, 9.5);
        Assert.InRange(m.AvgPowerW!.Value, 140, 160); // 9 s at 200 W and 9 s at 100 W
    }

    [Fact]
    public void Compute_ShouldPreferDeviceTiming_WhenTheFileSuppliesIt()
    {
        var samples = Series(10, i => new Sample(i, Speed: 5));

        var m = RideMetrics.Compute(samples, deviceElapsedS: 30, deviceMovingS: 20);

        Assert.Equal(30, m.ElapsedS);
        Assert.Equal(20, m.MovingS);
    }

    [Fact]
    public void Compute_ShouldRejectTheRide_WhenThereAreFewerThanTwoSamples()
    {
        var error = Assert.Throws<RideParseException>(() => RideMetrics.Compute([new Sample(0)]));

        Assert.Equal("too_short", error.Code);
    }

    [Fact]
    public void Tss_ShouldReturn64_WhenRidingAnHourAt200WWithFtpOf250()
    {
        // One hour at 200 W against an FTP of 250: IF 0.8, TSS 64.
        var samples = Series(3600, i => new Sample(i, Power: 200));

        var metrics = RideMetrics.Compute(samples, ftpW: 250);

        Assert.Equal(0.8, metrics.IntensityFactor!.Value, 2);
        Assert.Equal(64.0, metrics.Tss!.Value, 1);
    }

    [Fact]
    public void Trimp_ShouldWeightHigherZonesMore_WhenHeartRateIsHigher()
    {
        // 119 seconds at 60 % of a 200 bpm maximum is zone 2, worth two points a minute.
        var samples = Series(120, i => new Sample(i, HeartRate: 120));

        var metrics = RideMetrics.Compute(samples, maxHeartRate: 200);

        Assert.Equal(4.0, metrics.Trimp!.Value, 1);
    }

    [Fact]
    public void ZoneSeconds_ShouldSplitSamplesByZone_WhenGivenHeartRateSamples()
    {
        Sample[] samples =
        [
            new(0, HeartRate: 100),
            new(10, HeartRate: 160),
            new(20, HeartRate: 180),
        ];

        var seconds = TrainingLoad.ZoneSeconds(
            samples,
            s => s.HeartRate,
            200,
            TrainingLoad.HeartRateFloor,
            TrainingLoad.HeartRateBounds);

        Assert.Equal(new double[] { 10, 0, 0, 10, 0 }, seconds);
    }
}
