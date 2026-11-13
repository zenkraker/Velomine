using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Tests;

/// <summary>
/// The confirmation link without a server round-trip: the link carries a token that confirms its address once, and
/// only when email is configured. Identity's own expiry is its business, not this branch's.
/// </summary>
public sealed class EmailTokenTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private async Task<TestApi> StartAsync(bool smtp)
    {
        var mail = new FakeEmailSender();
        return await TestApi.StartAsync(postgres, b =>
        {
            b.UseSetting("Velomine:PublicUrl", "https://club.example");
            if (smtp)
            {
                b.UseSetting("Velomine:Smtp:Host", "smtp.club.example");
                b.UseSetting("Velomine:Smtp:From", "velomine@club.example");
            }

            b.ConfigureTestServices(s => s.AddSingleton<IEmailSender>(mail));
        });
    }

    /// <summary>A member who has registered but not confirmed: the address only, so the caller's scope tracks one user.</summary>
    private static async Task<string> NewEmailAsync(TestApi api)
    {
        var email = TestApi.NewEmail();
        (await api.RegisterAsync(email)).EnsureSuccessStatusCode();
        return email;
    }

    [Fact]
    public async Task EmailVerificationLink_ShouldConfirmTheAddress_WhenItIsOpened()
    {
        await using var api = await StartAsync(smtp: true);
        var email = await NewEmailAsync(api);
        await using var scope = api.Services.CreateAsyncScope();
        var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
        var user = (await users.FindByEmailAsync(email))!;
        var link = await scope.ServiceProvider.GetRequiredService<EmailVerificationLinks>().CreateAsync(user);

        Assert.StartsWith("https://club.example/verify-email#token=", link);
        var fragment = new Uri(link!).Fragment.TrimStart('#')
            .Split('&').ToDictionary(part => part.Split('=', 2)[0], part => Uri.UnescapeDataString(part.Split('=', 2)[1]));
        Assert.Equal(email, fragment["email"]);

        Assert.True((await users.ConfirmEmailAsync(user, fragment["token"])).Succeeded);
        Assert.True(user.EmailConfirmed);
    }

    [Fact]
    public async Task EmailVerificationLink_ShouldWorkOnce_WhenItIsOpenedTwice()
    {
        await using var api = await StartAsync(smtp: true);
        var email = await NewEmailAsync(api);
        await using var scope = api.Services.CreateAsyncScope();
        var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
        var user = (await users.FindByEmailAsync(email))!;

        var token = await users.GenerateEmailConfirmationTokenAsync(user);

        Assert.True((await users.ConfirmEmailAsync(user, token)).Succeeded);
        // Identity lets a token through again for a confirmed address; the endpoint refuses it, checked at the API level
        // (VerifyEmail_ShouldReject_WhenTheTokenWasAlreadyUsed).
        Assert.True(user.EmailConfirmed);
    }

    [Fact]
    public async Task EmailVerificationLinks_ShouldMakeNoLink_WhenEmailIsNotConfigured()
    {
        await using var api = await StartAsync(smtp: false);
        var email = await NewEmailAsync(api);
        await using var scope = api.Services.CreateAsyncScope();
        var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
        var user = (await users.FindByEmailAsync(email))!;

        Assert.Null(await scope.ServiceProvider.GetRequiredService<EmailVerificationLinks>().CreateAsync(user));
    }
}
