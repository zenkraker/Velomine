using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Admin;

/// <summary>Totals for the whole server. Counts only: an admin never sees whose rides they are.
/// ParserVersion is the generation rides are read with; RidesToReread still wait to be read again after it was raised,
/// and RidesNotReread could not be read again and keep their earlier numbers.</summary>
public sealed record OverviewResponse(int Accounts, int WaitingForApproval, int Locked, int Rides, long RideFilesBytes, string Version,
    int ParserVersion, int RidesToReread, int RidesNotReread);

public sealed class GetOverview(VelomineDbContext db, RideFileStore files, TimeProvider time) : EndpointWithoutRequest<OverviewResponse>
{
    public override void Configure()
    {
        Get("admin/overview");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Produces<OverviewResponse>(200).Produces(401).Produces(403), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var now = time.GetUtcNow();
        var accounts = await db.Users.CountAsync(ct);
        var waiting = await db.Users.CountAsync(u => !u.IsApproved, ct);
        var locked = await db.Users.CountAsync(u => u.LockoutEnd > now, ct);
        var rides = await db.Rides.CountAsync(r => r.Status == RideStatus.Ready, ct);
        var version = BuildInfo.Version;
        var current = RideParserVersion.Current;
        var toReread = await db.Rides.CountAsync(
            r => (r.Status == RideStatus.Ready || r.Status == RideStatus.Failed) && r.ParserVersion < current, ct);
        var notReread = await db.Rides.CountAsync(r => r.ReparseFailedVersion == current, ct);
        await Send.OkAsync(new OverviewResponse(accounts, waiting, locked, rides, files.TotalBytes(), version, current, toReread, notReread), ct);
    }
}
