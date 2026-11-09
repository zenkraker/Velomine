using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Rides;

public sealed class RideLapsRequest
{
    public Guid Id { get; set; }
}

/// <summary>One lap's numbers. Boundaries are seconds since the ride started, distances in metres.</summary>
public sealed record LapResponse(
    int Index,
    double StartS,
    double EndS,
    double DurationS,
    double MovingS,
    double DistanceM,
    double? AvgSpeedMs,
    double? MaxSpeedMs,
    int? AvgPowerW,
    int? MaxPowerW,
    int? AvgHeartRate,
    int? MaxHeartRate,
    int? AvgCadence,
    double? ElevationGainM)
{
    public static LapResponse From(RideLap lap) => new(
        lap.Index,
        lap.StartS,
        lap.EndS,
        lap.DurationS,
        lap.MovingS,
        lap.DistanceM,
        lap.AvgSpeedMs,
        lap.MaxSpeedMs,
        lap.AvgPowerW,
        lap.MaxPowerW,
        lap.AvgHeartRate,
        lap.MaxHeartRate,
        lap.AvgCadence,
        lap.ElevationGainM);
}

public sealed record RideLapsResponse(LapResponse[] Laps);

/// <summary>The rider's own laps, in the order the file recorded them. A ride read without laps answers with none.</summary>
public sealed class GetRideLaps(VelomineDbContext db) : Endpoint<RideLapsRequest, RideLapsResponse>
{
    public override void Configure()
    {
        Get("rides/{id}/laps");
        Description(d => d.Produces<RideLapsResponse>(200).Produces(401).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(RideLapsRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var status = await db.Rides.AsNoTracking()
            .Where(r => r.Id == req.Id && r.UserId == userId)
            .Select(r => (RideStatus?)r.Status)
            .FirstOrDefaultAsync(ct);
        if (status is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (status != RideStatus.Ready)
        {
            AddError("The ride has no laps: it is still being read, or the file could not be used.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var laps = await db.RideLaps.AsNoTracking()
            .Where(l => l.RideId == req.Id)
            .OrderBy(l => l.Index)
            .Select(l => new LapResponse(
                l.Index, l.StartS, l.EndS, l.DurationS, l.MovingS, l.DistanceM,
                l.AvgSpeedMs, l.MaxSpeedMs, l.AvgPowerW, l.MaxPowerW,
                l.AvgHeartRate, l.MaxHeartRate, l.AvgCadence, l.ElevationGainM))
            .ToListAsync(ct);
        await Send.OkAsync(new RideLapsResponse([.. laps]), ct);
    }
}
