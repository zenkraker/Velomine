using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

public sealed record ListServiceJobsResponse(MaintenanceJob[] Jobs);

/// <summary>
/// The common jobs that fit this bike's kind, each with an interval to start from. The ids are fixed; the app words them.
/// Nothing is added to the bike by asking.
/// </summary>
public sealed class ListServiceJobs(VelomineDbContext db) : Endpoint<BikeIdRequest, ListServiceJobsResponse>
{
    public override void Configure()
    {
        Get("bikes/{id}/service/jobs");
        Description(d => d.Produces<ListServiceJobsResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(BikeIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var kind = await db.Bikes.AsNoTracking().Where(b => b.Id == req.Id && b.UserId == userId).Select(b => b.Kind).FirstOrDefaultAsync(ct);
        if (kind is null) await Send.NotFoundAsync(ct);
        else await Send.OkAsync(new ListServiceJobsResponse(MaintenanceJobs.For(kind)), ct);
    }
}
