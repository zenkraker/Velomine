using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides.Import;

namespace Velomine.Server.Features.Rides;

public sealed record RideImportResponse(
    Guid Id,
    string Status,
    int Total,
    int Imported,
    int Duplicates,
    int Failed,
    int Skipped,
    int Pending,
    DateTimeOffset CreatedAt,
    DateTimeOffset? FinishedAt,
    string? Error);

/// <summary>How an import is going, and what it brought in. The counts are worked out from the rides it made.</summary>
public sealed class GetRideImport(VelomineDbContext db) : Endpoint<RideIdRequest, RideImportResponse>
{
    public override void Configure()
    {
        Get("rides/imports/{id}");
        Description(d => d.Produces<RideImportResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(RideIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var import = await db.RideImports.AsNoTracking()
            .FirstOrDefaultAsync(i => i.Id == req.Id && i.UserId == userId, ct);
        if (import is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var counts = await db.Rides.AsNoTracking()
            .Where(r => r.ImportId == import.Id)
            .GroupBy(r => new { r.Status, r.Error })
            .Select(g => new { g.Key.Status, g.Key.Error, Count = g.Count() })
            .ToListAsync(ct);

        var imported = counts.Where(c => c.Status == RideStatus.Ready).Sum(c => c.Count);
        var duplicates = counts.Where(c => c.Status == RideStatus.Duplicate).Sum(c => c.Count);
        var pending = counts.Where(c => c.Status == RideStatus.Processing).Sum(c => c.Count);
        // A run or a swim in the export is not a failed file: nothing was wrong with it, Velomine is cycling-only.
        var failed = counts.Where(c => c.Status == RideStatus.Failed && c.Error != "not_cycling").Sum(c => c.Count);
        // What the archive listed but produced no ride for. Only known once the whole archive has been read.
        var skipped = import.Status == RideImportStatus.Completed
            ? Math.Max(0, import.Total - counts.Sum(c => c.Count))
            : 0;

        await Send.OkAsync(new RideImportResponse(
            import.Id,
            import.Status.ToString().ToLowerInvariant(),
            import.Total,
            imported,
            duplicates,
            failed,
            skipped,
            pending,
            import.CreatedAt,
            import.FinishedAt,
            import.Error), ct);
    }
}
