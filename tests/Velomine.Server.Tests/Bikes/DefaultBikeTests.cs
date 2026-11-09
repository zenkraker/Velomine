using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Tests.Bikes;

public sealed class DefaultBikeTests
{
    private static Bike Make(string kind, bool isDefault = false) => new()
    {
        Id = Guid.CreateVersion7(),
        Name = kind,
        Kind = kind,
        IsDefault = isDefault,
        IsActive = true,
        WheelCircumferenceMm = 2100,
        CreatedAt = DateTimeOffset.UtcNow,
    };

    [Fact]
    public void DefaultBike_ShouldChooseTheEbike_WhenTheRideIsAssisted()
    {
        var road = Make("road", isDefault: true);
        var ebike = Make("ebike");

        var chosen = DefaultBike.For([road, ebike], Disciplines.Road, Assists.EBike, Environments.Outdoor, null);

        Assert.Equal(ebike.Id, chosen);
    }

    [Fact]
    public void DefaultBike_ShouldChooseTheMountainBike_WhenTheRideIsMountain()
    {
        var road = Make("road", isDefault: true);
        var mountain = Make("mountain");

        var chosen = DefaultBike.For([road, mountain], Disciplines.Mountain, Assists.None, Environments.Outdoor, null);

        Assert.Equal(mountain.Id, chosen);
    }

    [Fact]
    public void DefaultBike_ShouldChooseTheCityBike_WhenTheRideIsACommute()
    {
        var road = Make("road", isDefault: true);
        var city = Make("city");

        var chosen = DefaultBike.For([road, city], null, Assists.None, Environments.Outdoor, true);

        Assert.Equal(city.Id, chosen);
    }

    [Fact]
    public void DefaultBike_ShouldChooseTheDefaultOfTheKind_WhenSeveralBikesHaveIt()
    {
        var first = Make("road");
        var second = Make("road", isDefault: true);

        var chosen = DefaultBike.For([first, second], Disciplines.Road, Assists.None, Environments.Outdoor, null);

        Assert.Equal(second.Id, chosen);
    }

    [Fact]
    public void DefaultBike_ShouldFallBackToTheSingleDefault_WhenNoBikeOfThatKindExists()
    {
        var road = Make("road", isDefault: true);

        var chosen = DefaultBike.For([road], Disciplines.Mountain, Assists.None, Environments.Outdoor, null);

        Assert.Equal(road.Id, chosen);
    }

    [Fact]
    public void DefaultBike_ShouldUseTheSingleDefault_WhenTheRideIsIndoor()
    {
        var road = Make("road", isDefault: true);
        var mountain = Make("mountain");

        var chosen = DefaultBike.For([road, mountain], Disciplines.Mountain, Assists.None, Environments.Indoor, null);

        Assert.Equal(road.Id, chosen);
    }
}
