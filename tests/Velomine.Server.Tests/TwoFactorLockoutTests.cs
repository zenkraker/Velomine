using System.Net;
using System.Net.Http.Headers;
using Microsoft.Extensions.DependencyInjection;
using System.Net.Http.Json;
using System.Text.Json;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Tests;

/// <summary>When the second factor is or is not asked for, and what a wrong code costs.</summary>
public sealed class TwoFactorLockoutTests(PostgresFixture postgres, DexFixture dex)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task TwoFactor_ShouldLockTheAccount_WhenTheCodeIsWrongRepeatedly()
    {
        await using var api = await TestApi.StartAsync(postgres);
        var login = await api.LoginAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        login.EnsureSuccessStatusCode();
        // The admin has no second factor yet, so this is an ordinary sign-in; enable it, then sign in again.
        var first = await EnableTwoFactorAsync(api);

        for (var attempt = 0; attempt < 5; attempt++)
        {
            var wrong = await api.CreateClient().PostAsJsonAsync(
                "/api/v1/accounts/login/two-factor",
                new LoginTwoFactorRequest(first.Challenge, "000000"),
                Ct);
            Assert.True(
                wrong.StatusCode is HttpStatusCode.Unauthorized or (HttpStatusCode)423,
                $"Attempt {attempt + 1} answered {(int)wrong.StatusCode}.");
        }

        // The right password is now refused too: a wrong code counts towards the same lockout.
        var locked = await api.LoginAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        Assert.Equal((HttpStatusCode)423, locked.StatusCode);
    }

    [Fact]
    public async Task TwoFactor_ShouldNotBeAskedFor_WhenTheMemberSignsInWithSingleSignOn()
    {
        await dex.EnsureStartedAsync();
        await using var api = await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:Sso:Authority", dex.Authority);
            b.UseSetting("Velomine:Sso:AppClientId", DexFixture.AppClientId);
            b.UseSetting("Velomine:Sso:AllowInsecureHttp", "true");
            b.UseSetting("Velomine:Accounts:RequireAdminApproval", "false");
        });
        // Sign in once with the provider so the account exists, then turn the second factor on.
        var (idToken, accessToken) = await dex.TokensAsync(DexFixture.VerifiedEmail, Ct);
        var first = await api.CreateClient().PostAsJsonAsync(
            "/api/v1/accounts/sso/token", new ExchangeSsoTokenRequest(idToken, accessToken), Ct);
        first.EnsureSuccessStatusCode();
        // An account created by single sign-on has no password to confirm, so the factor is turned on in the store.
        await using (var scope = api.Services.CreateAsyncScope())
        {
            var users = scope.ServiceProvider.GetRequiredService<Microsoft.AspNetCore.Identity.UserManager<User>>();
            var member = await users.FindByEmailAsync(DexFixture.VerifiedEmail);
            await users.ResetAuthenticatorKeyAsync(member!);
            Assert.True((await users.SetTwoFactorEnabledAsync(member!, true)).Succeeded);
        }

        // A fresh provider sign-in goes straight through: single sign-on already proved who the member is.
        var (againId, againAccess) = await dex.TokensAsync(DexFixture.VerifiedEmail, Ct);
        var second = await api.CreateClient().PostAsJsonAsync(
            "/api/v1/accounts/sso/token", new ExchangeSsoTokenRequest(againId, againAccess), Ct);

        Assert.Equal(HttpStatusCode.OK, second.StatusCode);
        Assert.False(string.IsNullOrEmpty(JsonDocument.Parse(await second.Content.ReadAsStringAsync(Ct))
            .RootElement.GetProperty("accessToken").GetString()));
    }

    /// <summary>Turns the admin's second factor on and starts a sign-in that waits for a code.</summary>
    private static async Task<TwoFactorRequiredResponse> EnableTwoFactorAsync(TestApi api)
    {
        var client = api.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            "Bearer", await TokenAsync(api));
        var setup = await (await client.PostAsync("/api/v1/accounts/me/two-factor/start", null, Ct))
            .Content.ReadFromJsonAsync<TwoFactorSetup>(Ct);
        (await client.PostAsJsonAsync("/api/v1/accounts/me/two-factor/enable",
            new EnableTwoFactorRequest(TestApi.AdminPassword, Totp.Code(setup!.Key, DateTimeOffset.UtcNow)), Ct)).EnsureSuccessStatusCode();

        var login = await api.LoginAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        Assert.Equal(HttpStatusCode.Accepted, login.StatusCode);
        return (await login.Content.ReadFromJsonAsync<TwoFactorRequiredResponse>(Ct))!;
    }

    private static async Task<string> TokenAsync(TestApi api)
    {
        var login = await api.LoginAsync(TestApi.AdminEmail, TestApi.AdminPassword);
        login.EnsureSuccessStatusCode();
        return JsonDocument.Parse(await login.Content.ReadAsStringAsync(Ct)).RootElement.GetProperty("accessToken").GetString()!;
    }
}
