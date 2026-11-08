using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

public sealed class UpdateClubRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    public required string Name { get; set; }

    /// <summary>A disabled club keeps its data but takes no new joins.</summary>
    public required bool IsActive { get; set; }
}

public sealed class UpdateClubValidator : Validator<UpdateClubRequest>
{
    public UpdateClubValidator() => RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
}

public sealed class UpdateClub(VelomineDbContext db) : Endpoint<UpdateClubRequest, AdminClubResponse>
{
    public override void Configure()
    {
        Put("admin/clubs/{id}");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Accepts<UpdateClubRequest>("application/json").Produces<AdminClubResponse>(200).ProducesProblem(400).Produces(401).Produces(403).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateClubRequest req, CancellationToken ct)
    {
        if (await db.Clubs.FirstOrDefaultAsync(c => c.Id == req.Id, ct) is not { } club)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var name = req.Name.Trim();
        if (await db.Clubs.AnyAsync(c => c.Id != club.Id && c.Name == name, ct))
        {
            AddError("A club with that name already exists.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        club.Name = name;
        club.IsActive = req.IsActive;
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await ClubQueries.AdminAsync(db, club, ct), ct);
    }
}
