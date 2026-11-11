using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Routes;

public sealed class UpdateRouteRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    public required string Name { get; set; }

    public string? Description { get; set; }

    /// <summary>road, gravel, mountain or mixed.</summary>
    public required string Surface { get; set; }
}

public sealed class UpdateRouteValidator : Validator<UpdateRouteRequest>
{
    public UpdateRouteValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(120);
        RuleFor(x => x.Description).MaximumLength(1000);
        RuleFor(x => x.Surface).Must(RouteSurfaces.All.Contains).WithMessage("Choose road, gravel, mountain or mixed.");
    }
}

/// <summary>
/// Changes a route's name, description and surface. Only its owner may: a club admin can take a route out of the
/// library but cannot edit what a member wrote. A member of the club who is not the owner gets 403; anyone who
/// cannot see the route gets 404.
/// </summary>
public sealed class UpdateRoute(VelomineDbContext db) : Endpoint<UpdateRouteRequest, RouteSummaryResponse>
{
    public override void Configure()
    {
        Put("routes/{id}");
        Description(d => d.Accepts<UpdateRouteRequest>("application/json").Produces<RouteSummaryResponse>(200).ProducesProblem(400).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateRouteRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var clubId = await RouteQueries.ClubIdAsync(db, userId, ct);
        var route = await RouteQueries.Visible(db, userId, clubId).FirstOrDefaultAsync(r => r.Id == req.Id, ct);
        if (route is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (route.UserId != userId)
        {
            await Send.ForbiddenAsync(ct);
            return;
        }

        route.Name = req.Name.Trim();
        route.Description = string.IsNullOrWhiteSpace(req.Description) ? null : req.Description.Trim();
        route.Surface = req.Surface;
        await db.SaveChangesAsync(ct);

        await Send.OkAsync(
            await RouteQueries.Summaries(db.Routes.AsNoTracking().Where(r => r.Id == route.Id), userId).FirstAsync(ct), ct);
    }
}
