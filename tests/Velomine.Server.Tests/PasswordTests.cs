using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Notifications.Email;
using Velomine.Server.Tests.Admin;

namespace Velomine.Server.Tests;

[Collection("postgres")]
public sealed class PasswordTests(PostgresFixture postgres)
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
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
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

    private static async Task<(string Email, HttpClient Client)> NewMemberAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        // Email is on when the server sends, so sign-up mails a confirmation link the reset tests must skip.
        if (api.Services.GetRequiredService<IOptions<SmtpOptions>>().Value.Configured)
        {
            await using var scope = api.Services.CreateAsyncScope();
            var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
            var token = await users.GenerateEmailConfirmationTokenAsync((await users.FindByEmailAsync(email))!);
            Assert.Equal(HttpStatusCode.NoContent,
                (await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/email/verify", new VerifyEmailRequest(email, token), Ct)).StatusCode);
        }

        return (email, await api.SignedInClientAsync(email, TestApi.MemberPassword));
    }

    private static async Task<HttpResponseMessage> ForgotAsync(TestApi api, string email) =>
        await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/password/forgot", new ForgotPasswordRequest(email), Ct);

    /// <summary>The verifying test's mail: the reset or instructions message, not a sign-up confirmation still on its way.</summary>
    private static OutgoingEmail TheMail(FakeEmailSender mail) => Assert.Single(mail.Sent, m => !m.Subject.StartsWith("Confirm your email", StringComparison.Ordinal));

    /// <summary>The reset email is sent after the 202; wait for it, not for the sign-up confirmation already in the fake.</summary>
    private static async Task WaitForMailAsync(FakeEmailSender mail)
    {
        for (var i = 0; i < 100 && mail.Sent.All(m => m.Subject.StartsWith("Confirm", StringComparison.Ordinal)); i++)
            await Task.Delay(20, Ct);
    }

    /// <summary>The admin exists from the server's start, before email could confirm it; with the gate on, confirm it.</summary>
    private static async Task AdmitAsync(TestApi api) => await ConfirmAsync(api, TestApi.AdminEmail);

    /// <summary>Email is on in this suite, so an address is confirmed before it can sign in.</summary>
    private static async Task ConfirmAsync(TestApi api, string email)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
        var user = (await users.FindByEmailAsync(email))!;
        Assert.True((await users.ConfirmEmailAsync(user, await users.GenerateEmailConfirmationTokenAsync(user))).Succeeded);
    }

    private static Dictionary<string, string> Fragment(string link) =>
        new Uri(link).Fragment.TrimStart('#')
            .Split('&', StringSplitOptions.RemoveEmptyEntries)
            .Select(part => part.Split('=', 2))
            .ToDictionary(part => part[0], part => Uri.UnescapeDataString(part[1]));

    private static (string Email, string Token) FromEmail(FakeEmailSender mail)
    {
        var link = Regex.Match(TheMail(mail).Body, @"https?://\S+").Value;
        var query = Fragment(link);
        return (query["email"], query["token"]);
    }

    private static Task<HttpResponseMessage> ResetAsync(TestApi api, string email, string token, string password) =>
        api.CreateClient().PostAsJsonAsync("/api/v1/accounts/password/reset",
            new ResetPasswordRequest(email, token, password), Ct);

    [Fact]
    public async Task ForgotPassword_ShouldReturnAccepted_WhenEmailIsUnknown()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;

        var response = await ForgotAsync(api, TestApi.NewEmail());

        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task ForgotPassword_ShouldAnswerBeforeTheEmailIsSent()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (email, _) = await NewMemberAsync(api);
        // The sign-up confirmation is written before the answer, so waiting for it keeps it out of what comes next.
        for (var i = 0; i < 100 && mail.Sent.Count == 0; i++) await Task.Delay(20, Ct);
        mail.Sent.Clear();
        var gate = new TaskCompletionSource<bool>();
        mail.Gate = gate;

        var response = await ForgotAsync(api, email);

        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        Assert.Empty(mail.Sent);
        gate.SetResult(true);
        await Task.Delay(200, Ct);
        Assert.Equal(email, TheMail(mail).To);
    }

    [Fact]
    public async Task ForgotPassword_ShouldSendOneLink_WhenAccountHasPassword()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (email, _) = await NewMemberAsync(api);

        var response = await ForgotAsync(api, email);
        await WaitForMailAsync(mail);

        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        var sent = TheMail(mail);
        Assert.Equal(email, sent.To);
        Assert.Equal("Reset your Velomine password", sent.Subject);
        Assert.NotNull(sent.HtmlBody);
        Assert.StartsWith("<!doctype html>", sent.HtmlBody);
        Assert.Contains("reset-password#", sent.HtmlBody);
        var (linkEmail, token) = FromEmail(mail);
        Assert.Equal(email, linkEmail);
        Assert.False(string.IsNullOrEmpty(token));
    }

    [Fact]
    public async Task ForgotPassword_ShouldUseTheConfiguredAddress_WhenTheRequestHostIsForged()
    {
        var (api, mail) = await StartAsync(
            postgres,
            configure: b => b.UseSetting("Velomine:PublicUrl", "https://club.example"));
        await using var _ = api;
        var (email, _) = await NewMemberAsync(api);

        var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/accounts/password/forgot")
        {
            Content = JsonContent.Create(new ForgotPasswordRequest(email)),
        };
        request.Headers.Host = "evil.example";
        var response = await api.CreateClient().SendAsync(request, Ct);

        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        await WaitForMailAsync(mail);
        var link = Regex.Match(TheMail(mail).Body, @"https?://\S+").Value;
        Assert.StartsWith("https://club.example/reset-password#", link);
        Assert.DoesNotContain("evil.example", link);
    }

    [Fact]
    public async Task ForgotPassword_ShouldRefuse_WhenEmailIsNotConfigured()
    {
        var (api, mail) = await StartAsync(postgres, smtp: false);
        await using var _ = api;
        var (email, _) = await NewMemberAsync(api);

        var response = await ForgotAsync(api, email);
        await WaitForMailAsync(mail);

        Assert.Equal((HttpStatusCode)503, response.StatusCode);
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task ForgotPassword_ShouldSendInstructionsNotAToken_WhenAccountHasNoPassword()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var email = TestApi.NewEmail();
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
            var user = new User
            {
                UserName = email,
                Email = email,
                DisplayName = "Sso Rider",
                IsApproved = true,
                EmailConfirmed = true,
                CreatedAt = DateTimeOffset.UtcNow,
            };
            Assert.True((await users.CreateAsync(user)).Succeeded);
        }

        var response = await ForgotAsync(api, email);
        await WaitForMailAsync(mail);

        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        var sent = TheMail(mail);
        Assert.Equal("How to sign in to Velomine", sent.Subject);
        Assert.DoesNotContain("reset-password", sent.Body);
        Assert.Contains("no password", sent.Body);
    }

    [Fact]
    public async Task ForgotPassword_ShouldWriteItalian_WhenUserLanguageIsItalian()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (email, member) = await NewMemberAsync(api);
        await member.PutAsJsonAsync(
            "/api/v1/accounts/me/language", new SetMyLanguageRequest { Language = "it" }, Ct);

        await ForgotAsync(api, email);
        await WaitForMailAsync(mail);

        var sent = TheMail(mail);
        Assert.Equal("Reimposta la password di Velomine", sent.Subject);
        Assert.Contains("Qualcuno ha chiesto di reimpostare la password", sent.Body);
        Assert.Contains("lang=\"it\"", sent.HtmlBody);
    }

    [Fact]
    public async Task ForgotPassword_ShouldWriteEnglish_WhenLanguageIsNotSupported()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (email, member) = await NewMemberAsync(api);
        await member.PutAsJsonAsync(
            "/api/v1/accounts/me/language", new SetMyLanguageRequest { Language = "de" }, Ct);

        await ForgotAsync(api, email);
        await WaitForMailAsync(mail);

        var sent = TheMail(mail);
        Assert.Equal("Reset your Velomine password", sent.Subject);
        Assert.Contains("lang=\"en\"", sent.HtmlBody);
    }

    [Fact]
    public async Task ResetPassword_ShouldChangePassword_WhenTokenIsValid()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (email, _) = await NewMemberAsync(api);
        await ForgotAsync(api, email);
        await WaitForMailAsync(mail);
        var (linkEmail, token) = FromEmail(mail);

        var response = await ResetAsync(api, linkEmail, token, "New-password-1");

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.LoginAsync(email, TestApi.MemberPassword)).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await api.LoginAsync(email, "New-password-1")).StatusCode);
    }

    [Fact]
    public async Task ResetPassword_ShouldReject_WhenTokenWasAlreadyUsed()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (email, _) = await NewMemberAsync(api);
        await ForgotAsync(api, email);
        await WaitForMailAsync(mail);
        var (linkEmail, token) = FromEmail(mail);
        Assert.Equal(HttpStatusCode.NoContent, (await ResetAsync(api, linkEmail, token, "New-password-1")).StatusCode);

        var again = await ResetAsync(api, linkEmail, token, "Another-password-1");

        Assert.Equal(HttpStatusCode.BadRequest, again.StatusCode);
    }

    [Fact]
    public async Task ResetPassword_ShouldReject_WhenTokenExpired()
    {
        var (api, mail) = await StartAsync(postgres, configure: b => b.ConfigureTestServices(
            s => s.Configure<DataProtectionTokenProviderOptions>(o => o.TokenLifespan = TimeSpan.FromMilliseconds(100))));
        await using var _ = api;
        var (email, _) = await NewMemberAsync(api);
        await ForgotAsync(api, email);
        await WaitForMailAsync(mail);
        var (linkEmail, token) = FromEmail(mail);

        await Task.Delay(300, Ct);
        var response = await ResetAsync(api, linkEmail, token, "New-password-1");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task ResetPassword_ShouldRejectWeakPassword_WhenTheNewOneIsTooShort()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (email, _) = await NewMemberAsync(api);
        await ForgotAsync(api, email);
        await WaitForMailAsync(mail);
        var (linkEmail, token) = FromEmail(mail);

        var response = await ResetAsync(api, linkEmail, token, "short");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_ShouldReject_WhenTheCurrentPasswordIsWrong()
    {
        var (api, _) = await StartAsync(postgres);
        await using var __ = api;
        var (_, member) = await NewMemberAsync(api);

        var response = await member.PutAsJsonAsync("/api/v1/accounts/me/password",
            new ChangePasswordRequest("Not-the-password-1", "New-password-1"), Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_ShouldRevokeRefreshTokens_WhenItSucceeds()
    {
        var (api, _) = await StartAsync(postgres);
        await using var __ = api;
        var (email, member) = await NewMemberAsync(api);
        using var login = JsonDocument.Parse(await (await api.LoginAsync(email, TestApi.MemberPassword)).Content.ReadAsStringAsync(Ct));
        var oldRefresh = login.RootElement.GetProperty("refreshToken").GetString()!;

        var changed = await member.PutAsJsonAsync("/api/v1/accounts/me/password",
            new ChangePasswordRequest(TestApi.MemberPassword, "New-password-1"), Ct);
        Assert.Equal(HttpStatusCode.NoContent, changed.StatusCode);

        var refreshed = await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/refresh",
            new RefreshRequest(oldRefresh), Ct);
        Assert.Equal(HttpStatusCode.Unauthorized, refreshed.StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await api.LoginAsync(email, "New-password-1")).StatusCode);
    }

    [Fact]
    public async Task ChangePassword_ShouldLockTheAccount_WhenTheCurrentPasswordIsWrongRepeatedly()
    {
        var (api, _) = await StartAsync(postgres);
        await using var __ = api;
        var (email, member) = await NewMemberAsync(api);

        for (var attempt = 0; attempt < 5; attempt++)
            await member.PutAsJsonAsync("/api/v1/accounts/me/password",
                new ChangePasswordRequest("Wrong-password-1", "New-password-1"), Ct);

        var blocked = await member.PutAsJsonAsync("/api/v1/accounts/me/password",
            new ChangePasswordRequest(TestApi.MemberPassword, "New-password-1"), Ct);

        Assert.Equal((HttpStatusCode)423, blocked.StatusCode);
        Assert.Equal((HttpStatusCode)423, (await api.LoginAsync(email, TestApi.MemberPassword)).StatusCode);
    }

    [Fact]
    public async Task ChangePassword_ShouldRefuse_WhenAccountHasNoPassword()
    {
        var (api, _) = await StartAsync(postgres);
        await using var __ = api;
        var (email, member) = await NewMemberAsync(api);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
            var user = await users.FindByEmailAsync(email);
            Assert.True((await users.RemovePasswordAsync(user!)).Succeeded);
        }

        var response = await member.PutAsJsonAsync("/api/v1/accounts/me/password",
            new ChangePasswordRequest(TestApi.MemberPassword, "New-password-1"), Ct);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task PasswordResetLink_ShouldResetPassword_WhenAnAdminMakesOne()
    {
        var (api, _) = await StartAsync(postgres);
        await using var __ = api;
        await AdmitAsync(api);
        var email = TestApi.NewEmail();
        var registered = await api.RegisterAsync(email);
        var account = await registered.Content.ReadFromJsonAsync<RegisterResponse>(Ct);
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

        var linkResponse = await admin.PostAsync($"/api/v1/admin/users/{account!.Id}/password-reset-link", null, Ct);
        Assert.Equal(HttpStatusCode.OK, linkResponse.StatusCode);
        var link = await linkResponse.Content.ReadFromJsonAsync<PasswordResetLinkResponse>(Ct);
        var query = Fragment(link!.Link);

        var reset = await ResetAsync(api, query["email"], query["token"], "New-password-1");
        Assert.Equal(HttpStatusCode.NoContent, reset.StatusCode);
        // The link is the admin's way in when email is off; here the address still has to be confirmed to sign in.
        await ConfirmAsync(api, email);

        Assert.Equal(HttpStatusCode.OK, (await api.LoginAsync(email, "New-password-1")).StatusCode);
    }

    [Fact]
    public async Task PasswordResetLink_ShouldBeForbidden_WhenCallerIsNotAnAdmin()
    {
        var (api, _) = await StartAsync(postgres);
        await using var __ = api;
        var (_, member) = await NewMemberAsync(api);

        var response = await member.PostAsync($"/api/v1/admin/users/{Guid.NewGuid()}/password-reset-link", null, Ct);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task PasswordResetLink_ShouldRefuse_WhenAccountHasNoPassword()
    {
        var (api, _) = await StartAsync(postgres);
        await using var __ = api;
        var email = TestApi.NewEmail();
        Guid id;
        // The admin needs a session; email is on here, so its address is confirmed first.
        await AdmitAsync(api);
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
            var user = new User
            {
                UserName = email,
                Email = email,
                DisplayName = "Sso Rider",
                IsApproved = true,
                EmailConfirmed = true,
                CreatedAt = DateTimeOffset.UtcNow,
            };
            Assert.True((await users.CreateAsync(user)).Succeeded);
            id = user.Id;
        }
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

        var response = await admin.PostAsync($"/api/v1/admin/users/{id}/password-reset-link", null, Ct);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Login_ShouldSetASessionCookie_WhenStayLoggedInIsOff()
    {
        await using var api = (await StartAsync(postgres, smtp: false)).Api;
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();

        var response = await api.CreateClient().PostAsJsonAsync(
            "/api/v1/accounts/login",
            new LoginRequest(email, TestApi.MemberPassword, UseCookies: true, RememberMe: false),
            Ct);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        var cookie = Assert.Single(
            response.Headers.GetValues("Set-Cookie"),
            value => value.Contains("Identity.Application", StringComparison.Ordinal));
        Assert.DoesNotContain("expires=", cookie, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("max-age=", cookie, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Login_ShouldSetAPersistentCookie_WhenStayLoggedInIsOn()
    {
        await using var api = (await StartAsync(postgres, smtp: false)).Api;
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();

        var response = await api.CreateClient().PostAsJsonAsync(
            "/api/v1/accounts/login",
            new LoginRequest(email, TestApi.MemberPassword, UseCookies: true, RememberMe: true),
            Ct);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        var cookie = Assert.Single(
            response.Headers.GetValues("Set-Cookie"),
            value => value.Contains("Identity.Application", StringComparison.Ordinal));
        Assert.Contains("expires=", cookie, StringComparison.OrdinalIgnoreCase);
    }
}
