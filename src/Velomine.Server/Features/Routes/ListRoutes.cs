using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Routes;

public static class RouteSorts
{
    public const string Newest = "newest";
    public const string Shortest = "shortest";
    public const string Longest = "longest";

    public static readonly string[] All = [Newest, Shortest, Longest];
}

public sealed class ListRoutesRequest
{
    /// <summary>newest (default), shortest or longest.</summary>
    [QueryParam]
    public string? Sort { get; set; }

    /// <summary>Only routes of this surface: road, gravel, mountain or mixed.</summary>
    [QueryParam]
    public string? Surface { get; set; }
}

public sealed class ListRoutesValidator : Validator<ListRoutesRequest>
{
    public ListRoutesValidator()
    {
        RuleFor(x => x.Sort).Must(s => RouteSorts.All.Contains(s!)).When(x => x.Sort is not null)
            .WithMessage("Sort by newest, shortest or longest.");
        RuleFor(x => x.Surface).Must(s => RouteSurfaces.All.Contains(s!)).When(x => x.Surface is not null)
            .WithMessage("Choose road, gravel, mountain or mixed.");
    }
}

/// <summary>The routes in the signed-in member's club library. A member with no club has no library: 404.</summary>
public sealed class ListRoutes(VelomineDbContext db) : Endpoint<ListRoutesRequest, RouteListResponse>
{
    public override void Configure()
    {
        Get("routes");
        Description(d => d.Produces<RouteListResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(ListRoutesRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        if (await RouteQueries.ClubIdAsync(db, userId, ct) is not { } clubId)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var routes = db.Routes.AsNoTracking().Where(r => r.ClubId == clubId);
        if (req.Surface is not null) routes = routes.Where(r => r.Surface == req.Surface);
        routes = req.Sort switch
        {
            RouteSorts.Shortest => routes.OrderBy(r => r.DistanceM).ThenBy(r => r.Id),
            RouteSorts.Longest => routes.OrderByDescending(r => r.DistanceM).ThenBy(r => r.Id),
            _ => routes.OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.Id),
        };

        await Send.OkAsync(new RouteListResponse(await RouteQueries.Summaries(routes, userId).ToArrayAsync(ct)), ct);
    }
}

/// <summary>
/// Every route the member added, shared or not, newest first. It is their own data, so it works without a club: a
/// route outlives the share.
/// </summary>
public sealed class ListMyRoutes(VelomineDbContext db) : EndpointWithoutRequest<RouteListResponse>
{
    public override void Configure()
    {
        Get("routes/mine");
        Description(d => d.Produces<RouteListResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var routes = db.Routes.AsNoTracking().Where(r => r.UserId == userId)
            .OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.Id);
        await Send.OkAsync(new RouteListResponse(await RouteQueries.Summaries(routes, userId).ToArrayAsync(ct)), ct);
    }
}
