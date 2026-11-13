using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
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

[Collection("postgres")]
public sealed class EmailTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>
    /// SMTP on and the fake doing the sending: these tests are about the server deciding what to mail, and the fake
    /// still receives it through the real emailer's wiring. Email on also means sign-up mails a confirmation.
    /// </summary>
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

    /// <summary>The message a test asks for: not a sign-up confirmation, which these servers also put in the fake.</summary>
    private static OutgoingEmail TheMail(FakeEmailSender mail) =>
        Assert.Single(mail.Sent, m => !m.Subject.StartsWith("Confirm your email", StringComparison.Ordinal));

    /// <summary>Nothing but the sign-up confirmations has been sent, and one is always there when email is on.</summary>
    private static void ShouldBeConfirmationsOnly(FakeEmailSender mail) =>
        Assert.All(mail.Sent, m => Assert.StartsWith("Confirm your email", m.Subject));

    /// <summary>
    /// Signs up a member and waits until the sign-up confirmation has reached the fake: Register writes the token
    /// before answering, so once the answer is in, the mail is only a moment behind.
    /// </summary>
    private static async Task<(string Email, HttpClient Client)> NewMemberAfterConfirmationAsync(TestApi api, FakeEmailSender mail)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        for (var i = 0; i < 100 && !mail.Sent.Any(m => m.To == email && m.Subject.StartsWith("Confirm your email", StringComparison.Ordinal)); i++)
            await Task.Delay(20, Ct);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
            var user = (await users.FindByEmailAsync(email))!;
            Assert.True((await users.ConfirmEmailAsync(user, await users.GenerateEmailConfirmationTokenAsync(user))).Succeeded);
        }

        return (email, await api.SignedInClientAsync(email, TestApi.MemberPassword));
    }

    /// <summary>The admin is created before email can send; with the gate on, its address is confirmed here.</summary>
    private static async Task ConfirmAdminAsync(TestApi api)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
        var admin = (await users.FindByEmailAsync(TestApi.AdminEmail))!;
        Assert.True((await users.ConfirmEmailAsync(admin, await users.GenerateEmailConfirmationTokenAsync(admin))).Succeeded);
    }

    private static async Task<(string Email, HttpClient Client)> NewMemberAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        // Email is on, so the address is confirmed before the member signs in.
        await using var scope = api.Services.CreateAsyncScope();
        var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
        var user = (await users.FindByEmailAsync(email))!;
        Assert.True((await users.ConfirmEmailAsync(user, await users.GenerateEmailConfirmationTokenAsync(user))).Succeeded);
        return (email, await api.SignedInClientAsync(email, TestApi.MemberPassword));
    }

    /// <summary>Uploads a ride and waits until it has been read, which makes a "ride ready" notification.</summary>
    private static async Task UploadAsync(HttpClient client, DateTime start)
    {
        var form = new MultipartFormDataContent { { new ByteArrayContent(Fit(new FitSession(start, 120))), "file", "ride.fit" } };
        var id = (await (await client.PostAsync("/api/v1/rides/uploads", form, Ct)).Content.ReadFromJsonAsync<UploadRideResponse>(Ct))!.RideId;
        for (var i = 0; i < 100; i++)
        {
            if ((await client.GetFromJsonAsync<RideResponse>($"/api/v1/rides/{id}", Ct))!.Status != "processing") return;
            await Task.Delay(100, Ct);
        }

        throw new TimeoutException("The ride was still processing after 10 seconds.");
    }

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

        ShouldBeConfirmationsOnly(mail);
        Assert.False((await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", Ct))!.EmailAvailable);
    }

    [Fact]
    public async Task EmailSettings_ShouldBeAnnounced_WhenSmtpIsConfigured()
    {
        var (api, _) = await StartAsync(postgres);
        await using var __ = api;

        Assert.True((await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", Ct))!.EmailAvailable);
    }

    [Fact]
    public async Task EmailSender_ShouldResolveWithItsRetryPipelines_WhenSmtpIsConfigured()
    {
        var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
            b.UseSetting("Velomine:Smtp:Host", "smtp.club.example");
            b.UseSetting("Velomine:Smtp:From", "velomine@club.example");
        });
        await using var _ = api;

        Assert.IsType<MailKitEmailSender>(api.Services.GetRequiredService<IEmailSender>());
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
        Assert.DoesNotContain(mail.Sent, m => !m.Subject.StartsWith("Confirm your email", StringComparison.Ordinal));

        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "new rider", DateTimeOffset.UtcNow);
        Assert.Equal(1, await RunAsync(api));
        var sent = TheMail(mail);
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
        var (_, member) = await NewMemberAfterConfirmationAsync(api, mail);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api); // email is now on
        await member.PutAsJsonAsync(
            "/api/v1/accounts/me/profile",
            new UpdateProfileRequest("Rider", null, null, null, null, "monday", EmailNotifications: false),
            Ct);

        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "a rider", DateTimeOffset.UtcNow);

        Assert.Equal(0, await RunAsync(api));
        ShouldBeConfirmationsOnly(mail);
    }

    [Fact]
    public async Task NotificationEmail_ShouldSkip_WhenNotificationWasAlreadyRead()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAfterConfirmationAsync(api, mail);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api);
        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "a rider", DateTimeOffset.UtcNow);
        await member.PostAsync("/api/v1/notifications/read", null, Ct);

        Assert.Equal(0, await RunAsync(api));
        ShouldBeConfirmationsOnly(mail);
    }

    [Fact]
    public async Task NotificationEmail_ShouldRetry_WhenSendFails()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAfterConfirmationAsync(api, mail);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api);
        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "a rider", DateTimeOffset.UtcNow);

        mail.Fail = new InvalidOperationException("mail server down");
        Assert.Equal(0, await RunAsync(api));
        ShouldBeConfirmationsOnly(mail);

        mail.Fail = null;
        Assert.Equal(1, await RunAsync(api));
        Assert.NotNull(TheMail(mail));
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
        await RunAsync(api); // email is now on

        await AddAsync(api, badId, NotificationTypes.ClubJoinRequest, "a rider", DateTimeOffset.UtcNow);
        await AddAsync(api, goodId, NotificationTypes.ClubJoinRequest, "a rider", DateTimeOffset.UtcNow.AddSeconds(1));

        mail.Rejected.Add(badEmail);

        Assert.Equal(1, await RunAsync(api));
        Assert.Equal(goodEmail, TheMail(mail).To);

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
        await RunAsync(api); // email is now on

        await UploadAsync(member, Start);

        Assert.Equal(0, await RunAsync(api));
        Assert.DoesNotContain(mail.Sent, m => !m.Subject.StartsWith("Confirm your email", StringComparison.Ordinal));
    }

    [Fact]
    public async Task NotificationEmail_ShouldDelayRideEmail_WhenItIsNewerThanTheDigestWindow()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAfterConfirmationAsync(api, mail);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await TurnOnTrainingAsync(member);
        await RunAsync(api); // email is now on, which also sets the start of what it sends
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var settings = await db.Set<ServerSettings>().FirstAsync(Ct);
            // The account signed up just now; the server must look older than the ride mail to send it.
            settings.EmailStartedAt = DateTimeOffset.UtcNow.AddDays(-1);
            await db.SaveChangesAsync(Ct);
        }

        await AddAsync(api, id, NotificationTypes.RideReady, "old.fit", DateTimeOffset.UtcNow.AddMinutes(-11));
        await AddAsync(api, id, NotificationTypes.RideReady, "new.fit", DateTimeOffset.UtcNow.AddMinutes(-1));

        Assert.Equal(1, await RunAsync(api));
        var sent = TheMail(mail);
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
        var (_, member) = await NewMemberAfterConfirmationAsync(api, mail);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api);

        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "Ada", DateTimeOffset.UtcNow);
        await AddAsync(api, id, NotificationTypes.ClubJoinApproved, "Club", DateTimeOffset.UtcNow.AddSeconds(1));

        Assert.Equal(1, await RunAsync(api));
        var sent = TheMail(mail);
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
        await ConfirmAdminAsync(api);
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

        var response = await admin.PostAsync("/api/v1/admin/settings/test-email", null, Ct);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        var sent = TheMail(mail);
        Assert.Equal(TestApi.AdminEmail, sent.To);
        Assert.Equal("Velomine: test email", sent.Subject);
        Assert.NotNull(sent.HtmlBody);
    }

    [Fact]
    public async Task AdminTestEmail_ShouldExplainFailureAndBeAdminsOnly_WhenSendFails()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        await ConfirmAdminAsync(api);
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
    [InlineData(NotificationTypes.RideReady, "Your ride morning.fit is ready.")]
    [InlineData(NotificationTypes.RideFailed, "morning.fit could not be read.")]
    [InlineData(NotificationTypes.RideDuplicate, "morning.fit was already uploaded, so it is hidden.")]
    [InlineData(NotificationTypes.SignUpWaiting, "morning.fit signed up and is waiting for approval.")]
    [InlineData(NotificationTypes.PartSoon, "morning.fit is nearly worn.")]
    [InlineData(NotificationTypes.PartWorn, "morning.fit is worn out. Time to replace it.")]
    [InlineData(NotificationTypes.ReminderSoon, "Maintenance nearly due: morning.fit.")]
    [InlineData(NotificationTypes.ReminderDue, "Maintenance due: morning.fit.")]
    public void NotificationText_ShouldReturnTheSentence_WhenNotificationTypeIsKnown(string type, string sentence)
    {
        using var _ = EmailLanguage.Use("en");
        Assert.Equal(sentence, NotificationText.Sentence(new Notification { Type = type, Subject = "morning.fit" }));
    }

    [Fact]
    public void NotificationText_ShouldWriteOneFooter_WhenSeveralAreDue()
    {
        using var _ = EmailLanguage.Use("en");
        var body = NotificationText.Write(
        [
            new Notification { Type = NotificationTypes.ClubJoinRequest, Subject = "Ada" },
            new Notification { Type = NotificationTypes.ClubJoinApproved, Subject = "Club" },
        ]).Text;

        Assert.Contains("Ada asked to join your club.", body);
        Assert.Contains("Club accepted you.", body);
        Assert.Equal(1, body.Split("email notifications are on").Length - 1);
    }

    [Fact]
    public async Task NotificationEmail_ShouldWriteItalian_WhenMemberLanguageIsItalian()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAfterConfirmationAsync(api, mail);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api); // email is now on
        await member.PutAsJsonAsync("/api/v1/accounts/me/language", new SetMyLanguageRequest { Language = "it" }, Ct);

        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "Ada", DateTimeOffset.UtcNow);

        Assert.Equal(1, await RunAsync(api));
        var sent = TheMail(mail);
        Assert.Equal("Velomine: Ada ha chiesto di entrare nel tuo club.", sent.Subject);
        Assert.Contains("Ada ha chiesto di entrare nel tuo club.", sent.Body);
        Assert.Contains("lang=\"it\"", sent.HtmlBody);
    }

    [Fact]
    public async Task NotificationEmail_ShouldWriteEnglish_WhenMemberLanguageIsUnknown()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAfterConfirmationAsync(api, mail);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api);
        await member.PutAsJsonAsync("/api/v1/accounts/me/language", new SetMyLanguageRequest { Language = "de" }, Ct);

        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "Ada", DateTimeOffset.UtcNow);

        Assert.Equal(1, await RunAsync(api));
        var sent = TheMail(mail);
        Assert.Equal("Velomine: Ada asked to join your club.", sent.Subject);
        Assert.Contains("lang=\"en\"", sent.HtmlBody);
    }

    [Fact]
    public async Task NotificationEmail_ShouldEscapeTheSubject_WhenItContainsHtml()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAfterConfirmationAsync(api, mail);
        var id = (await member.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;
        await RunAsync(api);

        await AddAsync(api, id, NotificationTypes.ClubJoinRequest, "<b>Eve</b>", DateTimeOffset.UtcNow);
        Assert.Equal(1, await RunAsync(api));

        var sent = TheMail(mail);
        Assert.Contains("&lt;b&gt;Eve&lt;/b&gt;", sent.HtmlBody);
        Assert.DoesNotContain("<b>Eve</b>", sent.HtmlBody);
    }
}
