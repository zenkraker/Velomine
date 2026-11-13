using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Tests.Rides;

/// <summary>
/// The edges of "the same ride from another app": 60 s of elapsed time, 200 m or 2 % of distance, whichever is
/// larger. One second or one metre either side of each, so a change to a limit fails here.
/// </summary>
public sealed class RideMatchBoundaryTests
{
    [Theory]
    [InlineData(0)]
    [InlineData(30)]
    [InlineData(60)] // 60 s apart is still the same ride: the limit is inclusive
    public void SameRide_ShouldBeTheSameRide_WhenTheElapsedTimeIsWithinTheLimit(double secondsApart) =>
        Assert.True(RideMatch.SameRide(3600, 40_000, 3600 + secondsApart, 40_000));

    [Theory]
    [InlineData(61)]
    [InlineData(120)]
    public void SameRide_ShouldNotBeTheSameRide_WhenTheElapsedTimeIsPastTheLimit(double secondsApart) =>
        Assert.False(RideMatch.SameRide(3600, 40_000, 3600 + secondsApart, 40_000));

    [Theory]
    [InlineData(0)]
    [InlineData(199)]
    [InlineData(200)] // 200 m is inside the tolerance
    public void SameRide_ShouldBeTheSameRide_WhenTheDistanceIsWithinTwoHundredMetres(double metresApart) =>
        // A 5 km ride: 2 % is 100 m, so the fixed 200 m is the larger tolerance that applies.
        Assert.True(RideMatch.SameRide(3600, 5_000, 3600, 5_000 + metresApart));

    [Theory]
    [InlineData(201)]
    [InlineData(500)]
    public void SameRide_ShouldNotBeTheSameRide_WhenTheDistanceIsPastTwoHundredMetres(double metresApart) =>
        Assert.False(RideMatch.SameRide(3600, 5_000, 3600, 5_000 + metresApart));

    [Theory]
    [InlineData(19_800)] // 200 m under: exactly at 2 % of 20 km
    [InlineData(20_000)]
    [InlineData(20_200)] // 200 m over
    public void SameRide_ShouldUseTwoPercent_WhenTheRideIsLongEnoughToMakeItTheLargerTolerance(double otherDistance) =>
        // 20 km: 2 % is 400 m, so 200 m apart is well inside and 399 m is the real edge.
        Assert.True(RideMatch.SameRide(3600, 20_000, 3600, otherDistance));

    [Theory]
    [InlineData(19_600)] // 400 m under: exactly 2 % of 20 km, counted in both directions
    [InlineData(20_407)] // 407 m over: inside 2 % of the larger distance, 20 407 m, which is 408 m
    [InlineData(20_409)] // 409 m over: outside it
    public void SameRide_ShouldUseTwoPercentOfTheLargerDistance_WhenTheRideIsTwentyKilometres(double otherDistance)
    {
        // 20 km is long enough that 2 % (400 m, and 408 m for the longer copy) beats the fixed 200 m.
        var same = RideMatch.SameRide(3600, 20_000, 3600, otherDistance);

        Assert.Equal(Math.Abs(20_000 - otherDistance) <= Math.Max(20_000, otherDistance) * 0.02, same);
    }

    [Fact]
    public void SameRide_ShouldCompareAgainstTheLargerTwoPercent_WhenTheCopyIsLonger() =>
        // 400 m apart on a 20 km ride is at the edge; the same 400 m on a 5 km ride is 8 % and far outside.
        Assert.True(RideMatch.SameRide(3600, 20_000, 3600, 20_400));

    [Fact]
    public void SameRide_ShouldIgnoreTheDistance_WhenEitherFileHasNone() =>
        // An indoor ride has no distance; the elapsed time alone decides.
        Assert.True(RideMatch.SameRide(1800, null, 1830, 20_000));

    [Fact]
    public void SameRide_ShouldNotBeTheSameRide_WhenTheOtherRideHasNoElapsedTime() =>
        Assert.False(RideMatch.SameRide(1800, 20_000, null, 20_000));
}
