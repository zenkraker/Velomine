using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Demo;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;
using Velomine.Server.Features.Server;

namespace Velomine.Server.Tests.Demo;

public sealed class DemoTests(PostgresFixture postgres)
{
    private const string Rider = "demo-rider@velomine.eu";

    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartDemoAsync(TimeProvider? time = null) => TestApi.StartAsync(postgres, b =>
    {
        b.UseSetting("Velomine:Demo:Enabled", "true");
        if (time is not null) b.ConfigureTestServices(services => services.AddSingleton(time));
    });

    private static async Task ResetAsync(TestApi api)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<DemoData>().ResetAsync(Ct);
    }

    [Fact]
    public async Task ServerInfo_ShouldSayItIsADemo_WhenDemoModeIsOn()
    {
        await using var demo = await StartDemoAsync();
        await using var plain = await TestApi.StartAsync(postgres);

        var onDemo = await demo.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", Ct);
        var onPlain = await plain.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", Ct);

        Assert.True(onDemo!.Demo);
        Assert.False(onPlain!.Demo);
    }

    [Fact]
    public async Task DemoData_ShouldMakeTheAccountsTheClubAndTheirRides_WhenTheDemoIsReset()
    {
        await using var api = await StartDemoAsync();

        await ResetAsync(api);

        foreach (var account in DemoData.Accounts)
        {
            var client = await api.SignedInClientAsync(account.Email, DemoData.Password);
            var me = await client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);
            Assert.Equal(account.DisplayName, me!.DisplayName);
            Assert.DoesNotContain(Roles.Admin, me.Roles);
            var club = await client.GetFromJsonAsync<MyClubResponse>("/api/v1/club", Ct);
            Assert.Equal(DemoData.ClubName, club!.Club!.Name);
            var rides = await client.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct);
            Assert.NotEmpty(rides!.Rides);
        }
    }

    [Fact]
    public async Task DemoData_ShouldGiveEveryRideAnOriginalFileThatReadsBack_WhenTheDemoIsReset()
    {
        await using var api = await StartDemoAsync();

        await ResetAsync(api);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var files = scope.ServiceProvider.GetRequiredService<RideFileStore>();
        var rides = await db.Rides.AsNoTracking().Select(r => new { r.Id, r.FileSha256, r.ParserVersion }).ToListAsync(Ct);
        Assert.NotEmpty(rides);
        foreach (var ride in rides)
        {
            Assert.Equal(RideParserVersion.Current, ride.ParserVersion);
            var parsed = Assert.Single(RideFileParser.Parse(await files.ReadAsync(ride.FileSha256, Ct)));
            var samples = await db.RideStreams.Where(s => s.RideId == ride.Id).Select(s => s.Time.Length).SingleAsync(Ct);
            Assert.Equal(samples, parsed.Samples.Count);
        }

        // The export hands the files back, as it does for any member.
        var rider = await api.SignedInClientAsync(Rider, DemoData.Password);
        var link = (await (await rider.PostAsync("/api/v1/accounts/me/export-link", null, Ct)).Content.ReadFromJsonAsync<ExportLinkResponse>(Ct))!.Path;
        Assert.Equal(HttpStatusCode.OK, (await api.CreateClient().GetAsync(link, Ct)).StatusCode);
    }

    [Fact]
    public async Task DemoData_ShouldUndoWhatAVisitorChanged_WhenTheDemoIsResetAgain()
    {
        await using var api = await StartDemoAsync();
        await ResetAsync(api);
        var visitor = await api.SignedInClientAsync(Rider, DemoData.Password);
        var rides = await visitor.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct);
        (await visitor.DeleteAsync($"/api/v1/rides/{rides!.Rides[0].Id}", Ct)).EnsureSuccessStatusCode();
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            await db.Users.Where(u => u.Email == Rider).ExecuteUpdateAsync(u => u.SetProperty(x => x.DisplayName, "Changed"), Ct);
        }

        await ResetAsync(api);

        // The old sign-in went with the old account.
        Assert.Equal(HttpStatusCode.Unauthorized, (await visitor.GetAsync("/api/v1/accounts/me", Ct)).StatusCode);
        var fresh = await api.SignedInClientAsync(Rider, DemoData.Password);
        var me = await fresh.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);
        Assert.Equal("Luca Ferri", me!.DisplayName);
        var again = await fresh.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides?limit=1", Ct);
        Assert.NotEmpty(again!.Rides);
        await using var check = api.Services.CreateAsyncScope();
        var data = check.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.Equal(1, await data.Clubs.CountAsync(Ct));
        Assert.Equal(DemoData.Accounts.Count, await data.ClubMemberships.CountAsync(Ct));
    }

    [Fact]
    public async Task DemoData_ShouldKeepTheServerAdmin_WhenTheDemoIsReset()
    {
        await using var api = await StartDemoAsync();

        await ResetAsync(api);
        await ResetAsync(api);

        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var me = await admin.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);
        Assert.Contains(Roles.Admin, me!.Roles);
    }

    [Fact]
    public async Task DemoData_ShouldRefuseAndDeleteNothing_WhenTheServerHoldsAnAccountThatIsNotADemoAccount()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var member = await api.NewMemberAsync();

        await using var scope = api.Services.CreateAsyncScope();
        var demo = scope.ServiceProvider.GetRequiredService<DemoData>();
        Assert.NotNull(await demo.RefusalAsync(Ct));
        await Assert.ThrowsAsync<InvalidOperationException>(() => demo.ResetAsync(Ct));

        Assert.Equal(HttpStatusCode.OK, (await member.Client.GetAsync("/api/v1/accounts/me", Ct)).StatusCode);
    }

    [Fact]
    public async Task DemoLock_ShouldRefuseEveryLockedAction_WhenTheServerIsADemo()
    {
        await using var api = await StartDemoAsync();
        await ResetAsync(api);
        var visitor = await api.SignedInClientAsync(Rider, DemoData.Password);

        foreach (var (method, route) in DemoLock.Refused)
        {
            var path = "/api/v1/" + route.Replace("{id}", Guid.NewGuid().ToString()).Replace("{userId}", Guid.NewGuid().ToString());
            using var request = new HttpRequestMessage(new HttpMethod(method), path) { Content = JsonContent.Create(new { }) };
            var response = await visitor.SendAsync(request, Ct);

            Assert.True(response.StatusCode == HttpStatusCode.Forbidden, $"{method} {route} answered {(int)response.StatusCode}");
            Assert.Contains(DemoLock.Code, await response.Content.ReadAsStringAsync(Ct));
        }

        // The account still signs in with the public password, and what a visitor is meant to try still works.
        var again = await api.SignedInClientAsync(Rider, DemoData.Password);
        Assert.Equal(HttpStatusCode.OK, (await again.GetAsync("/api/v1/rides", Ct)).StatusCode);
    }

    [Fact]
    public async Task DemoLock_ShouldLetTheActionThrough_WhenTheServerIsNotADemo()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var member = await api.NewMemberAsync();

        var response = await member.Client.PutAsJsonAsync(
            "/api/v1/accounts/me/password",
            new ChangePasswordRequest("not the password", "Another-password-1"),
            Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task DemoResetService_ShouldResetOncePerNight_WhenThreeInTheMorningHasPassed()
    {
        var time = new FakeTime { Now = DateTimeOffset.UtcNow };
        await using var api = await StartDemoAsync(time);
        var service = api.Services.GetRequiredService<DemoResetService>();

        Assert.True(await service.RunOnceAsync(Ct));  // nothing there yet
        Assert.False(await service.RunOnceAsync(Ct)); // made after the last 03:00 UTC

        time.Now = DemoResetService.LastBoundary(time.Now).AddDays(1).AddMinutes(-1);
        Assert.False(await service.RunOnceAsync(Ct));

        time.Now = time.Now.AddMinutes(2);
        Assert.True(await service.RunOnceAsync(Ct));
        Assert.False(await service.RunOnceAsync(Ct));
    }

    [Theory]
    [InlineData("2026-11-13T02:59:00Z", "2026-11-12T03:00:00Z")]
    [InlineData("2026-11-13T03:00:00Z", "2026-11-13T03:00:00Z")]
    [InlineData("2026-11-13T23:30:00+02:00", "2026-11-13T03:00:00Z")]
    public void LastBoundary_ShouldBeTheLatestThreeInTheMorningUtc_WhenGivenAnInstant(string now, string expected) =>
        Assert.Equal(DateTimeOffset.Parse(expected), DemoResetService.LastBoundary(DateTimeOffset.Parse(now)));
}
