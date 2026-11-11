using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Privacy;

/// <summary>Which signals a non-owner may see, and how much of the start and end of every ride is hidden. One row per member.</summary>
public sealed class PrivacySettings
{
    public Guid UserId { get; set; }

    public bool HideHeartRate { get; set; }

    public bool HidePower { get; set; }

    public bool HideCadence { get; set; }

    public bool HideSpeed { get; set; }

    public bool HideElevation { get; set; }

    public bool HideTemperature { get; set; }

    /// <summary>Metres hidden at the start of every ride. 0 is off.</summary>
    public int TrimStartM { get; set; }

    /// <summary>Metres hidden at the end of every ride. 0 is off.</summary>
    public int TrimEndM { get; set; }

    public DateTimeOffset UpdatedAt { get; set; }
}

/// <summary>A saved place whose surroundings a non-owner never sees. The radius is capped at one mile.</summary>
public sealed class PrivacyZone
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string Name { get; set; } = "";

    public double Latitude { get; set; }

    public double Longitude { get; set; }

    public int RadiusM { get; set; }

    public DateTimeOffset CreatedAt { get; set; }
}

public static class PrivacyValues
{
    public const int MinRadiusM = 200;
    public const int MaxRadiusM = 1609;
    public const int MaxZones = 10;
    public const int MaxTrimM = 5000;
}

/// <summary>The owner's rules, loaded once per non-owner view.</summary>
public sealed record PrivacyProfile(
    bool HideHeartRate,
    bool HidePower,
    bool HideCadence,
    bool HideSpeed,
    bool HideElevation,
    bool HideTemperature,
    int TrimStartM,
    int TrimEndM,
    IReadOnlyList<PrivacyZone> Zones)
{
    public static readonly PrivacyProfile None = new(false, false, false, false, false, false, 0, 0, []);

    public bool HidesPowerOrHeartRate => HidePower || HideHeartRate;

    public static PrivacyProfile From(PrivacySettings? settings, IReadOnlyList<PrivacyZone> zones) => settings is null
        ? None with { Zones = zones }
        : new(
            settings.HideHeartRate,
            settings.HidePower,
            settings.HideCadence,
            settings.HideSpeed,
            settings.HideElevation,
            settings.HideTemperature,
            settings.TrimStartM,
            settings.TrimEndM,
            zones);
}

/// <summary>
/// The one place every non-owner view is redacted: stream switches, privacy zones and start/end trimming. The owner
/// never goes through here. A hidden point keeps its sample but loses its position, so charts still line up and the
/// client breaks the route line at the gap instead of drawing across it.
/// </summary>
public static class PrivacyRules
{
    public static async Task<PrivacyProfile> LoadAsync(VelomineDbContext db, Guid userId, CancellationToken ct)
    {
        var settings = await db.PrivacySettings.AsNoTracking()
            .FirstOrDefaultAsync(s => s.UserId == userId, ct);
        var zones = await db.PrivacyZones.AsNoTracking()
            .Where(z => z.UserId == userId)
            .ToListAsync(ct);
        return PrivacyProfile.From(settings, zones);
    }

    /// <summary>The stream switches for several owners at once, for a roster that shows their summaries.</summary>
    public static async Task<Dictionary<Guid, PrivacyProfile>> LoadManyAsync(
        VelomineDbContext db,
        IReadOnlyCollection<Guid> userIds,
        CancellationToken ct)
    {
        if (userIds.Count == 0) return [];
        var ids = userIds.Distinct().ToList();
        var settings = await db.PrivacySettings.AsNoTracking()
            .Where(s => ids.Contains(s.UserId))
            .ToListAsync(ct);
        var byUser = settings.ToDictionary(s => s.UserId);
        return ids.ToDictionary(id => id, id => PrivacyProfile.From(byUser.GetValueOrDefault(id), []));
    }

    public static RideResponse ForViewer(RideResponse ride, PrivacyProfile privacy) => ride with
    {
        AvgHeartRate = privacy.HideHeartRate ? null : ride.AvgHeartRate,
        MaxHeartRate = privacy.HideHeartRate ? null : ride.MaxHeartRate,
        Trimp = privacy.HideHeartRate ? null : ride.Trimp,
        HeartRateZones = privacy.HideHeartRate ? null : ride.HeartRateZones,
        AvgPowerW = privacy.HidePower ? null : ride.AvgPowerW,
        MaxPowerW = privacy.HidePower ? null : ride.MaxPowerW,
        NormalizedPowerW = privacy.HidePower ? null : ride.NormalizedPowerW,
        IntensityFactor = privacy.HidePower ? null : ride.IntensityFactor,
        Tss = privacy.HidePower ? null : ride.Tss,
        PowerZones = privacy.HidePower ? null : ride.PowerZones,
        AvgCadence = privacy.HideCadence ? null : ride.AvgCadence,
        AvgSpeedMs = privacy.HideSpeed ? null : ride.AvgSpeedMs,
        MaxSpeedMs = privacy.HideSpeed ? null : ride.MaxSpeedMs,
        ElevationGainM = privacy.HideElevation ? null : ride.ElevationGainM,
        ElevationLossM = privacy.HideElevation ? null : ride.ElevationLossM,
    };

