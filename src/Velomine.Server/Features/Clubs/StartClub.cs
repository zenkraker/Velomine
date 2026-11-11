using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;

namespace Velomine.Server.Features.Clubs;

public sealed class StartClubRequest
{
    public required string Name { get; set; }

    /// <summary>Where the club meets. Both coordinates or neither.</summary>
    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    /// <summary>Whether riders without a club may find the club by distance and ask to join.</summary>
    public required bool IsDiscoverable { get; set; }
}

public sealed class StartClubValidator : Validator<StartClubRequest>
{
    public StartClubValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
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

/// <summary>
/// A rider without a club starts one, when the operator has turned that on. They become its owner, and the club begins on
/// the smallest band with a month to try it. Otherwise it works as a club the operator created.
/// </summary>
public sealed class StartClub(VelomineDbContext db, SettingsReader settings, TimeProvider time)
    : Endpoint<StartClubRequest, MyClubResponse>
{
    public override void Configure()
    {
        Post("club");
        Options(b => b.RequireRateLimiting("club-creation"));
        Description(d => d.Accepts<StartClubRequest>("application/json").Produces<MyClubResponse>(200).ProducesProblem(400).Produces(401).ProducesProblem(403).ProducesProblem(409).Produces(429), clearDefaults: true);
    }

    public override async Task HandleAsync(StartClubRequest req, CancellationToken ct)
    {
        if (!(await settings.GetAsync(ct)).ClubCreationEnabled)
        {
            AddError("Riders cannot start clubs on this server. Ask the server admin to create one.");
            await Send.ErrorsAsync(403, ct);
            return;
        }

        var userId = User.UserId();
        if (await db.ClubMemberships.AnyAsync(m => m.UserId == userId, ct))
        {
            AddError("You are already in a club. One account belongs to one club.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var name = req.Name.Trim();
        if (await db.Clubs.AnyAsync(c => c.Name == name, ct))
        {
            AddError("A club with that name already exists.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var now = time.GetUtcNow();
        var club = new Club
        {
            Id = Guid.NewGuid(),
            Name = name,
            JoinCode = await JoinCodes.UniqueAsync(db, ct),
            Latitude = req.Latitude is { } latitude ? Math.Round(latitude, 6) : null,
            Longitude = req.Longitude is { } longitude ? Math.Round(longitude, 6) : null,
            IsDiscoverable = req.IsDiscoverable,
            MemberLimit = ClubPlan.Limits[0],
            PaidUntil = ClubPlan.Today(time).AddDays(ClubPlan.TrialDays),
            CreatedAt = now,
            CreatedBy = userId,
        };
        club.Memberships.Add(new ClubMembership
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Role = ClubRoles.Owner,
            JoinedAt = now,
        });
        db.Clubs.Add(club);

        // Starting a club answers any ask the rider had open elsewhere.
        var pending = await db.ClubJoinRequests.FirstOrDefaultAsync(r => r.UserId == userId, ct);
        if (pending is not null) db.ClubJoinRequests.Remove(pending);

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // The unique indexes are the final guard: the same name at once, or two requests from one rider.
            AddError("A club with that name already exists, or you are already in a club.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        await Send.OkAsync(new MyClubResponse(await ClubQueries.MyClubAsync(db, time, userId, ct), false), ct);
    }
}
