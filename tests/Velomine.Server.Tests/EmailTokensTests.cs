using System.Text.Json;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Tests;

/// <summary>The email colours are a copy of docs/design/tokens.json; this fails when the file and the copy disagree.</summary>
public sealed class EmailTokensTests
{
    [Fact]
    public void EmailTokens_ShouldMatchTheDesignTokens_WhenTheFileChanges()
    {
        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        while (dir is not null && !File.Exists(Path.Combine(dir.FullName, "docs/design/tokens.json"))) dir = dir.Parent;
        Assert.NotNull(dir);
        using var file = JsonDocument.Parse(File.ReadAllText(Path.Combine(dir.FullName, "docs/design/tokens.json")));
        var root = file.RootElement;

        string Color(string name, string theme) => root.GetProperty("color").GetProperty("tokens").EnumerateArray()
            .Single(t => t.GetProperty("name").GetString() == name).GetProperty("value").GetProperty(theme).GetString()!;
        string Token(string group, string name) => root.GetProperty(group).GetProperty("tokens").EnumerateArray()
            .Single(t => t.GetProperty("name").GetString() == name).GetProperty("value").GetString()!;

        Assert.Equal(EmailTokens.CanvasDay, Color("canvas", "day"));
        Assert.Equal(EmailTokens.CanvasNight, Color("canvas", "night"));
        Assert.Equal(EmailTokens.CardDay, Color("card", "day"));
        Assert.Equal(EmailTokens.CardNight, Color("card", "night"));
        Assert.Equal(EmailTokens.InkDay, Color("ink", "day"));
        Assert.Equal(EmailTokens.InkNight, Color("ink", "night"));
        Assert.Equal(EmailTokens.InkMutedDay, Color("ink-muted", "day"));
        Assert.Equal(EmailTokens.InkMutedNight, Color("ink-muted", "night"));
        Assert.Equal(EmailTokens.Accent, Color("accent", "day"));
        Assert.Equal(EmailTokens.OnAccent, Color("on-accent", "day"));
        Assert.Equal(EmailTokens.RadiusLarge, Token("radius", "radius-lg"));
        Assert.Equal(EmailTokens.RadiusPill, Token("radius", "radius-pill"));
        Assert.Equal(EmailTokens.SpaceXl, Token("spacing", "space-xl"));
        Assert.Equal(EmailTokens.SpaceXxl, Token("spacing", "space-xxl"));
        Assert.Equal(EmailTokens.Display, root.GetProperty("type").GetProperty("families").GetProperty("display").GetString()!.Replace('"', '\''));
    }
}
