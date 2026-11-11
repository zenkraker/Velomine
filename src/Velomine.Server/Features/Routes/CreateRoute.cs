using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Routes;

public sealed class CreateRouteRequest
{
    /// <summary>
    /// One of the member's own rides to take the line from. The server reads the ride itself, applies the member's
    /// privacy rules and ignores Latitude, Longitude and Elevation. Leave it out to send a line from a GPX file.
    /// </summary>
    public Guid? RideId { get; set; }

    public required string Name { get; set; }

    public string? Description { get; set; }

    /// <summary>road, gravel, mountain or mixed.</summary>
    public required string Surface { get; set; }

    /// <summary>The line from a GPX draft, 2 to 5,000 points. Not used with RideId.</summary>
    public double[]? Latitude { get; set; }

    public double[]? Longitude { get; set; }

    /// <summary>Metres, one per point, or left out.</summary>
    public double[]? Elevation { get; set; }
}

public sealed class CreateRouteValidator : Validator<CreateRouteRequest>
{
    public CreateRouteValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(120);
        RuleFor(x => x.Description).MaximumLength(1000);
        RuleFor(x => x.Surface).Must(RouteSurfaces.All.Contains).WithMessage("Choose road, gravel, mountain or mixed.");

        When(x => x.RideId is null, () =>
        {
            RuleFor(x => x.Latitude).Cascade(CascadeMode.Stop).NotNull().Must(l => l!.Length is >= 2 and <= RouteGeometry.MaxAcceptedPoints)
                .WithMessage($"Send between 2 and {RouteGeometry.MaxAcceptedPoints} points.");
            RuleFor(x => x.Longitude).Cascade(CascadeMode.Stop).NotNull().Must((x, l) => l!.Length == x.Latitude?.Length)
                .WithMessage("Latitude and longitude must have the same number of points.");
            RuleFor(x => x).Must(x => x.Latitude is null || x.Longitude is null || x.Latitude.Length != x.Longitude.Length
                    || x.Latitude.Select((la, i) => RouteGeometry.IsValid(la, x.Longitude[i])).All(ok => ok))
                .WithMessage("A point is not a place on Earth.");
            RuleFor(x => x.Elevation).Must((x, e) => e is null || (e.Length == x.Latitude?.Length && e.All(v => double.IsFinite(v) && v is > -1000 and < 10000)))
                .WithMessage("Elevation must be left out or have one value in metres for every point.");
        });
    }
}

/// <summary>
/// Adds a route and shares it with the member's club in one step. The line is measured and thinned here (see
/// <see cref="RouteGeometry"/>), never taken on trust from the request, and a ride's line is read from the ride itself
/// through the member's privacy rules.
/// </summary>
public sealed class CreateRoute(VelomineDbContext db, TimeProvider time) : Endpoint<CreateRouteRequest, RouteDetailResponse>
{
    public override void Configure()
    {
        Post("routes");
        Description(d => d.Accepts<CreateRouteRequest>("application/json").Produces<RouteDetailResponse>(201).ProducesProblem(400).Produces(401).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(CreateRouteRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        if (await RouteQueries.ClubIdAsync(db, userId, ct) is not { } clubId)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        IReadOnlyList<RoutePoint> points;
        if (req.RideId is { } rideId)
        {
            var ride = await RideRoutePoints.LoadAsync(db, userId, rideId, ct);
            if (ride.Problem == RideRouteProblem.NotFound)
            {
                await Send.NotFoundAsync(ct);
                return;
            }

            if (ride.Problem != RideRouteProblem.None)
            {
                AddError(RideRoutePoints.Message(ride.Problem));
                await Send.ErrorsAsync(409, ct);
                return;
            }

            points = ride.Points;
        }
        else
        {
            points = [.. req.Latitude!.Select((latitude, i) =>
                new RoutePoint(latitude, req.Longitude![i], req.Elevation is null ? null : (float)req.Elevation[i]))];
        }

        var (distance, climbing) = RouteGeometry.Measure(points);
        if (distance < RouteGeometry.MinDistanceM)
        {
            AddError("This line is shorter than 100 metres.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        var stored = RouteGeometry.Simplify(points);
        var route = new CyclingRoute
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            ClubId = clubId,
            Name = req.Name.Trim(),
            Description = string.IsNullOrWhiteSpace(req.Description) ? null : req.Description.Trim(),
            Surface = req.Surface,
            DistanceM = distance,
            ClimbingM = climbing,
            CreatedAt = time.GetUtcNow(),
            Line = new RouteLine
            {
                Latitude = [.. stored.Select(p => p.Latitude)],
                Longitude = [.. stored.Select(p => p.Longitude)],
                Elevation = RouteGeometry.FilledElevation(stored),
            },
        };
        db.Routes.Add(route);
        await db.SaveChangesAsync(ct);

        route.Owner = await db.Users.AsNoTracking().FirstAsync(u => u.Id == userId, ct);
        await Send.ResponseAsync(RouteQueries.Detail(route, userId), 201, ct);
    }
}
