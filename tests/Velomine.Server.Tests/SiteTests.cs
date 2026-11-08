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
        Assert.Contains("Not yet", html);
    }

    [Fact]
    public async Task Website_ShouldServeThePricingPage_WhenPricingIsRequested()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/pricing/", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var html = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.Contains("One plan. On-premise or cloud.", html);
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
}
