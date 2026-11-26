using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Privacy;

/// <summary>How much of the start and end of every ride a non-owner may see. One row per member.</summary>
public sealed class PrivacySettings
{
    public Guid UserId { get; set; }

    // Unused since pack-2-gaps-2 Task 10; drop the column in the next release.
    public bool HideHeartRate { get; set; }

    // Unused since pack-2-gaps-2 Task 10; drop the column in the next release.
    public bool HidePower { get; set; }

    // Unused since pack-2-gaps-2 Task 10; drop the column in the next release.
    public bool HideCadence { get; set; }

    // Unused since pack-2-gaps-2 Task 10; drop the column in the next release.
    public bool HideSpeed { get; set; }

    // Unused since pack-2-gaps-2 Task 10; drop the column in the next release.
    public bool HideElevation { get; set; }

    // Unused since pack-2-gaps-2 Task 10; drop the column in the next release.
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

/// <summary>
/// The start and end of every ride a non-owner may see. The member's row in <see cref="PrivacySettings"/> is the
/// default for new rides; a ride keeps its own copy from the moment it is imported (<see cref="Ride.Privacy"/>), so
/// changing the default never changes what a viewer sees of an older ride.
/// </summary>
public sealed record PrivacyDefaults(int TrimStartM, int TrimEndM)
{
    /// <summary>No trim: what a member with no saved settings imports, and the safe base in a test.</summary>
    public static readonly PrivacyDefaults None = new(0, 0);

    public static PrivacyDefaults From(PrivacySettings? settings) => settings is null
        ? None
        : new(settings.TrimStartM, settings.TrimEndM);
}

/// <summary>The owner's rules for one ride, loaded once per non-owner view. Zones are always the current ones: they are places, not a copy.</summary>
public sealed record PrivacyProfile(PrivacyDefaults Defaults, IReadOnlyList<PrivacyZone> Zones)
{
    public int TrimStartM => Defaults.TrimStartM;

    public int TrimEndM => Defaults.TrimEndM;
}

/// <summary>
/// The one place every non-owner view is redacted, and it redacts the route only: the start and end trim, the saved
/// places, and the routes grant that positions need at all. Every number and stream of a shared ride reaches a coach
/// as it is. The owner never goes through here. A hidden point keeps its sample but loses its position, so charts
/// still line up and the client breaks the route line at the gap instead of drawing across it.
/// </summary>
public static class PrivacyRules
{
    /// <summary>
    /// The rules for one ride: the trim it was imported with, so changing the member's default today never exposes a
    /// ride that was imported while its start or end was hidden. The zones are today's, because they are places.
    /// A ride imported before the snapshot existed falls back to the member's current trim. Load the whole ride
    /// row: <see cref="Ride.Privacy"/> reads the columns.
    /// </summary>
    public static async Task<PrivacyProfile> LoadAsync(VelomineDbContext db, Guid userId, Ride ride, CancellationToken ct) =>
        new(ride.Privacy ?? await CurrentDefaultsAsync(db, userId, ct), await ZonesAsync(db, userId, ct));

    private static async Task<PrivacyDefaults> CurrentDefaultsAsync(VelomineDbContext db, Guid userId, CancellationToken ct) =>
        PrivacyDefaults.From(await db.PrivacySettings.AsNoTracking().FirstOrDefaultAsync(s => s.UserId == userId, ct));

    private static Task<List<PrivacyZone>> ZonesAsync(VelomineDbContext db, Guid userId, CancellationToken ct) =>
        db.PrivacyZones.AsNoTracking().Where(z => z.UserId == userId).ToListAsync(ct);

    /// <summary>
    /// A ride for a viewer with the rides grant: every number of it, as the rider's own page shows them. Title and
    /// description are the member's own words about the ride and pass through on purpose (unlike the per-ride
    /// wellbeing note, which only the owner ever reads). Only what is the rider's own answer, rather than a number
    /// about the ride, stays theirs: the FTP suggestion, the heart-rate notes and the effort score. A viewer without
    /// the grant never reaches this function.
    /// </summary>
    public static RideResponse ForViewer(RideResponse ride) => ride with
    {
        FtpSuggestionW = null, // never shown to a coach or a share viewer
        FtpSuggestionEffortW = null,
        FtpSuggestionMethod = null,
        FtpSuggestionId = null,
        // The rider's own answer and what their ride did to their numbers: theirs only.
        HeartRateNote = null,
        HeartRateMaxNote = null,
        HeartRateThresholdNote = null,
        // The effort score is the owner's: a coach or a share viewer reads the ride's load, not its effort.
        EffortScore = null,
        EffortSource = null,
    };

    /// <summary>
    /// Streams for a viewer: every signal as the rider recorded it, and the route only with the member's separate
    /// routes grant, trimmed and with the saved places cut out. Without the grant every position is hidden, whatever
    /// the zones say.
    /// shortcut: zones are applied after sampling; one averaged point across a zone edge can sit just outside it.
    /// Upgrade if zones ever need to be exact at any zoom.
    /// </summary>
    public static RideStreamsResponse ForViewer(RideStreamsResponse streams, PrivacyProfile privacy, bool showRoute)
    {
        var result = streams;

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
