using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Tests.Analytics;

public sealed class PowerBestsTests
{
    private static int IndexOf(int seconds) => Array.IndexOf(PowerBests.Durations, seconds);

    [Fact]
    public void PowerBests_ShouldFindTheBestWindow_WhenPowerSpikesInTheMiddle()
    {
        var power = new List<double>();
        power.AddRange(Enumerable.Repeat(100.0, 60));
        power.AddRange(Enumerable.Repeat(400.0, 5));
        power.AddRange(Enumerable.Repeat(100.0, 60));

        var best = PowerBests.Compute(power);

        Assert.Equal(400, best[IndexOf(1)]);
        Assert.Equal(400, best[IndexOf(5)]);
        Assert.Equal(125, best[IndexOf(60)]);
        Assert.Equal(112, best[IndexOf(120)]);
    }

    [Fact]
    public void PowerBests_ShouldReturnZero_WhenTheSeriesIsShorterThanTheWindow()
    {
        var best = PowerBests.Compute(Enumerable.Repeat(200.0, 30).ToList());

        Assert.Equal(200, best[IndexOf(30)]);
        Assert.Equal(0, best[IndexOf(60)]);
        Assert.Equal(0, best[IndexOf(1200)]);
    }

    [Fact]
    public void PowerBestsFromStreams_ShouldIgnorePauses_WhenTheGapIsLongerThanThirtySeconds()
    {
        var time = new List<double>();
        for (var i = 0; i < 10; i++) time.Add(i);
        for (var i = 0; i < 10; i++) time.Add(60 + i);
        var power = Enumerable.Repeat((short?)200, 20).ToArray();

        var best = PowerBests.FromStreams(power, time);

        Assert.Equal(200, best[IndexOf(5)]);
        Assert.Equal(0, best[IndexOf(15)]);
    }
}
