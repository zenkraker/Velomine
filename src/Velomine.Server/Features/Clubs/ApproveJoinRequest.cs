using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Features.Clubs;

public sealed class ApproveJoinRequestRequest
{
    /// <summary>From the address.</summary>
    public Guid JoinRequestId { get; set; }
}

/// <summary>The owner lets a rider in. The rider gets the club's notification; the request disappears either way.</summary>
public sealed class ApproveJoinRequest(VelomineDbContext db, TimeProvider time)
    : Endpoint<ApproveJoinRequestRequest>
{
    public override void Configure()
    {
        Post("club/join-requests/{joinRequestId}/approve");
        Description(d => d.Produces(204).Produces(401).Produces(403).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(ApproveJoinRequestRequest req, CancellationToken ct)
    {
        var mine = await db.ClubMemberships.AsNoTracking()
            .FirstOrDefaultAsync(m => m.UserId == User.UserId(), ct);
        if (mine is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (mine.Role != ClubRoles.Owner)
        {
            await Send.ForbiddenAsync(ct);
            return;
        }

        var request = await db.ClubJoinRequests
            .Include(r => r.Club)
            .FirstOrDefaultAsync(r => r.Id == req.JoinRequestId && r.ClubId == mine.ClubId, ct);
        if (request is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (!request.Club.IsActive)
        {
            AddError("This club is not active. Joining is closed.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        if (await db.ClubMemberships.AnyAsync(m => m.UserId == request.UserId, ct))
        {
            // Someone else let them in meanwhile, or they joined with a code: the ask has no answer anymore.
            db.ClubJoinRequests.Remove(request);
            await db.SaveChangesAsync(ct);
            AddError("That person is already in a club.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        db.ClubMemberships.Add(new ClubMembership
        {
            Id = Guid.NewGuid(),
            ClubId = request.ClubId,
            UserId = request.UserId,
            Role = ClubRoles.Member,
            JoinedAt = time.GetUtcNow(),
        });
        db.ClubJoinRequests.Remove(request);
        Notify.Add(db, time, request.UserId, NotificationTypes.ClubJoinApproved, request.Club.Name);

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // The unique index on user_id is the final guard when two owners approve at once.
            AddError("That person is already in a club.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        await Send.NoContentAsync(ct);
    }
}
