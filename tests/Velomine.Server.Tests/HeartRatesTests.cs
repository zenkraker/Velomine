using System.IO.Compression;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;
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
            .OrderByDescending(h => h.SetAt).ThenByDescending(h => h.Sequence)
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

        // The newest row is the one written last, even when the fixed clock does not tick between the two: the row
        // keeps its place among those written on the same instant.
        var rows = await HistoryAsync(api, member.Id);
        Assert.Equal(new[] { 194, 190 }, rows.Select(r => r.Bpm));
        Assert.Equal(new[] { 1, 0 }, rows.Select(r => r.Sequence));
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

    /// <summary>A clock that ticks a second per read, so the two writes have instants of their own.</summary>
    private sealed class TickingTime(DateTimeOffset now) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => now = now.AddSeconds(1);
    }

    [Fact]
    public async Task SetHeartRate_ShouldKeepTheOrder_WhenTheClockTicksBetweenTwoWrites()
    {
        await using var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new TickingTime(Now)));
        });
        var member = await api.NewMemberAsync();

        await SetAsync(member.Client, "max", 190);
        await SetAsync(member.Client, "max", 194);

        var rows = await HistoryAsync(api, member.Id);
        Assert.Equal(new[] { 194, 190 }, rows.Select(r => r.Bpm));
        // Each row keeps its own instant and its first place, because the clock moved on.
        Assert.Equal(new[] { 0, 0 }, rows.Select(r => r.Sequence));
        Assert.True(rows[0].SetAt > rows[1].SetAt);
    }

    [Fact]
    public async Task UpdateProfile_ShouldKeepTheMax_WhenOnlyAThresholdIsSent()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetAsync(member.Client, "max", 190);

        var saved = await member.Client.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Test Rider", null, null, null, null, "monday", ThresholdHeartRate: 170), Ct);

        Assert.Equal(HttpStatusCode.OK, saved.StatusCode);
        var profile = (await saved.Content.ReadFromJsonAsync<ProfileResponse>(Ct))!;
        Assert.Equal((190, 170), (profile.MaxHeartRate, profile.ThresholdHeartRate));
    }

    [Fact]
    public async Task UpdateProfile_ShouldKeepTheThreshold_WhenOnlyTheMaxIsSent()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await SetAsync(member.Client, "max", 190);
        await SetAsync(member.Client, "threshold", 170);

        var saved = await member.Client.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Test Rider", null, null, null, null, "monday", MaxHeartRate: 195), Ct);

        Assert.Equal(HttpStatusCode.OK, saved.StatusCode);
        var profile = (await saved.Content.ReadFromJsonAsync<ProfileResponse>(Ct))!;
        Assert.Equal((195, 170), (profile.MaxHeartRate, profile.ThresholdHeartRate));
    }

    [Fact]
    public async Task UpdateProfile_ShouldRefuse_WhenTheThresholdIsNotBelowTheMax()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        // Both arrive together: the maximum is applied first, so 180 is the maximum the threshold is judged against.
        var refused = await member.Client.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Test Rider", null, null, null, null, "monday",
                MaxHeartRate: 180, ThresholdHeartRate: 180), Ct);

        Assert.Equal(HttpStatusCode.BadRequest, refused.StatusCode);
        var profile = await member.Client.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);
        Assert.Null(profile!.MaxHeartRate);
        Assert.Empty(await HistoryAsync(api, member.Id));
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
        // A clock near the real one: a data-protection token's own expiry uses the system clock, so a clock far in
        // the past would make the export link look expired the moment it was made.
        await using var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new OffsetTime(DateTimeOffset.UtcNow)));
        });
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
    public void HeartRates_ShouldReturnMeasuredAndTheRide_WhenARideSetTheNumber()
    {
        var ride = Guid.NewGuid();
        var rider = Rider(maxBpm: 192, thresholdBpm: 171);
        rider.MaxHeartRateSource = HeartRateSources.Measured;
        rider.MaxHeartRateRideId = ride;
        rider.ThresholdHeartRateSource = HeartRateSources.Measured;
        rider.ThresholdHeartRateRideId = ride;

        var (max, threshold) = HeartRates.For(rider, new FixedTime(Now));

        Assert.Equal((192, HeartRateSources.Measured, ride), (max!.Bpm, max.Source, max.RideId));
        Assert.Equal((171, HeartRateSources.Measured, ride), (threshold!.Bpm, threshold.Source, threshold.RideId));
    }

    [Fact]
    public async Task Profile_ShouldSayMeasured_WhenTheHeartRateCameFromARide()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        // A steady 150 bpm is the only number there is, so this ride measures the maximum.
        var ride = await UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 600)));

        var profile = await member.Client.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);
        Assert.Equal((150, HeartRateSources.Measured, ride.Id),
            (profile!.MaxHeartRate, profile.MaxHeartRateSource, profile.MaxHeartRateRideId));

        // Every answer that carries the profile says the same, not only getProfile.
        var setFtp = await member.Client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(250), Ct);
        var afterFtp = (await setFtp.Content.ReadFromJsonAsync<ProfileResponse>(Ct))!;
        Assert.Equal((150, HeartRateSources.Measured, ride.Id),
            (afterFtp.MaxHeartRate, afterFtp.MaxHeartRateSource, afterFtp.MaxHeartRateRideId));
    }

    [Fact]
    public async Task HeartRateHistory_ShouldAgreeWithTheColumns_WhenTheNumberChanges()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        await SetAsync(member.Client, "max", 190);
        var typed = await UserAsync(api, member.Id);
        Assert.Equal((190, HeartRateSources.Manual, (Guid?)null),
            (typed.MaxHeartRateBpm, typed.MaxHeartRateSource, typed.MaxHeartRateRideId));
        var rows = await HistoryAsync(api, member.Id);
        Assert.Equal((190, HeartRateSources.Manual, (Guid?)null), (rows[0].Bpm, rows[0].Source, rows[0].RideId));

        await ClearAsync(member.Client, "max");
        var cleared = await UserAsync(api, member.Id);
        Assert.Equal((null, null, null), (cleared.MaxHeartRateBpm, cleared.MaxHeartRateSource, cleared.MaxHeartRateRideId));
        rows = await HistoryAsync(api, member.Id);
        Assert.Equal((190, HeartRateSources.Cleared), (rows[0].Bpm, rows[0].Source));

        // A ride measures it: the value, its source and the ride move together.
        var ride = await UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 600)));
        var measured = await UserAsync(api, member.Id);
        Assert.Equal((150, HeartRateSources.Measured, (Guid?)ride.Id),
            (measured.MaxHeartRateBpm, measured.MaxHeartRateSource, measured.MaxHeartRateRideId));
        rows = await HistoryAsync(api, member.Id);
        Assert.Equal((150, HeartRateSources.Measured, (Guid?)ride.Id), (rows[0].Bpm, rows[0].Source, rows[0].RideId));
    }

    [Fact]
    public async Task HeartRateHistory_ShouldAgreeWithTheColumns_WhenTheProfileIsSaved()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();

        var saved = await member.Client.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Test Rider", null, null, null, null, "monday",
                MaxHeartRate: 190, ThresholdHeartRate: 170), Ct);
        saved.EnsureSuccessStatusCode();

        var user = await UserAsync(api, member.Id);
        Assert.Equal((190, HeartRateSources.Manual, (Guid?)null),
            (user.MaxHeartRateBpm, user.MaxHeartRateSource, user.MaxHeartRateRideId));
        Assert.Equal((170, HeartRateSources.Manual, (Guid?)null),
            (user.ThresholdHeartRateBpm, user.ThresholdHeartRateSource, user.ThresholdHeartRateRideId));
        var rows = await HistoryAsync(api, member.Id);
        var max = rows.First(h => h.Kind == HeartRateKinds.Max);
        var threshold = rows.First(h => h.Kind == HeartRateKinds.Threshold);
        Assert.Equal((190, HeartRateSources.Manual, (Guid?)null), (max.Bpm, max.Source, max.RideId));
        Assert.Equal((170, HeartRateSources.Manual, (Guid?)null), (threshold.Bpm, threshold.Source, threshold.RideId));
    }

    [Fact]
    public async Task HeartRate_ShouldStayMeasured_WhenTheRideWasDeleted()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        var ride = await UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 600)));

        Assert.Equal(HttpStatusCode.NoContent,
            (await member.Client.DeleteAsync($"/api/v1/rides/{ride.Id}", Ct)).StatusCode);

        var profile = await member.Client.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);
        Assert.Equal((150, HeartRateSources.Measured), (profile!.MaxHeartRate, profile.MaxHeartRateSource));
        Assert.Null(profile.MaxHeartRateRideId);
    }

    [Fact]
    public async Task AccountDeletion_ShouldDeleteAMember_WhenTheHeartRateCameFromARide()
    {
        await using var api = await StartAsync();
        var member = await api.NewMemberAsync();
        await UploadAndWaitAsync(member.Client, Fit(new FitSession(Start, 600)));
        Assert.Equal(HeartRateSources.Measured, (await UserAsync(api, member.Id)).MaxHeartRateSource);

        var deleted = await member.Client.PostAsJsonAsync(
            "/api/v1/accounts/me/delete", new DeleteMyAccountRequest(TestApi.MemberPassword, null), Ct);

        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        // The number, its history and the account itself are gone, not only answered 204.
        Assert.False(await db.Users.AnyAsync(u => u.Id == member.Id, Ct));
        Assert.False(await db.HeartRateHistory.AnyAsync(h => h.UserId == member.Id, Ct));
        Assert.False(await db.Rides.AnyAsync(r => r.UserId == member.Id, Ct));
    }

    private static async Task<User> UserAsync(TestApi api, Guid userId)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        return await db.Users.AsNoTracking().FirstAsync(u => u.Id == userId, Ct);
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

    [Fact]
    public async Task AccountExport_ShouldShowTheSourceAndTheRide_WhenARideMeasuredTheHeartRate()
    {
        // A clock near the real one: a data-protection token's own expiry uses the system clock.
        await using var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new OffsetTime(DateTimeOffset.UtcNow)));
        });
        var me = await api.NewMemberAsync("Ada");
        var yesterday = new DateTimeOffset(DateTimeOffset.UtcNow.Date.AddDays(-1).AddHours(10), TimeSpan.Zero);
        var ride = await UploadAndWaitAsync(me.Client, Fit(new FitSession(yesterday.UtcDateTime, 600)));
        Assert.Equal(HeartRateSources.Measured, (await UserAsync(api, me.Id)).MaxHeartRateSource);

        var requested = await me.Client.PostAsync("/api/v1/accounts/me/export-link", null, Ct);
        Assert.Equal(HttpStatusCode.OK, requested.StatusCode);
        var link = (await requested.Content.ReadFromJsonAsync<ExportLinkResponse>(Ct))!.Path;
        var download = await api.CreateClient().GetAsync(link, Ct);
        download.EnsureSuccessStatusCode();

        using var zip = new ZipArchive(await download.Content.ReadAsStreamAsync(Ct), ZipArchiveMode.Read);
        using var stream = zip.GetEntry("profile.json")!.Open();
        using var document = await JsonDocument.ParseAsync(stream, cancellationToken: Ct);
        var max = document.RootElement.GetProperty("heartRate").GetProperty("max");
        Assert.Equal(150, max.GetProperty("bpm").GetInt32());
        Assert.Equal(HeartRateSources.Measured, max.GetProperty("source").GetString());
        Assert.Equal(ride.Id, max.GetProperty("rideId").GetGuid());
    }

    [Fact]
    public async Task HeartRateSourceMigration_ShouldBackfillTheSource_WhenTheNewestRowMatchesTheNumber()
    {
        var connection = await postgres.CreateDatabaseAsync();
        static VelomineDbContext Db(string connection) =>
            new(new DbContextOptionsBuilder<VelomineDbContext>().UseNpgsql(connection).Options);

        // The database as it was before this migration: four members, their numbers and the history of each.
        const string insertUser = """
            INSERT INTO accounts.users (id, display_name, user_name, is_approved, email_confirmed,
                phone_number_confirmed, two_factor_enabled, lockout_enabled, access_failed_count, created_at,
                max_heart_rate_bpm, threshold_heart_rate_bpm)
            VALUES ({0}, {1}, {2}, true, true, false, false, true, 0, now(),
                NULLIF({3}, '')::integer, NULLIF({4}, '')::integer)
            """;
        const string insertRide = """
            INSERT INTO rides.rides (id, user_id, status, file_sha256, file_name, uploaded_at, parser_version)
            VALUES ({0}, {1}, 'Ready', repeat('a', 64), 'ride.fit', now(), 1)
            """;
        const string insertMeasured = """
            INSERT INTO accounts.heart_rate_history (id, user_id, kind, bpm, set_at, sequence, source, ride_id)
            VALUES (gen_random_uuid(), {0}, {1}, {2}, {3}, 0, 'measured', {4})
            """;
        const string insertCleared = """
            INSERT INTO accounts.heart_rate_history (id, user_id, kind, bpm, set_at, sequence, source, ride_id)
            VALUES (gen_random_uuid(), {0}, {1}, {2}, {3}, 0, 'cleared', NULL)
            """;

        var ada = Guid.NewGuid();
        var grace = Guid.NewGuid();
        var linus = Guid.NewGuid();
        var barbara = Guid.NewGuid();
        var adaRide = Guid.NewGuid();
        var graceRide = Guid.NewGuid();
        var now = DateTimeOffset.UtcNow;

        await using (var before = Db(connection))
        {
            await before.Database.MigrateAsync("20261118201454_LearnHeartRateFromRides", Ct);
            await before.Database.ExecuteSqlRawAsync(insertUser, [ada, "Ada", "ada@test.local", "195", ""], Ct);
            await before.Database.ExecuteSqlRawAsync(insertUser, [grace, "Grace", "grace@test.local", "190", ""], Ct);
            await before.Database.ExecuteSqlRawAsync(insertUser, [linus, "Linus", "linus@test.local", "", "170"], Ct);
            await before.Database.ExecuteSqlRawAsync(insertUser, [barbara, "Barbara", "barbara@test.local", "188", ""], Ct);
            await before.Database.ExecuteSqlRawAsync(insertRide, [adaRide, ada], Ct);
            await before.Database.ExecuteSqlRawAsync(insertRide, [graceRide, grace], Ct);

            // Ada's newest row matches her number and came from a ride; the cleared row before it does not count.
            await before.Database.ExecuteSqlRawAsync(insertCleared,
                [ada, HeartRateKinds.Max, 180, now.AddDays(-10)], Ct);
            await before.Database.ExecuteSqlRawAsync(insertMeasured,
                [ada, HeartRateKinds.Max, 195, now.AddDays(-2), adaRide], Ct);
            // Grace's measured row holds a number she no longer has.
            await before.Database.ExecuteSqlRawAsync(insertMeasured,
                [grace, HeartRateKinds.Max, 185, now.AddDays(-1), graceRide], Ct);
            // Linus cleared his threshold, so it is typed now; Barbara never had a history row at all.
            await before.Database.ExecuteSqlRawAsync(insertCleared,
                [linus, HeartRateKinds.Threshold, 170, now.AddDays(-1)], Ct);
        }

        NpgsqlConnection.ClearAllPools();
        await using (var after = Db(connection))
        {
            await after.Database.MigrateAsync(Ct);
            var users = await after.Users.AsNoTracking().ToDictionaryAsync(u => u.DisplayName, Ct);

            Assert.Equal((195, HeartRateSources.Measured, (Guid?)adaRide),
                (users["Ada"].MaxHeartRateBpm, users["Ada"].MaxHeartRateSource, users["Ada"].MaxHeartRateRideId));
            Assert.Equal((190, HeartRateSources.Manual, (Guid?)null),
                (users["Grace"].MaxHeartRateBpm, users["Grace"].MaxHeartRateSource, users["Grace"].MaxHeartRateRideId));
            Assert.Equal((170, HeartRateSources.Manual, (Guid?)null),
                (users["Linus"].ThresholdHeartRateBpm, users["Linus"].ThresholdHeartRateSource, users["Linus"].ThresholdHeartRateRideId));
            Assert.Equal((188, HeartRateSources.Manual, (Guid?)null),
                (users["Barbara"].MaxHeartRateBpm, users["Barbara"].MaxHeartRateSource, users["Barbara"].MaxHeartRateRideId));
            Assert.Null(users["Ada"].ThresholdHeartRateSource);
            Assert.Null(users["Grace"].ThresholdHeartRateSource);
            Assert.Null(users["Barbara"].ThresholdHeartRateSource);
            Assert.Null(users["Linus"].MaxHeartRateSource);
        }
    }
}
