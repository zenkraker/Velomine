using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Features.Clubs;

public sealed class RequestToJoinRequest
{
    public required Guid ClubId { get; set; }

    /// <summary>A short word for the owner; optional.</summary>
    public string? Note { get; set; }
}

public sealed class RequestToJoinValidator : Validator<RequestToJoinRequest>
{
    public RequestToJoinValidator()
    {
        RuleFor(x => x.ClubId).NotEmpty();
        RuleFor(x => x.Note).MaximumLength(300);
    }
}

/// <summary>A rider without a club asks a discoverable club to let them in. One request per rider; asking another moves it.</summary>
public sealed class RequestToJoin(VelomineDbContext db, TimeProvider time)
    : Endpoint<RequestToJoinRequest, MyJoinRequestResponse>
{
    public override void Configure()
    {
        Post("club/join-request");
        Description(d => d.Accepts<RequestToJoinRequest>("application/json").Produces<MyJoinRequestResponse>(200).ProducesProblem(400).Produces(401).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(RequestToJoinRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        if (await db.ClubMemberships.AnyAsync(m => m.UserId == userId, ct))
        {
            AddError("You are already in a club.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var club = await db.Clubs.AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == req.ClubId && c.IsActive && c.IsDiscoverable, ct);
        if (club is null)
        {
            // A club that is not open to discovery is as good as absent here.
            await Send.NotFoundAsync(ct);
            return;
        }

        var user = await db.Users.AsNoTracking().FirstAsync(u => u.Id == userId, ct);
        var now = time.GetUtcNow();
        var request = await db.ClubJoinRequests.FirstOrDefaultAsync(r => r.UserId == userId, ct);
        if (request is null)
        {
            request = new ClubJoinRequest { Id = Guid.NewGuid(), UserId = userId };
            db.ClubJoinRequests.Add(request);
        }

        request.ClubId = club.Id;
        request.Note = string.IsNullOrWhiteSpace(req.Note) ? null : req.Note.Trim();
        request.CreatedAt = now;

        var owners = await db.ClubMemberships.AsNoTracking()
            .Where(m => m.ClubId == club.Id && m.Role == ClubRoles.Owner)
            .Select(m => m.UserId)
            .ToListAsync(ct);
        foreach (var ownerId in owners)
            Notify.Add(db, time, ownerId, NotificationTypes.ClubJoinRequest, user.DisplayName, aboutUserId: userId);

        await db.SaveChangesAsync(ct);
        await Send.OkAsync(new MyJoinRequestResponse(await JoinRequestQueries.MineAsync(db, userId, ct)), ct);
    }
}
