using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Rides;

/// <summary>
/// Deletes a ride and its samples. A hidden copy of it is not deleted: it is read again and becomes visible, so a ride
/// wrongly hidden as a duplicate can be recovered. The original file goes too, unless another ride still uses it.
/// </summary>
public sealed class DeleteRide(VelomineDbContext db, RideFileStore files, IngestionQueue queue) : Endpoint<RideIdRequest>
{
    public override void Configure() => Delete("rides/{id}");

    public override async Task HandleAsync(RideIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var ride = await db.Rides.FirstOrDefaultAsync(r => r.Id == req.Id && r.UserId == userId, ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var hidden = await db.Rides
            .Where(r => r.UserId == userId && r.DuplicateOf == ride.Id)
            .ToListAsync(ct);
        foreach (var copy in hidden)
        {
            copy.Status = RideStatus.Processing;
            copy.DuplicateOf = null;
            copy.DedupKey = null; // the reader works it out again; it must not clash with the ride being removed
        }
        db.Rides.Remove(ride);
        await db.SaveChangesAsync(ct);

        foreach (var copy in hidden) queue.Enqueue(copy.Id);
        if (!await db.Rides.AnyAsync(r => r.FileSha256 == ride.FileSha256, ct)) files.Delete(ride.FileSha256);
        await Send.NoContentAsync(ct);
    }
}
