using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Tests.Rides;

public sealed class RideMatchTests
{
    [Fact]
    public void RideMatch_ShouldBeTheSameRide_WhenElapsedAndDistanceMatch()
    {
        Assert.True(RideMatch.SameRide(3600, 30000, 3605, 30100));
    }

    [Fact]
    public void RideMatch_ShouldNotBeTheSameRide_WhenTheElapsedTimeDiffers()
    {
        Assert.False(RideMatch.SameRide(3600, 30000, 3700, 30000));
    }

    [Fact]
    public void RideMatch_ShouldNotBeTheSameRide_WhenTheDistanceDiffers()
    {
        Assert.False(RideMatch.SameRide(3600, 30000, 3600, 31500));
    }

    [Fact]
    public void RideMatch_ShouldBeTheSameRide_WhenNeitherFileHasADistance()
    {
        Assert.True(RideMatch.SameRide(1800, null, 1800, null));
        Assert.True(RideMatch.SameRide(1800, 0, 1800, 0));
    }

    [Fact]
    public void RideMatch_ShouldNotBeTheSameRide_WhenTheOtherRideHasNoElapsedTime()
    {
        Assert.False(RideMatch.SameRide(1800, 10000, null, 10000));
    }
}
