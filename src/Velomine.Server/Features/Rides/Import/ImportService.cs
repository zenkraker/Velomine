using System.Diagnostics;
using System.IO.Compression;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using Velomine.Server.Data;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Rides.Import;

/// <summary>
/// Reads an export archive one activity at a time: extract the file, make a ride row and let the usual ingestion read
/// it. The import rows are the durable record, so a restart picks up an import that was still running.
/// </summary>
public sealed class ImportService(
    IServiceProvider services,
    ImportQueue queue,
    ImportStore store,
    RideFileStore files,
    IngestionQueue rides,
    TimeProvider time,
    ILogger<ImportService> logger) : BackgroundService
{
    /// <summary>Largest activity file and largest activities.csv read from an archive.</summary>
    private const long MaxFileBytes = 200L * 1024 * 1024;
    private const long MaxCsvBytes = 100L * 1024 * 1024;

    private const string SourceIndex = "ux_rides_user_source";

    private static readonly TimeSpan PollInterval = TimeSpan.FromMilliseconds(500);

    // shortcut: a ride that never finishes holds its import for five minutes without progress and then leaves it
    // pending; the next start reads it again. Fail the ride instead if this ever shows up in practice.
    private const int MaxStallPolls = 600;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await using (var scope = services.CreateAsyncScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var unfinished = await db.RideImports.Where(i => i.Status == RideImportStatus.Processing)
                .Select(i => new { i.Id, i.UserId, i.ArchiveSha256 }).ToListAsync(stoppingToken);
            store.KeepOnly(unfinished.Select(i => (i.UserId, i.ArchiveSha256)).ToHashSet());
            foreach (var import in unfinished) queue.Enqueue(import.Id);
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
                return;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Import {ImportId} failed unexpectedly.", id);
                try
                {
                    await using var scope = services.CreateAsyncScope();
                    await FailAsync(scope.ServiceProvider.GetRequiredService<VelomineDbContext>(), id, "internal_error", stoppingToken);
                }
                catch (Exception markEx) when (markEx is not OperationCanceledException)
                {
                    logger.LogError(markEx, "Could not record the failure for import {ImportId}.", id);
                }
            }
        }
    }

    private async Task ProcessAsync(VelomineDbContext db, Guid id, CancellationToken ct)
    {
        var import = await db.RideImports.FirstOrDefaultAsync(i => i.Id == id && i.Status == RideImportStatus.Processing, ct);
        if (import is null) return;

        await using var archive = store.OpenRead(import.UserId, import.ArchiveSha256);
        if (archive is null)
        {
            await FailAsync(db, import, "archive_missing", ct);
            return;
        }

        List<StravaActivity> activities;
        using (var zip = new ZipArchive(archive, ZipArchiveMode.Read, leaveOpen: true))
        {
            var csv = zip.Entries.FirstOrDefault(e => string.Equals(e.FullName, StravaExport.CsvEntry, StringComparison.OrdinalIgnoreCase));
            if (csv is null)
            {
                await FailAsync(db, import, "not_a_strava_export", ct);
                return;
            }

            try
            {
                await using var stream = csv.Open();
                activities = [.. StravaExport.Parse(new MemoryStream(await ReadLimitedAsync(stream, MaxCsvBytes, ct)))];
            }
            catch (InvalidDataException)
            {
                await FailAsync(db, import, "not_a_strava_export", ct);
                return;
            }

            import.Total = activities.Count;
            await db.SaveChangesAsync(ct);

            // What a newer export of the same account would list again.
            var alreadyImported = (await db.Rides.AsNoTracking()
                    .Where(r => r.UserId == import.UserId && r.Source == StravaExport.Source && r.SourceId != null)
                    .Select(r => r.SourceId!)
                    .ToListAsync(ct))
                .ToHashSet(StringComparer.Ordinal);

            var watched = Stopwatch.GetTimestamp();
            foreach (var activity in activities)
            {
                if (activity.File.Length == 0) continue;
                var entry = zip.GetEntry(activity.File);
                if (entry is null || entry.Length == 0 || entry.Length > MaxFileBytes) continue;
                if (activity.SourceId is { } known && alreadyImported.Contains(known)) continue;

                string sha;
                try
                {
                    await using var content = entry.Open();
                    sha = await files.SaveAsync(content, ct, MaxFileBytes);
                }
                catch (InvalidDataException)
                {
                    continue; // oversized or damaged: nothing to read, and the import carries on
                }

                var ride = new Ride
                {
                    Id = Guid.CreateVersion7(),
                    UserId = import.UserId,
                    Status = RideStatus.Processing,
                    ImportId = import.Id,
                    Source = StravaExport.Source,
                    SourceId = activity.SourceId,
                    Commute = activity.Commute,
                    FileSha256 = sha,
                    FileName = StravaExport.FileName(activity.File, "ride"),
                    UploadedAt = time.GetUtcNow(),
                };
                db.Rides.Add(ride);
                try
                {
                    await db.SaveChangesAsync(ct);
                }
                catch (DbUpdateException ex) when (ex.InnerException is PostgresException
                { SqlState: PostgresErrorCodes.UniqueViolation, ConstraintName: SourceIndex })
                {
                    db.Entry(ride).State = EntityState.Detached;
                    continue; // the same activity was added by an earlier run of this import
                }
                db.Entry(ride).State = EntityState.Detached;
                if (activity.SourceId is { } added) alreadyImported.Add(added);
                rides.Enqueue(ride.Id);
            }

            logger.LogInformation("Import {ImportId} extracted {Count} activities in {ElapsedMs} ms.",
                import.Id, activities.Count, Stopwatch.GetElapsedTime(watched).TotalMilliseconds);
        }

        // The usual ingestion reads the rides; wait until it is done with all of them. A ride it cannot finish must
        // not hold every later import behind it.
        var pending = await PendingAsync(db, import.Id, ct);
        var stalls = 0;
        while (pending > 0 && stalls < MaxStallPolls)
        {
            await Task.Delay(PollInterval, time, ct);
            var next = await PendingAsync(db, import.Id, ct);
            stalls = next >= pending ? stalls + 1 : 0;
            pending = next;
        }
        if (pending > 0) logger.LogWarning("Import {ImportId} finished with {Count} rides still being read.", id, pending);

        // A run or a swim is not a failed upload: keep nothing, count it as skipped. Velomine is cycling-only.
        var notCycling = await db.Rides
            .Where(r => r.ImportId == import.Id && r.Status == RideStatus.Failed && r.Error == "not_cycling")
            .ToListAsync(ct);
        if (notCycling.Count > 0)
        {
            db.Rides.RemoveRange(notCycling);
            await db.SaveChangesAsync(ct);
            foreach (var sha in notCycling.Select(r => r.FileSha256).Distinct())
                if (!await db.Rides.AnyAsync(r => r.FileSha256 == sha, ct)) files.Delete(sha);
        }

        db.ChangeTracker.Clear();
        import = await db.RideImports.FirstAsync(i => i.Id == id, ct);
        import.Status = RideImportStatus.Completed;
        import.FinishedAt = time.GetUtcNow();
        Notify.Add(db, time, import.UserId, NotificationTypes.RideImport, import.FileName);
        var bikes = await db.Rides.AsNoTracking()
            .Where(r => r.ImportId == import.Id && r.Status == RideStatus.Ready && r.BikeId != null)
            .Select(r => r.BikeId!.Value).Distinct().ToListAsync(ct);
        await db.SaveChangesAsync(ct);
        DeleteArchive(import.UserId, import.ArchiveSha256);

        // Once for the whole import, not once per ride: wear is recomputed from every ride each time.
        try
        {
            await Notify.WornPartsAsync(db, time, import.UserId, bikes, ct);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            // The import is done; a wear warning that failed must not turn it into a failed import.
            logger.LogWarning(ex, "Wear warnings after import {ImportId} failed.", id);
        }
    }

    private static Task<int> PendingAsync(VelomineDbContext db, Guid importId, CancellationToken ct) =>
        db.Rides.AsNoTracking().CountAsync(r => r.ImportId == importId && r.Status == RideStatus.Processing, ct);

    /// <summary>Reads at most <paramref name="max"/> bytes, whatever size the archive claims the entry is.</summary>
    private static async Task<byte[]> ReadLimitedAsync(Stream stream, long max, CancellationToken ct)
    {
        using var buffer = new MemoryStream();
        var chunk = new byte[81920];
        int read;
        while ((read = await stream.ReadAsync(chunk, ct)) > 0)
        {
            if (buffer.Length + read > max) throw new InvalidDataException("The entry is larger than it is allowed to be.");
            buffer.Write(chunk, 0, read);
        }
        return buffer.ToArray();
    }

    private async Task FailAsync(VelomineDbContext db, Guid id, string code, CancellationToken ct)
    {
        db.ChangeTracker.Clear();
        var import = await db.RideImports.FirstOrDefaultAsync(i => i.Id == id, ct);
        if (import is null) return;
        await FailAsync(db, import, code, ct);
    }

    private async Task FailAsync(VelomineDbContext db, RideImport import, string code, CancellationToken ct)
    {
        import.Status = RideImportStatus.Failed;
        import.Error = code;
        import.FinishedAt = time.GetUtcNow();
        await db.SaveChangesAsync(ct);
        DeleteArchive(import.UserId, import.ArchiveSha256);
    }

    private void DeleteArchive(Guid userId, string sha)
    {
        try
        {
            store.Delete(userId, sha);
        }
        catch (IOException ex)
        {
            logger.LogWarning(ex, "Could not delete an import archive.");
        }
    }
}
