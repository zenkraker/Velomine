namespace Velomine.Server.Tests;

/// <summary>
/// The presentation site's content, read from site/ at the repository root. Which request reaches which file is the
/// web image's job (app/nginx.conf) and is checked by tools/smoke-test-image.sh.
/// </summary>
public sealed class SiteTests
{
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
    public async Task SitePages_ShouldDeclareTheCanonicalSiteAddress_WhenServed(string path)
    {
        var html = await ReadSiteAsync(path);

        // Absolute at velomine.eu on every copy of the site (AGENTS.md: the site's search identity).
        Assert.Contains($"<link rel=\"canonical\" href=\"https://velomine.eu{path}\">", html);
        Assert.Single(System.Text.RegularExpressions.Regex.Matches(html, "rel=\"canonical\""));
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