    public static LapResponse ForViewer(LapResponse lap, PrivacyProfile privacy) => lap with
    {
        AvgHeartRate = privacy.HideHeartRate ? null : lap.AvgHeartRate,
        MaxHeartRate = privacy.HideHeartRate ? null : lap.MaxHeartRate,
        AvgPowerW = privacy.HidePower ? null : lap.AvgPowerW,
        MaxPowerW = privacy.HidePower ? null : lap.MaxPowerW,
        AvgCadence = privacy.HideCadence ? null : lap.AvgCadence,
        AvgSpeedMs = privacy.HideSpeed ? null : lap.AvgSpeedMs,
        MaxSpeedMs = privacy.HideSpeed ? null : lap.MaxSpeedMs,
        ElevationGainM = privacy.HideElevation ? null : lap.ElevationGainM,
    };

    /// <summary>
    /// Streams for a viewer. <paramref name="showRoute"/> is the member's separate routes grant; without it every
    /// position is hidden, whatever the zones say.
    /// shortcut: zones are applied after sampling; one averaged point across a zone edge can sit just outside it.
    /// Upgrade if zones ever need to be exact at any zoom.
    /// </summary>
    public static RideStreamsResponse ForViewer(RideStreamsResponse streams, PrivacyProfile privacy, bool showRoute)
    {
        var result = streams with
        {
            HeartRate = privacy.HideHeartRate ? null : streams.HeartRate,
            Power = privacy.HidePower ? null : streams.Power,
            Cadence = privacy.HideCadence ? null : streams.Cadence,
            Speed = privacy.HideSpeed ? null : streams.Speed,
            Altitude = privacy.HideElevation ? null : streams.Altitude,
            Temperature = privacy.HideTemperature ? null : streams.Temperature,
        };

        if (!showRoute) return result with { Latitude = null, Longitude = null };
        if (privacy.Zones.Count == 0 && privacy.TrimStartM == 0 && privacy.TrimEndM == 0) return result;
        if (streams.Latitude is not { } sourceLatitude || streams.Longitude is not { } sourceLongitude) return result;
        if (sourceLatitude.Length == 0 || sourceLatitude.Length != sourceLongitude.Length)
            return result with { Latitude = null, Longitude = null };

        // Cumulative metres at each sample, for trimming by distance rather than by point count.
        var distance = CumulativeMetres(streams, sourceLatitude, sourceLongitude);
        var total = distance[^1];
        var latitude = new double?[sourceLatitude.Length];
        var longitude = new double?[sourceLongitude.Length];
        for (var i = 0; i < latitude.Length; i++)
        {
            var la = sourceLatitude[i];
            var lo = sourceLongitude[i];
            if (la is null || lo is null) continue;
            if (privacy.TrimStartM > 0 && distance[i] < privacy.TrimStartM) continue;
            if (privacy.TrimEndM > 0 && distance[i] > total - privacy.TrimEndM) continue;
            if (privacy.Zones.Any(zone => Geo.Metres(la.Value, lo.Value, zone.Latitude, zone.Longitude) <= zone.RadiusM)) continue;
            latitude[i] = la;
            longitude[i] = lo;
        }

        return result with { Latitude = latitude, Longitude = longitude };
    }

    private static double[] CumulativeMetres(RideStreamsResponse streams, double?[] latitude, double?[] longitude)
    {
        var result = new double[latitude.Length];
        if (streams.Distance is { } stored && stored.Length == latitude.Length)
        {
            var last = 0.0;
            for (var i = 0; i < stored.Length; i++)
            {
                last = stored[i] ?? last;
                result[i] = last;
            }
            return result;
        }

        var travelled = 0.0;
        for (var i = 0; i < latitude.Length; i++)
        {
            if (i > 0 && latitude[i] is { } la && longitude[i] is { } lo
                && latitude[i - 1] is { } previousLatitude && longitude[i - 1] is { } previousLongitude)
            {
                travelled += Geo.Metres(previousLatitude, previousLongitude, la, lo);
            }
            result[i] = travelled;
        }
        return result;
    }
}
