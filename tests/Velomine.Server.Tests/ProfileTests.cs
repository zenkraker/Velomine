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
    public async Task NewProfile_HasNothingSet_AndWeeksStartOnMonday()
    {
        var (api, member) = await StartAsync();
        await using var _ = api;

        var profile = await member.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);

        Assert.Equal(new ProfileResponse("Ada", null, null, null, null, "monday"), profile);
    }

    [Fact]
    public async Task ProfileCanBeChanged_AndCleared()
    {
        var (api, member) = await StartAsync();
        await using var _ = api;

        var put = await member.PutAsJsonAsync("/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Ada L", 265, 68.04, 188, "Europe/Rome", "sunday"), Ct);
        Assert.Equal(HttpStatusCode.OK, put.StatusCode);
        Assert.Equal(new ProfileResponse("Ada L", 265, 68.0, 188, "Europe/Rome", "sunday"), await put.Content.ReadFromJsonAsync<ProfileResponse>(Ct));

        await member.PutAsJsonAsync("/api/v1/accounts/me/profile", new UpdateProfileRequest("Ada L", null, null, null, null, "monday"), Ct);
        var cleared = await member.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct);
        Assert.Equal(new ProfileResponse("Ada L", null, null, null, null, "monday"), cleared);

        var me = await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);
        Assert.Equal("Ada L", me!.DisplayName); // the name is the same everywhere
    }

    [Theory]
    [InlineData("", null, null, null, null, "monday")]
    [InlineData("Ada", 5, null, null, null, "monday")]
    [InlineData("Ada", null, 5.0, null, null, "monday")]
    [InlineData("Ada", null, null, 300, null, "monday")]
    [InlineData("Ada", null, null, null, "Mars/Olympus", "monday")]
    [InlineData("Ada", null, null, null, null, "someday")]
    [InlineData("Ada", null, null, null, null, "1")]
    public async Task InvalidProfilesAreRejected(string name, int? ftp, double? weight, int? maxHr, string? zone, string firstDay)
    {
        var (api, member) = await StartAsync();
        await using var _ = api;

        var put = await member.PutAsJsonAsync("/api/v1/accounts/me/profile", new UpdateProfileRequest(name, ftp, weight, maxHr, zone, firstDay), Ct);

        Assert.Equal(HttpStatusCode.BadRequest, put.StatusCode);
    }

    [Fact]
    public async Task ProfileNeedsSignIn()
    {
        var (api, _) = await StartAsync();
        await using var __ = api;

        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync("/api/v1/accounts/me/profile", Ct)).StatusCode);
    }
}
