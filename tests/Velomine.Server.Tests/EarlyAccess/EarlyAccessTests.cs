using System.Net;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Tests.EarlyAccess;

public sealed class EarlyAccessTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static async Task<(TestApi Api, FakeEmailSender Mail)> StartAsync(PostgresFixture postgres, bool configured = true, bool smtp = true, bool demo = false)
    {
        var mail = new FakeEmailSender();
        var api = await TestApi.StartAsync(postgres, b =>
        {
            if (demo) b.UseSetting("Velomine:Demo:Enabled", "true");
            if (configured) b.UseSetting("Velomine:Feedback:Address", "feedback@club.example");
            if (smtp)
            {
                b.UseSetting("Velomine:Smtp:Host", "smtp.club.example");
                b.UseSetting("Velomine:Smtp:From", "velomine@club.example");
            }

            b.ConfigureTestServices(s => s.AddSingleton<IEmailSender>(mail));
        });
        return (api, mail);
    }

    private static Task<HttpResponseMessage> PostAsync(TestApi api, Dictionary<string, string?>? extra = null)
    {
        var fields = new Dictionary<string, string?>
        {
            ["email"] = "rider@example.org",
            ["who"] = "club",
            ["club"] = "Velo Club Girona, Girona",
            ["consent"] = "yes",
        };
        foreach (var (k, v) in extra ?? []) fields[k] = v;
        var content = new FormUrlEncodedContent(fields.Where(f => f.Value is not null).Select(f => new KeyValuePair<string, string>(f.Key, f.Value!)));
        return api.CreateClient().PostAsync("/api/v1/early-access", content, Ct);
    }

    private static string Location(HttpResponseMessage r) => r.Headers.Location!.OriginalString;

    [Fact]
    public async Task JoinEarlyAccess_ShouldEmailTheSignUpAndRedirectToSent_WhenFormIsValid()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;

        var response = await PostAsync(api);

        Assert.Equal(HttpStatusCode.SeeOther, response.StatusCode);
        Assert.Equal("/early-access/sent/", Location(response));
        var sent = Assert.Single(mail.Sent);
        Assert.Equal("feedback@club.example", sent.To);
        Assert.Equal("Velomine early access", sent.Subject);
        Assert.Contains("rider@example.org", sent.Body);
        Assert.Contains("pilot", sent.Body);
        Assert.Contains("Velo Club Girona, Girona", sent.Body);
    }

    [Theory]
    [InlineData("email", "not an email")]
    [InlineData("email", null)]
    [InlineData("who", null)]
    [InlineData("who", "coach")]
    [InlineData("consent", null)]
    [InlineData("consent", "")]
    public async Task JoinEarlyAccess_ShouldRedirectAsInvalid_WhenAFieldIsMissingOrWrong(string field, string? value)
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;

        var response = await PostAsync(api, new() { [field] = value });

        Assert.Equal(HttpStatusCode.SeeOther, response.StatusCode);
        Assert.Equal("/early-access/not-sent/?reason=invalid", Location(response));
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task JoinEarlyAccess_ShouldRedirectAsInvalid_WhenTheClubNameIsTooLong()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;

        var response = await PostAsync(api, new() { ["club"] = new string('x', 201) });

        Assert.Equal("/early-access/not-sent/?reason=invalid", Location(response));
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task JoinEarlyAccess_ShouldAcceptARiderWithoutAClubName_WhenWhoIsRider()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;

        var response = await PostAsync(api, new() { ["who"] = "rider", ["club"] = null });

        Assert.Equal("/early-access/sent/", Location(response));
        Assert.Single(mail.Sent);
    }

    [Fact]
    public async Task JoinEarlyAccess_ShouldSendNothing_WhenNoFeedbackAddressIsConfigured()
    {
        var (api, mail) = await StartAsync(postgres, configured: false);
        await using var _ = api;

        var response = await PostAsync(api);

        Assert.Equal("/early-access/not-sent/?reason=unavailable", Location(response));
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task JoinEarlyAccess_ShouldSendNothing_WhenEmailIsNotConfigured()
    {
        var (api, mail) = await StartAsync(postgres, smtp: false);
        await using var _ = api;

        var response = await PostAsync(api);

        Assert.Equal("/early-access/not-sent/?reason=unavailable", Location(response));
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task JoinEarlyAccess_ShouldRedirectAsBusy_WhenOneAddressSendsTooMany()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;

        for (var i = 0; i < 5; i++) Assert.Equal("/early-access/sent/", Location(await PostAsync(api)));
        var response = await PostAsync(api);

        Assert.Equal(HttpStatusCode.SeeOther, response.StatusCode);
        Assert.Equal("/early-access/not-sent/?reason=busy", Location(response));
        Assert.Equal(5, mail.Sent.Count);
    }

    [Fact]
    public async Task JoinEarlyAccess_ShouldStillEmailTheAddress_WhenTheServerIsADemoWithSmtp()
    {
        var (api, mail) = await StartAsync(postgres, demo: true);
        await using var _ = api;

        var response = await PostAsync(api);

        Assert.Equal("/early-access/sent/", Location(response));
        Assert.Equal("feedback@club.example", Assert.Single(mail.Sent).To);
    }
}
