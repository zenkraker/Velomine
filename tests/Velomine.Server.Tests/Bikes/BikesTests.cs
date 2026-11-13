using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Rides;
using Velomine.Server.Tests.Rides;

namespace Velomine.Server.Tests.Bikes;

public sealed class BikesTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static Task<HttpClient> NewMemberAsync(TestApi api) => api.NewMemberClientAsync();

    private static CreateBikeRequest NewBike(string name = "Road bike") =>
        new() { Name = name, Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 5_000_000 };

    private static async Task<BikeDetailResponse> AddBikeAsync(HttpClient client, CreateBikeRequest bike)
    {
        var response = await client.PostAsJsonAsync("/api/v1/bikes", bike, Ct);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct))!;
    }

    [Fact]
    public async Task Bikes_ShouldDefaultTheFirstBikeAndMoveTheDefault_WhenBikesAreAdded()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var first = await AddBikeAsync(member, NewBike("One"));
        var second = await AddBikeAsync(member, NewBike("Two"));
        Assert.True(first.Bike.IsDefault);
        Assert.False(second.Bike.IsDefault);
        Assert.Equal(5_000_000, first.Bike.DistanceM); // the distance it came with

        (await member.PostAsync($"/api/v1/bikes/{second.Bike.Id}/default", null, Ct)).EnsureSuccessStatusCode();

        var list = (await member.GetFromJsonAsync<ListBikesResponse>("/api/v1/bikes", Ct))!.Bikes;
        Assert.Equal(["Two"], list.Where(b => b.IsDefault).Select(b => b.Name));
        Assert.Equal("Two", list[0].Name); // default first
    }

    [Fact]
    public async Task Bikes_ShouldClearTheDefaultAndRefuseArchiveAsDefault_WhenArchived()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member, NewBike());

        var archive = new UpdateBikeRequest { Name = "Road bike", Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 0, IsActive = false };
        var put = await member.PutAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}", archive, Ct);
        Assert.Equal(HttpStatusCode.OK, put.StatusCode);
        var updated = await put.Content.ReadFromJsonAsync<BikeDetailResponse>(Ct);

        Assert.False(updated!.Bike.IsActive);
        Assert.False(updated.Bike.IsDefault);
        Assert.Equal(HttpStatusCode.BadRequest, (await member.PostAsync($"/api/v1/bikes/{bike.Bike.Id}/default", null, Ct)).StatusCode);
    }

    [Theory]
    [InlineData("", "road", 2105, 0)]
    [InlineData("Bike", "unicycle", 2105, 0)]
    [InlineData("Bike", "road", 500, 0)]
    [InlineData("Bike", "road", 2105, -1)]
    public async Task Bikes_ShouldRejectTheBike_WhenItsFieldsAreInvalid(string name, string kind, int wheel, double initial)
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var response = await member.PostAsJsonAsync("/api/v1/bikes", new CreateBikeRequest { Name = name, Kind = kind, WheelCircumferenceMm = wheel, InitialDistanceM = initial }, Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Bikes_ShouldBeNotFound_WhenBikeBelongsToAnotherMember()
    {
        await using var api = await StartAsync();
        var mine = await NewMemberAsync(api);
        var other = await NewMemberAsync(api);
        var bike = await AddBikeAsync(mine, NewBike());

        Assert.Equal(HttpStatusCode.NotFound, (await other.GetAsync($"/api/v1/bikes/{bike.Bike.Id}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PutAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}", new UpdateBikeRequest { Name = "x", Kind = "road", WheelCircumferenceMm = 2105, InitialDistanceM = 0 }, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.DeleteAsync($"/api/v1/bikes/{bike.Bike.Id}", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PostAsync($"/api/v1/bikes/{bike.Bike.Id}/default", null, Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/components", Chain(), Ct)).StatusCode);
        Assert.Empty((await other.GetFromJsonAsync<ListBikesResponse>("/api/v1/bikes", Ct))!.Bikes);
    }

    private static CreateComponentRequest Chain() =>
        new() { Type = "chain", InstalledOn = new DateOnly(2026, 1, 1), ExpectedDistanceM = 4_000_000 };

    [Fact]
    public async Task BikeComponents_ShouldSupportTheFullLifecycle_WhenManagedByTheOwner()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member, NewBike());
        var id = bike.Bike.Id;

        var added = await (await member.PostAsJsonAsync($"/api/v1/bikes/{id}/components", Chain(), Ct)).Content.ReadFromJsonAsync<BikeDetailResponse>(Ct);
        var chain = Assert.Single(added!.Components);
        Assert.Equal("Chain", chain.TypeName);
        Assert.Equal(0, chain.UsedDistanceM);

        var retire = new UpdateComponentRequest { Type = "chain", InstalledOn = new DateOnly(2026, 1, 1), RemovedOn = new DateOnly(2026, 2, 1) };
        var retired = await (await member.PutAsJsonAsync($"/api/v1/bikes/{id}/components/{chain.Id}", retire, Ct)).Content.ReadFromJsonAsync<BikeDetailResponse>(Ct);
        Assert.Equal("retired", Assert.Single(retired!.Components).Status);

        var bad = Chain();
        bad.Type = "flux_capacitor";
        Assert.Equal(HttpStatusCode.BadRequest, (await member.PostAsJsonAsync($"/api/v1/bikes/{id}/components", bad, Ct)).StatusCode);

        Assert.Equal(HttpStatusCode.NoContent, (await member.DeleteAsync($"/api/v1/bikes/{id}/components/{chain.Id}", Ct)).StatusCode);
        Assert.Empty((await member.GetFromJsonAsync<BikeDetailResponse>($"/api/v1/bikes/{id}", Ct))!.Components);
    }

    [Fact]
    public async Task BikeComponentTypes_ShouldListTheCatalogue_WhenRequested()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);

        var types = (await member.GetFromJsonAsync<ListComponentTypesResponse>("/api/v1/bikes/component-types", Ct))!.Types;

        var chain = Assert.Single(types, t => t.Id == "chain");
        Assert.Equal(4_000_000, chain.TypicalDistanceM);
    }

    [Fact]
    public async Task Bikes_ShouldAssignAndKeepRides_WhenRideIsImportedAndBikeDeleted()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var bike = await AddBikeAsync(member, NewBike());
        await member.PostAsJsonAsync($"/api/v1/bikes/{bike.Bike.Id}/components",
            new CreateComponentRequest { Type = "chain", InstalledOn = new DateOnly(2026, 10, 1), ExpectedDistanceM = 500 }, Ct);

        var ride = await UploadRideAsync(api, member);

        Assert.Equal(bike.Bike.Id, ride.BikeId);
        var detail = (await member.GetFromJsonAsync<BikeDetailResponse>($"/api/v1/bikes/{bike.Bike.Id}", Ct))!;
        Assert.Equal(1, detail.Bike.RideCount);
        Assert.Equal(5_000_000 + ride.DistanceM!.Value, detail.Bike.DistanceM, 1);
        Assert.Equal(ride.DistanceM.Value, detail.Components[0].UsedDistanceM, 1);
        Assert.Equal("worn", detail.Components[0].Status); // the sample ride is longer than 500 m

        Assert.Equal(HttpStatusCode.NoContent, (await member.DeleteAsync($"/api/v1/bikes/{bike.Bike.Id}", Ct)).StatusCode);
        Assert.Null((await member.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct))!.BikeId);
    }

    [Fact]
    public async Task RideBike_ShouldRejectOtherMembersBike_WhenChangingTheRideBike()
    {
        await using var api = await StartAsync();
        var member = await NewMemberAsync(api);
        var other = await NewMemberAsync(api);
        var mine = await AddBikeAsync(member, NewBike("Mine"));
        var theirs = await AddBikeAsync(other, NewBike("Theirs"));
        var ride = await UploadRideAsync(api, member);

        var none = await member.PutAsJsonAsync($"/api/v1/rides/{ride.Id}/bike", new SetRideBikeRequest { BikeId = null }, Ct);
        Assert.Null((await none.Content.ReadFromJsonAsync<RideResponse>(Ct))!.BikeId);

        var set = await member.PutAsJsonAsync($"/api/v1/rides/{ride.Id}/bike", new SetRideBikeRequest { BikeId = mine.Bike.Id }, Ct);
        Assert.Equal(mine.Bike.Id, (await set.Content.ReadFromJsonAsync<RideResponse>(Ct))!.BikeId);

        var stolen = await member.PutAsJsonAsync($"/api/v1/rides/{ride.Id}/bike", new SetRideBikeRequest { BikeId = theirs.Bike.Id }, Ct);
        Assert.Equal(HttpStatusCode.BadRequest, stolen.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await other.PutAsJsonAsync($"/api/v1/rides/{ride.Id}/bike", new SetRideBikeRequest { BikeId = theirs.Bike.Id }, Ct)).StatusCode);
    }

    private static async Task<RideResponse> UploadRideAsync(TestApi api, HttpClient client)
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(TestRideFiles.Fit(new TestRideFiles.FitSession(TestRideFiles.Start, 120))), "file", "ride.fit" } };
        var accepted = await client.PostAsync("/api/v1/rides/uploads", form, Ct);
        Assert.Equal(HttpStatusCode.Accepted, accepted.StatusCode);
        var id = (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        for (var i = 0; i < 100; i++)
        {
            var ride = (await client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{id}", Ct))!;
            if (ride.Status != "processing") return ride;
            await Task.Delay(100, Ct);
        }

        throw new TimeoutException();
    }
}
