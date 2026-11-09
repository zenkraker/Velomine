using Dynastream.Fit;
using Velomine.Server.Features.Rides.Ingestion;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Rides;

public sealed class RideDimensionsTests
{
    [Theory]
    [InlineData(Sport.Cycling, SubSport.Generic, null, "none", "outdoor", null)]
    [InlineData(Sport.Cycling, SubSport.Road, "road", "none", "outdoor", null)]
    [InlineData(Sport.Cycling, SubSport.GravelCycling, "gravel", "none", "outdoor", null)]
    [InlineData(Sport.Cycling, SubSport.Mountain, "mountain", "none", "outdoor", null)]
    [InlineData(Sport.Cycling, SubSport.TrackCycling, "track", "none", "outdoor", null)]
    [InlineData(Sport.Cycling, SubSport.IndoorCycling, null, "none", "indoor", null)]
    [InlineData(Sport.Cycling, SubSport.VirtualActivity, null, "none", "virtual", null)]
    [InlineData(Sport.Cycling, SubSport.Commuting, null, "none", "outdoor", true)]
    [InlineData(Sport.EBiking, SubSport.EBikeMountain, "mountain", "ebike", "outdoor", null)]
    [InlineData(Sport.EBiking, SubSport.Generic, null, "ebike", "outdoor", null)]
    public void FitParser_ShouldReadTheDimensions_WhenTheSessionHasASubSport(
        Sport sport,
        SubSport subSport,
        string? discipline,
        string? assist,
        string? environment,
        bool? commute)
    {
        var ride = Assert.Single(RideFileParser.Parse(Fit(new FitSession(Start, 30, sport, SubSport: subSport))));

        Assert.Equal(discipline, ride.Discipline);
        Assert.Equal(assist, ride.Assist);
        Assert.Equal(environment, ride.Environment);
        Assert.Equal(commute, ride.Commute);
    }

    [Theory]
    [InlineData("road cycling", "road", null, "outdoor", null)]
    [InlineData("mountain biking", "mountain", null, "outdoor", null)]
    [InlineData("gravel", "gravel", null, "outdoor", null)]
    [InlineData("track cycling", "track", null, "outdoor", null)]
    [InlineData("e-bike commute", null, "ebike", "outdoor", true)]
    [InlineData("indoor trainer", null, null, "indoor", null)]
    [InlineData("virtual ride", null, null, "virtual", null)]
    public void GpxParser_ShouldReadTheDimensions_WhenTheTrackTypeSaysThem(
        string type,
        string? discipline,
        string? assist,
        string? environment,
        bool? commute)
    {
        var ride = Assert.Single(RideFileParser.Parse(Bytes(Gpx(30, type: type))));

        Assert.Equal(discipline, ride.Discipline);
        Assert.Equal(assist, ride.Assist);
        Assert.Equal(environment, ride.Environment);
        Assert.Equal(commute, ride.Commute);
    }

    [Fact]
    public void GpxParser_ShouldLeaveTheDimensionsUnset_WhenTheTrackHasNoType()
    {
        var ride = Assert.Single(RideFileParser.Parse(Bytes(Gpx(30))));

        Assert.Null(ride.Discipline);
        Assert.Null(ride.Assist);
        Assert.Equal("outdoor", ride.Environment); // the points say where it happened
        Assert.Null(ride.Commute);
    }

    [Fact]
    public void TcxParser_ShouldMarkTheRideOutdoor_WhenTheTrackHasPositions()
    {
        var ride = Assert.Single(RideFileParser.Parse(Bytes(Tcx("Biking", 30))));

        Assert.Null(ride.Discipline);
        Assert.Null(ride.Assist);
        Assert.Equal("outdoor", ride.Environment);
        Assert.Null(ride.Commute);
    }
}
