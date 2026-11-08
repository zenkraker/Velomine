using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

public sealed class CreateClubRequest
{
    public required string Name { get; set; }

    /// <summary>An existing account that becomes the club's owner.</summary>
    public required string OwnerEmail { get; set; }
}

public sealed class CreateClubValidator : Validator<CreateClubRequest>
{
    public CreateClubValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.OwnerEmail).NotEmpty().EmailAddress();
    }
}

/// <summary>The instance admin creates a club and names the account that owns it.</summary>
public sealed class CreateClub(VelomineDbContext db, UserManager<User> users, TimeProvider time)
    : Endpoint<CreateClubRequest, AdminClubResponse>
{
    public override void Configure()
    {
        Post("admin/clubs");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Accepts<CreateClubRequest>("application/json").Produces<AdminClubResponse>(200).ProducesProblem(400).Produces(401).Produces(403).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(CreateClubRequest req, CancellationToken ct)
    {
        var name = req.Name.Trim();
        var owner = await users.FindByEmailAsync(req.OwnerEmail.Trim());
        if (owner is null)
        {
            AddError("There is no account with that email address.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        if (await db.ClubMemberships.AnyAsync(m => m.UserId == owner.Id, ct))
        {
            AddError("That account is already in a club. One account belongs to one club.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

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
            CreatedAt = now,
            CreatedBy = User.UserId(),
        };
        club.Memberships.Add(new ClubMembership
        {
            Id = Guid.NewGuid(),
            UserId = owner.Id,
            Role = ClubRoles.Owner,
            JoinedAt = now,
        });
        db.Clubs.Add(club);

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // The unique indexes are the final guard against two admins creating the same name at once.
            AddError("A club with that name or code already exists.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        await Send.OkAsync(await ClubQueries.AdminAsync(db, club, ct), ct);
    }
}
