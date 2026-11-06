using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Tests.Rides;

public sealed class RideMetricsTests
{
    private static Sample[] Series(int seconds, Func<int, Sample> at) => [.. Enumerable.Range(0, seconds).Select(at)];

    [Fact]
    public void NormalizedPower_OfSteadyPower_IsThatPower()
    {
        var power = Enumerable.Repeat(200.0, 120).ToArray();

        Assert.Equal(200, RideMetrics.NormalizedPower(power));
    }

    [Fact]
    public void NormalizedPower_UsesA30SecondRollingAverage_NotTheRawSamples()
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
    public void NormalizedPower_OfLessThan30Seconds_IsUnknown() =>
        Assert.Null(RideMetrics.NormalizedPower(Enumerable.Repeat(250.0, 29).ToArray()));

    [Fact]
    public void RobustMax_IgnoresASingleGlitch()
    {
        var speeds = Enumerable.Repeat(8f, 40).ToArray();
        speeds[20] = 55f;

        Assert.Equal(8, RideMetrics.RobustMax(speeds));
    }

    [Fact]
    public void RobustMax_KeepsARealSustainedMaximum()
    {
        var speeds = Enumerable.Repeat(8f, 40).Select((v, i) => i is >= 20 and < 26 ? 15f : v).ToArray();

        Assert.Equal(15, RideMetrics.RobustMax(speeds));
    }

    [Fact]
    public void Elevation_CountsARealClimb_ButNotNoise()
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
    public void Elevation_WithoutAltitude_IsUnknown() =>
        Assert.Equal((null, null), RideMetrics.ElevationChange([null, null, null]));

    [Fact]
    public void Haversine_OneDegreeOfLatitude_Is111Km() =>
        Assert.InRange(RideMetrics.Haversine(0, 0, 1, 0), 111_100, 111_300);

    [Fact]
    public void Distance_FromPositions_WhenTheFileHasNoCumulativeDistance()
    {
        var samples = Series(2, i => new Sample(i * 3600, Latitude: i, Longitude: 0));

        Assert.InRange(RideMetrics.TotalDistance(samples), 111_100, 111_300);
    }

    [Fact]
    public void Distance_PrefersTheDevicesCumulativeDistance()
    {
        var samples = Series(5, i => new Sample(i, Latitude: i * 0.001, Longitude: 0, Distance: 100 + i * 10));

        Assert.Equal(40, RideMetrics.TotalDistance(samples));
    }

    [Fact]
    public void MovingTime_SkipsPausesAndStops()
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
    public void Speed_WithoutSpeedValues_IsWorkedOutFromPositions()
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
    public void Compute_AveragesPowerHeartRateAndCadence_AndLeavesOutCoastingCadence()
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
    public void Compute_PrefersTheDevicesNormalizedPower()
    {
        var samples = Series(120, i => new Sample(i, Speed: 7, Power: 200));

        Assert.Equal(231, RideMetrics.Compute(samples, deviceNormalizedPowerW: 231).NormalizedPowerW);
        Assert.Equal(200, RideMetrics.Compute(samples).NormalizedPowerW);
    }

    [Fact]
    public void Pauses_ExcludeMovingTime_AveragesAndTheDistanceAcrossTheStop()
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
    public void DeviceTiming_IsPreferredWhenTheFileHasIt()
    {
        var samples = Series(10, i => new Sample(i, Speed: 5));

        var m = RideMetrics.Compute(samples, deviceElapsedS: 30, deviceMovingS: 20);

        Assert.Equal(30, m.ElapsedS);
        Assert.Equal(20, m.MovingS);
    }

    [Fact]
    public void Compute_RejectsARideWithFewerThanTwoSamples()
    {
        var error = Assert.Throws<RideParseException>(() => RideMetrics.Compute([new Sample(0)]));

        Assert.Equal("too_short", error.Code);
    }
}
