using System.IO.Compression;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests;

/// <summary>
/// The two heart-rate numbers: each is the one the rider set, or an estimate from the age. Tanaka gives the maximum
/// (208 − 0.7 × age) and the threshold is 89 % of the maximum in use.
/// </summary>
public sealed class HeartRatesTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>A clock that always says the same day, so "this year" is known.</summary>
    private static readonly DateTimeOffset Now = new(2026, 11, 18, 9, 0, 0, TimeSpan.Zero);

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(Now)));
    });

    private static User Rider(int? birthYear = null, int? maxBpm = null, int? thresholdBpm = null) => new()
    {
        Id = Guid.NewGuid(),
        BirthYear = birthYear,
        MaxHeartRateBpm = maxBpm,
        ThresholdHeartRateBpm = thresholdBpm,
    };

    private static Task<HttpResponseMessage> SetAsync(HttpClient client, string kind, int bpm) =>
        client.PutAsJsonAsync($"/api/v1/accounts/me/heart-rate/{kind}", new SetHeartRateRequest(bpm), Ct);

    private static Task<HttpResponseMessage> ClearAsync(HttpClient client, string kind) =>
        client.DeleteAsync($"/api/v1/accounts/me/heart-rate/{kind}", Ct);

    private static async Task UpdateProfileAsync(HttpClient client, int? birthYear) =>
        (await client.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Test Rider", null, null, birthYear, null, "monday"), Ct)).EnsureSuccessStatusCode();

    private static async Task<List<HeartRateHistory>> HistoryAsync(TestApi api, Guid userId)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        return await db.HeartRateHistory.AsNoTracking()
            .Where(h => h.UserId == userId)
            .OrderByDescending(h => h.SetAt).ThenByDescending(h => h.Id.ToString())
            .ToListAsync(Ct);
    }

    [Fact]
    public void HeartRates_ShouldEstimateMaxFromAge_WhenNothingIsSet()
    {
        var (max, threshold) = HeartRates.For(Rider(birthYear: 1986), new FixedTime(Now));

        // Born 1986, today 2026: 208 − 0.7 × 28 = 180, and 89 % of it.
        Assert.Equal((180, FtpSources.Estimate), (max?.Bpm, max?.Source));
        Assert.Equal((160, FtpSources.Estimate), (threshold?.Bpm, threshold?.Source));
    }

    [Theory]
    [InlineData(180, 160)]
    [InlineData(192, 171)]
    public void HeartRates_ShouldEstimateThresholdFromMax_WhenOnlyMaxIsKnown(int maxBpm, int expected)
    {
        var (max, threshold) = HeartRates.For(Rider(maxBpm: maxBpm), new FixedTime(Now));

        Assert.Equal(maxBpm, max?.Bpm);
        Assert.Equal((expected, FtpSources.Estimate), (threshold?.Bpm, threshold?.Source));
    }

    [Fact]
    public void HeartRates_ShouldUseTheSetValues_WhenTheRiderTypedThem()
    {
        var (max, threshold) = HeartRates.For(
            Rider(birthYear: 1986, maxBpm: 191, thresholdBpm: 175), new FixedTime(Now));

        Assert.Equal((191, HeartRateSources.Manual), (max?.Bpm, max?.Source));
        Assert.Equal((175, HeartRateSources.Manual), (threshold?.Bpm, threshold?.Source));
    }

    [Fact]
    public void HeartRates_ShouldHaveNoNumbers_WhenThereIsNeitherABirthYearNorATypedMaximum()
    {
        var (max, threshold) = HeartRates.For(Rider(), new FixedTime(Now));

        Assert.Null(max);
        Assert.Null(threshold);
    }

    [Fact]
    public async Task SetHeartRate_ShouldWriteHistory_WhenTheValueChanges()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        var first = await SetAsync(member.Client, "max", 190);
        Assert.Equal(HttpStatusCode.OK, first.StatusCode);
        var profile = (await first.Content.ReadFromJsonAsync<ProfileResponse>(Ct))!;
        Assert.Equal((190, HeartRateSources.Manual), (profile.MaxHeartRate, profile.MaxHeartRateSource));
        Assert.Equal(Now, profile.MaxHeartRateSetAt);

        Assert.Equal(HttpStatusCode.OK, (await SetAsync(member.Client, "max", 194)).StatusCode);

        // The newest row is the one written last, even when the fixed clock does not tick between the two.
        var rows = await HistoryAsync(api, member.Id);
        Assert.Equal(new[] { 194, 190 }, rows.Select(r => r.Bpm));
        Assert.All(rows, r => Assert.Equal((HeartRateKinds.Max, HeartRateSources.Manual), (r.Kind, r.Source)));
    }

    [Fact]
    public async Task SetHeartRate_ShouldNotWriteHistory_WhenTheValueIsTheSame()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        await SetAsync(member.Client, "max", 190);
        Assert.Equal(HttpStatusCode.OK, (await SetAsync(member.Client, "max", 190)).StatusCode);

        Assert.Single(await HistoryAsync(api, member.Id));
    }

    [Fact]
    public async Task SetHeartRate_ShouldRefuse_WhenTheThresholdIsNotBelowTheMax()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        await SetAsync(member.Client, "max", 190);

        Assert.Equal(HttpStatusCode.BadRequest, (await SetAsync(member.Client, "threshold", 190)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await SetAsync(member.Client, "threshold", 200)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await SetAsync(member.Client, "threshold", 175)).StatusCode);
        Assert.Single(await HistoryAsync(api, member.Id), r => r.Kind == HeartRateKinds.Threshold);
    }

    [Fact]
    public async Task SetHeartRate_ShouldRefuse_WhenTheValueIsOutsideTheRange()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        Assert.Equal(HttpStatusCode.BadRequest, (await SetAsync(member.Client, "max", 110)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await SetAsync(member.Client, "threshold", 85)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await SetAsync(member.Client, "speed", 190)).StatusCode);
        Assert.Empty(await HistoryAsync(api, member.Id));
    }

    [Fact]
    public async Task ClearHeartRate_ShouldGoBackToTheEstimate_WhenCalled()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await UpdateProfileAsync(member.Client, birthYear: 1986);
        await SetAsync(member.Client, "max", 195);

        var cleared = await ClearAsync(member.Client, "max");

        Assert.Equal(HttpStatusCode.OK, cleared.StatusCode);
        var profile = (await cleared.Content.ReadFromJsonAsync<ProfileResponse>(Ct))!;
        Assert.Equal(180, profile.MaxHeartRate);
        Assert.Equal(FtpSources.Estimate, profile.MaxHeartRateSource);
        Assert.Null(profile.MaxHeartRateSetAt);
        // The threshold follows the maximum again.
        Assert.Equal(160, profile.ThresholdHeartRate);
        var row = Assert.Single(await HistoryAsync(api, member.Id), r => r.Source == HeartRateSources.Cleared);
        Assert.Equal(195, row.Bpm);
    }

    [Fact]
    public async Task ClearHeartRate_ShouldLeaveTheEstimateAlone_WhenNothingWasSet()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        Assert.Equal(HttpStatusCode.OK, (await ClearAsync(member.Client, "threshold")).StatusCode);
        Assert.Empty(await HistoryAsync(api, member.Id));
    }

    [Fact]
    public async Task HeartRate_ShouldNotBeVisible_WhenAnotherMemberAsks()
    {
        await using var api = await StartAsync();
        var me = await api.NewMemberAsync("Ada");
        var other = await api.NewMemberAsync("Grace");
        await SetAsync(me.Client, "max", 195);

        // The other member's profile keeps her own numbers, and the endpoints need a sign-in.
        var theirs = (await other.Client.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct))!;
        Assert.Null(theirs.MaxHeartRate);
        Assert.Empty(await HistoryAsync(api, other.Id));
        Assert.Equal(HttpStatusCode.Unauthorized,
            (await api.CreateClient().PutAsJsonAsync("/api/v1/accounts/me/heart-rate/max", new SetHeartRateRequest(195), Ct)).StatusCode);
    }

    [Fact]
    public async Task RideIngestion_ShouldUseTheTypedMax_WhenTheRiderSetOne()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // A steady 150 bpm: heart-rate zone 3 opens at 70 % of the maximum. Against 200 that is 140 bpm, so 150 is
        // 75 % — zone 3. Against the Tanaka estimate (201 without a birth year) it would only be 74 %, zone 2.
        Assert.Equal(HttpStatusCode.OK, (await SetAsync(member.Client, "max", 200)).StatusCode);

        var ride = await UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 600)));

        // Every interval but the last sample's: 599 of them, all in zone 3.
        Assert.Equal(599, ride.HeartRateZones!.Sum(z => z.Seconds), 0);
        Assert.Equal(599, ride.HeartRateZones![2].Seconds, 0);
    }

    [Fact]
    public async Task RideIngestion_ShouldUseTheEstimate_WhenTheRiderSetNoMax()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // Born 1986 in 2026: 180 bpm, so 150 bpm is 83 % of it, in zone 4.
        await UpdateProfileAsync(member.Client, birthYear: 1986);

        var ride = await UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 600)));

        Assert.Equal(599, ride.HeartRateZones!.Sum(z => z.Seconds), 0);
        Assert.Equal(599, ride.HeartRateZones![3].Seconds, 0);
    }

    private async Task<RideResponse> UploadAndWaitAsync(HttpClient client, byte[] file)
    {
        var accepted = await client.PostAsync("/api/v1/rides/uploads",
            new MultipartFormDataContent { { new ByteArrayContent(file), "file", "ride.fit" } }, Ct);
        Assert.Equal(HttpStatusCode.Accepted, accepted.StatusCode);
        var id = (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        return await TestApi.WaitForReadAsync(client, id);
    }

    [Fact]
    public async Task AccountExport_ShouldContainTheHeartRateHistory_WhenTheMemberHasIt()
    {
        await using var api = await StartAsync();
        var me = await api.NewMemberAsync("Ada");
        var other = await api.NewMemberAsync("Grace");
        await SetAsync(me.Client, "max", 190);
        await SetAsync(me.Client, "max", 194);
        await SetAsync(other.Client, "max", 200);

        var requested = await me.Client.PostAsync("/api/v1/accounts/me/export-link", null, Ct);
        Assert.Equal(HttpStatusCode.OK, requested.StatusCode);
        var link = (await requested.Content.ReadFromJsonAsync<ExportLinkResponse>(Ct))!.Path;
        var download = await api.CreateClient().GetAsync(link, Ct);
        download.EnsureSuccessStatusCode();

        using var zip = new ZipArchive(await download.Content.ReadAsStreamAsync(Ct), ZipArchiveMode.Read);
        using var stream = zip.GetEntry("heart-rate-history.json")!.Open();
        using var document = await JsonDocument.ParseAsync(stream, cancellationToken: Ct);
        var rows = document.RootElement.EnumerateArray().ToList();
        Assert.Equal(new[] { 190, 194 }, rows.Select(r => r.GetProperty("bpm").GetInt32())); // oldest first
        Assert.All(rows, r => Assert.Equal(HeartRateKinds.Max, r.GetProperty("kind").GetString()));
        Assert.All(rows, r => Assert.Equal(HeartRateSources.Manual, r.GetProperty("source").GetString()));
    }

    [Fact]
    public async Task AccountDeletion_ShouldRemoveTheHeartRateHistory_WhenTheAccountIsDeleted()
    {
        await using var api = await StartAsync();
        var me = await api.NewMemberAsync();
        await SetAsync(me.Client, "max", 190);

        var deleted = await me.Client.PostAsJsonAsync(
            "/api/v1/accounts/me/delete", new DeleteMyAccountRequest(TestApi.MemberPassword, null), Ct);

        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.False(await db.HeartRateHistory.AnyAsync(h => h.UserId == me.Id, Ct));
    }
}
