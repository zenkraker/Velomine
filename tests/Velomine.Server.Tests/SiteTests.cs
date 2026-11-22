namespace Velomine.Server.Tests;

/// <summary>
/// The presentation site's content, read from site/ at the repository root. GitHub Pages serves it as it is
/// (.github/workflows/pages.yml); the app lives on another host, so its links are absolute.
/// </summary>
public sealed class SiteTests
{
    [Theory]
    [InlineData("/")]
    [InlineData("/status/")]
    [InlineData("/pricing/")]
    [InlineData("/demo/")]
    [InlineData("/contact/")]
    [InlineData("/feedback/")]
    [InlineData("/feedback/sent/")]
    [InlineData("/feedback/not-sent/")]
    [InlineData("/early-access/")]
    [InlineData("/early-access/sent/")]
    [InlineData("/early-access/not-sent/")]
    [InlineData("/principles/")]
    [InlineData("/privacy/")]
    [InlineData("/terms/")]
    [InlineData("/security/")]
    public async Task SitePages_ShouldDeclareTheCanonicalSiteAddress_WhenServed(string path)
    {
        var html = await ReadSiteAsync(path);

        // Absolute at velomine.eu on every copy of the site (AGENTS.md: the site's search identity).
        Assert.Contains($"<link rel=\"canonical\" href=\"https://velomine.eu{path}\">", html);
        Assert.Single(System.Text.RegularExpressions.Regex.Matches(html, "rel=\"canonical\""));
    }

    [Theory]
    [InlineData("/feedback/", "https://demo.velomine.eu/api/v1/feedback")]
    [InlineData("/early-access/", "https://demo.velomine.eu/api/v1/early-access")]
    public async Task SiteForms_ShouldPostToTheAppHost_WhenTheSiteIsOnItsOwnHost(string path, string action)
    {
        var html = await ReadSiteAsync(path);

        // The site is on GitHub Pages and the app on another host, so the form cannot post to a path of the site's host.
        Assert.Contains($"action=\"{action}\"", html);
    }

    [Theory]
    [InlineData("/")]
    [InlineData("/status/")]
    [InlineData("/demo/")]
    public async Task SitePages_ShouldLinkToTheAppWithItsFullAddress_WhenTheSiteIsOnItsOwnHost(string path)
    {
        var html = await ReadSiteAsync(path);

        Assert.Contains("href=\"https://demo.velomine.eu/sign-in\"", html);
        Assert.DoesNotContain("href=\"/sign-in\"", html);
    }

    [Theory]
    [InlineData("/")]
    [InlineData("/demo/")]
    public async Task SitePages_ShouldPrintTheDemoPassword_WhenTheyShowTheDemoAccounts(string path)
    {
        var html = await ReadSiteAsync(path);

        // "Try the demo" opens the demo's sign-in directly, so the password a visitor needs is printed on the site.
        Assert.Contains($"<code>{Velomine.Server.Features.Demo.DemoData.Password}</code>", html);
        Assert.Contains("<code>demo-rider@velomine.eu</code>", html);
    }

    /// <summary>The file GitHub Pages serves for <paramref name="path"/>: a directory path is its index.html.</summary>
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
