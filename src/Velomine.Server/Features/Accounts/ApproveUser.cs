using FastEndpoints;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Features.Accounts;

public sealed class ApproveUserRequest
{
    public Guid Id { get; set; }
}

public sealed class ApproveUser(UserManager<User> users, VelomineDbContext db, TimeProvider time) : Endpoint<ApproveUserRequest>
{
    public override void Configure()
    {
        Post("accounts/users/{id}/approve");
        Roles(Accounts.Roles.Admin);
    }

    public override async Task HandleAsync(ApproveUserRequest req, CancellationToken ct)
    {
        if (await users.FindByIdAsync(req.Id.ToString()) is not { } user)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        user.IsApproved = true;
        await users.UpdateAsync(user);

        // Once one admin has approved the account, the other admins' "waiting for approval" notices are dealt with.
        var now = time.GetUtcNow();
        await db.Notifications
            .Where(n => n.Type == NotificationTypes.SignUpWaiting && n.AboutUserId == user.Id && n.ReadAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.ReadAt, now), ct);
        await Send.NoContentAsync(ct);
    }
}
