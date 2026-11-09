namespace Velomine.Server.Features.Server;

/// <summary>
/// Bound from "Velomine:Map" (environment: Velomine__Map__TileUrl, Velomine__Map__Attribution).
/// Maps are always on. A self-hoster may point the server at their own tile provider; an empty or unusable
/// address falls back to OpenStreetMap, so the map cannot be turned off.
/// </summary>
public sealed class MapOptions
{
    public const string DefaultTileUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";

    public const string DefaultAttribution = "© OpenStreetMap contributors";

    /// <summary>A tile address with {z}, {x} and {y}, for example a private tile server.</summary>
    public string? TileUrl { get; set; }

    /// <summary>The credit the tile provider requires. Empty uses the default (OpenStreetMap).</summary>
    public string? Attribution { get; set; }

    /// <summary>The address clients always get: the usable configured one, otherwise OpenStreetMap.</summary>
    public string EffectiveTileUrl => Usable(TileUrl) ? TileUrl! : DefaultTileUrl;

    /// <summary>The credit that matches the tiles actually served: a configured address may set its own.</summary>
    public string EffectiveAttribution =>
        Usable(TileUrl) && !string.IsNullOrWhiteSpace(Attribution)
            ? Attribution.Trim()
            : DefaultAttribution;

    /// <summary>An http or https address with all three placeholders.</summary>
    private static bool Usable(string? url) =>
        Uri.TryCreate(url?.Replace("{z}", "0").Replace("{x}", "0").Replace("{y}", "0"), UriKind.Absolute, out var uri)
        && uri.Scheme is "http" or "https"
        && url!.Contains("{z}") && url.Contains("{x}") && url.Contains("{y}");
}
