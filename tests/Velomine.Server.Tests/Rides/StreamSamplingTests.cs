using Velomine.Server.Features.Rides;

namespace Velomine.Server.Tests.Rides;

public sealed class StreamSamplingTests
{
    private static RideStreams Ride(int n) => new()
    {
        RideId = Guid.NewGuid(),
        Time = [.. Enumerable.Range(0, n).Select(i => (double)i)],
        Latitude = [.. Enumerable.Range(0, n).Select(i => (double?)(46 + i * 0.00001))],
        Longitude = [.. Enumerable.Range(0, n).Select(_ => (double?)11.0)],
        Altitude = [.. Enumerable.Range(0, n).Select(i => (float?)(300 + i * 0.1f))],
        Speed = null,
        Distance = [.. Enumerable.Range(0, n).Select(i => (float?)(i * 8f))],
        HeartRate = [.. Enumerable.Range(0, n).Select(_ => (short?)150)],
        Power = [.. Enumerable.Range(0, n).Select(i => i % 2 == 0 ? (short?)100 : (short?)300)],
        Cadence = [.. Enumerable.Range(0, n).Select(i => i < n / 2 ? (short?)90 : null)],
        Temperature = null,
    };

    [Fact]
    public void StreamSampling_ShouldReturnTheSameRide_WhenItHasAtMostTheRequestedPoints()
    {
        var ride = Ride(100);

        Assert.Same(ride, StreamSampling.Reduce(ride, 100));
    }

    [Fact]
    public void StreamSampling_ShouldAverageDownToTheRequestedPoints_WhenTheRideIsLonger()
    {
        var reduced = StreamSampling.Reduce(Ride(1000), 100);

        Assert.Equal(100, reduced.Time.Length);
        Assert.Equal(100, reduced.Power!.Length);
        Assert.All(reduced.Power, p => Assert.Equal((short?)200, p)); // 100 and 300 alternate: every slice of 10 averages 200
        Assert.All(reduced.HeartRate!, p => Assert.Equal((short?)150, p));
        Assert.Equal(4.5, reduced.Time[0]); // the middle of seconds 0 to 9
        Assert.Equal(994.5, reduced.Time[^1]);
    }

    [Fact]
    public void StreamSampling_ShouldKeepTheLastDistanceOfEachSlice_WhenReducing()
    {
        var reduced = StreamSampling.Reduce(Ride(1000), 100);

        Assert.Equal(9 * 8f, reduced.Distance![0]);
        Assert.Equal(999 * 8f, reduced.Distance[^1]);
        Assert.Equal(reduced.Distance.OrderBy(d => d), reduced.Distance);
    }

    [Fact]
    public void StreamSampling_ShouldKeepMissingSignalsNull_WhenASliceHasNoValue()
    {
        var reduced = StreamSampling.Reduce(Ride(1000), 100);

        Assert.Equal((short?)90, reduced.Cadence![10]);
        Assert.Null(reduced.Cadence[90]); // the second half of the ride has no cadence
        Assert.Null(reduced.Speed);
        Assert.Null(reduced.Temperature);
    }

    [Fact]
    public void StreamSampling_ShouldKeepPositionsInOrder_WhenReducing()
    {
        var reduced = StreamSampling.Reduce(Ride(1000), 50);

        Assert.Equal(reduced.Latitude!.OrderBy(l => l), reduced.Latitude);
        Assert.InRange(reduced.Latitude![0]!.Value, 46.0, 46.0003);
    }
}
