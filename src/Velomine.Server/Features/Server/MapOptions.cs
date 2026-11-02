namespace Velomine.Server.Features.Server;

/// <summary>
/// Bound from "Velomine:Map" (environment: Velomine__Map__TileUrl, Velomine__Map__Attribution).
/// Off by default: with no tile URL the ride map shows only the route, and the app makes no map requests to any outside server.
/// </summary>
public sealed class MapOptions
{
    /// <summary>A tile address with {z}, {x} and {y}, for example https://tile.openstreetmap.org/{z}/{x}/{y}.png</summary>
    public string? TileUrl { get; set; }

    /// <summary>The credit the tile provider requires, shown on the map, for example "© OpenStreetMap contributors".</summary>
    public string? Attribution { get; set; }

    /// <summary>The tile URL if it is usable (an http or https address with all three placeholders), otherwise null.</summary>
    public string? UsableTileUrl =>
        Uri.TryCreate(TileUrl?.Replace("{z}", "0").Replace("{x}", "0").Replace("{y}", "0"), UriKind.Absolute, out var uri)
        && uri.Scheme is "http" or "https"
        && TileUrl!.Contains("{z}") && TileUrl.Contains("{x}") && TileUrl.Contains("{y}")
            ? TileUrl
            : null;
}
