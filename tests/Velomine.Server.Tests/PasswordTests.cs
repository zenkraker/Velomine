using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
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
        return (email, await api.SignedInClientAsync(email, TestApi.MemberPassword));
    }

    private static async Task<HttpResponseMessage> ForgotAsync(TestApi api, string email) =>
        await api.CreateClient().PostAsJsonAsync("/api/v1/accounts/password/forgot", new ForgotPasswordRequest(email), Ct);

    private static Dictionary<string, string> Fragment(string link) =>
        new Uri(link).Fragment.TrimStart('#')
            .Split('&', StringSplitOptions.RemoveEmptyEntries)
            .Select(part => part.Split('=', 2))
            .ToDictionary(part => part[0], part => Uri.UnescapeDataString(part[1]));

    private static (string Email, string Token) FromEmail(FakeEmailSender mail)
    {
        var link = Regex.Match(mail.Sent[^1].Body, @"https?://\S+").Value;
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
    public async Task ForgotPassword_ShouldSendOneLink_WhenAccountHasPassword()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (email, _) = await NewMemberAsync(api);

        var response = await ForgotAsync(api, email);

        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        var sent = Assert.Single(mail.Sent);
        Assert.Equal(email, sent.To);
        Assert.Equal(PasswordResetEmail.Subject, sent.Subject);
        var (linkEmail, token) = FromEmail(mail);
        Assert.Equal(email, linkEmail);
        Assert.False(string.IsNullOrEmpty(token));
    }

    [Fact]
    public async Task ForgotPassword_ShouldRefuse_WhenEmailIsNotConfigured()
    {
        var (api, mail) = await StartAsync(postgres, smtp: false);
        await using var _ = api;
        var (email, _) = await NewMemberAsync(api);

        var response = await ForgotAsync(api, email);

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
                CreatedAt = DateTimeOffset.UtcNow,
            };
            Assert.True((await users.CreateAsync(user)).Succeeded);
        }

        var response = await ForgotAsync(api, email);

        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        var sent = Assert.Single(mail.Sent);
        Assert.Equal(PasswordResetEmail.SsoSubject, sent.Subject);
        Assert.DoesNotContain("reset-password", sent.Body);
        Assert.Contains("no password", sent.Body);
    }

    [Fact]
    public async Task ResetPassword_ShouldChangePassword_WhenTokenIsValid()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;
        var (email, _) = await NewMemberAsync(api);
        await ForgotAsync(api, email);
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
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
            var user = new User
            {
                UserName = email,
                Email = email,
                DisplayName = "Sso Rider",
                IsApproved = true,
                CreatedAt = DateTimeOffset.UtcNow,
            };
            Assert.True((await users.CreateAsync(user)).Succeeded);
            id = user.Id;
        }
        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

        var response = await admin.PostAsync($"/api/v1/admin/users/{id}/password-reset-link", null, Ct);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }
}
