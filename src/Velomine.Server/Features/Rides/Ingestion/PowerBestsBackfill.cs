using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// Fills in best efforts for rides that were read before power bests existed. New rides get them during ingestion;
/// this runs once at startup and does nothing when every ready ride already has them.
/// </summary>
public sealed class PowerBestsBackfill(
    IServiceProvider services,
    ILogger<PowerBestsBackfill> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            await using var scope = services.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();

            var rides = await db.Rides.AsNoTracking()
                .Where(r => r.Status == RideStatus.Ready && r.Streams != null && r.Streams.Power != null)
                .Where(r => !db.RidePowerBests.Any(b => b.RideId == r.Id))
                .Select(r => new { r.Id, r.Streams!.Power, r.Streams!.Time })
                .ToListAsync(stoppingToken);

            if (rides.Count == 0) return;

            foreach (var ride in rides)
            {
                var bests = PowerBests.FromStreams(ride.Power, ride.Time);
                for (var i = 0; i < bests.Length; i++)
                {
                    if (bests[i] <= 0) continue;
                    db.RidePowerBests.Add(new RidePowerBest
                    {
                        RideId = ride.Id,
                        DurationS = PowerBests.Durations[i],
                        Watts = bests[i],
                    });
                }
            }

            await db.SaveChangesAsync(stoppingToken);
            logger.LogInformation("Backfilled power bests for {Count} rides.", rides.Count);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            // Shutting down: the next start tries again.
        }
        catch (Exception ex)
        {
            // A curve without bests is still usable; never keep the rest of the server from starting.
            logger.LogWarning(ex, "Could not backfill power bests.");
        }
    }
}
