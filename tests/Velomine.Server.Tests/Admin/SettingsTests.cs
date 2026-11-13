using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;

namespace Velomine.Server.Tests.Admin;

[Collection("postgres")]
public sealed class SettingsTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync(Action<IWebHostBuilder>? more = null) => TestApi.StartAsync(postgres, b => more?.Invoke(b));

    /// <summary>Email is on in these tests, so the admin's address is confirmed before it can sign in.</summary>
    private static async Task<HttpClient> AdminAsync(TestApi api)
    {
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
            var admin = (await users.FindByEmailAsync(TestApi.AdminEmail))!;
            Assert.True((await users.ConfirmEmailAsync(admin, await users.GenerateEmailConfirmationTokenAsync(admin))).Succeeded);
        }

        return await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
    }

    /// <summary>Approval is off by default now, so the member is in as soon as it signs up.</summary>
    private static async Task<HttpClient> MemberAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        return await api.SignedInClientAsync(email, TestApi.MemberPassword);
    }

    private static Task<HttpResponseMessage> SaveAsync(HttpClient admin, bool signUp = true, bool approval = true) =>
        admin.PutAsJsonAsync("/api/v1/admin/settings", new UpdateSettingsRequest(signUp, approval), Ct);

    [Fact]
    public async Task AdminSettings_ShouldBeForbidden_WhenCallerIsNotAnAdmin()
    {
        await using var api = await StartAsync();
        var member = await MemberAsync(api);

        Assert.Equal(HttpStatusCode.Unauthorized, (await api.CreateClient().GetAsync("/api/v1/admin/settings", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await member.GetAsync("/api/v1/admin/settings", Ct)).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await SaveAsync(member)).StatusCode);
    }

    [Fact]
    public async Task AdminSettings_ShouldReturnEnvironmentValues_WhenNothingIsSaved()
    {
        await using var api = await StartAsync(b =>
        {
            b.UseSetting("Velomine:Accounts:SignUpEnabled", "false");
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        });
        var admin = await AdminAsync(api);

        var settings = await admin.GetFromJsonAsync<SettingsResponse>("/api/v1/admin/settings", Ct);

        Assert.False(settings!.SignUpEnabled);
        Assert.False(settings.RequireAdminApproval);
        Assert.False(settings.Smtp.Configured);
        Assert.False(settings.Sso.Enabled);
    }

    [Fact]
    public async Task AdminSettings_ShouldShowSmtpAndSsoWithoutSecrets_WhenRead()
    {
        await using var api = await StartAsync(b =>
        {
            b.UseSetting("Velomine:Smtp:Host", "smtp.club.example");
            b.UseSetting("Velomine:Smtp:Port", "2525");
            b.UseSetting("Velomine:Smtp:From", "velomine@club.example");
            b.UseSetting("Velomine:Smtp:User", "mailer-user-xyz");
            b.UseSetting("Velomine:Smtp:Password", "smtp-password-xyz");
            b.UseSetting("Velomine:Sso:Authority", "https://idp.club.example");
            b.UseSetting("Velomine:Sso:ClientId", "client-id-xyz");
            b.UseSetting("Velomine:Sso:ClientSecret", "client-secret-xyz");
            b.UseSetting("Velomine:Sso:DisplayName", "Club login");
        });
        var admin = await AdminAsync(api);

        var json = await admin.GetStringAsync("/api/v1/admin/settings", Ct);
        var settings = await admin.GetFromJsonAsync<SettingsResponse>("/api/v1/admin/settings", Ct);

        Assert.Equal(new SmtpStatus(true, "smtp.club.example", 2525, "starttls", "velomine@club.example"), settings!.Smtp);
        Assert.Equal(new SsoStatus(true, "Club login", "https://idp.club.example"), settings.Sso);
        foreach (var secret in new[] { "mailer-user-xyz", "smtp-password-xyz", "client-id-xyz", "client-secret-xyz" })
            Assert.DoesNotContain(secret, json);

        // And saving cannot reach them: the request has no such fields, and what is saved is not returned from elsewhere.
        var saved = await (await SaveAsync(admin)).Content.ReadAsStringAsync(Ct);
        foreach (var secret in new[] { "mailer-user-xyz", "smtp-password-xyz", "client-id-xyz", "client-secret-xyz" })
            Assert.DoesNotContain(secret, saved);
    }

    [Fact]
    public async Task AdminSettings_ShouldOverrideTheEnvironment_WhenValuesAreSaved()
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);

        var put = await SaveAsync(admin, signUp: true, approval: false);
        Assert.Equal(HttpStatusCode.OK, put.StatusCode);
        var saved = await put.Content.ReadFromJsonAsync<SettingsResponse>(Ct);
        Assert.False(saved!.RequireAdminApproval);

        // New accounts no longer wait for approval.
        var registered = await (await api.RegisterAsync(TestApi.NewEmail())).Content.ReadFromJsonAsync<RegisterResponse>(Ct);
        Assert.True(registered!.IsApproved);

        // Sign-up off closes the door.
        await SaveAsync(admin, signUp: false, approval: false);
        Assert.Equal(HttpStatusCode.Forbidden, (await api.RegisterAsync(TestApi.NewEmail())).StatusCode);
    }

    [Theory]
    [InlineData("smtp.example", null, "starttls", 587)]
    [InlineData(null, "velomine@example", "starttls", 587)]
    [InlineData("smtp.example", "velomine@example", "tls", 587)]
    [InlineData("smtp.example", "velomine@example", "starttls", 0)]
    public void SmtpOptionsValidator_ShouldFail_WhenSettingsAreIncompleteOrWrong(string? host, string? from, string security, int port)
    {
        var result = new SmtpOptionsValidator().Validate(null, new SmtpOptions { Host = host, From = from, Security = security, Port = port });

        Assert.True(result.Failed);
    }

    [Fact]
    public void SmtpOptionsValidator_ShouldPassAndMeanEmailIsOff_WhenNothingIsSet()
    {
        var options = new SmtpOptions();

        Assert.True(new SmtpOptionsValidator().Validate(null, options).Succeeded);
        Assert.False(options.Configured);
    }
}
