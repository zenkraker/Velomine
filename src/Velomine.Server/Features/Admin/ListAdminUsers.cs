using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Admin;

/// <summary>An account as an admin manages it. No ride or training data: admins do not see members' rides.</summary>
public sealed record AdminUserSummary(
    Guid Id,
    string Email,
    string DisplayName,
    bool IsApproved,
    bool IsLockedOut,
    string[] Roles,
    DateTimeOffset CreatedAt);

public sealed record ListAdminUsersResponse(AdminUserSummary[] Users);

public sealed class ListAdminUsers(VelomineDbContext db, TimeProvider time) : EndpointWithoutRequest<ListAdminUsersResponse>
{
    public override void Configure()
    {
        Get("admin/users");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Produces<ListAdminUsersResponse>(200).Produces(401).Produces(403), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var now = time.GetUtcNow();
        var users = await db.Users.AsNoTracking().OrderBy(u => u.CreatedAt).ThenBy(u => u.Email).ToListAsync(ct);
        var roles = (await (from ur in db.UserRoles
                            join r in db.Roles on ur.RoleId equals r.Id
                            select new { ur.UserId, r.Name }).ToListAsync(ct))
            .ToLookup(x => x.UserId, x => x.Name!);

        await Send.OkAsync(new ListAdminUsersResponse([.. users.Select(u => new AdminUserSummary(
            u.Id, u.Email!, u.DisplayName, u.IsApproved, u.LockoutEnd > now, [.. roles[u.Id].Order()], u.CreatedAt))]), ct);
    }
}
