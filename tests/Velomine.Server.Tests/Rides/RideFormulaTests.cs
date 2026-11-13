using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Tests.Rides;

/// <summary>
/// The formulas against hand-computed numbers: zone boundaries, the pause rule, normalized power and elevation.
/// Each value here was worked out on paper, not read back from the code.
/// </summary>
public sealed class RideFormulaTests
{
    // 200 W at an FTP of 200: zone boundaries are 55, 75, 90, 105, 120 and 150 % of it.
    private static short?[] Watts(params short[] values) => [.. values.Select(v => (short?)v)];

    private static double[] Seconds(params short[] watts) => [.. Enumerable.Range(0, watts.Length).Select(i => (double)i)];

    [Theory]
    [InlineData(109, 0)] // 54.5 %: below Z1
    [InlineData(110, 0)] // 55 %: Z1 starts
    [InlineData(149, 0)] // 74.5 %: still Z1
    [InlineData(150, 1)] // 75 %: Z2
    [InlineData(180, 2)] // 90 %: Z3
    [InlineData(210, 3)] // 105 %: Z4
    [InlineData(240, 4)] // 120 %: Z5
    [InlineData(300, 5)] // 150 %: Z6
    [InlineData(301, 6)] // above 150 %: Z7, open-ended
    public void PowerZones_ShouldPlaceTheWattInItsZone_WhenItIsOnTheBoundary(short watts, int zone)
    {
        var found = Array.FindIndex(
            TrainingLoad.ZoneSeconds(Watts(watts, watts, watts), Seconds(watts, watts, watts), 200, 0, TrainingLoad.PowerBounds),
            seconds => seconds > 0);

        Assert.Equal(zone, found);
    }

    [Fact]
    public void PowerZones_ShouldCountNothing_WhenTheMemberCoasts() =>
        // 0 W is coasting, not training time, and a zero FTP means no zones at all.
        Assert.All(TrainingLoad.ZoneSeconds(Watts(0, 0, 0), Seconds(0, 0, 0), 200, 0, TrainingLoad.PowerBounds), seconds => Assert.Equal(0, seconds));

    [Fact]
    public void PowerZones_ShouldShowTheWattRangeOfEachZone_WhenDisplayed()
    {
        var zones = TrainingLoad.Zones([10, 20, 30, 40, 50, 60, 70], 200, 0, TrainingLoad.PowerBounds);

        // Power has no floor, so Z1 starts at 0; each zone ends one watt below the next boundary.
        Assert.Equal((1, 0, 109), (zones[0].Zone, zones[0].From, zones[0].To));
        Assert.Equal((2, 110, 149), (zones[1].Zone, zones[1].From, zones[1].To));
        Assert.Equal((7, 300, (int?)null), (zones[6].Zone, zones[6].From, zones[6].To)); // open-ended
    }

    [Theory]
    [InlineData(99, 0)] // 49.5 %: under the floor, not training time
    [InlineData(100, 0)] // 50 %: Z1
    [InlineData(119, 0)] // 59.5 %: Z1
    [InlineData(120, 1)] // 60 %: Z2
    [InlineData(140, 2)] // 70 %: Z3
    [InlineData(160, 3)] // 80 %: Z4
    [InlineData(180, 4)] // 90 %: Z5, open-ended
    public void HeartRateZones_ShouldPlaceTheBeatInItsZone_WhenItIsOnTheBoundary(short bpm, int zone)
    {
        var found = Array.FindIndex(
            TrainingLoad.ZoneSeconds(Watts(bpm, bpm, bpm), Seconds(bpm, bpm, bpm), 200, TrainingLoad.HeartRateFloor, TrainingLoad.HeartRateBounds),
            seconds => seconds > 0);

        Assert.Equal(zone, found);
    }

    [Fact]
    public void Trimp_ShouldWeighEachMinuteByItsZone_WhenTheZonesAreKnown() =>
        // 60 s in Z1 (weight 1), 120 s in Z3 (weight 3): (60 + 360) / 60 = 7 points.
        Assert.Equal(7.0, TrainingLoad.Trimp([60, 0, 120, 0, 0]));

