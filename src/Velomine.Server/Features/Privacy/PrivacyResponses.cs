namespace Velomine.Server.Features.Privacy;

/// <summary>
/// The six stream switches of the last release, kept in the response so an older app still reads it: they no longer
/// do anything, so they always answer false.
/// </summary>
public sealed record PrivacyStreamsResponse(
    bool HideHeartRate,
    bool HidePower,
    bool HideCadence,
    bool HideSpeed,
    bool HideElevation,
    bool HideTemperature);

public sealed record PrivacyZoneResponse(Guid Id, string Name, double Latitude, double Longitude, int RadiusM);

/// <summary>The member's privacy choices: what is hidden and where.</summary>
public sealed record PrivacyResponse(PrivacyStreamsResponse Streams, int TrimStartM, int TrimEndM, PrivacyZoneResponse[] Zones)
{
    public static PrivacyResponse From(PrivacySettings? settings, IReadOnlyList<PrivacyZone> zones) => new(
        new PrivacyStreamsResponse(false, false, false, false, false, false),
        settings?.TrimStartM ?? 0,
        settings?.TrimEndM ?? 0,
        [.. zones.Select(z => new PrivacyZoneResponse(z.Id, z.Name, z.Latitude, z.Longitude, z.RadiusM))]);
}
