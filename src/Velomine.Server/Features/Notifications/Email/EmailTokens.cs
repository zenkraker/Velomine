namespace Velomine.Server.Features.Notifications.Email;

/// <summary>
/// The design tokens an email uses, copied from docs/design/tokens.json (the server cannot read that file at run time).
/// EmailTokensTests fails when a value here differs from the file. Day is the default; Night is the dark-mode override.
/// </summary>
public static class EmailTokens
{
    public const string CanvasDay = "#f0eee9";
    public const string CanvasNight = "#0e0f0c";
    public const string CardDay = "#ffffff";
    public const string CardNight = "#22241f";
    public const string InkDay = "#18201e";
    public const string InkNight = "#e9ebe4";
    public const string InkMutedDay = "#5c625e";
    public const string InkMutedNight = "#a6aa9e";

    /// <summary>Volt, as a fill: the button. The same in both themes, with <see cref="OnAccent"/> on it.</summary>
    public const string Accent = "#d4f23a";
    public const string OnAccent = "#0e0f0c";


    public const string RadiusLarge = "28px";
    public const string RadiusPill = "999px";
    public const string SpaceXl = "24px";
    public const string SpaceXxl = "32px";
    public const string Sans = "Geist, system-ui, -apple-system, 'Segoe UI', sans-serif";
    public const string Display = "'Instrument Serif', Georgia, serif";
}
