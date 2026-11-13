using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Notifications.Email;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Server;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Admin;

public sealed class EmailTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static async Task<(TestApi Api, FakeEmailSender Mail)> StartAsync(PostgresFixture postgres, bool smtp = true)
    {
        var mail = new FakeEmailSender();
        var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            if (smtp)
            {
                b.UseSetting("Velomine:Smtp:Host", "smtp.club.example");
                b.UseSetting("Velomine:Smtp:From", "velomine@club.example");
            }

            b.ConfigureTestServices(s => s.AddSingleton<IEmailSender>(mail));
        });
        return (api, mail);
    }

    private static async Task<(string Email, HttpClient Client)> NewMemberAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        return (email, await api.SignedInClientAsync(email, TestApi.MemberPassword));
    }

    /// <summary>Uploads a ride and waits until it has been read, which makes a "ride ready" notification.</summary>
    private static Task UploadAsync(HttpClient client, DateTime start) =>
        TestApi.UploadAndWaitAsync(client, Fit(new FitSession(start, 120)));

    private static Task<int> RunAsync(TestApi api) =>
        api.Services.GetRequiredService<NotificationEmailService>().RunOnceAsync(Ct);

    private static Task TurnOnTrainingAsync(HttpClient member) =>
        member.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Rider", null, null, null, null, "monday", EmailTrainingNotifications: true),
            Ct);

    private static async Task AddAsync(TestApi api, Guid userId, string type, string subject, DateTimeOffset at)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Notify.Add(db, new FixedTime(at), userId, type, subject);
        await db.SaveChangesAsync(Ct);
    }

    [Fact]
    public async Task EmailSettings_ShouldSendNothingAndAnnounceNothing_WhenSmtpIsMissing()
    {
        var (api, mail) = await StartAsync(postgres, smtp: false);
        await using var _ = api;
        var (_, member) = await NewMemberAsync(api);
        await UploadAsync(member, Start);

        Assert.Equal(0, await RunAsync(api));

        Assert.Empty(mail.Sent);
        Assert.False((await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", Ct))!.EmailAvailable);
    }

    [Fact]
    public async Task EmailSettings_ShouldBeAnnounced_WhenSmtpIsConfigured()
    {
        var (api, _) = await StartAsync(postgres);
        await using var _ = api;

        Assert.True((await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", Ct))!.EmailAvailable);
    }

    [Fact]
    public async Task NotificationEmail_ShouldSkipBacklogAndSendOnce_WhenEmailIsTurnedOn()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (email, member) = await NewMemberAsync(api);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;

        // A notification from before email was switched on (the server started with SMTP set after this one was made).
        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "old rider", DateTimeOffset.UtcNow.AddHours(-3));

        Assert.Equal(0, await RunAsync(api));
        Assert.Empty(mail.Sent);

        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "new rider", DateTimeOffset.UtcNow);
        Assert.Equal(1, await RunAsync(api));
        var sent = Assert.Single(mail.Sent);
        Assert.Equal(email, sent.To);
        Assert.Equal("Velomine: new rider asked to join your club.", sent.Subject);
        Assert.Contains("email notifications are on in your Velomine profile", sent.Body);
        Assert.NotNull(sent.HtmlBody);
        Assert.Contains("new rider asked to join your club.", sent.HtmlBody);

        Assert.Equal(0, await RunAsync(api)); // not again

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.Equal(1, await db.Notifications.CountAsync(n => n.EmailedAt != null, Ct));
    }

    [Fact]
    public async Task NotificationEmail_ShouldSendNothing_WhenMemberTurnedEmailOff()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAsync(api);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api); // email is now on
        await member.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Rider", null, null, null, null, "monday", EmailNotifications: false),
            Ct);

        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "a rider", DateTimeOffset.UtcNow);

        Assert.Equal(0, await RunAsync(api));
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task NotificationEmail_ShouldSkip_WhenNotificationWasAlreadyRead()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAsync(api);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api);
        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "a rider", DateTimeOffset.UtcNow);
        await member.PostAsync("/api/v1/notifications/read", null, Ct);

        Assert.Equal(0, await RunAsync(api));
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task NotificationEmail_ShouldRetry_WhenSendFails()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAsync(api);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api);
        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "a rider", DateTimeOffset.UtcNow);

        mail.Fail = new InvalidOperationException("mail server down");
        Assert.Equal(0, await RunAsync(api));
        Assert.Empty(mail.Sent);

        mail.Fail = null;
        Assert.Equal(1, await RunAsync(api));
        Assert.Single(mail.Sent);
    }

    [Fact]
    public async Task NotificationEmail_ShouldSkipTheRejectedAddressAndSendTheRest_WhenOneRecipientIsRefused()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (badEmail, badClient) = await NewMemberAsync(api);
        var (goodEmail, goodClient) = await NewMemberAsync(api);
        var badId = (await badClient.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        var goodId = (await goodClient.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api); // email is on from now

        await AddAsync(api, badId, NotificationTypes.ClubJoinRequest, "a rider", DateTimeOffset.UtcNow);
        await AddAsync(api, goodId, NotificationTypes.ClubJoinRequest, "a rider", DateTimeOffset.UtcNow.AddSeconds(1));

        mail.Rejected.Add(badEmail);

        Assert.Equal(1, await RunAsync(api));
        Assert.Equal(goodEmail, Assert.Single(mail.Sent).To);

        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            Assert.All(await db.Notifications.ToListAsync(Ct), n => Assert.NotNull(n.EmailedAt));
        }

        Assert.Equal(0, await RunAsync(api));
    }

    [Fact]
    public async Task NotificationEmail_ShouldNotEmailARideReady_WhenTrainingEmailIsOff()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAsync(api);
        await RunAsync(api); // email is on from now

        await UploadAsync(member, Start);

        Assert.Equal(0, await RunAsync(api));
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task NotificationEmail_ShouldDelayRideEmail_WhenItIsNewerThanTheDigestWindow()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAsync(api);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api);
        await TurnOnTrainingAsync(member);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var settings = await db.Set<ServerSettings>().FirstAsync(Ct);
            settings.EmailStartedAt = DateTimeOffset.UtcNow.AddHours(-1);
            await db.SaveChangesAsync(Ct);
        }

        await AddAsync(api, id, NotificationTypes.RideReady, "old.fit", DateTimeOffset.UtcNow.AddMinutes(-11));
        await AddAsync(api, id, NotificationTypes.RideReady, "new.fit", DateTimeOffset.UtcNow.AddMinutes(-1));

        Assert.Equal(1, await RunAsync(api));
        var sent = Assert.Single(mail.Sent);
        Assert.Contains("old.fit", sent.Subject);
        Assert.Contains("old.fit", sent.Body);
        Assert.DoesNotContain("new.fit", sent.Body);

        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            Assert.NotNull((await db.Notifications.SingleAsync(n => n.Subject == "old.fit", Ct)).EmailedAt);
            Assert.Null((await db.Notifications.SingleAsync(n => n.Subject == "new.fit", Ct)).EmailedAt);
        }
    }

    [Fact]
    public async Task NotificationEmail_ShouldSendOneEmail_WhenSeveralNotificationsAreDue()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAsync(api);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api);

        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "Ada", DateTimeOffset.UtcNow);
        await AddAsync(api, id, NotificationTypes.ClubJoinApproved, "Club", DateTimeOffset.UtcNow.AddSeconds(1));

        Assert.Equal(1, await RunAsync(api));
        var sent = Assert.Single(mail.Sent);
        Assert.Equal("Velomine: 2 updates", sent.Subject);
        Assert.Contains("Ada asked to join your club.", sent.Body);
        Assert.Contains("Club accepted you.", sent.Body);
        Assert.Equal(1, sent.Body.Split("email notifications are on").Length - 1);

        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        Assert.All(await db.Notifications.ToListAsync(Ct), n => Assert.NotNull(n.EmailedAt));
    }

    [Fact]
    public async Task AdminTestEmail_ShouldGoToTheAdminAddress_WhenRequested()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

        var response = await admin.PostAsync("/api/v1/admin/settings/test-email", null, Ct);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        var sent = Assert.Single(mail.Sent);
        Assert.Equal(TestApi.AdminEmail, sent.To);
        Assert.Equal("Velomine: test email", sent.Subject);
        Assert.NotNull(sent.HtmlBody);
    }

    [Fact]
    public async Task AdminTestEmail_ShouldExplainFailureAndBeAdminsOnly_WhenSendFails()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var (_, member) = await NewMemberAsync(api);

        Assert.Equal(HttpStatusCode.Forbidden, (await member.PostAsync("/api/v1/admin/settings/test-email", null, Ct)).StatusCode);

        mail.Fail = new InvalidOperationException("535 authentication failed");
        var failed = await admin.PostAsync("/api/v1/admin/settings/test-email", null, Ct);
        Assert.Equal(HttpStatusCode.BadGateway, failed.StatusCode);
        Assert.Contains("535 authentication failed", await failed.Content.ReadAsStringAsync(Ct));

        var (offApi, _) = await StartAsync(postgres, smtp: false);
        await using var __ = offApi;
        var offAdmin = await offApi.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        Assert.Equal(HttpStatusCode.Conflict, (await offAdmin.PostAsync("/api/v1/admin/settings/test-email", null, Ct)).StatusCode);
    }

    [Theory]
    // The member's own rides and parts; the training switch decides whether they are mailed.
    [InlineData(NotificationTypes.RideReady, "Your ride morning.fit is ready.", true)]
    [InlineData(NotificationTypes.RideFailed, "morning.fit could not be read.", true)]
    [InlineData(NotificationTypes.RideDuplicate, "morning.fit was already uploaded, so it is hidden.", true)]
    [InlineData(NotificationTypes.PartSoon, "morning.fit is nearly worn.", true)]
    [InlineData(NotificationTypes.PartWorn, "morning.fit is worn out. Time to replace it.", true)]
    [InlineData(NotificationTypes.ReminderSoon, "Maintenance nearly due: morning.fit.", true)]
    [InlineData(NotificationTypes.ReminderDue, "Maintenance due: morning.fit.", true)]
    // Someone waits on the member, or an answer came: always mailed.
    [InlineData(NotificationTypes.SignUpWaiting, "morning.fit signed up and is waiting for approval.", false)]
    [InlineData(NotificationTypes.ClubJoinRequest, "morning.fit asked to join your club.", false)]
    public void NotificationText_ShouldReturnTheSentence_WhenNotificationTypeIsKnown(string type, string sentence, bool training)
    {
        using var _ = EmailLanguage.Use("en");

        Assert.Equal(sentence, NotificationText.Sentence(new Notification { Type = type, Subject = "morning.fit" }));
        Assert.Equal(training ? NotificationKinds.Training : NotificationKinds.Account, NotificationKinds.Of(type));
    }

    [Fact]
    public async Task NotificationEmail_ShouldWriteItalian_WhenMemberLanguageIsItalian()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAsync(api);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api); // email is on from now
        await member.PutAsJsonAsync("/api/v1/accounts/me/language", new SetMyLanguageRequest { Language = "it" }, Ct);

        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "Ada", DateTimeOffset.UtcNow);

        Assert.Equal(1, await RunAsync(api));
        var sent = Assert.Single(mail.Sent);
        Assert.Equal("Velomine: Ada ha chiesto di entrare nel tuo club.", sent.Subject);
        Assert.Contains("Ada ha chiesto di entrare nel tuo club.", sent.Body);
        Assert.Contains("lang=\"it\"", sent.HtmlBody);
    }

}
