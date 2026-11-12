using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

[Collection("postgres")]
public sealed class ProfileTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private async Task<(TestApi Api, HttpClient Member)> StartAsync()
    {
        var api = await TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
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

        Assert.Equal(new ProfileResponse("Ada", null, null, null, null, null, "monday", true, true, true, false), profile);
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
            new ProfileResponse("Ada L", 265, 68.0, 1990, User.EstimateMaxHeartRate(1990), "Europe/Rome", "sunday", true, true, true, false),
            await put.Content.ReadFromJsonAsync<ProfileResponse>(Ct));

        await member.PutAsJsonAsync("/api/v1/accounts/me/profile", new UpdateProfileRequest("Ada L", null, null, null, null, "monday"), Ct);
        var cleared = await member.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);
        Assert.Equal(new ProfileResponse("Ada L", null, null, null, null, null, "monday", true, true, true, false), cleared);

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
        var (api, member) = await StartAsync();
        await using var _ = api;

        var put = await member.PutAsJsonAsync("/api/v1/accounts/me/profile", new UpdateProfileRequest(name, ftp, weight, birthYear, zone, firstDay), Ct);

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
    public async Task Units_ShouldBeUnauthorized_WhenNotSignedIn()
    {
        var (api, _) = await StartAsync();
        await using var __ = api;

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            (await api.CreateClient().PutAsJsonAsync("/api/v1/accounts/me/units", new SetMyUnitsRequest("imperial"), Ct)).StatusCode);
    }

    [Fact]
    public async Task Profile_ShouldBeUnauthorized_WhenNotSignedIn()
    {
        var (api, _) = await StartAsync();
        await using var __ = api;

        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync("/api/v1/accounts/me/profile", Ct)).StatusCode);
    }
}
