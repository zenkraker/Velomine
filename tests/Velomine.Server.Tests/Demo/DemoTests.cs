using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Demo;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Notifications.Email;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;
using Velomine.Server.Features.Routes;
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
    public async Task DemoData_ShouldSeedTraining_WhenDemoIsRemadeAfterAVisitorChangedTheMode()
    {
        await using var api = await StartDemoAsync();
        await ResetAsync(api);
        var visitor = await api.SignedInClientAsync(Rider, DemoData.Password);
        Assert.Equal(RiderModes.Training, (await visitor.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.RiderMode);
        (await visitor.PutAsJsonAsync("/api/v1/accounts/me/rider-mode", new SetMyRiderModeRequest(RiderModes.JustRiding), Ct)).EnsureSuccessStatusCode();

        await ResetAsync(api);

        var fresh = await api.SignedInClientAsync(Rider, DemoData.Password);
        Assert.Equal(RiderModes.Training, (await fresh.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.RiderMode);
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

    // Girona and its hills: every seeded coordinate must fall in this box.
    private static bool InGironaArea(double latitude, double longitude) =>
        latitude is > 41.80 and < 42.15 && longitude is > 2.55 and < 3.00;

    [Fact]
    public async Task DemoData_ShouldSeedTheClubRoutesAroundGirona_WhenTheDemoIsReset()
    {
        await using var api = await StartDemoAsync();

        await ResetAsync(api);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var clubId = await db.Clubs.Select(c => c.Id).SingleAsync(Ct);
        var routes = await db.Routes.AsNoTracking().Include(r => r.Line).Where(r => r.ClubId == clubId).ToListAsync(Ct);
        Assert.Equal(4, routes.Count);
        Assert.Equal(["gravel", "mixed", "mountain", "road"], routes.Select(r => r.Surface).Order());
        foreach (var route in routes)
        {
            var line = route.Line!;
            Assert.InRange(line.Latitude.Length, 200, 500);
            Assert.Equal(line.Latitude.Length, line.Elevation!.Length);
            Assert.All(line.Latitude.Zip(line.Longitude), p => Assert.True(InGironaArea(p.First, p.Second)));
            var points = line.Latitude.Select((lat, i) => new RoutePoint(lat, line.Longitude[i], line.Elevation[i])).ToList();
            var (distance, climbing) = RouteGeometry.Measure(points);
            Assert.Equal(distance, route.DistanceM, 1);
            Assert.InRange(route.ClimbingM!.Value, 1, climbing!.Value * 2);
        }

        var road = routes.Single(r => r.Surface == "road");
        Assert.InRange(road.DistanceM, 59_000, 61_000);
    }

    [Fact]
    public async Task DemoData_ShouldPlanClubRidesOnSeededRoutes_WhenTheDemoIsReset()
    {
        await using var api = await StartDemoAsync();

        await ResetAsync(api);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var rides = await db.PlannedRides.AsNoTracking().ToListAsync(Ct);
        Assert.NotEmpty(rides);
        foreach (var ride in rides)
        {
            Assert.True(ride.StartsAt > DateTimeOffset.UtcNow);
            Assert.True(InGironaArea(ride.MeetingLatitude, ride.MeetingLongitude));
            Assert.True(await db.Routes.AnyAsync(r => r.Id == ride.RouteId && r.ClubId == ride.ClubId, Ct));
        }
    }

    [Fact]
    public async Task DemoData_ShouldKeepEveryPrivacyZoneAndRideAroundGirona_WhenTheDemoIsReset()
    {
        await using var api = await StartDemoAsync();

        await ResetAsync(api);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var zones = await db.PrivacyZones.AsNoTracking().ToListAsync(Ct);
        Assert.NotEmpty(zones);
        Assert.All(zones, z => Assert.True(InGironaArea(z.Latitude, z.Longitude)));
        var streams = await db.RideStreams.AsNoTracking().Where(s => s.Latitude != null)
            .Select(s => new { s.Latitude, s.Longitude }).ToListAsync(Ct);
        Assert.NotEmpty(streams);
        Assert.All(streams, s => Assert.All(s.Latitude!.Zip(s.Longitude!), p => Assert.True(InGironaArea(p.First!.Value, p.Second!.Value))));
    }

    [Fact]
    public async Task DemoLock_ShouldRefuseEveryLockedAction_WhenTheServerIsADemo()
    {
        await using var api = await StartDemoAsync();
        await ResetAsync(api);
        var visitor = await api.SignedInClientAsync(Rider, DemoData.Password);
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

        foreach (var (method, route) in DemoLock.Refused)
        {
            var path = "/api/v1/" + route.Replace("{id}", Guid.NewGuid().ToString()).Replace("{userId}", Guid.NewGuid().ToString());
            using var request = new HttpRequestMessage(new HttpMethod(method), path) { Content = JsonContent.Create(new { }) };
            var response = await (route.StartsWith("admin/", StringComparison.Ordinal) ? admin : visitor).SendAsync(request, Ct);

            Assert.True(response.StatusCode == HttpStatusCode.Forbidden, $"{method} {route} answered {(int)response.StatusCode}");
            Assert.Contains(DemoLock.Code, await response.Content.ReadAsStringAsync(Ct));
        }

        // The account still signs in with the public password, and what a visitor is meant to try still works.
        var again = await api.SignedInClientAsync(Rider, DemoData.Password);
        Assert.Equal(HttpStatusCode.OK, (await again.GetAsync("/api/v1/rides", Ct)).StatusCode);
    }

    /// <summary>A demo with SMTP set, as it runs when the operator wants the feedback form to send email.</summary>
    private async Task<(TestApi Api, FakeEmailSender Mail)> StartDemoWithEmailAsync()
    {
        var mail = new FakeEmailSender();
        var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Demo:Enabled", "true");
            b.UseSetting("Velomine:Smtp:Host", "smtp.club.example");
            b.UseSetting("Velomine:Smtp:From", "velomine@club.example");
            b.UseSetting("Velomine:Feedback:Address", "feedback@club.example");
            b.ConfigureTestServices(s => s.AddSingleton<IEmailSender>(mail));
        });
        return (api, mail);
    }

    [Fact]
    public async Task DemoLock_ShouldRefuseResendAndTestEmail_WhenTheDemoHasSmtp()
    {
        var (api, mail) = await StartDemoWithEmailAsync();
        await using var _ = api;
        await ResetAsync(api);
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

        var test = await admin.PostAsync("/api/v1/admin/settings/test-email", null, Ct);
        var resend = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/email/resend", new { email = Rider }, Ct);

        foreach (var response in new[] { test, resend })
        {
            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
            Assert.Contains(DemoLock.Code, await response.Content.ReadAsStringAsync(Ct));
        }

        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task Demo_ShouldLetEveryAccountSignInAndAnnounceNoEmail_WhenSmtpIsConfigured()
    {
        var (api, _) = await StartDemoWithEmailAsync();
        await using var _ = api;
        await ResetAsync(api);

        // The server admin is not seeded with a confirmed address, yet must not be locked out.
        await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        foreach (var account in DemoData.Accounts) await api.SignedInClientAsync(account.Email, DemoData.Password);
        var info = await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", Ct);
        Assert.False(info!.EmailAvailable);
    }

    [Fact]
    public async Task NotificationEmailService_ShouldSendNothingButKeepTheNotification_WhenTheServerIsADemoWithSmtp()
    {
        var (api, mail) = await StartDemoWithEmailAsync();
        await using var _ = api;
        await ResetAsync(api);
        var rider = await api.SignedInClientAsync(Rider, DemoData.Password);
        var id = (await rider.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            // Email has been "on" for an hour, so the notification below is due.
            db.Set<ServerSettings>().Add(new ServerSettings { EmailStartedAt = DateTimeOffset.UtcNow.AddHours(-1) });
            Notify.Add(db, TimeProvider.System, id, NotificationTypes.ClubJoinRequest, "a rider");
            await db.SaveChangesAsync(Ct);
        }

        var sent = await api.Services.GetRequiredService<NotificationEmailService>().RunOnceAsync(Ct);

        Assert.Equal(0, sent);
        Assert.Empty(mail.Sent);
        var notifications = await rider.GetStringAsync("/api/v1/notifications", Ct);
        Assert.Contains("a rider", notifications);
    }

    [Fact]
    public async Task SendFeedback_ShouldStillEmailTheFeedbackAddress_WhenTheServerIsADemoWithSmtp()
    {
        var (api, mail) = await StartDemoWithEmailAsync();
        await using var _ = api;
        var form = new FormUrlEncodedContent([new("who", "A coach"), new("tried", "The public demo"), new("broke", "The map did not load.")]);

        var response = await api.CreateClient().PostAsync("/api/v1/feedback", form, Ct);

        Assert.Equal(HttpStatusCode.SeeOther, response.StatusCode);
        Assert.Equal("feedback@club.example", Assert.Single(mail.Sent).To);
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

    /// <summary>The demo rider, signed in, on a demo that has just been reset: every ride is there to be read.</summary>
    private async Task<(TestApi Api, HttpClient Rider)> StartResetRiderAsync()
    {
        var api = await StartDemoAsync();
        await ResetAsync(api);
        return (api, await api.SignedInClientAsync(Rider, DemoData.Password));
    }

    private static async Task<PowerCurveResponse> PowerCurveAsync(HttpClient rider) =>
        (await rider.GetFromJsonAsync<PowerCurveResponse>("/api/v1/analytics/power-curve?days=90", Ct))!;

    private static async Task<TrainingResponse> TrainingAsync(HttpClient rider) =>
        (await rider.GetFromJsonAsync<TrainingResponse>("/api/v1/analytics/training?days=90", Ct))!;

    private static async Task<RideResponse[]> RidesAsync(HttpClient rider) =>
        (await rider.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides?limit=200", Ct))!.Rides;

    [Fact]
    public async Task DemoData_ShouldGiveTheRiderACriticalPowerFit_WhenTheDemoIsReset()
    {
        var (api, rider) = await StartResetRiderAsync();
        await using var _ = api;

        var curve = await PowerCurveAsync(rider);

        Assert.True(curve.HasPower);
        Assert.NotNull(curve.CriticalPower);
        var fit = curve.CriticalPower!;
        Assert.InRange(fit.CpW, 50, 600);
        Assert.InRange(fit.WPrimeJ, 3_000, 50_000);
        Assert.True(fit.R2 >= 0.90, $"R² was {fit.R2}");
        // The 2, 5, 10 and 20-minute windows are all there, which is what a fit needs.
        Assert.Equal([120, 300, 600, 1200], fit.Durations);
    }

    [Fact]
    public async Task DemoData_ShouldGiveTheRiderAWPprimeBalance_WhenTheDemoIsReset()
    {
        var (api, rider) = await StartResetRiderAsync();
        await using var _ = api;

        // The balance is on the ride's own page, where the app draws it.
        var details = new List<RideResponse>();
        foreach (var ride in (await RidesAsync(rider)).Take(3))
            details.Add((await rider.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct))!);
        var withBalance = details.Where(r => r.WPrimeJ is not null).ToArray();

        Assert.NotEmpty(withBalance);
        Assert.All(withBalance, r => Assert.InRange(r.WPrimeJ!.Value, 3_000, 50_000));
        Assert.All(withBalance, r => Assert.NotNull(r.MinWPrimeBalanceJ));
    }

    [Fact]
    public async Task DemoData_ShouldGiveTheRiderSteadyRidesWithDecoupling_WhenTheDemoIsReset()
    {
        var (api, rider) = await StartResetRiderAsync();
        await using var _ = api;

        var rides = await RidesAsync(rider);
        var steady = rides.Where(r => r.Steady == true && r.DecouplingPct is not null).ToArray();

        Assert.True(steady.Length >= 2, $"only {steady.Length} steady rides");
        Assert.All(steady, r => Assert.NotNull(r.EfficiencyFactor));
    }

    /// <summary>The stored streams as the reader sees them, and the one call an import makes for these three numbers.</summary>
    private static async Task<Dictionary<Guid, (double? EfficiencyFactor, double? DecouplingPct, bool? Steady)>> ReadMetricsAsync(
        VelomineDbContext db) =>
        (await db.RideStreams.AsNoTracking().ToListAsync(Ct)).ToDictionary(
            s => s.RideId,
            s => Read(Samples(s)));

    private static List<Sample> Samples(RideStreams s) =>
        [.. Enumerable.Range(0, s.Time.Length).Select(i => new Sample(s.Time[i], HeartRate: s.HeartRate?[i], Power: s.Power?[i]))];

    private static (double? EfficiencyFactor, double? DecouplingPct, bool? Steady) Read(List<Sample> samples) =>
        RideMetrics.Efficiency(RideMetrics.PairedSeconds(samples, RideMetrics.PauseThresholdS(samples)));

    [Fact]
    public async Task DemoData_ShouldStoreWhatTheReaderWorksOut_WhenTheDemoIsReset()
    {
        await using var api = await StartDemoAsync();
        await ResetAsync(api);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var rides = await db.Rides.AsNoTracking()
            .Select(r => new { r.Id, r.EfficiencyFactor, r.DecouplingPct, r.Steady })
            .ToListAsync(Ct);
        var read = await ReadMetricsAsync(db);

        Assert.NotEmpty(rides);
        Assert.Contains(rides, r => r.Steady == true && r.DecouplingPct is not null);
        foreach (var ride in rides)
        {
            // The seed writes no efficiency of its own: the stored number is the reader's, for every ride.
            var (efficiencyFactor, decoupling, steady) = read[ride.Id];
            Assert.Equal(efficiencyFactor, ride.EfficiencyFactor);
            Assert.Equal(decoupling, ride.DecouplingPct);
            Assert.Equal(steady, ride.Steady);
        }
    }

    [Fact]
    public async Task DemoData_ShouldStoreThePowerBestsTheReaderWorksOut_WhenTheDemoIsReset()
    {
        await using var api = await StartDemoAsync();
        await ResetAsync(api);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var rides = await db.Rides.AsNoTracking().Select(r => new { r.Id, r.PowerBests }).ToListAsync(Ct);
        var streams = (await db.RideStreams.AsNoTracking().ToListAsync(Ct)).ToDictionary(s => s.RideId);
        Assert.NotEmpty(rides);

        foreach (var ride in rides)
        {
            var s = streams[ride.Id];
            var read = PowerBests.FromStreams(s.Power, s.Time);
            var stored = ride.PowerBests.ToDictionary(b => b.DurationS, b => b.Watts);
            for (var d = 0; d < PowerBests.Durations.Length; d++)
            {
                var expected = read[d] > 0 ? read[d] : 0; // a zero is not stored
                Assert.Equal(expected, stored.GetValueOrDefault(PowerBests.Durations[d]));
            }
        }
    }

    [Fact]
    public async Task DemoData_ShouldGiveTheRiderAWeeklyEfficiencyTrend_WhenTheDemoIsReset()
    {
        var (api, rider) = await StartResetRiderAsync();
        await using var _ = api;

        var training = await TrainingAsync(rider);

        Assert.True(training.Efficiency.Length >= 2, $"only {training.Efficiency.Length} weeks with a steady ride");
        Assert.All(training.Efficiency, w => Assert.True(w.EfficiencyFactor > 0));
        Assert.All(training.Efficiency, w => Assert.True(w.Rides >= 1));
    }

    [Fact]
    public async Task DemoData_ShouldGiveTheRiderAnIntensityDistribution_WhenTheDemoIsReset()
    {
        var (api, rider) = await StartResetRiderAsync();
        await using var _ = api;

        var training = await TrainingAsync(rider);

        Assert.NotNull(training.Intensity);
        var intensity = training.Intensity!;
        Assert.True(intensity.Rides > 0);
        Assert.True(intensity.ModerateS > 0);
        Assert.True(intensity.HardS > 0);
        Assert.Equal(100, intensity.EasyPct + intensity.ModeratePct + intensity.HardPct, 1);
        Assert.Contains(intensity.Label, Labels.All);
        Assert.NotEmpty(training.IntensityWeeks);
    }

    [Fact]
    public async Task DemoData_ShouldGiveTheRiderAPowerRecord_WhenALaterRideBeatsAnEarlierBest()
    {
        var (api, rider) = await StartResetRiderAsync();
        await using var _ = api;

        var rides = await RidesAsync(rider);

        // Records are worked out per ride: the ride page of the ride that set one lists it.
        var withRecords = new List<(RideResponse Ride, PowerRecord[] Records)>();
        foreach (var ride in rides)
        {
            var detail = (await rider.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{ride.Id}", Ct))!;
            if (detail.PowerRecords is { Length: > 0 }) withRecords.Add((detail, detail.PowerRecords));
        }

        Assert.NotEmpty(withRecords);
        var (record, records) = withRecords.OrderByDescending(r => r.Ride.StartTime).First();
        // A record only exists when an earlier ride was already there and this one beat it.
        Assert.All(records, r => Assert.Contains(r.Kind, new[] { PowerRecords.AllTime, PowerRecords.NinetyDays }));
        Assert.All(records, r => Assert.True(r.Watts > 0));
        Assert.NotNull(record.StartTime);
    }

    [Fact]
    public async Task DemoData_ShouldGiveTheRiderAnFtpHistory_WhenTheDemoIsReset()
    {
        var (api, rider) = await StartResetRiderAsync();
        await using var _ = api;

        var history = (await rider.GetFromJsonAsync<FtpHistoryResponse>("/api/v1/accounts/me/ftp-history", Ct))!;

        Assert.True(history.Entries.Count >= 2, $"only {history.Entries.Count} FTP history rows");
        Assert.Contains(history.Entries, e => e.Source == FtpSources.Earlier);
        // The newest row is the number the rider's zones use.
        var profile = (await rider.GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct))!;
        Assert.Equal(profile.FtpW, history.Entries[0].Watts);
    }
}
