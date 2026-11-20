using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Sharing;
using Velomine.Server.Tests.Routes;

namespace Velomine.Server.Tests;

public sealed class ProfileTests(PostgresFixture postgres) : IAsyncLifetime
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    // Row after row asks the same question; they share one server and one member, and every row only sends a refused
    // profile update, so nothing a later row reads changes.
    private TestApi? shared;
    private HttpClient? member;

    public async ValueTask InitializeAsync()
    {
        shared = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            // A known date, so the estimated maximum heart rate is one number.
            b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(new DateTimeOffset(2026, 11, 13, 12, 0, 0, TimeSpan.Zero))));
        });
        var email = TestApi.NewEmail();
        (await shared.RegisterAsync(email, name: "Ada")).EnsureSuccessStatusCode();
        member = await shared.SignedInClientAsync(email, TestApi.MemberPassword);
    }

    public async ValueTask DisposeAsync()
    {
        if (shared is not null) await shared.DisposeAsync();
    }

    private async Task<(TestApi Api, HttpClient Member)> StartAsync()
    {
        var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            // A known date, so the estimated maximum heart rate is one number.
            b.ConfigureTestServices(s => s.AddSingleton<TimeProvider>(new FixedTime(new DateTimeOffset(2026, 11, 13, 12, 0, 0, TimeSpan.Zero))));
        });
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email, name: "Ada")).EnsureSuccessStatusCode();
        return (api, await api.SignedInClientAsync(email, TestApi.MemberPassword));
    }

    [Fact]
    public async Task Profile_ShouldBeEmptyWithMondayWeeks_WhenTheAccountIsNew()
    {
        var (api, member) = await StartAsync();
        await using var _ = api;

        var profile = await member.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);

        Assert.Equal(new ProfileResponse("Ada", null, null, null, null, null, "monday", true, true, true, false, null), profile! with { SoloTrialEndsAt = null });
        Assert.NotNull(profile.SoloTrialEndsAt); // the trial started at sign-up
    }

    [Fact]
    public async Task Profile_ShouldUpdateAndClear_WhenTheMemberChangesIt()
    {
        var (api, member) = await StartAsync();
        await using var _ = api;

        var put = await member.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Ada L", 265, 68.04, 1990, "Europe/Rome", "sunday"), Ct);
        Assert.Equal(HttpStatusCode.OK, put.StatusCode);
        Assert.Equal(
            // 183 is Tanaka for a 1990 birth year on the pinned 2026-11-13 clock, and 163 is 89 % of it; the trial
            // ends 30 days later. Setting the FTP starts its history: the same pinned clock is when it was set, by the
            // rider.
            new ProfileResponse(
                "Ada L", 265, 68.0, 1990, 183, "Europe/Rome", "sunday", true, true, true, false, new DateOnly(2026, 12, 13),
                new DateTimeOffset(2026, 11, 13, 12, 0, 0, TimeSpan.Zero), "manual",
                MaxHeartRateSource: "estimate", ThresholdHeartRate: 163, ThresholdHeartRateSource: "estimate"),
            await put.Content.ReadFromJsonAsync<ProfileResponse>(Ct));

        await member.PutAsJsonAsync("/api/v1/accounts/me/profile", new UpdateProfileRequest("Ada L", null, null, null, null, "monday"), Ct);
        var cleared = await member.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);
        // No birth year and no typed maximum, so neither number exists.
        Assert.Equal(
            new ProfileResponse("Ada L", null, null, null, null, null, "monday", true, true, true, false, new DateOnly(2026, 12, 13)),
            cleared);

        var me = await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);
        Assert.Equal("Ada L", me!.DisplayName); // the name is the same everywhere
    }

    [Fact]
    public async Task Profile_ShouldToggleEmailNotificationsAndKeepThem_WhenTheFieldIsLeftOut()
    {
        var (api, member) = await StartAsync();
        await using var _ = api;
        Assert.True((await member.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct))!.EmailNotifications);

        await member.PutAsJsonAsync("/api/v1/accounts/me/profile", new UpdateProfileRequest("Ada", null, null, null, null, "monday", false), Ct);
        Assert.False((await member.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct))!.EmailNotifications);

        // An older app that does not send the field changes nothing about it.
        await member.PutAsJsonAsync("/api/v1/accounts/me/profile", new UpdateProfileRequest("Ada B", null, null, null, null, "monday"), Ct);
        var after = await member.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);
        Assert.False(after!.EmailNotifications);
        Assert.Equal("Ada B", after.DisplayName);
    }

    [Fact]
    public async Task Profile_ShouldKeepTheEmailCategories_WhenTheAppDoesNotSendThem()
    {
        var (api, member) = await StartAsync();
        await using var _ = api;
        Assert.True((await member.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct))!.EmailAccountNotifications);
        Assert.False((await member.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct))!.EmailTrainingNotifications);

        await member.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Ada", null, null, null, null, "monday", EmailAccountNotifications: false, EmailTrainingNotifications: true),
            Ct);
        var changed = await member.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);
        Assert.False(changed!.EmailAccountNotifications);
        Assert.True(changed.EmailTrainingNotifications);

        // An older app that does not send the fields changes nothing about them.
        await member.PutAsJsonAsync("/api/v1/accounts/me/profile", new UpdateProfileRequest("Ada B", null, null, null, null, "monday"), Ct);
        var after = await member.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);
        Assert.False(after!.EmailAccountNotifications);
        Assert.True(after.EmailTrainingNotifications);
    }

    [Theory]
    [InlineData("", null, null, null, null, "monday")]
    [InlineData("Ada", 5, null, null, null, "monday")]
    [InlineData("Ada", null, 5.0, null, null, "monday")]
    [InlineData("Ada", null, null, 1800, null, "monday")]
    [InlineData("Ada", null, null, 3000, null, "monday")]
    [InlineData("Ada", null, null, null, "Mars/Olympus", "monday")]
    [InlineData("Ada", null, null, null, null, "someday")]
    [InlineData("Ada", null, null, null, null, "1")]
    public async Task Profile_ShouldRejectTheUpdate_WhenTheValuesAreInvalid(string name, int? ftp, double? weight, int? birthYear, string? zone, string firstDay)
    {
        var put = await member!.PutAsJsonAsync("/api/v1/accounts/me/profile", new UpdateProfileRequest(name, ftp, weight, birthYear, zone, firstDay), Ct);

        Assert.Equal(HttpStatusCode.BadRequest, put.StatusCode);
    }

    [Fact]
    public async Task Language_ShouldBeKeptOnTheAccount_WhenSetFromAnotherDevice()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email, name: "Ada")).EnsureSuccessStatusCode();

        var first = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        var put = await first.PutAsJsonAsync("/api/v1/accounts/me/language", new SetMyLanguageRequest { Language = "it" }, Ct);
        Assert.Equal(HttpStatusCode.OK, put.StatusCode);

        // A second device signs in with the same account and sees the same choice.
        var second = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        Assert.Equal("it", (await second.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Language);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            (await second.PutAsJsonAsync("/api/v1/accounts/me/language", new SetMyLanguageRequest { Language = "not a code" }, Ct)).StatusCode);

        await second.PutAsJsonAsync("/api/v1/accounts/me/language", new SetMyLanguageRequest { Language = null }, Ct);
        Assert.Null((await second.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Language);
    }

    [Fact]
    public async Task Units_ShouldBeKeptOnTheAccount_WhenSetFromAnotherDevice()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email, name: "Ada")).EnsureSuccessStatusCode();

        var first = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        var put = await first.PutAsJsonAsync("/api/v1/accounts/me/units", new SetMyUnitsRequest("imperial"), Ct);
        Assert.Equal(HttpStatusCode.OK, put.StatusCode);

        // A second device signs in with the same account and sees the same choice.
        var second = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        Assert.Equal("imperial", (await second.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Units);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            (await second.PutAsJsonAsync("/api/v1/accounts/me/units", new SetMyUnitsRequest("furlongs"), Ct)).StatusCode);
    }

    [Fact]
    public async Task Units_ShouldBeMetric_WhenTheMemberNeverChose()
    {
        var (api, member) = await StartAsync();
        await using var _ = api;

        var me = await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);

        Assert.Equal("metric", me!.Units);
    }

    [Fact]
    public async Task SetMyRiderMode_ShouldSaveAndReturnMode_WhenSignedInOnAnotherDevice()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email, name: "Ada")).EnsureSuccessStatusCode();

        var first = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        var put = await first.PutAsJsonAsync("/api/v1/accounts/me/rider-mode", new SetMyRiderModeRequest(RiderModes.Training), Ct);
        Assert.Equal(HttpStatusCode.OK, put.StatusCode);
        Assert.Equal(RiderModes.Training, (await put.Content.ReadFromJsonAsync<MeResponse>(Ct))!.RiderMode);

        // A second device signs in with the same account and sees the same choice.
        var second = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        Assert.Equal(RiderModes.Training, (await second.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.RiderMode);
    }

    [Fact]
    public async Task SetMyRiderMode_ShouldAnswer400AndKeepOldMode_WhenModeIsUnknown()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email, name: "Ada")).EnsureSuccessStatusCode();
        var member = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        await member.PutAsJsonAsync("/api/v1/accounts/me/rider-mode", new SetMyRiderModeRequest(RiderModes.WithGoals), Ct);

        var refused = await member.PutAsJsonAsync("/api/v1/accounts/me/rider-mode", new SetMyRiderModeRequest("racer"), Ct);

        Assert.Equal(HttpStatusCode.BadRequest, refused.StatusCode);
        Assert.Equal(RiderModes.WithGoals, (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.RiderMode);
    }

    [Fact]
    public async Task GetMe_ShouldReturnNullRiderModeAndSupportedTrue_WhenMemberNeverChose()
    {
        var (api, member) = await StartAsync();
        await using var _ = api;

        var me = await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);

        Assert.Null(me!.RiderMode);
        Assert.True(me.RiderModeSupported);
    }

    [Fact]
    public async Task RiderMode_ShouldNotAppearInAnyOtherMembersView_WhenCoachOrClubMemberReadsTheRide()
    {
        await using var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var world = await RoutesTestKit.NewWorldAsync(api);
        var rideId = await RoutesTestKit.UploadRideAsync(world.Rider.Client);
        (await world.Rider.Client.PutAsJsonAsync("/api/v1/sharing",
            new UpdateSharingRequest { Rides = "coaches", Analytics = "coaches", Routes = "none", Wellbeing = "coaches" }, Ct)).EnsureSuccessStatusCode();
        (await world.Rider.Client.PutAsJsonAsync("/api/v1/accounts/me/rider-mode", new SetMyRiderModeRequest(RiderModes.Training), Ct)).EnsureSuccessStatusCode();

        var athlete = $"/api/v1/clubs/{world.Club.Id}/athletes/{world.Rider.Id}";
        foreach (var path in new[] { athlete, $"{athlete}/rides", $"{athlete}/rides/{rideId}", $"{athlete}/training", $"{athlete}/power-curve", $"{athlete}/wellbeing" })
        {
            var response = await world.Coach.Client.GetAsync(path, Ct);
            Assert.True(response.IsSuccessStatusCode, $"{path} answered {(int)response.StatusCode} to the athlete's coach.");
            Assert.DoesNotContain("riderMode", await response.Content.ReadAsStringAsync(Ct), StringComparison.OrdinalIgnoreCase);
        }

        // The coach's own account never carries the athlete's choice either.
        Assert.Null((await world.Coach.Client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.RiderMode);
    }

}
