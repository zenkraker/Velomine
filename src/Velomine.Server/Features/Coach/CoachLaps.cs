using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Features.Coach;

public sealed class CoachRideLapsRequest
{
    public Guid ClubId { get; set; }

    public Guid UserId { get; set; }

    public Guid RideId { get; set; }
}

/// <summary>An athlete's laps, read-only. Laps carry no positions, so they need the rides grant only.</summary>
public sealed class GetCoachRideLaps(VelomineDbContext db, TimeProvider time)
    : Endpoint<CoachRideLapsRequest, RideLapsResponse>
{
    public override void Configure()
    {
        Get("clubs/{clubId}/athletes/{userId}/rides/{rideId}/laps");
        Description(d => d.Produces<RideLapsResponse>(200).Produces(401).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(CoachRideLapsRequest req, CancellationToken ct)
    {
        var viewerId = User.UserId();
        if (!await SharingRules.CanViewAsync(db, req.ClubId, viewerId, req.UserId, DataTypes.Rides, ct))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var ride = await db.Rides.AsNoTracking()
            .Where(r => r.Id == req.RideId && r.UserId == req.UserId)
            .FirstOrDefaultAsync(ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (ride.Status != RideStatus.Ready)
        {
            AddError("The ride has no laps: it is still being read, or the file could not be used.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        await SharingRules.RecordViewAsync(
            db, time, req.UserId, req.ClubId, viewerId,
            await CoachQueries.ViewerNameAsync(db, viewerId, ct), ViewKinds.Ride, ct, req.RideId);

        var laps = await db.RideLaps.AsNoTracking()
            .Where(l => l.RideId == req.RideId)
            .OrderBy(l => l.Index)
            .Select(l => new LapResponse(
                l.Index, l.StartS, l.EndS, l.DurationS, l.MovingS, l.DistanceM,
                l.AvgSpeedMs, l.MaxSpeedMs, l.AvgPowerW, l.MaxPowerW,
                l.AvgHeartRate, l.MaxHeartRate, l.AvgCadence, l.ElevationGainM))
            .ToListAsync(ct);
        var privacy = await PrivacyRules.LoadAsync(db, req.UserId, ride, ct);
        await Send.OkAsync(new RideLapsResponse([.. laps.Select(l => PrivacyRules.ForViewer(l, privacy))]), ct);
    }
}
