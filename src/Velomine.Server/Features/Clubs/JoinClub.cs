using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

public sealed class JoinClubRequest
{
    /// <summary>The club's join code, from a shared link or read out by the owner.</summary>
    public required string Code { get; set; }
}

public sealed class JoinClubValidator : Validator<JoinClubRequest>
{
    public JoinClubValidator() => RuleFor(x => x.Code).NotEmpty().MaximumLength(16);
}

/// <summary>Joins a club as a rider. One account belongs to one club, so an existing membership is a conflict.</summary>
public sealed class JoinClub(VelomineDbContext db, TimeProvider time) : Endpoint<JoinClubRequest, MyClubResponse>
{
    public override void Configure()
    {
        Post("club/join");
        Description(d => d.Accepts<JoinClubRequest>("application/json").Produces<MyClubResponse>(200).ProducesProblem(400).Produces(401).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(JoinClubRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        if (await db.ClubMemberships.AnyAsync(m => m.UserId == userId, ct))
        {
            AddError("You are already in a club. One account belongs to one club.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var code = req.Code.Trim().ToUpperInvariant();
        var club = await db.Clubs.FirstOrDefaultAsync(c => c.JoinCode == code && c.IsActive, ct);
        if (club is null)
        {
            // The same answer for a wrong code and a disabled club: neither tells a stranger which clubs exist.
            await Send.NotFoundAsync(ct);
            return;
        }

        // A code join answers any ask the rider had open elsewhere.
        var pending = await db.ClubJoinRequests.FirstOrDefaultAsync(r => r.UserId == userId, ct);
        var result = await ClubAdmission.AdmitAsync(db, time, club.Id, userId, () =>
        {
            if (pending is not null) db.ClubJoinRequests.Remove(pending);
        }, ct);
        if (result == AdmissionResult.ClubNotFound)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (result != AdmissionResult.Admitted)
        {
            AddError(result == AdmissionResult.AlreadyInClub
                ? "You are already in a club. One account belongs to one club."
                : ClubAdmission.Refusal(result)!);
            await Send.ErrorsAsync(409, ct);
            return;
        }

        await Send.OkAsync(new MyClubResponse(await ClubQueries.MyClubAsync(db, time, userId, ct), false), ct);
    }
}
