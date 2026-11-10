using System.Net;

namespace Velomine.Server.Tests;

[Collection("postgres")]
public sealed class SiteTests(PostgresFixture postgres)
{
    [Fact]
    public async Task Website_ShouldServeTheHomePage_WhenRootIsRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("text/html", response.Content.Headers.ContentType?.MediaType);
        var html = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.Contains("<title>Velomine", html);
        Assert.Contains("href=\"/sign-in\"", html);
        Assert.Contains("href=\"/status/\"", html);
        Assert.Contains("href=\"/pricing/\"", html);
        Assert.Contains("href=\"/contact/\"", html);
    }

    [Fact]
    public async Task Website_ShouldServeTheStatusPage_WhenStatusIsRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/status/", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var html = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.Contains("What works today", html);
        Assert.Contains("The v1 goal", html);
        Assert.Contains("What is still missing", html);
    }

    [Fact]
    public async Task Website_ShouldServeThePricingPage_WhenPricingIsRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/pricing/", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var html = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.Contains("One plan for clubs. One price for solo riders.", html);
        Assert.Contains("Activation", html);
        Assert.Contains("No feature paywall", html);
    }

    [Fact]
    public async Task Website_ShouldServeTheContactPage_WhenContactIsRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/contact/", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var html = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.Contains("mailto:", html);
        Assert.Contains("Tell me how your club rides", html);
    }

    [Fact]
    public async Task Website_ShouldServeThePrivacyPage_WhenPrivacyIsRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/privacy/", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var html = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.Contains("Your data, in plain language.", html);
        Assert.Contains("Sub-processors and the DPA", html);
        Assert.Contains("Backups: up to 90 days", html);
    }

    [Fact]
    public async Task Website_ShouldServeTheTermsPage_WhenTermsIsRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/terms/", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var html = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.Contains("The agreement, in plain language.", html);
        Assert.Contains("one yearly fee per club", html, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("no feature paywall", html, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Website_ShouldServeTheSecurityPage_WhenSecurityIsRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/security/", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var html = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.Contains("Tell us before it becomes a problem.", html);
        Assert.Contains("/.well-known/security.txt", html);
    }

    [Fact]
    public async Task Website_ShouldServeThePrinciplesPage_WhenPrinciplesIsRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/principles/", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var html = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.Contains("Principles, not slogans.", html);
        Assert.Contains("No feature paywall", html);
        Assert.Contains("id=\"licence\"", html);
    }

    [Fact]
    public async Task Website_ShouldServeSecurityTxt_WhenTheWellKnownPathIsRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/.well-known/security.txt", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var text = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.Contains("Contact: mailto:", text);
        Assert.Contains("Preferred-Languages:", text);
    }

    [Fact]
    public async Task Website_ShouldNotListBuiltFeaturesAsNotYet_WhenStatusIsRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/status/", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var html = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        var start = html.IndexOf("Promised for v1, still missing", StringComparison.Ordinal);
        var end = html.IndexOf("After v1", start, StringComparison.Ordinal);
        Assert.True(start >= 0 && end > start, "The status page should have a v1 gap list.");
        var notYet = html[start..end];
        Assert.DoesNotContain("password reset", notYet, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("laps", notYet, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("Laps read from FIT and TCX", html);
        Assert.Contains("Password reset by email", html);
    }

    [Fact]
    public async Task Website_ShouldServeTheDemoPage_WhenDemoIsRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/demo/", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var html = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.Contains("Try a real club", html);
        Assert.Contains("Resets every night", html);
    }

    [Fact]
    public async Task Website_ShouldStillServeTheFlutterApp_WhenSignInIsRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/sign-in", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("text/html", response.Content.Headers.ContentType?.MediaType);
        var html = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.Contains("flutter_bootstrap.js", html);
        Assert.Contains("<base href=\"/\">", html);
        Assert.Contains("name=\"robots\" content=\"noindex\"", html);
    }

    [Fact]
    public async Task Website_ShouldRedirectToTheStatusPage_WhenTheTrailingSlashIsMissing()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/status", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.MovedPermanently, response.StatusCode);
        Assert.Equal("/status/", response.Headers.Location?.ToString());
    }

    [Fact]
    public async Task Website_ShouldRedirectToTheDemoPage_WhenTheTrailingSlashIsMissing()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/demo", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.MovedPermanently, response.StatusCode);
        Assert.Equal("/demo/", response.Headers.Location?.ToString());
    }

    [Fact]
    public async Task Website_ShouldRedirectToThePrivacyPage_WhenTheTrailingSlashIsMissing()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/privacy", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.MovedPermanently, response.StatusCode);
        Assert.Equal("/privacy/", response.Headers.Location?.ToString());
    }
}
