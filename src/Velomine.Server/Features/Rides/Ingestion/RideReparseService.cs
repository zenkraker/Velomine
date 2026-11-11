using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// Reads stored rides again from their original files when <see cref="RideParserVersion.Current"/> has been raised, so
/// a parser fix reaches a member's whole history without the member doing anything.
/// <para>
/// It is driven by the data (rides whose parser version is below the current one, oldest first), so a restart or a
/// missed run simply continues. It is a separate, slower path from <see cref="RideIngestionService"/>: it waits while
/// any upload is queued, works a small batch and pauses, so new uploads are never delayed by it.
/// </para>
/// <para>
/// A re-read replaces only what is derived from the file. Everything else on the ride is left alone by construction:
/// the fields assigned below are the whole list, so a field added to <see cref="Ride"/> later is preserved. The
/// training load is worked out from the FTP and maximum heart rate recorded when the ride was first read, never
/// today's. A ride that cannot be read again keeps all its data and status and is not tried again until the version
/// changes. A ride that failed originally is handed back to the normal reader when its file parses now.
/// </para>
/// </summary>
public sealed class RideReparseService(
    IServiceProvider services,
    IngestionQueue queue,
    RideFileStore files,
    TimeProvider time,
    ILogger<RideReparseService> logger) : BackgroundService
{
    private const int BatchSize = 20;
    private const int MaxAttempts = 3;
    private static readonly TimeSpan BatchPause = TimeSpan.FromSeconds(2);
    private static readonly TimeSpan UploadPoll = TimeSpan.FromMilliseconds(500);
    private static readonly TimeSpan Idle = TimeSpan.FromHours(1);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var stuck = new HashSet<Guid>();
        while (!stoppingToken.IsCancellationRequested)
        {
            var wait = Idle;
            try
            {
                if (await RunBatchAsync(BatchSize, RideParserVersion.Current, stuck, stoppingToken) > 0) wait = BatchPause;
                await Task.Delay(wait, time, stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                return; // the data says where to continue
            }
            catch (Exception ex)
            {
                logger.LogWarning("Reading old rides again stopped for now ({Exception}).", ex.GetType().Name);
                try
                {
                    await Task.Delay(Idle, time, stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    return;
                }
            }
        }
    }

    /// <summary>Reads every waiting ride again, without the pauses of the hosted loop. For tests and tools.</summary>
    public async Task RunAsync(CancellationToken ct, int version = RideParserVersion.Current)
    {
        var stuck = new HashSet<Guid>();
        while (await RunBatchAsync(BatchSize, version, stuck, ct) > 0)
        {
        }
    }

    /// <summary>Handles up to <paramref name="size"/> waiting rides, oldest first, and returns how many it picked.</summary>
    private async Task<int> RunBatchAsync(int size, int version, HashSet<Guid> stuck, CancellationToken ct)
    {
        List<Guid> ids;
        await using (var scope = services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            ids = await db.Rides.AsNoTracking()
                .Where(r => (r.Status == RideStatus.Ready || r.Status == RideStatus.Failed)
                    && r.ParserVersion < version
                    && !stuck.Contains(r.Id))
                .OrderBy(r => r.ParserVersion).ThenBy(r => r.UploadedAt).ThenBy(r => r.Id)
                .Select(r => r.Id)
                .Take(size)
                .ToListAsync(ct);
        }

        foreach (var id in ids)
        {
            // Strict priority: an upload that is queued is read before any old ride is touched.
            while (queue.Pending > 0) await Task.Delay(UploadPoll, time, ct);
            await ReadAgainAsync(id, version, stuck, ct);
        }

        if (ids.Count > 0) logger.LogInformation("Read {Count} stored rides again.", ids.Count);
        return ids.Count;
    }

    private async Task ReadAgainAsync(Guid id, int version, HashSet<Guid> stuck, CancellationToken ct)
    {
        string? failure;
        try
        {
            failure = await TryReadAsync(id, version, ct);
        }
        catch (OperationCanceledException) when (ct.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogWarning("Reading a stored ride again failed unexpectedly ({Exception}).", ex.GetType().Name);
            failure = "unexpected_error";
        }

        if (failure is null) return;
        logger.LogWarning("A stored ride could not be read again: {Reason}. It keeps its data and is not retried at parser version {Version}.", failure, version);
        if (!await MarkFailedAsync(id, version, ct)) stuck.Add(id); // never select the same ride forever
    }

    /// <summary>Returns null when the ride was handled (or is gone), or a short reason code when it could not be read.</summary>
    private async Task<string?> TryReadAsync(Guid id, int version, CancellationToken ct)
    {
        RideStatus status;
        string sha;
        string? dedupKey;
        DateTimeOffset? storedStart;
        await using (var scope = services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var found = await db.Rides.AsNoTracking()
                .Where(r => r.Id == id && r.ParserVersion < version && (r.Status == RideStatus.Ready || r.Status == RideStatus.Failed))
                .Select(r => new { r.Status, r.FileSha256, r.DedupKey, r.StartTime })
                .FirstOrDefaultAsync(ct);
            if (found is null) return null;
            (status, sha, dedupKey, storedStart) = (found.Status, found.FileSha256, found.DedupKey, found.StartTime);
        }

        IReadOnlyList<ParsedRide> parsed;
        try
        {
            parsed = RideFileParser.Parse(await files.ReadAsync(sha, ct));
        }
        catch (RideParseException ex)
        {
            return ex.Code;
        }
        catch (FileNotFoundException)
        {
            return "file_missing";
        }

        return status == RideStatus.Failed
            ? await RescueAsync(id, version, parsed, ct)
            : await ReplaceAsync(id, version, parsed, dedupKey, storedStart, ct);
    }

    /// <summary>
    /// A ride that failed to read before and whose file parses now goes back to the normal reader, which does
    /// everything a first read does (bike, duplicate check, the "ride read" notification) and so makes it a normal ride.
    /// </summary>
    private async Task<string?> RescueAsync(Guid id, int version, IReadOnlyList<ParsedRide> parsed, CancellationToken ct)
    {
        string? lastError = null;
        var readable = false;
        foreach (var file in parsed)
        {
            try
            {
                RideMetrics.Compute(file.Samples, file.DeviceNormalizedPowerW, file.DeviceElapsedS, file.DeviceMovingS, file.Pauses);
                readable = true;
                break;
            }
            catch (RideParseException ex)
            {
                lastError = ex.Code;
            }
        }
        if (!readable) return lastError ?? "no_records";

        await using var scope = services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var changed = await db.Rides
            .Where(r => r.Id == id && r.Status == RideStatus.Failed && r.ParserVersion < version)
            .ExecuteUpdateAsync(s => s
                .SetProperty(r => r.Status, RideStatus.Processing)
                .SetProperty(r => r.Error, (string?)null)
                .SetProperty(r => r.ParserVersion, version)
                .SetProperty(r => r.ReparseFailedVersion, (int?)null), ct);
        if (changed > 0) queue.Enqueue(id);
        return null;
    }

    private async Task<string?> ReplaceAsync(
        Guid id,
        int version,
        IReadOnlyList<ParsedRide> parsed,
        string? dedupKey,
        DateTimeOffset? storedStart,
        CancellationToken ct)
    {
        var file = Match(parsed, dedupKey, storedStart);
        if (file is null) return "activity_not_found";

        for (var attempt = 0; attempt < MaxAttempts; attempt++)
        {
            await using var scope = services.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            await using var tx = await db.Database.BeginTransactionAsync(ct);
            var ride = await db.Rides.FirstOrDefaultAsync(
                r => r.Id == id && r.Status == RideStatus.Ready && r.ParserVersion < version, ct);
            if (ride is null) return null;

            // The load comes from the profile of the first read. Where that was never recorded, the FTP is recovered
            // from the stored numbers; what cannot be recovered is left as stored.
            var recoveredFtp = ride.LoadFtpW is null
                ? RideParserVersion.RecoverFtp(ride.NormalizedPowerW, ride.MovingS, ride.IntensityFactor, ride.Tss)
                : null;
            var ftpKnown = ride.LoadFtpW is not null || recoveredFtp is not null;
            int? ftp = ride.LoadFtpW is { } recorded ? (recorded > 0 ? recorded : null) : recoveredFtp;
            var hrKnown = ride.LoadMaxHeartRate is not null;
            int? maxHr = ride.LoadMaxHeartRate is > 0 ? ride.LoadMaxHeartRate : null;

            RideMetricValues metrics;
            try
            {
                metrics = RideMetrics.Compute(
                    file.Samples, file.DeviceNormalizedPowerW, file.DeviceElapsedS, file.DeviceMovingS, file.Pauses,
                    ftpW: ftp, maxHeartRate: maxHr);
            }
            catch (RideParseException ex)
            {
                return ex.Code;
            }

            var (storedIntensity, storedTss, storedTrimp) = (ride.IntensityFactor, ride.Tss, ride.Trimp);
            RideIngestionService.Apply(ride, metrics);
            if (!ftpKnown) (ride.IntensityFactor, ride.Tss) = (storedIntensity, storedTss);
            if (!hrKnown) ride.Trimp = storedTrimp;
            if (ftpKnown) ride.LoadFtpW = ftp ?? 0;

            ride.StartTime = file.StartTime;
            ride.UtcOffsetMinutes = file.UtcOffsetMinutes ?? ride.UtcOffsetMinutes ?? await ZoneOffsetAsync(db, ride, file, ct);
            ride.Device = file.Device ?? ride.Device;
            // The member may have changed these by hand and nothing records which: only fill in what is empty.
            ride.Discipline ??= file.Discipline;
            ride.Assist ??= file.Assist;
            ride.Environment ??= file.Environment;
            ride.Commute ??= file.Commute;

            await db.RideStreams.Where(s => s.RideId == id).ExecuteDeleteAsync(ct);
            await db.RideLaps.Where(l => l.RideId == id).ExecuteDeleteAsync(ct);
            await db.RidePowerBests.Where(b => b.RideId == id).ExecuteDeleteAsync(ct);
            ride.Streams = RideIngestionService.ToStreams(file.Samples);
            ride.Laps.AddRange(LapMetrics.Build(id, file.Laps, file.Samples, file.Pauses, ftp, maxHr));
            ride.PowerBests.AddRange(PowerBests.Rows(id, metrics.PowerBests));
            ride.PowerBestsBackfilledAt = time.GetUtcNow();
            ride.ParserVersion = version;
            ride.ReparseFailedVersion = null;

            try
            {
                await db.SaveChangesAsync(ct);
                await tx.CommitAsync(ct);
                return null;
            }
            catch (DbUpdateConcurrencyException)
            {
                // The member edited the ride meanwhile: their edit is kept, and the next attempt starts from it.
            }
        }
        return "concurrent_edit";
    }

    /// <summary>
    /// Which activity of the file a stored ride is. A file with several activities becomes several rides, each keyed by
    /// the file hash and its start time, so the key picks the same activity again. A single-activity file needs no key.
    /// </summary>
    private static ParsedRide? Match(IReadOnlyList<ParsedRide> parsed, string? dedupKey, DateTimeOffset? storedStart)
    {
        if (dedupKey is not null
            && long.TryParse(dedupKey[(dedupKey.LastIndexOf(':') + 1)..], out var seconds)
            && parsed.FirstOrDefault(p => p.StartTime.ToUnixTimeSeconds() == seconds) is { } byKey)
            return byKey;
        if (storedStart is { } start
            && parsed.FirstOrDefault(p => p.StartTime.ToUnixTimeSeconds() == start.ToUnixTimeSeconds()) is { } byStart)
            return byStart;
        return parsed.Count == 1 ? parsed[0] : null;
    }

    private static async Task<int?> ZoneOffsetAsync(VelomineDbContext db, Ride ride, ParsedRide file, CancellationToken ct)
    {
        var zone = await db.Users.AsNoTracking().Where(u => u.Id == ride.UserId).Select(u => u.TimeZone).FirstOrDefaultAsync(ct);
        return (int)TimeZoneInfo.ConvertTime(file.StartTime, MemberClock.ZoneOf(zone)).Offset.TotalMinutes;
    }

    /// <summary>Marks the ride as tried at this version without touching its data or status.</summary>
    private async Task<bool> MarkFailedAsync(Guid id, int version, CancellationToken ct)
    {
        try
        {
            await using var scope = services.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            await db.Rides.Where(r => r.Id == id && r.ParserVersion < version)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(r => r.ParserVersion, version)
                    .SetProperty(r => r.ReparseFailedVersion, version), ct);
            return true;
        }
        catch (OperationCanceledException) when (ct.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError("Could not mark a ride as not readable again ({Exception}); the next start tries it again.", ex.GetType().Name);
            return false;
        }
    }
}
