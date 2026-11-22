using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;

namespace Velomine.Server.Features.Rides;

public sealed class RideIdRequest
{
    public Guid Id { get; set; }
}

/// <summary>A member's own ride. Someone else's ride looks exactly like a ride that does not exist.</summary>
public sealed class GetRide(VelomineDbContext db, TimeProvider time) : Endpoint<RideIdRequest, RideResponse>
{
    public override void Configure() => Get("rides/{id}");

    public override async Task HandleAsync(RideIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var ride = await db.Rides.AsNoTracking()
            .Include(r => r.Streams)
            .Include(r => r.Owner)
            .FirstOrDefaultAsync(r => r.Id == req.Id && r.UserId == userId, ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var suggestion = await db.FtpSuggestions.AsNoTracking()
            .Where(s => s.RideId == ride.Id && s.Status == FtpSuggestionStatuses.Open)
            .Select(s => new { s.Id, s.Watts, s.Method, s.EffortWatts })
            .FirstOrDefaultAsync(ct);
        // The effort score is the owner's, and how hard the ride felt can be rated after it was read.
        var rpe = await db.RideFeels.AsNoTracking()
            .Where(f => f.RideId == ride.Id)
            .Select(f => (int?)f.Rpe)
            .FirstOrDefaultAsync(ct);
        var (effortScore, effortSource) = TrainingLoad.Effort(
            ride.Tss,
            ride.HrTss,
            TrainingLoad.FeelScore(ride.MovingS, rpe),
            ride.EstimatedTss);
        await Send.OkAsync(
            (await RideDetails.BuildAsync(db, time, ride, ct)) with
            {
                PowerRecords = await PowerRecords.ForRideAsync(db, userId, ride.Id, ride.StartTime, ct),
                // Only the owner sees the suggestion, and only on the ride it came from.
                FtpSuggestionW = suggestion?.Watts,
                FtpSuggestionEffortW = suggestion?.EffortWatts,
                FtpSuggestionMethod = suggestion?.Method,
                FtpSuggestionId = suggestion?.Id,
                EffortScore = effortScore,
                EffortSource = effortSource,
            },
            ct);
    }
}
