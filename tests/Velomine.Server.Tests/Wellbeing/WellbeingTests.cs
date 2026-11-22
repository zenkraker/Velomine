using System.IO.Compression;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Coach;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;
using Velomine.Server.Features.Wellbeing;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Wellbeing;

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

    private static Task<HttpResponseMessage> CheckInAsync(HttpClient client, int fatigue = 3, int? sleep = null) =>
        client.PutAsJsonAsync(
            "/api/v1/wellbeing/check-ins/today",
            new SaveCheckInRequest { Fatigue = fatigue, Soreness = 2, Mood = 4, Stress = 2, Motivation = 5, Sleep = sleep },
            Ct);

    private static Task<RideResponse> UploadAsync(HttpClient client) =>
        TestApi.UploadAndWaitAsync(client, Fit(new FitSession(DateTime.UtcNow.AddDays(-1), 1300)));

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
        var club = await TestClubs.CreateAsync(api, coachEmail);
        var (athlete, athleteId, athleteEmail) = await NewMemberAsync(api, "Athlete Luca");
        (await athlete.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct)).EnsureSuccessStatusCode();

        await ConsentAsync(athlete);
        await CheckInAsync(athlete, fatigue: 4, sleep: 3);
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
        Assert.Equal(3, wellbeing.CheckIns[0].Sleep);
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
    public async Task WithdrawConsent_ShouldStopSharingAndProcessing_WhenTheMemberWithdraws()
    {
        await using var api = await StartAsync();
        var (coach, _, coachEmail) = await NewMemberAsync(api, "Coach Rina");
        var club = await TestClubs.CreateAsync(api, coachEmail);
        var (athlete, athleteId, _) = await NewMemberAsync(api, "Athlete Luca");
        (await athlete.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct)).EnsureSuccessStatusCode();
        await ConsentAsync(athlete);
        await CheckInAsync(athlete, fatigue: 4);
        await ShareAsync(athlete, "none", "none", "coaches");

        var before = await coach.GetFromJsonAsync<CoachWellbeingResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athleteId}/wellbeing?days=30", Ct);
        Assert.Single(before!.CheckIns);

        var withdrawn = await athlete.DeleteAsync("/api/v1/wellbeing/consent", Ct);

        Assert.Equal(HttpStatusCode.OK, withdrawn.StatusCode);
        var body = await withdrawn.Content.ReadFromJsonAsync<WellbeingResponse>(Ct);
        Assert.True(body!.ConsentRequired);
        Assert.False(body.Consented);
        Assert.NotNull(body.Today); // the history is kept, not deleted
        Assert.Equal(HttpStatusCode.Conflict, (await CheckInAsync(athlete)).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict,
            (await athlete.GetAsync("/api/v1/wellbeing/check-ins?days=30", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,
            (await coach.GetAsync($"/api/v1/clubs/{club.Id}/athletes/{athleteId}/wellbeing", Ct)).StatusCode);

        await using var scope = api.Services.CreateAsyncScope();
        Assert.True(await scope.ServiceProvider.GetRequiredService<VelomineDbContext>()
            .DailyCheckIns.AnyAsync(c => c.UserId == athleteId, Ct));
    }

    [Fact]
    public async Task Wellbeing_ShouldAskAgain_WhenTheConsentVersionHasChanged()
    {
        await using var api = await StartAsync();
        var (client, _, _) = await NewMemberAsync(api);
        (await ConsentAsync(client)).EnsureSuccessStatusCode();
        (await CheckInAsync(client, fatigue: 3)).EnsureSuccessStatusCode();
        Assert.False((await client.GetFromJsonAsync<WellbeingResponse>("/api/v1/wellbeing", Ct))!.ConsentRequired);

        // The wording changed: the stored consent is for the old version, so the member is asked again and saves stop.
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        await db.Users.Where(u => u.WellbeingConsentVersion == WellbeingTerms.Version)
            .ExecuteUpdateAsync(s => s.SetProperty(u => u.WellbeingConsentVersion, WellbeingTerms.Version - 1), Ct);

        var after = await client.GetFromJsonAsync<WellbeingResponse>("/api/v1/wellbeing", Ct);
        Assert.True(after!.ConsentRequired);
        Assert.False(after.Consented);
        Assert.Equal(HttpStatusCode.Conflict, (await CheckInAsync(client, fatigue: 4)).StatusCode);
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

    [Fact]
    public async Task SaveCheckIn_ShouldStoreSleep_WhenItIsSent()
    {
        await using var api = await StartAsync();
        var (client, _, _) = await NewMemberAsync(api);
        await ConsentAsync(client);

        (await CheckInAsync(client, sleep: 2)).EnsureSuccessStatusCode();

        var today = await client.GetFromJsonAsync<WellbeingResponse>("/api/v1/wellbeing", Ct);
        Assert.Equal(2, today!.Today!.Sleep);
    }

    [Fact]
    public async Task SaveCheckIn_ShouldAcceptACheckIn_WhenSleepIsLeftOut()
    {
        await using var api = await StartAsync();
        var (client, _, _) = await NewMemberAsync(api);
        await ConsentAsync(client);

        // A build that predates the question sends no sleep; the check-in is still saved, with no sleep.
        Assert.Equal(HttpStatusCode.OK, (await CheckInAsync(client)).StatusCode);

        var today = await client.GetFromJsonAsync<WellbeingResponse>("/api/v1/wellbeing", Ct);
        Assert.Null(today!.Today!.Sleep);
    }

    [Fact]
    public async Task SaveCheckIn_ShouldRefuseSleep_WhenItIsOutsideOneToFive()
    {
        await using var api = await StartAsync();
        var (client, _, _) = await NewMemberAsync(api);
        await ConsentAsync(client);

        Assert.Equal(HttpStatusCode.BadRequest, (await CheckInAsync(client, sleep: 0)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await CheckInAsync(client, sleep: 6)).StatusCode);
    }

    [Fact]
    public async Task CheckInTable_ShouldRefuseSleepOutsideTheRange_WhenWrittenDirectly()
    {
        await using var api = await StartAsync();
        var (client, memberId, _) = await NewMemberAsync(api);
        await ConsentAsync(client);
        (await CheckInAsync(client, sleep: 3)).EnsureSuccessStatusCode();

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var error = await Assert.ThrowsAsync<PostgresException>(() => db.Database.ExecuteSqlAsync(
            $"UPDATE wellbeing.daily_check_ins SET sleep = 6 WHERE user_id = {memberId}", Ct));

        Assert.Equal("ck_daily_check_ins_sleep", error.ConstraintName);
    }

    [Fact]
    public async Task Readiness_ShouldCountSleep_WhenTheCheckInHasIt()
    {
        await using var api = await StartAsync();
        var (client, _, _) = await NewMemberAsync(api);
        (await client.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Rider", 200, 75, 2000, "UTC", "monday"),
            Ct)).EnsureSuccessStatusCode();
        await UploadAsync(client);
        await ConsentAsync(client);

        await CheckInAsync(client, sleep: 1);
        var tired = await client.GetFromJsonAsync<ReadinessResponse>("/api/v1/analytics/readiness", Ct);
        await CheckInAsync(client, sleep: 5);
        var rested = await client.GetFromJsonAsync<ReadinessResponse>("/api/v1/analytics/readiness", Ct);

        // (4 + 5 + 1 + 3 + 4 + 4) / 6 = 3.5 against (4 + 5 + 5 + 3 + 4 + 4) / 6 = 4.2, each as points from 3.
        var tiredWellbeing = Assert.Single(tired!.Factors, f => f.Key == "wellbeing");
        var restedWellbeing = Assert.Single(rested!.Factors, f => f.Key == "wellbeing");
        Assert.Equal(3.5, tiredWellbeing.Value);
        Assert.Equal(5.0, tiredWellbeing.Effect);
        Assert.Equal(4.2, restedWellbeing.Value);
        Assert.Equal(11.7, restedWellbeing.Effect);
    }

    [Fact]
    public async Task CoachCheckIns_ShouldShowSleep_WhenWellbeingIsShared()
    {
        await using var api = await StartAsync();
        var (coach, _, coachEmail) = await NewMemberAsync(api, "Coach Rina");
        var club = await TestClubs.CreateAsync(api, coachEmail);
        var (athlete, athleteId, _) = await NewMemberAsync(api, "Athlete Luca");
        (await athlete.PostAsJsonAsync("/api/v1/club/join", new JoinClubRequest { Code = club.JoinCode }, Ct))
            .EnsureSuccessStatusCode();
        await ConsentAsync(athlete);
        await CheckInAsync(athlete, sleep: 1);
        await ShareAsync(athlete, "none", "none", "coaches");

        var wellbeing = await coach.GetFromJsonAsync<CoachWellbeingResponse>(
            $"/api/v1/clubs/{club.Id}/athletes/{athleteId}/wellbeing?days=30", Ct);

        Assert.Equal(1, Assert.Single(wellbeing!.CheckIns).Sleep);
    }

    [Fact]
    public async Task AccountExport_ShouldIncludeSleep_WhenTheCheckInHasIt()
    {
        await using var api = await StartAsync();
        var (client, _, _) = await NewMemberAsync(api);
        await ConsentAsync(client);
        await CheckInAsync(client, sleep: 2);

        var link = await (await client.PostAsync("/api/v1/accounts/me/export-link", null, Ct))
            .Content.ReadFromJsonAsync<ExportLinkResponse>(Ct);
        var download = await api.CreateClient().GetAsync(link!.Path, Ct);
        using var zip = new ZipArchive(await download.Content.ReadAsStreamAsync(Ct), ZipArchiveMode.Read);
        using var reader = new StreamReader(zip.GetEntry("wellbeing.json")!.Open());
        var json = await reader.ReadToEndAsync(Ct);

        Assert.Contains("\"sleep\": 2", json);
    }
}
