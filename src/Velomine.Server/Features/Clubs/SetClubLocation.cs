using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

public sealed class SetClubLocationRequest
{
    /// <summary>Where the club meets. Both coordinates or neither.</summary>
    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    /// <summary>Whether riders without a club may find the club by distance and ask to join.</summary>
    public required bool IsDiscoverable { get; set; }
}

public sealed class SetClubLocationValidator : Validator<SetClubLocationRequest>
{
    public SetClubLocationValidator()
    {
        RuleFor(x => x.Latitude).InclusiveBetween(-90, 90).When(x => x.Latitude.HasValue);
        RuleFor(x => x.Longitude).InclusiveBetween(-180, 180).When(x => x.Longitude.HasValue);
        RuleFor(x => x)
            .Must(x => x.Latitude.HasValue == x.Longitude.HasValue)
            .WithMessage("Set both coordinates or neither.");
        RuleFor(x => x.IsDiscoverable)
            .Must((request, discoverable) => !discoverable || request.Latitude.HasValue)
            .WithMessage("Set the club's location before showing it to riders nearby.");
    }
}

/// <summary>The owner sets where the club is and whether riders nearby may find it.</summary>
public sealed class SetClubLocation(VelomineDbContext db, TimeProvider time) : Endpoint<SetClubLocationRequest, MyClubResponse>
{
    public override void Configure()
    {
        Put("club/location");
        Description(d => d.Accepts<SetClubLocationRequest>("application/json").Produces<MyClubResponse>(200).ProducesProblem(400).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(SetClubLocationRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var membership = await db.ClubMemberships.Include(m => m.Club)
            .FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (membership is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (membership.Role != ClubRoles.Owner)
        {
            await Send.ForbiddenAsync(ct);
            return;
        }

        membership.Club.Latitude = req.Latitude is { } latitude ? Math.Round(latitude, 6) : null;
        membership.Club.Longitude = req.Longitude is { } longitude ? Math.Round(longitude, 6) : null;
        membership.Club.IsDiscoverable = req.IsDiscoverable;
        await db.SaveChangesAsync(ct);

        await Send.OkAsync(new MyClubResponse(await ClubQueries.MyClubAsync(db, time, userId, ct), false), ct);
    }
}
