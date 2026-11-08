using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Server;

namespace Velomine.Server.Tests.Admin;

[Collection("postgres")]
public sealed class SettingsTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private Task<TestApi> StartAsync(Action<IWebHostBuilder>? more = null) => TestApi.StartAsync(postgres, b => more?.Invoke(b));

    private static Task<HttpClient> AdminAsync(TestApi api) => api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);

    private static async Task<HttpClient> MemberAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        var admin = await AdminAsync(api);
        var users = await admin.GetFromJsonAsync<UserSummary[]>("/api/v1/accounts/users?pending=true", Ct);
        await admin.PostAsync($"/api/v1/accounts/users/{users!.Single(u => u.Email == email).Id}/approve", null, Ct);
        return await api.SignedInClientAsync(email, TestApi.MemberPassword);
    }

    private static Task<HttpResponseMessage> SaveAsync(HttpClient admin, bool signUp = true, bool approval = true, string? tile = null, string? credit = null) =>
        admin.PutAsJsonAsync("/api/v1/admin/settings", new UpdateSettingsRequest(signUp, approval, tile, credit), Ct);

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
            b.UseSetting("Velomine:Map:TileUrl", "https://tiles.example/{z}/{x}/{y}.png");
            b.UseSetting("Velomine:Map:Attribution", "© Example Maps");
        });
        var admin = await AdminAsync(api);

        var settings = await admin.GetFromJsonAsync<SettingsResponse>("/api/v1/admin/settings", Ct);

        Assert.False(settings!.SignUpEnabled);
        Assert.False(settings.RequireAdminApproval);
        Assert.Equal("https://tiles.example/{z}/{x}/{y}.png", settings.MapTileUrl);
        Assert.Equal("© Example Maps", settings.MapAttribution);
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
        await using var api = await StartAsync(b => b.UseSetting("Velomine:Map:TileUrl", "https://env.example/{z}/{x}/{y}.png"));
        var admin = await AdminAsync(api);

        var put = await SaveAsync(admin, signUp: true, approval: false, tile: "https://tiles.club.example/{z}/{x}/{y}.png", credit: "© Club Maps");
        Assert.Equal(HttpStatusCode.OK, put.StatusCode);
        var saved = await put.Content.ReadFromJsonAsync<SettingsResponse>(Ct);
        Assert.False(saved!.RequireAdminApproval);

        // The public server info follows the saved map.
        var info = await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", Ct);
        Assert.Equal("https://tiles.club.example/{z}/{x}/{y}.png", info!.MapTileUrl);
        Assert.Equal("© Club Maps", info.MapAttribution);

        // New accounts no longer wait for approval.
        var registered = await (await api.RegisterAsync(TestApi.NewEmail())).Content.ReadFromJsonAsync<RegisterResponse>(Ct);
        Assert.True(registered!.IsApproved);

        // Sign-up off closes the door.
        await SaveAsync(admin, signUp: false, approval: false, tile: "https://tiles.club.example/{z}/{x}/{y}.png");
        Assert.Equal(HttpStatusCode.Forbidden, (await api.RegisterAsync(TestApi.NewEmail())).StatusCode);

        // An empty address switches the map off, even though the environment sets one.
        await SaveAsync(admin, tile: "");
        info = await api.CreateClient().GetFromJsonAsync<ServerInfoResponse>("/api/v1/server", Ct);
        Assert.Null(info!.MapTileUrl);
        Assert.Null(info.MapAttribution);
    }

    [Theory]
    [InlineData("https://tiles.example/map.png")]
    [InlineData("ftp://tiles.example/{z}/{x}/{y}.png")]
    [InlineData("not a url {z}{x}{y}")]
    public async Task AdminSettings_ShouldRejectTileAddress_WhenItIsUnusable(string tile)
    {
        await using var api = await StartAsync();
        var admin = await AdminAsync(api);

        Assert.Equal(HttpStatusCode.BadRequest, (await SaveAsync(admin, tile: tile)).StatusCode);
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
