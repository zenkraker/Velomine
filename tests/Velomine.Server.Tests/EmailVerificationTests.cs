using System.Net;
using System.Net.Http.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Tests;

/// <summary>Email verification on sign-up: on when SMTP is configured, absent when it is not. The solo trial starts too.</summary>
public sealed class EmailVerificationTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static async Task<(TestApi Api, FakeEmailSender Mail)> StartAsync(
        PostgresFixture postgres,
        bool smtp = true,
        Action<IWebHostBuilder>? configure = null)
    {
        var mail = new FakeEmailSender();
        var api = await TestApi.StartAsync(postgres, b =>
        {
            if (smtp)
            {
                b.UseSetting("Velomine:Smtp:Host", "smtp.club.example");
                b.UseSetting("Velomine:Smtp:From", "velomine@club.example");
            }

            b.ConfigureTestServices(s => s.AddSingleton<IEmailSender>(mail));
            configure?.Invoke(b);
        });
        return (api, mail);
    }

    /// <summary>The verification email is sent after the 201; wait for the background send before reading it.</summary>
    private static async Task<OutgoingEmail> WaitForMailAsync(FakeEmailSender mail)
    {
        for (var i = 0; i < 100 && mail.Sent.Count == 0; i++) await Task.Delay(20, Ct);
        return Assert.Single(mail.Sent);
    }

    private static (string Email, string Token) FromEmail(OutgoingEmail mail)
    {
        var link = Regex.Match(mail.Body, @"https?://\S+").Value;
        var fragment = new Uri(link).Fragment.TrimStart('#')
            .Split('&', StringSplitOptions.RemoveEmptyEntries)
            .Select(part => part.Split('=', 2))
            .ToDictionary(part => part[0], part => Uri.UnescapeDataString(part[1]));
        return (fragment["email"], fragment["token"]);
    }

    private static Task<HttpResponseMessage> VerifyAsync(TestApi api, string email, string token) =>
        api.CreateClient().PostAsJsonAsync("/api/v1/accounts/email/verify", new VerifyEmailRequest(email, token), Ct);

    private static Task<HttpResponseMessage> ResendAsync(TestApi api, string email) =>
        api.CreateClient().PostAsJsonAsync("/api/v1/accounts/email/resend", new ResendVerificationRequest(email), Ct);

    private static async Task<ProfileResponse> ProfileAsync(TestApi api, string email, string password) =>
        await (await api.SignedInClientAsync(email, password)).GetFromJsonAsync<ProfileResponse>("/api/v1/accounts/me/profile", Ct)
        ?? throw new InvalidOperationException("No profile");

    [Fact]
    public async Task Register_ShouldStartTheSoloTrial_WhenSignUpSucceeds()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var email = TestApi.NewEmail();

        var registered = await api.RegisterAsync(email);
        Assert.Equal(HttpStatusCode.Created, registered.StatusCode);

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<Velomine.Server.Data.VelomineDbContext>();
        var user = db.Users.Single(u => u.Email == email);
        Assert.Equal(today.AddDays(ClubPlan.TrialDays), user.SoloTrialEndsAt);
        Assert.True(user.IsApproved);

        var profile = await ProfileAsync(api, email, TestApi.MemberPassword);
        Assert.Equal(user.SoloTrialEndsAt, profile.SoloTrialEndsAt);
    }

    [Fact]
    public async Task Register_ShouldSendAVerificationEmail_WhenEmailIsConfigured()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var email = TestApi.NewEmail();

        var registered = await api.RegisterAsync(email);
        Assert.Equal(HttpStatusCode.Created, registered.StatusCode);
        Assert.True((await registered.Content.ReadFromJsonAsync<RegisterResponse>(Ct))!.EmailConfirmationRequired);

        var sent = await WaitForMailAsync(mail);
        Assert.Equal(email, sent.To);
        Assert.Equal("Confirm your email for Velomine", sent.Subject);
        Assert.Contains("verify-email#", sent.Body);
        var (linkEmail, token) = FromEmail(sent);
        Assert.Equal(email, linkEmail);
        Assert.False(string.IsNullOrEmpty(token));
    }

    [Fact]
    public async Task Register_ShouldAnswerWithoutWaitingForSmtp_WhenTheMailServerIsSlow()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var gate = new TaskCompletionSource<bool>();
        mail.Gate = gate;

        var registered = await api.RegisterAsync(TestApi.NewEmail());

        Assert.Equal(HttpStatusCode.Created, registered.StatusCode);
        Assert.Empty(mail.Sent);
        gate.SetResult(true);
        await WaitForMailAsync(mail);
    }

    [Fact]
    public async Task Register_ShouldNotRequireConfirmation_WhenEmailIsNotConfigured()
    {
        var (api, mail) = await StartAsync(postgres, smtp: false);
        await using var _ = api;
        var email = TestApi.NewEmail();

        var registered = await api.RegisterAsync(email);
        Assert.Equal(HttpStatusCode.Created, registered.StatusCode);
        Assert.False((await registered.Content.ReadFromJsonAsync<RegisterResponse>(Ct))!.EmailConfirmationRequired);
        Assert.Empty(mail.Sent);

        var signedIn = await api.LoginAsync(email, TestApi.MemberPassword);
        Assert.Equal(HttpStatusCode.OK, signedIn.StatusCode);

        Assert.Equal((HttpStatusCode)503, (await ResendAsync(api, email)).StatusCode);
    }

    [Fact]
    public async Task Login_ShouldRefuseAnUnconfirmedEmail_WhenEmailIsConfigured()
    {
        var (api, _) = await StartAsync(postgres);
        await using var scope = api;
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();

        var refused = await api.LoginAsync(email, TestApi.MemberPassword);

        Assert.Equal(HttpStatusCode.Forbidden, refused.StatusCode);
        Assert.Equal("email_not_confirmed", (await refused.Content.ReadFromJsonAsync<ErrorBody>(Ct))!.Error);
    }

    [Fact]
    public async Task Login_ShouldAcceptTheAccount_WhenTheEmailIsConfirmed()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        var (linkEmail, token) = FromEmail(await WaitForMailAsync(mail));

        Assert.Equal(HttpStatusCode.NoContent, (await VerifyAsync(api, linkEmail, token)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await api.LoginAsync(email, TestApi.MemberPassword)).StatusCode);
    }

    [Fact]
    public async Task VerifyEmail_ShouldReject_WhenTheTokenIsInvalid()
    {
        var (api, _) = await StartAsync(postgres);
        await using var scope = api;
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();

        Assert.Equal(HttpStatusCode.BadRequest, (await VerifyAsync(api, email, "not-a-real-token")).StatusCode);
    }

    [Fact]
    public async Task VerifyEmail_ShouldReject_WhenTheTokenWasAlreadyUsed()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        var (linkEmail, token) = FromEmail(await WaitForMailAsync(mail));
        Assert.Equal(HttpStatusCode.NoContent, (await VerifyAsync(api, linkEmail, token)).StatusCode);

        // Identity would let the token through again for a confirmed address; the server refuses it itself.
        Assert.Equal(HttpStatusCode.BadRequest, (await VerifyAsync(api, linkEmail, token)).StatusCode);
    }

    [Fact]
    public async Task ResendVerification_ShouldSendANewLink_WhenTheAddressIsUnconfirmed()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        await WaitForMailAsync(mail);

        var response = await ResendAsync(api, email);

        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        for (var i = 0; i < 100 && mail.Sent.Count < 2; i++) await Task.Delay(20, Ct);
        Assert.Equal(2, mail.Sent.Count);
        Assert.All(mail.Sent, sent => Assert.Equal(email, sent.To));
    }

    [Fact]
    public async Task ResendVerification_ShouldAnswerAccepted_WhenTheAddressIsUnknown()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;

        var response = await ResendAsync(api, TestApi.NewEmail());

        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task VerifyEmailLink_ShouldUseTheConfiguredAddress_WhenTheRequestHostIsForged()
    {
        var (api, mail) = await StartAsync(postgres, configure: b => b.UseSetting("Velomine:PublicUrl", "https://club.example"));
        await using var _ = api;
        var email = TestApi.NewEmail();
        var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/accounts/register")
        {
            Content = JsonContent.Create(new RegisterRequest(email, TestApi.MemberPassword, "Test Rider")),
        };
        request.Headers.Host = "evil.example";
        Assert.Equal(HttpStatusCode.Created, (await api.CreateClient().SendAsync(request, Ct)).StatusCode);

        var sent = await WaitForMailAsync(mail);
        var link = Regex.Match(sent.Body, @"https?://\S+").Value;
        Assert.StartsWith("https://club.example/verify-email#", link);
        Assert.DoesNotContain("evil.example", link);
    }

    private sealed record ErrorBody(string? Error);
}
