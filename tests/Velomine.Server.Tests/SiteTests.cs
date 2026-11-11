namespace Velomine.Server.Tests;

/// <summary>
/// The presentation site's content, read from site/ at the repository root. Which request reaches which file is the
/// web image's job (app/nginx.conf) and is checked by tools/smoke-test-image.sh.
/// </summary>
public sealed class SiteTests
{
    [Fact]
    public async Task Website_ShouldServeTheHomePage_WhenRootIsRequested()
    {
        var html = await ReadSiteAsync("/");
        Assert.Contains("<title>Velomine", html);
        Assert.Contains("href=\"/sign-in\"", html);
        Assert.Contains("href=\"/status/\"", html);
        Assert.Contains("href=\"/pricing/\"", html);
        Assert.Contains("href=\"/contact/\"", html);
    }

    [Fact]
    public async Task Website_ShouldServeTheStatusPage_WhenStatusIsRequested()
    {
        var html = await ReadSiteAsync("/status/");
        Assert.Contains("What works today", html);
        Assert.Contains("The v1 goal", html);
        Assert.Contains("What is still missing", html);
    }

    [Fact]
    public async Task Website_ShouldServeThePricingPage_WhenPricingIsRequested()
    {
        var html = await ReadSiteAsync("/pricing/");
        Assert.Contains("One plan for clubs. One price for solo riders.", html);
        Assert.Contains("Guided setup", html);
        Assert.Contains("No feature paywall", html);
    }

    [Fact]
    public async Task Website_ShouldServeTheContactPage_WhenContactIsRequested()
    {
        var html = await ReadSiteAsync("/contact/");
        Assert.Contains("mailto:", html);
        Assert.Contains("Tell me how your club rides", html);
    }

    [Fact]
    public async Task Website_ShouldServeThePrivacyPage_WhenPrivacyIsRequested()
    {
        var html = await ReadSiteAsync("/privacy/");
        Assert.Contains("Your data, in plain language.", html);
        Assert.Contains("Sub-processors and the DPA", html);
        Assert.Contains("Backups: up to 90 days", html);
    }

    [Fact]
    public async Task Website_ShouldServeTheTermsPage_WhenTermsIsRequested()
    {
        var html = await ReadSiteAsync("/terms/");
        Assert.Contains("The agreement, in plain language.", html);
        Assert.Contains("one yearly fee per club", html, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("no feature paywall", html, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Website_ShouldServeTheSecurityPage_WhenSecurityIsRequested()
    {
        var html = await ReadSiteAsync("/security/");
        Assert.Contains("Tell us before it becomes a problem.", html);
        Assert.Contains("/.well-known/security.txt", html);
    }

    [Fact]
    public async Task Website_ShouldServeThePrinciplesPage_WhenPrinciplesIsRequested()
    {
        var html = await ReadSiteAsync("/principles/");
        Assert.Contains("Principles, not slogans.", html);
        Assert.Contains("No feature paywall", html);
        Assert.Contains("id=\"licence\"", html);
    }

    [Fact]
    public async Task Website_ShouldServeSecurityTxt_WhenTheWellKnownPathIsRequested()
    {
        var text = await ReadSiteAsync("/.well-known/security.txt");
        Assert.Contains("Contact: mailto:", text);
        Assert.Contains("Preferred-Languages:", text);
    }

    [Fact]
    public async Task SiteStylesheet_ShouldNotUseGravelForText_WhenServed()
    {
        var css = await ReadSiteAsync("/static/site.css");
        Assert.DoesNotContain("color: var(--gravel)", css);
    }

    [Fact]
    public async Task SiteStylesheet_ShouldNotDefineACustomPropertyAsItself_WhenServed()
    {
        var css = await ReadSiteAsync("/static/site.css");
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
        var html = await ReadSiteAsync("/status/");
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
        var html = await ReadSiteAsync("/demo/");
        Assert.Contains("Try a real club", html);
        Assert.Contains("Resets every night", html);
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
        var html = await ReadSiteAsync(path);

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
        var html = await ReadSiteAsync(path);

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
        var html = await ReadSiteAsync(path);

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
        var html = await ReadSiteAsync(path);

        Assert.Contains("class=\"wordmark\" translate=\"no\"", html);
    }

    [Fact]
    public async Task SiteStylesheet_ShouldSetScrollPadding_WhenServed()
    {
        var css = await ReadSiteAsync("/static/site.css");

        Assert.Contains("scroll-padding-top", css);
    }

    [Fact]
    public async Task SiteStylesheet_ShouldNotAnimateBoxShadow_WhenServed()
    {
        var css = await ReadSiteAsync("/static/site.css");

        Assert.DoesNotMatch(@"transition:\s*[^;]*box-shadow", css);
        foreach (var keyframes in System.Text.RegularExpressions.Regex
                     .Matches(css, @"@keyframes\s+[\w-]+\s*\{(?:[^{}]*\{[^{}]*\})*[^{}]*\}")
                     .Cast<System.Text.RegularExpressions.Match>())
        {
            Assert.DoesNotContain("box-shadow", keyframes.Value);
        }
    }

    /// <summary>The file the web image serves for <paramref name="path"/>: a directory path is its index.html.</summary>
    private static async Task<string> ReadSiteAsync(string path)
    {
        var relative = path.TrimStart('/');
        if (relative.Length == 0 || relative.EndsWith('/')) relative += "index.html";
        var file = Path.Combine(SiteRoot, relative);
        Assert.True(File.Exists(file), $"site/{relative} is missing.");
        return await File.ReadAllTextAsync(file, TestContext.Current.CancellationToken);
    }

    private static readonly string SiteRoot = FindSiteRoot();

    private static string FindSiteRoot()
    {
        for (var dir = new DirectoryInfo(AppContext.BaseDirectory); dir is not null; dir = dir.Parent)
        {
            if (File.Exists(Path.Combine(dir.FullName, "Velomine.slnx"))) return Path.Combine(dir.FullName, "site");
        }

        throw new InvalidOperationException("The repository root (Velomine.slnx) was not found above the test binaries.");
    }
}
