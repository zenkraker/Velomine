using System.Reflection;
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Admin;

/// <summary>Totals for the whole server. Counts only: an admin never sees whose rides they are.</summary>
public sealed record OverviewResponse(int Accounts, int WaitingForApproval, int Locked, int Rides, long RideFilesBytes, string Version);

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
        var version = Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "0.0.0";
        await Send.OkAsync(new OverviewResponse(accounts, waiting, locked, rides, files.TotalBytes(), version), ct);
    }
}
