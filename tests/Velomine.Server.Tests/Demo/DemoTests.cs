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
using Velomine.Server.Features.Sharing;
using Velomine.Server.Features.Training;

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
    public async Task DemoData_ShouldUndoWhatAVisitorChanged_WhenTheDemoIsResetAgain()
    {
        await using var api = await StartDemoAsync();
        await ResetAsync(api);
        var visitor = await api.SignedInClientAsync(Rider, DemoData.Password);
        var rides = await visitor.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides", Ct);
        (await visitor.DeleteAsync($"/api/v1/rides/{rides!.Rides[0].Id}", Ct)).EnsureSuccessStatusCode();
        Assert.Equal(RiderModes.Training, (await visitor.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.RiderMode);
        (await visitor.PutAsJsonAsync("/api/v1/accounts/me/rider-mode", new SetMyRiderModeRequest(RiderModes.JustRiding), Ct)).EnsureSuccessStatusCode();
        var weeks = (await visitor.GetFromJsonAsync<TrainingWeeksResponse>("/api/v1/training/week", Ct))!;
        (await visitor.PostAsync($"/api/v1/training/sessions/{weeks.Weeks[0].Sessions.Single(x => x.CanMakeEasy).Id}/easy", null, Ct)).EnsureSuccessStatusCode();
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
        // The mode a visitor switched is back to the training the demo is made for.
        Assert.Equal(RiderModes.Training, me.RiderMode);
        // The week a visitor made easy is the seeded week again.
        var seededWeek = (await fresh.GetFromJsonAsync<TrainingWeeksResponse>("/api/v1/training/week", Ct))!;
        Assert.DoesNotContain(seededWeek.Weeks[0].Sessions, x => x.State == TrainingSessionStates.Easy);
        var again = await fresh.GetFromJsonAsync<ListRidesResponse>("/api/v1/rides?limit=1", Ct);
        Assert.NotEmpty(again!.Rides);
        await using var check = api.Services.CreateAsyncScope();
        var data = check.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.Equal(1, await data.Clubs.CountAsync(Ct));
        Assert.Equal(DemoData.Accounts.Count, await data.ClubMemberships.CountAsync(Ct));
        // The server admin is not a demo account and survives the reset.
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        Assert.Contains(Roles.Admin, (await admin.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Roles);
    }

    [Fact]
    public async Task DemoLock_ShouldRefuseEveryLockedAction_WhenTheServerIsADemo()
    {
        await using var api = await StartDemoAsync();
        // The lock answers before an endpoint runs, so the server admin is enough: no seeded demo.
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var visitor = admin;

        foreach (var (method, route) in DemoLock.Refused)
        {
            var path = "/api/v1/" + route.Replace("{id}", Guid.NewGuid().ToString()).Replace("{userId}", Guid.NewGuid().ToString());
            using var request = new HttpRequestMessage(new HttpMethod(method), path) { Content = JsonContent.Create(new { }) };
            var response = await (route.StartsWith("admin/", StringComparison.Ordinal) ? admin : visitor).SendAsync(request, Ct);

            Assert.True(response.StatusCode == HttpStatusCode.Forbidden, $"{method} {route} answered {(int)response.StatusCode}");
            Assert.Contains(DemoLock.Code, await response.Content.ReadAsStringAsync(Ct));
        }

        // The rest of a week is refused by the endpoint, because the body decides it, and before it looks the session up.
        var rest = await admin.PostAsJsonAsync($"/api/v1/training/sessions/{Guid.NewGuid()}/skip",
            new SkipTrainingSessionRequest { Reason = TrainingSkipReasons.NoTime, RestOfWeek = true }, Ct);
        Assert.Equal(HttpStatusCode.Forbidden, rest.StatusCode);
        Assert.Contains(DemoLock.Code, await rest.Content.ReadAsStringAsync(Ct));

        // The account still signs in with the public password, and what a visitor is meant to try still works.
        var again = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
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
        var rider = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
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
}
