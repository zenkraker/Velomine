using System.Net;
using System.Net.Http.Json;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

[Collection("postgres")]
public sealed class TelemetryTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() =>
        TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static async Task<(HttpClient Client, string Email)> NewMemberAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        return (await api.SignedInClientAsync(email, TestApi.MemberPassword), email);
    }

    [Fact]
    public async Task Telemetry_ShouldBeOff_WhenTheMemberHasNotChosen()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);

        var telemetry = await client.GetFromJsonAsync<TelemetryResponse>("/api/v1/accounts/me/telemetry", Ct);
        var me = await client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);

        Assert.NotNull(telemetry);
        Assert.True(telemetry.ConsentRequired);
        Assert.False(telemetry.Crash);
        Assert.False(telemetry.Usage);
        Assert.True(me!.TelemetryConsentRequired);
        Assert.False(me.TelemetryCrash);
        Assert.False(me.TelemetryUsage);
    }

    [Fact]
    public async Task Telemetry_ShouldStoreTheChoice_WhenTheMemberOptsIn()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);

        var saved = await client.PutAsJsonAsync(
            "/api/v1/accounts/me/telemetry",
            new SetTelemetryRequest(Crash: true, Usage: false),
            Ct);
        var telemetry = await client.GetFromJsonAsync<TelemetryResponse>("/api/v1/accounts/me/telemetry", Ct);

        Assert.Equal(HttpStatusCode.OK, saved.StatusCode);
        Assert.False(telemetry!.ConsentRequired);
        Assert.True(telemetry.Crash);
        Assert.False(telemetry.Usage);
    }

    [Fact]
    public async Task Telemetry_ShouldStop_WhenTheMemberOptsOut()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);

        (await client.PutAsJsonAsync("/api/v1/accounts/me/telemetry", new SetTelemetryRequest(true, true), Ct))
            .EnsureSuccessStatusCode();
        (await client.PutAsJsonAsync("/api/v1/accounts/me/telemetry", new SetTelemetryRequest(false, false), Ct))
            .EnsureSuccessStatusCode();

        var telemetry = await client.GetFromJsonAsync<TelemetryResponse>("/api/v1/accounts/me/telemetry", Ct);
        var me = await client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);

        Assert.False(telemetry!.ConsentRequired);
        Assert.False(telemetry.Crash);
        Assert.False(telemetry.Usage);
        Assert.False(me!.TelemetryCrash);
        Assert.False(me.TelemetryUsage);
    }

    [Fact]
    public async Task Telemetry_ShouldRequireSignIn_WhenRequestedAnonymously()
    {
        await using var api = await StartAsync();

        var response = await api.CreateClient().GetAsync("/api/v1/accounts/me/telemetry", Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Telemetry_ShouldNotCrossTenants_WhenTwoClubsAreConfigured()
    {
        await using var one = await StartAsync();
        await using var two = await StartAsync();
        var (mine, _) = await NewMemberAsync(one);
        var (theirs, _) = await NewMemberAsync(two);

        (await mine.PutAsJsonAsync("/api/v1/accounts/me/telemetry", new SetTelemetryRequest(true, true), Ct))
            .EnsureSuccessStatusCode();
        var other = await theirs.GetFromJsonAsync<TelemetryResponse>("/api/v1/accounts/me/telemetry", Ct);

        Assert.True(other!.ConsentRequired);
        Assert.False(other.Crash);
        Assert.False(other.Usage);
    }
}
