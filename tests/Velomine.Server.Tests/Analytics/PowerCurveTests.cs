using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Analytics;

public sealed class PowerCurveTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static async Task<(HttpClient Client, Guid Id)> NewMemberAsync(TestApi api, string name = "Test Rider")
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email, name: name)).EnsureSuccessStatusCode();
        var client = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        return (client, (await client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id);
    }

    private static Task SetProfileAsync(HttpClient client, int ftpW, double weightKg) =>
        client.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Rider", ftpW, weightKg, 2000, "UTC", "monday"),
            Ct);

    private static Task UploadAsync(HttpClient client, byte[] file) => TestApi.UploadAndWaitAsync(client, file);

    [Fact]
    public async Task PowerCurve_ShouldReturnBestPowerAndEstimates_WhenARideHasPower()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        await SetProfileAsync(client, 200, 75);
        await UploadAsync(client, Fit(new FitSession(DateTime.UtcNow.AddDays(-1), 1300)));

        var curve = await client.GetFromJsonAsync<PowerCurveResponse>("/api/v1/analytics/power-curve?days=90", Ct);

        Assert.True(curve!.HasPower);
        Assert.Equal(1, curve.Rides);
        Assert.Equal(200, curve.CurrentFtpW);
        Assert.Equal(75.0, curve.WeightKg);
        Assert.Contains(curve.Points, p => p.Seconds == 1200 && p.Watts == 200);
        Assert.DoesNotContain(curve.Points, p => p.Seconds == 3600);
        Assert.Equal(190, curve.Ftp!.Watts);
        Assert.Equal("20min", curve.Ftp.Method);
        Assert.Equal(2.5, curve.Ftp.WPerKg);
        Assert.Equal(35.8, curve.Vo2Max!.Value);
    }

    [Fact]
    public async Task PowerCurve_ShouldHideWeightDerivedNumbers_WhenTheCoachLooks()
    {
        await using var api = await StartAsync();
        var ownerEmail = TestApi.NewEmail();
        (await api.RegisterAsync(ownerEmail, name: "Coach Rina")).EnsureSuccessStatusCode();
        var coach = await api.SignedInClientAsync(ownerEmail, TestApi.MemberPassword);
        var club = await TestClubs.CreateAsync(api, ownerEmail);

        var (athlete, athleteId) = await NewMemberAsync(api, "Athlete Luca");
        (await athlete.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct)).EnsureSuccessStatusCode();
        await SetProfileAsync(athlete, 200, 75);
        await UploadAsync(athlete, Fit(new FitSession(DateTime.UtcNow.AddDays(-1), 1300)));
        (await athlete.PutAsJsonAsync(
            "/api/v1/sharing",
            new UpdateSharingRequest { Rides = "coaches", Analytics = "coaches", Routes = "none", Wellbeing = "none" },
            Ct)).EnsureSuccessStatusCode();

        var curve = await coach.GetFromJsonAsync<PowerCurveResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athleteId}/power-curve?days=90", Ct);

        Assert.True(curve!.HasPower);
        Assert.NotNull(curve.Ftp);
        Assert.Null(curve.Ftp.WPerKg);
        Assert.Null(curve.Vo2Max);
        Assert.Null(curve.WeightKg);

        var views = await athlete.GetFromJsonAsync<ShareViewsResponse>("/api/v1/sharing/views", Ct);
        Assert.Contains(views!.Views, v => v.What == ViewKinds.PowerCurve && v.ViewerName == "Coach Rina");

        var (other, _) = await NewMemberAsync(api, "Other Rider");
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await other.GetAsync($"/api/v1/clubs/{club.Id}/athletes/{athleteId}/power-curve", Ct)).StatusCode);
    }

    [Fact]
    public async Task SetFtp_ShouldReplaceOnlyTheFtp_WhenTheMemberAdoptsTheEstimate()
    {
        await using var api = await StartAsync();
        var (client, _) = await NewMemberAsync(api);
        await SetProfileAsync(client, 200, 75);

        var response = await client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(285), Ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var profile = await response.Content.ReadFromJsonAsync<ProfileResponse>(Ct);
        Assert.Equal(285, profile!.FtpW);
        Assert.Equal(75, profile.WeightKg);
        Assert.Equal(
            HttpStatusCode.BadRequest,
            (await client.PutAsJsonAsync("/api/v1/accounts/me/ftp", new SetFtpRequest(5), Ct)).StatusCode);
    }
}
