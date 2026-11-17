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
public sealed class GetRide(VelomineDbContext db) : Endpoint<RideIdRequest, RideResponse>
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
            .Select(s => new { s.Id, s.Watts, s.Method })
            .FirstOrDefaultAsync(ct);
        await Send.OkAsync(
            RideDetails.Build(ride) with
            {
                PowerRecords = await PowerRecords.ForRideAsync(db, userId, ride.Id, ride.StartTime, ct),
                // Only the owner sees the suggestion, and only on the ride it came from.
                FtpSuggestionW = suggestion?.Watts,
                FtpSuggestionMethod = suggestion?.Method,
                FtpSuggestionId = suggestion?.Id,
            },
            ct);
    }
}
