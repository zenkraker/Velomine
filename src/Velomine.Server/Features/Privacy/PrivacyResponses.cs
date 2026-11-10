namespace Velomine.Server.Features.Privacy;

/// <summary>What a non-owner may see of a ride's signals. Everything is visible by default.</summary>
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
        new PrivacyStreamsResponse(
            settings?.HideHeartRate ?? false,
            settings?.HidePower ?? false,
            settings?.HideCadence ?? false,
            settings?.HideSpeed ?? false,
            settings?.HideElevation ?? false,
            settings?.HideTemperature ?? false),
        settings?.TrimStartM ?? 0,
        settings?.TrimEndM ?? 0,
        [.. zones.Select(z => new PrivacyZoneResponse(z.Id, z.Name, z.Latitude, z.Longitude, z.RadiusM))]);
}
