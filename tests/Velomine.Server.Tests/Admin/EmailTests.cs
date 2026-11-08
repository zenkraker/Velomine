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

/// <summary>Stands in for the mail server: keeps what was sent, and can be told to fail.</summary>
public sealed class FakeEmailSender : IEmailSender
{
    public List<(string To, string Subject, string Body)> Sent { get; } = [];

    public Exception? Fail { get; set; }

    public Task SendAsync(string to, string subject, string body, CancellationToken ct)
    {
        if (Fail is not null) throw Fail;
        Sent.Add((to, subject, body));
        return Task.CompletedTask;
    }
}

[Collection("postgres")]
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
        await using (var oldScope = api.Services.CreateAsyncScope())
        {
            var oldDb = oldScope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            Notify.Add(oldDb, new FixedTime(DateTimeOffset.UtcNow.AddHours(-3)), id, NotificationTypes.RideReady, "old.fit");
            await oldDb.SaveChangesAsync(Ct);
        }

        Assert.Equal(0, await RunAsync(api));
        Assert.Empty(mail.Sent);

        await UploadAsync(member, Start.AddHours(5));
        Assert.Equal(1, await RunAsync(api));
        var (to, subject, body) = Assert.Single(mail.Sent);
        Assert.Equal(email, to);
        Assert.Equal("Velomine: Your ride ride.fit is ready.", subject);
        Assert.Contains("email notifications are on in your Velomine profile", body);

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
        await RunAsync(api); // email is now on
        await member.PutAsJsonAsync("/api/v1/accounts/me/profile", new UpdateProfileRequest("Rider", null, null, null, null, "monday", false), Ct);

        await UploadAsync(member, Start);

        Assert.Equal(0, await RunAsync(api));
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task NotificationEmail_ShouldSkip_WhenNotificationWasAlreadyRead()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (_, member) = await NewMemberAsync(api);
        await RunAsync(api);
        await UploadAsync(member, Start);
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
        await RunAsync(api);
        await UploadAsync(member, Start);

        mail.Fail = new InvalidOperationException("mail server down");
        Assert.Equal(0, await RunAsync(api));
        Assert.Empty(mail.Sent);

        mail.Fail = null;
        Assert.Equal(1, await RunAsync(api));
        Assert.Single(mail.Sent);
    }

    [Fact]
    public async Task AdminTestEmail_ShouldGoToTheAdminAddress_WhenRequested()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

        var response = await admin.PostAsync("/api/v1/admin/settings/test-email", null, Ct);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        var (to, subject, _) = Assert.Single(mail.Sent);
        Assert.Equal(TestApi.AdminEmail, to);
        Assert.Equal("Velomine: test email", subject);
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
    [InlineData(NotificationTypes.RideReady, "Your ride morning.fit is ready.")]
    [InlineData(NotificationTypes.RideFailed, "morning.fit could not be read.")]
    [InlineData(NotificationTypes.RideDuplicate, "morning.fit was already uploaded, so it is hidden.")]
    [InlineData(NotificationTypes.SignUpWaiting, "morning.fit signed up and is waiting for approval.")]
    [InlineData(NotificationTypes.PartSoon, "morning.fit is nearly worn.")]
    [InlineData(NotificationTypes.PartWorn, "morning.fit is worn out. Time to replace it.")]
    public void NotificationText_ShouldReturnTheSentence_WhenNotificationTypeIsKnown(string type, string sentence) =>
        Assert.Equal(sentence, NotificationText.Sentence(new Notification { Type = type, Subject = "morning.fit" }));
}
