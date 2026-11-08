using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Sharing;

public sealed record ShareViewResponse(string ViewerName, string What, DateTimeOffset At);

public sealed record ShareViewsResponse(ShareViewResponse[] Views);

/// <summary>Who looked at the member's shared data, most recent first.</summary>
public sealed class GetShareViews(VelomineDbContext db) : EndpointWithoutRequest<ShareViewsResponse>
{
    public override void Configure()
    {
        Get("sharing/views");
        Description(d => d.Produces<ShareViewsResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var views = await db.ShareViews.AsNoTracking()
            .Where(v => v.MemberId == User.UserId())
            .OrderByDescending(v => v.At)
            .Take(50)
            .Select(v => new ShareViewResponse(v.ViewerName, v.What, v.At))
            .ToListAsync(ct);
        await Send.OkAsync(new ShareViewsResponse([.. views]), ct);
    }
}
