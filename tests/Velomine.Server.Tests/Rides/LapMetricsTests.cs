using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Tests.Rides;

public sealed class LapMetricsTests
{
    private static readonly Guid RideId = Guid.CreateVersion7();

    private static List<Sample> Samples(int seconds) =>
        [.. Enumerable.Range(0, seconds + 1).Select(i => new Sample(
            i,
            Speed: 8,
            Distance: i * 8f,
            HeartRate: 150,
            Power: 200,
            Cadence: 90,
            Altitude: 300))];

    [Fact]
    public void LapMetrics_ShouldLeavePausedTimeOutOfMovingTime_WhenTheLapHasAPause()
    {
        var lap = Assert.Single(LapMetrics.Build(
            RideId,
            [new ParsedLap(0, 30)],
            Samples(30),
            [new PauseInterval(5, 15)],
            ftpW: null,
            maxHeartRate: null));

        Assert.Equal(20, lap.MovingS);
        Assert.Equal(30, lap.DurationS);
    }

    [Fact]
    public void LapMetrics_ShouldCoverTheWholeRide_WhenTheLapsLeaveGapsAtTheEnds()
    {
        var lap = Assert.Single(LapMetrics.Build(
            RideId,
            [new ParsedLap(10, 20)],
            Samples(30),
            [],
            ftpW: null,
            maxHeartRate: null));

        Assert.Equal(0, lap.StartS);
        Assert.Equal(30, lap.EndS);
    }

    [Fact]
    public void LapMetrics_ShouldNumberTheLapsFromOne_WhenTheFileHasSeveral()
    {
        var laps = LapMetrics.Build(
            RideId,
            [new ParsedLap(0, 15), new ParsedLap(15, 30)],
            Samples(30),
            [],
            ftpW: null,
            maxHeartRate: null);

        Assert.Equal([1, 2], laps.Select(l => l.Index).ToArray());
    }
}
