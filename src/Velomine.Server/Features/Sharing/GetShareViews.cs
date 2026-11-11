using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Sharing;

public sealed class ShareViewsRequest
{
    /// <summary>Only the looks at this ride. Omit for every look at the member's data.</summary>
    [QueryParam]
    public Guid? RideId { get; set; }
}

public sealed record ShareViewResponse(string ViewerName, string What, DateTimeOffset At);

public sealed record ShareViewsResponse(ShareViewResponse[] Views);

/// <summary>
/// Who looked at the member's shared data, most recent first. Only ever the caller's own log. For one ride, opening it
/// writes several rows within moments (the ride, its samples, its laps); those read as one look per viewer.
/// </summary>
public sealed class GetShareViews(VelomineDbContext db) : Endpoint<ShareViewsRequest, ShareViewsResponse>
{
    /// <summary>Looks by the same person closer together than this are one look at a ride.</summary>
    private static readonly TimeSpan SameLook = TimeSpan.FromMinutes(10);

    private const int ForRide = 20;

    public override void Configure()
    {
        Get("sharing/views");
        Description(d => d.Produces<ShareViewsResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(ShareViewsRequest req, CancellationToken ct)
    {
        var memberId = User.UserId();
        if (req.RideId is { } rideId)
        {
            var rows = await db.ShareViews.AsNoTracking()
                .Where(v => v.MemberId == memberId && v.RideId == rideId)
                .OrderByDescending(v => v.At)
                .Take(200)
                .Select(v => new { v.ViewerId, v.ViewerName, v.What, v.At })
                .ToListAsync(ct);

            var looks = new List<ShareViewResponse>();
            var lastByViewer = new Dictionary<Guid, DateTimeOffset>();
            foreach (var row in rows)
            {
                if (lastByViewer.TryGetValue(row.ViewerId, out var later) && later - row.At < SameLook) continue;
                lastByViewer[row.ViewerId] = row.At;
                looks.Add(new ShareViewResponse(row.ViewerName, row.What, row.At));
                if (looks.Count == ForRide) break;
            }

            await Send.OkAsync(new ShareViewsResponse([.. looks]), ct);
            return;
        }

        var views = await db.ShareViews.AsNoTracking()
            .Where(v => v.MemberId == memberId)
            .OrderByDescending(v => v.At)
            .Take(50)
            .Select(v => new ShareViewResponse(v.ViewerName, v.What, v.At))
            .ToListAsync(ct);
        await Send.OkAsync(new ShareViewsResponse([.. views]), ct);
    }
}