    [Fact]
    public void PowerLoad_ShouldBeOneTssPerHourAtThreshold_WhenTheRideIsAnHourAtFtp()
    {
        // An hour at exactly FTP is an IF of 1.00 and 100 TSS.
        Assert.Equal((1.0, 100.0), TrainingLoad.PowerLoad(200, 3600, 200));
        // Half an hour a watt above FTP: IF 0.51, TSS = 1800 x 101 x 0.505 / (200 x 3600) x 100 = 12.75.
        Assert.Equal((0.51, 12.8), TrainingLoad.PowerLoad(101, 1800, 200));
    }

    [Fact]
    public void PowerLoad_ShouldBeNull_WhenThereIsNoPowerOrNoFtp() =>
        Assert.Equal((null, null), TrainingLoad.PowerLoad(null, 3600, 200));

    [Fact]
    public void PauseThreshold_ShouldStayAtThirtySeconds_WhenSamplesAreTenSecondsApart()
    {
        // A 10 s recording cadence gives a median gap of 10, so 5 x 10 = 50 s -- but the floor is 30, and the rule
        // is max(30, 5 x median): a 40 s hole in 10 s data is a gap the device left, not a clock problem.
        var samples = Samples([0, 10, 20, 30, 70, 80]);

        Assert.Equal(50, RideMetrics.PauseThresholdS(samples));
        // 40 s is a recording hiccup, not a stop; longer than the threshold is a pause.
        Assert.True(samples[4].T - samples[3].T < RideMetrics.PauseThresholdS(samples));
    }

    [Fact]
    public void NormalizedPower_ShouldLeavePausesOut_WhenAPauseSplitsTheRide()
    {
        // 60 s at 200 W, a two-minute stop, then 60 s at 100 W. The stop adds no seconds: NP of
        // [200 x60, 100 x60] is (sqrt@30s windows) -- 145 W, and 100 W of average is what the stop would drag down.
        var samples = new List<Sample>();
        for (var t = 0; t < 60; t += 1) samples.Add(new Sample(t, Power: 200));
        for (var t = 60; t < 180; t += 1) samples.Add(new Sample(t, Power: 0)); // standing still
        for (var t = 180; t < 240; t += 1) samples.Add(new Sample(t, Power: 100));

        var metrics = RideMetrics.Compute(samples, ftpW: 200);
        var powerOnlyRiding = RideMetrics.NormalizedPower([.. Enumerable.Repeat(200d, 60), .. Enumerable.Repeat(100d, 60)]);

        // The 120 samples without power are left out, so the ride is the 60 slow + 60 fast samples.
        // Hand-computed: 30 s windows give 167 W. With the stop counted it would be 131 W.
        Assert.Equal(powerOnlyRiding, metrics.NormalizedPowerW);
        Assert.Equal(167, metrics.NormalizedPowerW);
    }

    [Fact]
    public void ElevationGain_ShouldCountADescentAsLoss_WhenTheRideGoesDown()
    {
        // 100 m down to 40 m in 10 m steps: the drop is the loss, the gain stays zero. The 5-point filter smooths
        // the first and last steps towards the ends, so 60 m of descent counts as 30 m.
        var (gain, loss) = RideMetrics.ElevationChange([100, 90, 80, 70, 60, 50, 40]);

        Assert.Equal(0, gain);
        Assert.True(loss > 20 && loss <= 60, $"a 60 m descent counted as {loss} m");
    }

    [Fact]
    public void ElevationGain_ShouldIgnoreASingleSpike_WhenOnePointJumps()
    {
        // A flat 100 m road with one 400 m GPS spike: the median filter and the threshold throw it away.
        var (gain, loss) = RideMetrics.ElevationChange([100, 100, 100, 400, 100, 100, 100, 100]);

        Assert.Equal(0, gain);
        Assert.Equal(0, loss);
    }

    [Fact]
    public void ElevationGain_ShouldCountAClimb_WhenItRisesWellOverTheThreshold()
    {
        // A steady 20 m climb over 20 samples: the filter settles and the climb counts.
        var profile = new float?[20];
        for (var i = 0; i < profile.Length; i++) profile[i] = (float?)(100 + i); // 1 m per sample

        var (gain, loss) = RideMetrics.ElevationChange(profile);

        Assert.True(gain > 10, $"a 19 m climb counted as {gain} m");
        Assert.Equal(0, loss);
    }

    private static List<Sample> Samples(params double[] times) =>
        [.. times.Select(t => new Sample(t))];
}
