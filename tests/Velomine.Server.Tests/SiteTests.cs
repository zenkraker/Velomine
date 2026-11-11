using System.Net;
using Microsoft.AspNetCore.Hosting;

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
        Assert.Contains("Guided setup", html);
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
    public async Task SiteStylesheet_ShouldNotUseGravelForText_WhenServed()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/static/site.css", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var css = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        Assert.DoesNotContain("color: var(--gravel)", css);
    }

    [Fact]
    public async Task SiteStylesheet_ShouldNotDefineACustomPropertyAsItself_WhenServed()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/static/site.css", TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var css = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        foreach (var declaration in System.Text.RegularExpressions.Regex
                     .Matches(css, @"--([a-z-]+)\s*:\s*([^;}]+)")
                     .Cast<System.Text.RegularExpressions.Match>())
        {
            var name = declaration.Groups[1].Value;
            Assert.DoesNotContain($"var(--{name})", declaration.Groups[2].Value);
        }
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

    private const string AppMarker = "<!-- velomine web app -->";

    /// <summary>
    /// Starts the server with a stand-in web app, so the fallback routing is tested without a Flutter build. What the
    /// real index.html contains is Flutter's business; which requests reach it is the server's.
    /// </summary>
    private async Task<(TestApi Api, string WebRoot)> StartWithWebAppAsync()
    {
        var webRoot = Directory.CreateTempSubdirectory("velomine-webroot-").FullName;
        await File.WriteAllTextAsync(Path.Combine(webRoot, "index.html"), AppMarker, TestContext.Current.CancellationToken);
        var api = await TestApi.StartAsync(postgres, b => b.UseWebRoot(webRoot));
        return (api, webRoot);
    }

    [Theory]
    [InlineData("/sign-in")]
    [InlineData("/rides/0190a5b2-7c3e-7000-8000-000000000000")]
    [InlineData("/settings/profile")]
    public async Task Website_ShouldServeTheWebApp_WhenAnAppRouteIsRequested(string path)
    {
        var (api, webRoot) = await StartWithWebAppAsync();
        await using var _ = api;
        try
        {
            using var response = await api.CreateClient().GetAsync(path, TestContext.Current.CancellationToken);

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            Assert.Equal("text/html", response.Content.Headers.ContentType?.MediaType);
            Assert.Equal(AppMarker, await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken));
        }
        finally
        {
            Directory.Delete(webRoot, recursive: true);
        }
    }

    [Theory]
    [InlineData("/api/v1/does-not-exist")]
    [InlineData("/api")]
    [InlineData("/main.dart.js")]
    [InlineData("/assets/missing.png")]
    public async Task Website_ShouldNotServeTheWebApp_WhenAnApiPathOrFileIsMissing(string path)
    {
        var (api, webRoot) = await StartWithWebAppAsync();
        await using var _ = api;
        try
        {
            using var response = await api.CreateClient().GetAsync(path, TestContext.Current.CancellationToken);

            Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        }
        finally
        {
            Directory.Delete(webRoot, recursive: true);
        }
    }

    [Theory]
    [InlineData("/status")]
    [InlineData("/pricing")]
    [InlineData("/demo")]
    [InlineData("/contact")]
    [InlineData("/principles")]
    [InlineData("/privacy")]
    [InlineData("/terms")]
    [InlineData("/security")]
    public async Task SitePages_ShouldRedirectToTrailingSlash_WhenSlashIsMissing(string path)
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync(path, TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.MovedPermanently, response.StatusCode);
        Assert.Equal(path + "/", response.Headers.Location?.ToString());
    }

    [Theory]
    [InlineData("/")]
    [InlineData("/status/")]
    [InlineData("/pricing/")]
    [InlineData("/demo/")]
    [InlineData("/contact/")]
    [InlineData("/principles/")]
    [InlineData("/privacy/")]
    [InlineData("/terms/")]
    [InlineData("/security/")]
    public async Task SitePages_ShouldOfferTheMenuDisclosure_WhenServed(string path)
    {
        await using var api = await TestApi.StartAsync(postgres);

        var html = await FetchPageAsync(api, path);

        Assert.Contains("<details class=\"nav-menu\">", html);
        Assert.Contains("<summary aria-label=\"Menu\">", html);
    }

    [Theory]
    [InlineData("/")]
    [InlineData("/status/")]
    [InlineData("/pricing/")]
    [InlineData("/demo/")]
    [InlineData("/contact/")]
    [InlineData("/principles/")]
    [InlineData("/privacy/")]
    [InlineData("/terms/")]
    [InlineData("/security/")]
    public async Task SitePages_ShouldNotUseNumberedMarkers_WhenServed(string path)
    {
        await using var api = await TestApi.StartAsync(postgres);

        var html = await FetchPageAsync(api, path);

        Assert.DoesNotContain("class=\"num\"", html);
    }

    [Theory]
    [InlineData("/")]
    [InlineData("/status/")]
    [InlineData("/pricing/")]
    [InlineData("/demo/")]
    [InlineData("/contact/")]
    [InlineData("/principles/")]
    [InlineData("/privacy/")]
    [InlineData("/terms/")]
    [InlineData("/security/")]
    public async Task SitePages_ShouldDeclareACanonicalLink_WhenServed(string path)
    {
        await using var api = await TestApi.StartAsync(postgres);

        var html = await FetchPageAsync(api, path);

        Assert.Contains($"<link rel=\"canonical\" href=\"{path}\">", html);
        Assert.Single(System.Text.RegularExpressions.Regex.Matches(html, "rel=\"canonical\""));
    }

    [Theory]
    [InlineData("/")]
    [InlineData("/status/")]
    [InlineData("/pricing/")]
    [InlineData("/demo/")]
    [InlineData("/contact/")]
    [InlineData("/principles/")]
    [InlineData("/privacy/")]
    [InlineData("/terms/")]
    [InlineData("/security/")]
    public async Task SitePages_ShouldNotTranslateTheBrand_WhenServed(string path)
    {
        await using var api = await TestApi.StartAsync(postgres);

        var html = await FetchPageAsync(api, path);

        Assert.Contains("class=\"wordmark\" translate=\"no\"", html);
    }

    [Fact]
    public async Task SiteStylesheet_ShouldSetScrollPadding_WhenServed()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var css = await FetchPageAsync(api, "/static/site.css");

        Assert.Contains("scroll-padding-top", css);
    }

    [Fact]
    public async Task SiteStylesheet_ShouldNotAnimateBoxShadow_WhenServed()
    {
        await using var api = await TestApi.StartAsync(postgres);

        var css = await FetchPageAsync(api, "/static/site.css");

        Assert.DoesNotMatch(@"transition:\s*[^;]*box-shadow", css);
        foreach (var keyframes in System.Text.RegularExpressions.Regex
                     .Matches(css, @"@keyframes\s+[\w-]+\s*\{(?:[^{}]*\{[^{}]*\})*[^{}]*\}")
                     .Cast<System.Text.RegularExpressions.Match>())
        {
            Assert.DoesNotContain("box-shadow", keyframes.Value);
        }
    }

    [Fact]
    public async Task ItalianPath_ShouldNotRedirectToAMissingFolder_WhenTheItalianSiteIsNotBuilt()
    {
        await using var api = await TestApi.StartAsync(postgres);

        using var response = await api.CreateClient().GetAsync("/it", TestContext.Current.CancellationToken);

        Assert.NotEqual(HttpStatusCode.MovedPermanently, response.StatusCode);
        Assert.NotEqual("/it/", response.Headers.Location?.ToString());
    }

    private static async Task<string> FetchPageAsync(TestApi api, string path)
    {
        using var response = await api.CreateClient().GetAsync(path, TestContext.Current.CancellationToken);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
    }
}
