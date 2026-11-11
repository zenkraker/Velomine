namespace Velomine.Server.Features.Rides;

/// <summary>The surface and style a ride was ridden on. Null when neither the file nor the member has said.</summary>
public static class Disciplines
{
    public const string Road = "road";
    public const string Gravel = "gravel";
    public const string Mountain = "mountain";
    public const string Track = "track";

    public static readonly string[] All = [Road, Gravel, Mountain, Track];
}

/// <summary>Whether the ride was assisted. Null when the file does not say and the member has not chosen.</summary>
public static class Assists
{
    public const string None = "none";
    public const string EBike = "ebike";

    public static readonly string[] All = [None, EBike];
}

/// <summary>Where the ride happened. Virtual is an indoor platform such as Zwift; indoor is a trainer without one.</summary>
public static class Environments
{
    public const string Outdoor = "outdoor";
    public const string Indoor = "indoor";
    public const string Virtual = "virtual";

    public static readonly string[] All = [Outdoor, Indoor, Virtual];
}

/// <summary>
/// The four independent dimensions that describe a ride. They are separate on purpose: an e-MTB is
/// mountain + ebike, and a commute can also be training, so no dimension has to swallow another.
/// </summary>
public sealed record RideDimensions(string? Discipline, string? Assist, string? Environment, bool? Commute)
{
    public static readonly RideDimensions Unset = new(null, null, null, null);

    /// <summary>
    /// Reads the free-text type some GPX writers put on a track ("road cycling", "mountain biking",
    /// "indoor", "commute"). Only what the words actually say is filled in.
    /// </summary>
    public static RideDimensions FromText(string? text)
    {
        if (string.IsNullOrWhiteSpace(text)) return Unset;
        var words = text.ToLowerInvariant();

        string? discipline = null;
        if (words.Contains("gravel", StringComparison.Ordinal)) discipline = Disciplines.Gravel;
        else if (words.Contains("mountain", StringComparison.Ordinal)
                 || words.Contains("mtb", StringComparison.Ordinal)
                 || words.Contains("enduro", StringComparison.Ordinal)
                 || words.Contains("downhill", StringComparison.Ordinal)
                 || words.Contains("cyclocross", StringComparison.Ordinal)
                 || words.Contains("trail", StringComparison.Ordinal)) discipline = Disciplines.Mountain;
        else if (words.Contains("track", StringComparison.Ordinal)) discipline = Disciplines.Track;
        else if (words.Contains("road", StringComparison.Ordinal) || words.Contains("street", StringComparison.Ordinal))
            discipline = Disciplines.Road;

        var assist = words.Contains("e-bike", StringComparison.Ordinal)
                     || words.Contains("ebike", StringComparison.Ordinal)
                     || words.Contains("emountainbike", StringComparison.Ordinal)
                     || words.Contains("e bike", StringComparison.Ordinal)
                     || words.Contains("electric", StringComparison.Ordinal)
                     || words.Contains("pedelec", StringComparison.Ordinal)
            ? Assists.EBike
            : null;

        string? environment = null;
        if (words.Contains("virtual", StringComparison.Ordinal)
            || words.Contains("zwift", StringComparison.Ordinal)
            || words.Contains("rouvy", StringComparison.Ordinal)) environment = Environments.Virtual;
        else if (words.Contains("indoor", StringComparison.Ordinal) || words.Contains("trainer", StringComparison.Ordinal))
            environment = Environments.Indoor;
        else if (words.Contains("outdoor", StringComparison.Ordinal)) environment = Environments.Outdoor;

        var commute = words.Contains("commut", StringComparison.Ordinal) ? true : (bool?)null;

        return new RideDimensions(discipline, assist, environment, commute);
    }
}
