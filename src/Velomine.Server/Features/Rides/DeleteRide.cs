using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Rides;

/// <summary>Deletes a ride and its samples. The original file goes too, unless another ride was read from the same file.</summary>
public sealed class DeleteRide(VelomineDbContext db, RideFileStore files) : Endpoint<RideIdRequest>
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

        db.Rides.Remove(ride);
        await db.SaveChangesAsync(ct);

        if (!await db.Rides.AnyAsync(r => r.FileSha256 == ride.FileSha256, ct)) files.Delete(ride.FileSha256);
        await Send.NoContentAsync(ct);
    }
}
