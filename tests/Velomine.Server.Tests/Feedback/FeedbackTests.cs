using System.Net;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Tests.Feedback;

public sealed class FeedbackTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static async Task<(TestApi Api, FakeEmailSender Mail)> StartAsync(PostgresFixture postgres, bool configured = true, bool smtp = true)
    {
        var mail = new FakeEmailSender();
        var api = await TestApi.StartAsync(postgres, b =>
        {
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

    private static Task<HttpResponseMessage> PostAsync(TestApi api, Dictionary<string, string>? extra = null, params string[] who)
    {
        var fields = new List<KeyValuePair<string, string>>();
        foreach (var w in who.Length == 0 ? ["A coach"] : who) fields.Add(new("who", w));
        fields.Add(new("tried", "The public demo"));
        fields.Add(new("broke", "The map did not load."));
        foreach (var (k, _) in extra ?? []) fields.RemoveAll(f => f.Key == k);
        foreach (var (k, v) in extra ?? []) fields.Add(new(k, v));
        return api.CreateClient().PostAsync("/api/v1/feedback", new FormUrlEncodedContent(fields), Ct);
    }

    private static string Location(HttpResponseMessage r) => r.Headers.Location!.OriginalString;

    [Fact]
    public async Task SendFeedback_ShouldEmailTheAnswersAndRedirectToSent_WhenFormIsValid()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;

        var response = await PostAsync(api);

        Assert.Equal(HttpStatusCode.SeeOther, response.StatusCode);
        Assert.Equal("/feedback/sent/", Location(response));
        var sent = Assert.Single(mail.Sent);
        Assert.Equal("feedback@club.example", sent.To);
        Assert.Equal("Velomine feedback", sent.Subject);
        Assert.Contains("The map did not load.", sent.Body);
        Assert.Contains("A coach", sent.Body);
    }

    [Fact]
    public async Task SendFeedback_ShouldSendNothing_WhenNoFeedbackAddressIsConfigured()
    {
        var (api, mail) = await StartAsync(postgres, configured: false);
        await using var _ = api;

        var response = await PostAsync(api);

        Assert.Equal(HttpStatusCode.SeeOther, response.StatusCode);
        Assert.Equal("/feedback/not-sent/?reason=unavailable", Location(response));
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task SendFeedback_ShouldSendNothing_WhenEmailIsNotConfigured()
    {
        var (api, mail) = await StartAsync(postgres, smtp: false);
        await using var _ = api;

        var response = await PostAsync(api);

        Assert.Equal("/feedback/not-sent/?reason=unavailable", Location(response));
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task SendFeedback_ShouldRedirectAsInvalid_WhenNoWrittenAnswerIsFilled()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;

        var response = await PostAsync(api, new() { ["broke"] = "   " });

        Assert.Equal(HttpStatusCode.SeeOther, response.StatusCode);
        Assert.Equal("/feedback/not-sent/?reason=invalid", Location(response));
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task SendFeedback_ShouldRedirectAsInvalid_WhenAFieldIsTooLong()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;

        var response = await PostAsync(api, new() { ["broke"] = new string('x', 2001) });

        Assert.Equal("/feedback/not-sent/?reason=invalid", Location(response));
        Assert.Empty(mail.Sent);
    }

    [Fact]
    public async Task SendFeedback_ShouldRedirectAsBusy_WhenOneAddressSendsTooMany()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;

        for (var i = 0; i < 5; i++) Assert.Equal("/feedback/sent/", Location(await PostAsync(api)));
        var response = await PostAsync(api);

        Assert.Equal(HttpStatusCode.SeeOther, response.StatusCode);
        Assert.Equal("/feedback/not-sent/?reason=busy", Location(response));
        Assert.Equal(5, mail.Sent.Count);
    }

    [Fact]
    public async Task SendFeedback_ShouldNotMentionTheSenderOrAReplyAddress_WhenEmailIsSent()
    {
        var (api, mail) = await StartAsync(postgres);
        await using var _ = api;

        await PostAsync(api);

        var sent = Assert.Single(mail.Sent);
        Assert.DoesNotContain("127.0.0.1", sent.Body);
        Assert.DoesNotContain("::1", sent.Body);
        Assert.DoesNotContain("Reply", sent.Body, StringComparison.OrdinalIgnoreCase);
        Assert.Equal(["To", "Subject", "Body", "HtmlBody"], typeof(OutgoingEmail).GetProperties().Select(p => p.Name).Where(n => n != "EqualityContract"));
    }
}
