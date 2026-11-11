namespace Velomine.Server.Features.Rides;

/// <summary>The member's own words on a ride: one rule for what counts as empty and how long a text may be.</summary>
public static class RideText
{
    public const int MaxTitle = 120;
    public const int MaxDescription = 2000;

    /// <summary>The text without surrounding whitespace, or null when nothing is left.</summary>
    public static string? Clean(string? text) => string.IsNullOrWhiteSpace(text) ? null : text.Trim();

    /// <summary>
    /// A text read from a file or an export, which no member typed here: cleaned and cut to <paramref name="max"/>
    /// characters (never in the middle of a surrogate pair) so a long name never fails a ride.
    /// </summary>
    public static string? Imported(string? text, int max)
    {
        var clean = Clean(text);
        if (clean is null || clean.Length <= max) return clean;
        var length = char.IsHighSurrogate(clean[max - 1]) ? max - 1 : max;
        return Clean(clean[..length]);
    }

    /// <summary>The pattern for a case-insensitive "contains" match, with LIKE's own wildcards made literal.</summary>
    public static string ContainsPattern(string term) =>
        "%" + term.Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_") + "%";

    public const string LikeEscape = "\\";
}
