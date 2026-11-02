using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

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
                await using var scope = services.CreateAsyncScope();
                await MarkFailedAsync(scope.ServiceProvider.GetRequiredService<VelomineDbContext>(), id, "internal_error", stoppingToken);
            }
        }
    }

    private async Task ProcessAsync(VelomineDbContext db, Guid id, CancellationToken ct)
    {
        var ride = await db.Rides.FirstOrDefaultAsync(r => r.Id == id && r.Status == RideStatus.Processing, ct);
        if (ride is null) return;

        IReadOnlyList<ParsedRide> parsed;
        try
        {
            parsed = RideFileParser.Parse(await files.ReadAsync(ride.FileSha256, ct));
        }
        catch (RideParseException ex)
        {
            Fail(ride, ex.Code);
            await db.SaveChangesAsync(ct);
            return;
        }
        catch (FileNotFoundException)
        {
            Fail(ride, "file_missing");
            await db.SaveChangesAsync(ct);
            return;
        }

        // One file can hold several rides: the first fills the row made at upload, the others get rows of their own.
        var used = false;
        Guid? defaultBike = null;
        string? lastError = null;
        foreach (var file in parsed)
        {
            RideMetricValues metrics;
            try
            {
                metrics = RideMetrics.Compute(file.Samples, file.DeviceNormalizedPowerW);
            }
            catch (RideParseException ex)
            {
                lastError = ex.Code;
                continue;
            }

            var target = used
                ? new Ride { Id = Guid.CreateVersion7(), UserId = ride.UserId, FileSha256 = ride.FileSha256, FileName = ride.FileName, UploadedAt = ride.UploadedAt }
                : ride;
            if (used) db.Rides.Add(target);
            used = true;

            target.StartTime = file.StartTime;
            target.UtcOffsetMinutes = file.UtcOffsetMinutes;
            target.Device = file.Device;
            target.DedupKey = $"file:{ride.FileSha256}:{file.StartTime.ToUnixTimeSeconds()}";
            target.Error = null;

            var original = await db.Rides.AsNoTracking()
                .Where(r => r.UserId == ride.UserId && r.DedupKey == target.DedupKey && r.Status == RideStatus.Ready && r.Id != target.Id)
                .Select(r => (Guid?)r.Id)
                .FirstOrDefaultAsync(ct);
            if (original is not null)
            {
                target.Status = RideStatus.Duplicate;
                target.DuplicateOf = original;
                continue;
            }

            Apply(target, metrics);
            target.BikeId ??= defaultBike ??= await db.Bikes.AsNoTracking()
                .Where(b => b.UserId == ride.UserId && b.IsDefault && b.IsActive).Select(b => (Guid?)b.Id).FirstOrDefaultAsync(ct);
            target.Status = RideStatus.Ready;
            target.Streams = ToStreams(file.Samples);
        }

        if (!used) Fail(ride, lastError ?? "no_records");
        await db.SaveChangesAsync(ct);
    }

    private static void Fail(Ride ride, string code)
    {
        ride.Status = RideStatus.Failed;
        ride.Error = code;
    }

    private static async Task MarkFailedAsync(VelomineDbContext db, Guid id, string code, CancellationToken ct)
    {
        var ride = await db.Rides.FirstOrDefaultAsync(r => r.Id == id, ct);
        if (ride is null) return;
        Fail(ride, code);
        await db.SaveChangesAsync(ct);
    }

    private static void Apply(Ride ride, RideMetricValues m)
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
        ride.AvgHeartRate = m.AvgHeartRate;
        ride.MaxHeartRate = m.MaxHeartRate;
        ride.AvgCadence = m.AvgCadence;
    }

    /// <summary>One array per signal; a signal the file never had is left null instead of an array of nulls.</summary>
    private static RideStreams ToStreams(IReadOnlyList<Sample> samples)
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
