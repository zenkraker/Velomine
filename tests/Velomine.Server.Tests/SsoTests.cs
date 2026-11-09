using System.Net;
using System.Net.Http.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Hosting;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

/// <summary>The whole single sign-on flow against a real OpenID Connect provider (Dex), played by a test "browser".</summary>
[Collection("postgres")]
public sealed partial class SsoTests(PostgresFixture postgres, DexFixture dex)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private async Task<TestApi> StartAsync(Action<IWebHostBuilder>? more = null)
    {
        await dex.EnsureStartedAsync();
        return await TestApi.StartAsync(postgres, builder =>
        {
            builder.UseSetting("Velomine:Sso:Authority", DexFixture.Authority);
            builder.UseSetting("Velomine:Sso:ClientId", DexFixture.ClientId);
            builder.UseSetting("Velomine:Sso:ClientSecret", DexFixture.ClientSecret);
            builder.UseSetting("Velomine:Sso:AllowInsecureHttp", "true");
            more?.Invoke(builder);
        });
    }

    /// <summary>
    /// Plays the browser: start SSO on the server, sign in on the provider's login page, come back with the code.
    /// Returns the server's final redirect; <paramref name="server"/> then holds the session cookie if sign-in worked.
    /// </summary>
    private static async Task<HttpResponseMessage> SignInWithProviderAsync(HttpClient server, string email, string returnUrl = "/")
    {
        var query = "returnUrl=" + Uri.EscapeDataString(returnUrl);
        var start = await server.GetAsync("/api/v1/accounts/sso/login?" + query, Ct);
        Assert.Equal(HttpStatusCode.Redirect, start.StatusCode);

        using var provider = new HttpClient(new HttpClientHandler { AllowAutoRedirect = false, UseCookies = true });
        var current = start.Headers.Location!;
        Uri? callback = null;
        for (var hop = 0; hop < 12 && callback is null; hop++)
        {
            var response = await provider.GetAsync(current, Ct);
            if (response.StatusCode == HttpStatusCode.OK)
            {
                // Dex's login form: post the email and password to the form's own address.
                var html = await response.Content.ReadAsStringAsync(Ct);
                var action = WebUtility.HtmlDecode(FormAction().Match(html).Groups[1].Value);
                response = await provider.PostAsync(
                    new Uri(current, action),
                    new FormUrlEncodedContent(new Dictionary<string, string> { ["login"] = email, ["password"] = DexFixture.Password }),
                    Ct);
            }

            Assert.True((int)response.StatusCode is >= 300 and < 400, $"Unexpected {(int)response.StatusCode} from the provider at {current}");
            var next = new Uri(current, response.Headers.Location!);
            if (next.AbsoluteUri.StartsWith("http://localhost/signin-oidc")) callback = next;
            else current = next;
        }

        Assert.NotNull(callback);
        // The server exchanges the code with the provider, then redirects to its own callback slice.
        var signedIn = await server.GetAsync(callback.PathAndQuery, Ct);
        Assert.Equal(HttpStatusCode.Redirect, signedIn.StatusCode);
        return await server.GetAsync(signedIn.Headers.Location!.OriginalString, Ct);
    }

    [GeneratedRegex("action=\"([^\"]+)\"")]
    private static partial Regex FormAction();

    [Fact]
    public async Task Sso_ShouldReportWhetherItIsEnabled_WhenTheInfoEndpointIsCalled()
    {
        await using var on = await StartAsync();
        var info = await on.CreateClient().GetFromJsonAsync<SsoInfoResponse>("/api/v1/accounts/sso", Ct);
        Assert.True(info!.Enabled);
        Assert.Equal("/api/v1/accounts/sso/login", info.LoginUrl);

        await using var off = await TestApi.StartAsync(postgres);
        var none = await off.CreateClient().GetFromJsonAsync<SsoInfoResponse>("/api/v1/accounts/sso", Ct);
        Assert.False(none!.Enabled);
        Assert.Equal(HttpStatusCode.NotFound, (await off.CreateClient().GetAsync("/api/v1/accounts/sso/login", Ct)).StatusCode);
    }

    [Fact]
    public async Task Sso_ShouldCreateTheAccountAndStartASession_WhenSigningInForTheFirstTime()
    {
        await using var api = await StartAsync(b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var browser = api.CreateClient(handleCookies: true);

        var final = await SignInWithProviderAsync(browser, DexFixture.VerifiedEmail, "/rides");

        Assert.Equal("/rides", final.Headers.Location!.OriginalString);
        var me = await browser.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct);
        Assert.Equal(DexFixture.VerifiedEmail, me!.Email);
        Assert.Equal("SSO Rider", me.DisplayName);
        Assert.Equal(["member"], me.Roles);
    }

    [Fact]
    public async Task Sso_ShouldReuseTheSameAccount_WhenSigningInAgain()
    {
        await using var api = await StartAsync(b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var first = api.CreateClient(handleCookies: true);
        await SignInWithProviderAsync(first, DexFixture.VerifiedEmail);
        var id = (await first.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id;

        var second = api.CreateClient(handleCookies: true);
        await SignInWithProviderAsync(second, DexFixture.VerifiedEmail);

        Assert.Equal(id, (await second.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id);
    }

    [Fact]
    public async Task Sso_ShouldRefuseSignInUntilApproved_WhenTheAccountIsNew()
    {
        await using var api = await StartAsync(); // approval is required by default
        var browser = api.CreateClient(handleCookies: true);

        var pending = await SignInWithProviderAsync(browser, DexFixture.VerifiedEmail);
        Assert.Equal("/?sso_error=not_approved", pending.Headers.Location!.OriginalString);
        Assert.Equal(HttpStatusCode.Unauthorized, (await browser.GetAsync("/api/v1/accounts/me", Ct)).StatusCode);

        var admin = await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        var waiting = await admin.GetFromJsonAsync<UserSummary[]>("/api/v1/accounts/users?pending=true", Ct);
        var user = Assert.Single(waiting!, u => u.Email == DexFixture.VerifiedEmail);
        await admin.PostAsync($"/api/v1/accounts/users/{user.Id}/approve", null, Ct);

        var approved = await SignInWithProviderAsync(browser, DexFixture.VerifiedEmail);
        Assert.Equal("/", approved.Headers.Location!.OriginalString);
        Assert.Equal(HttpStatusCode.OK, (await browser.GetAsync("/api/v1/accounts/me", Ct)).StatusCode);
    }

    [Fact]
    public async Task Sso_ShouldLinkTheExistingAccount_WhenTheEmailIsVerified()
    {
        await using var api = await StartAsync(b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var registered = await (await api.RegisterAsync(DexFixture.VerifiedEmail)).Content.ReadFromJsonAsync<RegisterResponse>(Ct);
        var browser = api.CreateClient(handleCookies: true);

        await SignInWithProviderAsync(browser, DexFixture.VerifiedEmail);

        Assert.Equal(registered!.Id, (await browser.GetFromJsonAsync<MeResponse>("/api/v1/accounts/me", Ct))!.Id);
        var everyone = await (await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword))
            .GetFromJsonAsync<UserSummary[]>("/api/v1/accounts/users", Ct);
        Assert.Single(everyone!, u => u.Email == DexFixture.VerifiedEmail);
    }

    [Fact]
    public async Task Sso_ShouldRefuseSignIn_WhenTheEmailIsNotVerified()
    {
        await using var api = await StartAsync(b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var browser = api.CreateClient(handleCookies: true);

        var final = await SignInWithProviderAsync(browser, DexFixture.UnverifiedEmail);

        Assert.Equal("/?sso_error=email_not_verified", final.Headers.Location!.OriginalString);
        var everyone = await (await api.SignedInClientAsync(TestApi.AdminEmail, TestApi.AdminPassword))
            .GetFromJsonAsync<UserSummary[]>("/api/v1/accounts/users", Ct);
        Assert.DoesNotContain(everyone!, u => u.Email == DexFixture.UnverifiedEmail);
    }

    [Fact]
    public async Task Sso_ShouldRefuseUnknownAccounts_WhenAutoCreateIsOff()
    {
        await using var api = await StartAsync(b => b.UseSetting("Velomine:Sso:AutoCreateUsers", "false"));
        var browser = api.CreateClient(handleCookies: true);

        var final = await SignInWithProviderAsync(browser, DexFixture.VerifiedEmail);

        Assert.Equal("/?sso_error=no_account", final.Headers.Location!.OriginalString);
    }

    [Theory]
    [InlineData("https://evil.example/phish")]
    [InlineData("//evil.example")]
    [InlineData("/\\evil.example")]
    public async Task Sso_ShouldReplaceTheReturnUrlWithHome_WhenItLeavesTheServer(string returnUrl)
    {
        await using var api = await StartAsync(b => b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false"));
        var browser = api.CreateClient(handleCookies: true);

        var final = await SignInWithProviderAsync(browser, DexFixture.VerifiedEmail, returnUrl);

        Assert.Equal("/", final.Headers.Location!.OriginalString);
    }
}
