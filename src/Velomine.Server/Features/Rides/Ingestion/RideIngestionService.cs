using Microsoft.EntityFrameworkCore;
using Npgsql;
using System.Diagnostics;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Observability;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// Reads uploaded files one at a time: parse, work out the metrics, check for a duplicate, save the ride and its samples.
/// The upload endpoint has already stored the file and a ride row in the Processing state, so a restart loses nothing:
/// on start, every ride still Processing is queued again.
/// </summary>
public sealed class RideIngestionService(
    IServiceProvider services,
    IngestionQueue queue,
    RideFileStore files,
    TimeProvider time,
    ILogger<RideIngestionService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await using (var scope = services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var unfinished = await db.Rides.Where(r => r.Status == RideStatus.Processing).Select(r => r.Id).ToListAsync(stoppingToken);
            foreach (var id in unfinished) queue.Enqueue(id);
        }

        await foreach (var id in queue.ReadAllAsync(stoppingToken))
        {
            try
            {
                await using var scope = services.CreateAsyncScope();
                await ProcessAsync(scope.ServiceProvider.GetRequiredService<VelomineDbContext>(), id, stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                return; // still Processing, so the next start picks it up
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Reading ride {RideId} failed unexpectedly.", id);
                try
                {
                    await using var scope = services.CreateAsyncScope();
                    await MarkFailedAsync(scope.ServiceProvider.GetRequiredService<VelomineDbContext>(), id, "internal_error", stoppingToken);
                }
                catch (Exception markEx) when (markEx is not OperationCanceledException)
                {
                    // The ride stays Processing and the next start tries it again; one failure must not stop the host.
                    logger.LogError(markEx, "Could not record the failure for ride {RideId}.", id);
                }
            }
        }
    }

    private async Task ProcessAsync(VelomineDbContext db, Guid id, CancellationToken ct)
    {
        var started = Stopwatch.GetTimestamp();
        try
        {
            await ProcessCoreAsync(db, id, ct);
        }
        finally
        {
            VelomineMetrics.RideIngestionDuration.Record(Stopwatch.GetElapsedTime(started).TotalMilliseconds);
        }
    }

    private async Task ProcessCoreAsync(VelomineDbContext db, Guid id, CancellationToken ct)
    {
        var ride = await db.Rides.Include(r => r.Laps).FirstOrDefaultAsync(r => r.Id == id && r.Status == RideStatus.Processing, ct);
        if (ride is null) return;

        IReadOnlyList<ParsedRide> parsed;
        try
        {
            parsed = RideFileParser.Parse(await files.ReadAsync(ride.FileSha256, ct));
        }
        catch (RideParseException ex)
        {
            await FailAsync(db, ride, ex.Code, ct);
            return;
        }
        catch (FileNotFoundException)
        {
            await FailAsync(db, ride, "file_missing", ct);
            return;
        }

        // One file can hold several rides: the first fills the row made at upload, the others get rows of their own.
        var profile = await db.Users.AsNoTracking()
            .Where(u => u.Id == ride.UserId)
            .Select(u => new { u.FtpW, u.BirthYear, u.TimeZone })
            .FirstAsync(ct);
        var maxHeartRate = User.EstimateMaxHeartRate(profile.BirthYear);
        // Copied once, onto the ride row made at upload: the activities of a multi-activity file inherit it below, and
        // a re-read from the original file leaves the columns alone because it assigns only what it derives.
        ride.Privacy ??= PrivacyDefaults.From(await db.PrivacySettings.AsNoTracking()
            .FirstOrDefaultAsync(s => s.UserId == ride.UserId, ct));
        var memberBikes = await db.Bikes.AsNoTracking()
            .Where(b => b.UserId == ride.UserId && b.IsActive)
            .OrderBy(b => b.CreatedAt)
            .ToListAsync(ct);
        var used = false;
        var read = new List<Ride>();
        string? lastError = null;
        foreach (var file in parsed)
        {
            RideMetricValues metrics;
            try
            {
                metrics = RideMetrics.Compute(
                    file.Samples,
                    file.DeviceNormalizedPowerW,
                    file.DeviceElapsedS,
                    file.DeviceMovingS,
                    file.Pauses,
                    ftpW: profile.FtpW,
                    maxHeartRate: maxHeartRate);
            }
            catch (RideParseException ex)
            {
                lastError = ex.Code;
                continue;
            }

            var target = used
                ? new Ride
                {
                    Id = Guid.CreateVersion7(),
                    UserId = ride.UserId,
                    FileSha256 = ride.FileSha256,
                    FileName = ride.FileName,
                    UploadedAt = ride.UploadedAt,
                    // Every ride read from an imported file belongs to that import; the activity id only to the first.
                    ImportId = ride.ImportId,
                    Quiet = ride.Quiet,
                    Source = ride.Source,
                    Privacy = ride.Privacy,
                }
                : ride;
            if (used) db.Rides.Add(target);
            used = true;
            read.Add(target);

            target.StartTime = file.StartTime;
            target.UtcOffsetMinutes = file.UtcOffsetMinutes
                // A GPX or TCX file has no offset; keep the member's zone at that moment so a later
                // time-zone change does not move the ride to another day.
                ?? (int)TimeZoneInfo.ConvertTime(file.StartTime, MemberClock.ZoneOf(profile.TimeZone)).Offset.TotalMinutes;
            target.Device = file.Device;
            // A name the member or an import already gave the ride is theirs; the file's only fills a gap.
            target.Title ??= file.Title;
            target.Discipline = file.Discipline;
            target.Assist = file.Assist;
            target.Environment = file.Environment;
            // The export's CSV is the only source for a commute, so it outlives what the file says.
            target.Commute = file.Commute ?? target.Commute;
            target.DedupKey = $"file:{ride.FileSha256}:{file.StartTime.ToUnixTimeSeconds()}";
            target.Error = null;
            Apply(target, metrics);
            target.StampRead(profile.FtpW, maxHeartRate);

            if (await FindOriginalAsync(db, target, ct) is { } original)
            {
                target.Status = RideStatus.Duplicate;
                target.DuplicateOf = original;
                continue;
            }

            target.BikeId ??= DefaultBike.For(memberBikes, file.Discipline, file.Assist, file.Environment, file.Commute);
            target.Status = RideStatus.Ready;
            target.Streams = ToStreams(file.Samples);
            target.Laps.Clear();
            target.Laps.AddRange(LapMetrics.Build(target.Id, file.Laps, file.Samples, file.Pauses, profile.FtpW, maxHeartRate));
            target.PowerBests.Clear();
            target.PowerBests.AddRange(PowerBests.Rows(target.Id, metrics.PowerBests));
            target.PowerBestsBackfilledAt = time.GetUtcNow();
        }

        if (!used)
        {
            await FailAsync(db, ride, lastError ?? "no_records", ct);
            return;
        }

        foreach (var r in read.Where(r => r.NotifiesMember)) Notify.RideRead(db, time, r);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException
        { SqlState: PostgresErrorCodes.UniqueViolation, ConstraintName: DedupIndex })
        {
            // Two reads of the same file finished together. The unique index lets one in; the other becomes a
            // duplicate of it, exactly as when it is seen later.
            await MarkDuplicateAsync(db, ride.Id, ride.UserId, read.FirstOrDefault()?.DedupKey, ct);
            return;
        }

        // The new rides add wear to their bike's parts; warn when one is nearly or fully worn.
        var bikes = read.Where(r => r.Status == RideStatus.Ready && r.BikeId != null).Select(r => r.BikeId!.Value).Distinct().ToList();
        VelomineMetrics.RidesIngested.Add(read.Count(r => r.Status == RideStatus.Ready));
        // An import warns once when it finishes, not once per ride: wear is recomputed from every ride each time.
        if (ride.NotifiesMember) await Notify.WornPartsAsync(db, time, ride.UserId, bikes, ct);
    }

    /// <summary>
    /// The ride this one repeats, or null. The same file is known by its hash and start time; another app's copy of the
    /// same ride is recognised by the same member, the same start within two minutes, the same elapsed time and the
    /// same distance.
    /// </summary>
    private static async Task<Guid?> FindOriginalAsync(VelomineDbContext db, Ride ride, CancellationToken ct)
    {
        var exact = await db.Rides.AsNoTracking()
            .Where(r => r.UserId == ride.UserId && r.DedupKey == ride.DedupKey
                && (r.Status == RideStatus.Processing || r.Status == RideStatus.Ready)
                && r.Id != ride.Id)
            .Select(r => (Guid?)r.Id)
            .FirstOrDefaultAsync(ct);
        if (exact is not null) return exact;

        if (ride.StartTime is not { } start || ride.ElapsedS is not { } elapsed) return null;
        var from = start.AddSeconds(-StartWindowS);
        var to = start.AddSeconds(StartWindowS);
        var candidates = await db.Rides.AsNoTracking()
            .Where(r => r.UserId == ride.UserId && r.Status == RideStatus.Ready && r.Id != ride.Id
                && r.StartTime >= from && r.StartTime <= to)
            .Select(r => new { r.Id, r.ElapsedS, r.DistanceM })
            .ToListAsync(ct);
        return candidates.FirstOrDefault(c => RideMatch.SameRide(elapsed, ride.DistanceM, c.ElapsedS, c.DistanceM))?.Id;
    }

    /// <summary>How far apart two devices' start times may be and still be the same ride.</summary>
    private const int StartWindowS = 120;

    private async Task FailAsync(VelomineDbContext db, Ride ride, string code, CancellationToken ct)
    {
        VelomineMetrics.UploadFailures.Add(1, new KeyValuePair<string, object?>("reason", code));
        ride.Status = RideStatus.Failed;
        ride.Error = code;
        ride.ParserVersion = RideParserVersion.Current;
        // An import reports its failures once, in its counts; only a direct upload notifies per ride.
        if (ride.NotifiesMember) Notify.RideRead(db, time, ride);
        await db.SaveChangesAsync(ct);
    }

    private const string DedupIndex = "ux_rides_user_dedup_key";

    private async Task MarkDuplicateAsync(VelomineDbContext db, Guid id, Guid userId, string? dedupKey, CancellationToken ct)
    {
        db.ChangeTracker.Clear();
        var survivor = await db.Rides.AsNoTracking()
            .Where(r => r.UserId == userId && r.DedupKey == dedupKey && r.Id != id
                && (r.Status == RideStatus.Processing || r.Status == RideStatus.Ready))
            .Select(r => (Guid?)r.Id)
            .FirstOrDefaultAsync(ct);
        var ride = await db.Rides.FirstOrDefaultAsync(r => r.Id == id, ct);
        if (ride is null || survivor is null) return;
        ride.DedupKey = dedupKey;
        ride.Status = RideStatus.Duplicate;
        ride.DuplicateOf = survivor;
        if (ride.NotifiesMember) Notify.RideRead(db, time, ride);
        await db.SaveChangesAsync(ct);
    }

    private async Task MarkFailedAsync(VelomineDbContext db, Guid id, string code, CancellationToken ct)
    {
        var ride = await db.Rides.FirstOrDefaultAsync(r => r.Id == id, ct);
        if (ride is null) return;
        await FailAsync(db, ride, code, ct);
    }

    internal static void Apply(Ride ride, RideMetricValues m)
    {
        ride.ElapsedS = m.ElapsedS;
        ride.MovingS = m.MovingS;
        ride.DistanceM = m.DistanceM;
        ride.ElevationGainM = m.ElevationGainM;
        ride.ElevationLossM = m.ElevationLossM;
        ride.AvgSpeedMs = m.AvgSpeedMs;
        ride.MaxSpeedMs = m.MaxSpeedMs;
        ride.SpeedSource = m.SpeedSource;
        ride.AvgPowerW = m.AvgPowerW;
        ride.MaxPowerW = m.MaxPowerW;
        ride.NormalizedPowerW = m.NormalizedPowerW;
        ride.IntensityFactor = m.IntensityFactor;
        ride.Tss = m.Tss;
        ride.Trimp = m.Trimp;
        ride.AvgHeartRate = m.AvgHeartRate;
        ride.MaxHeartRate = m.MaxHeartRate;
        ride.AvgCadence = m.AvgCadence;
    }

    /// <summary>One array per signal; a signal the file never had is left null instead of an array of nulls.</summary>
    internal static RideStreams ToStreams(IReadOnlyList<Sample> samples)
    {
        static T?[]? Column<T>(IReadOnlyList<Sample> all, Func<Sample, T?> pick)
            where T : struct
        {
            var values = all.Select(pick).ToArray();
            return values.Any(v => v.HasValue) ? values : null;
        }

        return new RideStreams
        {
            Time = [.. samples.Select(s => s.T)],
            Latitude = Column(samples, s => s.Latitude),
            Longitude = Column(samples, s => s.Longitude),
            Altitude = Column(samples, s => s.Altitude),
            Speed = Column(samples, s => s.Speed),
            Distance = Column(samples, s => s.Distance),
            HeartRate = Column(samples, s => s.HeartRate),
            Power = Column(samples, s => s.Power),
            Cadence = Column(samples, s => s.Cadence),
            Temperature = Column(samples, s => s.Temperature),
        };
    }
}
