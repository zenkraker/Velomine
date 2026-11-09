using System.IO.Compression;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Coach;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;
using Velomine.Server.Features.Wellbeing;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Wellbeing;

[Collection("postgres")]
public sealed class WellbeingTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync() => TestApi.StartAsync(postgres, b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));

    private static async Task<(HttpClient Client, Guid Id, string Email)> NewMemberAsync(TestApi api, string name = "Test Rider")
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email, name: name)).EnsureSuccessStatusCode();
        var client = await api.SignedInClientAsync(email, TestApi.MemberPassword);
        var me = await client.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);
        return (client, me!.Id, email);
    }

    private static Task<HttpResponseMessage> ConsentAsync(HttpClient client) =>
        client.PostAsJsonAsync("/api/v1/wellbeing/consent", new WellbeingConsentRequest(true), Ct);

    private static Task<HttpResponseMessage> CheckInAsync(HttpClient client, int fatigue = 3) =>
        client.PutAsJsonAsync(
            "/api/v1/wellbeing/check-ins/today",
            new SaveCheckInRequest { Fatigue = fatigue, Soreness = 2, Mood = 4, Stress = 2, Motivation = 5 },
            Ct);

    private static async Task<RideResponse> UploadAsync(HttpClient client)
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(Fit(new FitSession(DateTime.UtcNow.AddDays(-1), 1300))), "file", "ride.fit" } };
        var accepted = await client.PostAsync("/api/v1/rides/uploads", form, Ct);
        accepted.EnsureSuccessStatusCode();
        var id = (await accepted.Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        for (var i = 0; i < 100; i++)
        {
            var ride = await client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{id}", Ct);
            if (ride!.Status != "processing") return ride;
            await Task.Delay(100, Ct);
        }

        throw new TimeoutException("The ride was still processing after 10 seconds.");
    }

    private static async Task<AdminClubResponse> CreateClubAsync(TestApi api, string ownerEmail)
    {
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var response = await admin.PostAsJsonAsync(
            "/api/v1/admin/clubs",
            new CreateClubRequest { Name = $"Club {Guid.NewGuid():N}", OwnerEmail = ownerEmail },
            Ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AdminClubResponse>(Ct))!;
    }

    private static async Task ShareAsync(HttpClient client, string rides, string analytics, string wellbeing) =>
        (await client.PutAsJsonAsync(
            "/api/v1/sharing",
            new UpdateSharingRequest { Rides = rides, Analytics = analytics, Routes = "none", Wellbeing = wellbeing },
            Ct)).EnsureSuccessStatusCode();

    [Fact]
    public async Task Wellbeing_ShouldAskForConsent_WhenTheMemberHasNotAcceptedTheTerms()
    {
        await using var api = await StartAsync();
        var (client, _, _) = await NewMemberAsync(api);

        var before = await client.GetFromJsonAsync<WellbeingResponse>("/api/v1/wellbeing", Ct);
        Assert.True(before!.ConsentRequired);
        Assert.False(before.Consented);
        Assert.Null(before.Today);

        Assert.Equal(HttpStatusCode.Conflict, (await CheckInAsync(client)).StatusCode);

        Assert.Equal(HttpStatusCode.OK, (await ConsentAsync(client)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await CheckInAsync(client, fatigue: 5)).StatusCode);

        var after = await client.GetFromJsonAsync<WellbeingResponse>("/api/v1/wellbeing", Ct);
        Assert.False(after!.ConsentRequired);
        Assert.Equal(5, after.Today!.Fatigue);
        Assert.Equal(2, after.Today.Soreness);
        Assert.Equal(4, after.Today.Mood);
        Assert.Equal(2, after.Today.Stress);
        Assert.Equal(5, after.Today.Motivation);

        var history = await client.GetFromJsonAsync<CheckInsResponse>("/api/v1/wellbeing/check-ins?days=30", Ct);
        Assert.Single(history!.CheckIns);

        Assert.Equal(
            HttpStatusCode.BadRequest,
            (await client.PutAsJsonAsync(
                "/api/v1/wellbeing/check-ins/today",
                new SaveCheckInRequest { Fatigue = 6, Soreness = 2, Mood = 4, Stress = 2, Motivation = 5 },
                Ct)).StatusCode);
    }

    [Fact]
    public async Task Wellbeing_ShouldShareScoresButNotNotes_WhenTheCoachLooks()
    {
        await using var api = await StartAsync();
        var (coach, _, coachEmail) = await NewMemberAsync(api, "Coach Rina");
        var club = await CreateClubAsync(api, coachEmail);
        var (athlete, athleteId, athleteEmail) = await NewMemberAsync(api, "Athlete Luca");
        (await athlete.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct)).EnsureSuccessStatusCode();

        await ConsentAsync(athlete);
        await CheckInAsync(athlete, fatigue: 4);
        var ride = await UploadAsync(athlete);
        (await athlete.PutAsJsonAsync(
            $"/api/v1/rides/{ride.Id}/feel",
            new SaveRideFeelRequest { Id = ride.Id, Rpe = 7, Notes = "Felt strong but tired" },
            Ct)).EnsureSuccessStatusCode();

        await ShareAsync(athlete, "none", "none", "coaches");

        var wellbeing = await coach.GetFromJsonAsync<CoachWellbeingResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athleteId}/wellbeing?days=30", Ct);
        Assert.Single(wellbeing!.CheckIns);
        Assert.Equal(4, wellbeing.CheckIns[0].Fatigue);
        Assert.Single(wellbeing.Rides);
        Assert.Equal(7, wellbeing.Rides[0].Rpe);
        Assert.DoesNotContain("Felt strong", JsonSerializer.Serialize(wellbeing));

        var views = await athlete.GetFromJsonAsync<ShareViewsResponse>("/api/v1/sharing/views", Ct);
        Assert.Contains(views!.Views, v => v.What == ViewKinds.Wellbeing && v.ViewerName == "Coach Rina");

        // A wellbeing-only sharer still appears on the roster, with no ride or training numbers.
        var roster = await coach.GetFromJsonAsync<CoachAthletesResponse>($"/api/v1/clubs/{club.Id}/athletes", Ct);
        var summary = Assert.Single(roster!.Athletes, a => a.UserId == athleteId);
        Assert.True(summary.SharesWellbeing);
        Assert.False(summary.SharesRides);
        Assert.False(summary.SharesAnalytics);
        Assert.Null(summary.Rides);
        Assert.Null(summary.Tss7);

        // A plain member of the club is not a coach and sees nothing.
        var (other, _, _) = await NewMemberAsync(api, "Other Rider");
        (await other.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct)).EnsureSuccessStatusCode();
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await other.GetAsync($"/api/v1/clubs/{club.Id}/athletes/{athleteId}/wellbeing", Ct)).StatusCode);

        _ = athleteEmail;
    }

    [Fact]
    public async Task Readiness_ShouldUseTheCheckIn_WhenTheMemberFilledItIn()
    {
        await using var api = await StartAsync();
        var (client, _, _) = await NewMemberAsync(api);
        (await client.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Rider", 200, 75, 2000, "UTC", "monday"),
            Ct)).EnsureSuccessStatusCode();
        await UploadAsync(client);

        var loadOnly = await client.GetFromJsonAsync<ReadinessResponse>("/api/v1/analytics/readiness", Ct);
        Assert.NotNull(loadOnly!.Score);
        Assert.False(loadOnly.HasWellbeing);
        Assert.DoesNotContain(loadOnly.Factors, f => f.Key == "wellbeing");

        await ConsentAsync(client);
        await CheckInAsync(client, fatigue: 2);

        var withFeel = await client.GetFromJsonAsync<ReadinessResponse>("/api/v1/analytics/readiness", Ct);
        Assert.NotNull(withFeel!.Score);
        Assert.True(withFeel.HasWellbeing);
        Assert.Contains(withFeel.Factors, f => f.Key == "wellbeing");
    }

    [Fact]
    public async Task Readiness_ShouldReturnUnknown_WhenTheMemberHasNoRides()
    {
        await using var api = await StartAsync();
        var (client, _, _) = await NewMemberAsync(api);

        var readiness = await client.GetFromJsonAsync<ReadinessResponse>("/api/v1/analytics/readiness", Ct);

        Assert.Null(readiness!.Score);
        Assert.Equal("unknown", readiness.Band);
    }

    [Fact]
    public async Task Export_ShouldIncludeWellbeing_WhenTheMemberHasCheckInsAndNotes()
    {
        await using var api = await StartAsync();
        var (client, _, _) = await NewMemberAsync(api);
        await ConsentAsync(client);
        await CheckInAsync(client, fatigue: 4);
        var ride = await UploadAsync(client);
        (await client.PutAsJsonAsync(
            $"/api/v1/rides/{ride.Id}/feel",
            new SaveRideFeelRequest { Id = ride.Id, Rpe = 8, Notes = "Hard day" },
            Ct)).EnsureSuccessStatusCode();

        var link = await (await client.PostAsync("/api/v1/accounts/me/export-link", null, Ct))
            .Content.ReadFromJsonAsync<ExportLinkResponse>(Ct);
        var download = await api.CreateClient().GetAsync(link!.Path, Ct);
        using var zip = new ZipArchive(await download.Content.ReadAsStreamAsync(Ct), ZipArchiveMode.Read);
        using var reader = new StreamReader(zip.GetEntry("wellbeing.json")!.Open());
        var json = await reader.ReadToEndAsync(Ct);

        Assert.Contains("Hard day", json);
        Assert.Contains("\"fatigue\": 4", json);
    }
}
