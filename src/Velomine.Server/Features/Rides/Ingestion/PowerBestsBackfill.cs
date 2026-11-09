using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// Fills in best efforts for rides that were read before power bests existed. New rides get them during ingestion.
/// Runs once at startup, one ride at a time, so a long history never holds every power stream in memory at once.
/// The marker on the ride makes the job resumable and also covers rides whose power is all zeroes (they get no rows).
/// </summary>
public sealed class PowerBestsBackfill(
    IServiceProvider services,
    TimeProvider time,
    ILogger<PowerBestsBackfill> logger) : BackgroundService
{
    /// <summary>How many ride ids to read at a time. Each ride is processed in its own scope.</summary>
    private const int BatchSize = 50;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            await RunAsync(stoppingToken);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Shutting down: the marker means the next start continues where this one stopped.
        }
        catch (Exception ex)
        {
            // A curve without bests is still usable; never keep the rest of the server from starting.
            logger.LogWarning(ex, "Could not backfill power bests.");
        }
    }

    /// <summary>Processes every unmarked ready ride with a power stream, a small page of ids at a time.</summary>
    public async Task RunAsync(CancellationToken ct)
    {
        var total = 0;
        while (true)
        {
            await using var batchScope = services.CreateAsyncScope();
            var db = batchScope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var ids = await db.Rides.AsNoTracking()
                .Where(r => r.Status == RideStatus.Ready
                    && r.PowerBestsBackfilledAt == null
                    && r.Streams != null
                    && r.Streams.Power != null)
                .OrderBy(r => r.Id)
                .Select(r => r.Id)
                .Take(BatchSize)
                .ToListAsync(ct);

            if (ids.Count == 0) break;

            foreach (var id in ids)
            {
                // A marker that cannot be saved would select the same ride forever, so stop and retry on the next start.
                if (!await ProcessOneAsync(id, ct)) return;
                total++;
            }

            logger.LogInformation("Backfilled power bests for {Count} rides.", total);
        }

        if (total > 0) logger.LogInformation("Power-best backfill finished: {Count} rides.", total);
    }

    private async Task<bool> ProcessOneAsync(Guid id, CancellationToken ct, bool retried = false)
    {
        try
        {
            await using var scope = services.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var ride = await db.Rides.Include(r => r.Streams)
                .FirstOrDefaultAsync(r => r.Id == id && r.PowerBestsBackfilledAt == null, ct);
            if (ride is null) return true;

            if (ride.Streams?.Power is not null
                && !await db.RidePowerBests.AnyAsync(b => b.RideId == id, ct))
            {
                var bests = PowerBests.FromStreams(ride.Streams.Power, ride.Streams.Time);
                for (var i = 0; i < bests.Length; i++)
                {
                    if (bests[i] <= 0) continue;
                    db.RidePowerBests.Add(new RidePowerBest
                    {
                        RideId = id,
                        DurationS = PowerBests.Durations[i],
                        Watts = bests[i],
                    });
                }
            }

            // Set it even when there were no positive bests: otherwise the zero-power ride is selected forever.
            ride.PowerBestsBackfilledAt = time.GetUtcNow();
            await db.SaveChangesAsync(ct);
            return true;
        }
        catch (DbUpdateConcurrencyException) when (!retried)
        {
            // A member changed the ride while it was being processed: try once more with the current row.
            return await ProcessOneAsync(id, ct, retried: true);
        }
        catch (OperationCanceledException) when (ct.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogWarning("Could not backfill power bests for one ride ({Exception}); marking it done.", ex.GetType().Name);
            return await MarkDoneAsync(id, ct);
        }
    }

    private async Task<bool> MarkDoneAsync(Guid id, CancellationToken ct)
    {
        try
        {
            await using var scope = services.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var ride = await db.Rides.FirstOrDefaultAsync(r => r.Id == id, ct);
            if (ride is null || ride.PowerBestsBackfilledAt is not null) return true;
            ride.PowerBestsBackfilledAt = time.GetUtcNow();
            await db.SaveChangesAsync(ct);
            return true;
        }
        catch (OperationCanceledException) when (ct.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError("Could not mark a ride as backfilled ({Exception}); the next start will retry.", ex.GetType().Name);
            return false;
        }
    }
}
