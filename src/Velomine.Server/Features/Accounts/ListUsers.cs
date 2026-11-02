using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

public sealed class ListUsersRequest
{
    /// <summary>Only accounts waiting for approval.</summary>
    public bool Pending { get; set; }
}

public sealed record UserSummary(Guid Id, string Email, string DisplayName, bool IsApproved, DateTimeOffset CreatedAt);

public sealed class ListUsers(VelomineDbContext db) : Endpoint<ListUsersRequest, UserSummary[]>
{
    public override void Configure()
    {
        Get("accounts/users");
        Roles(Accounts.Roles.Admin);
    }

    public override async Task HandleAsync(ListUsersRequest req, CancellationToken ct)
    {
        var query = db.Users.AsNoTracking();
        if (req.Pending) query = query.Where(u => !u.IsApproved);

        var users = await query
            .OrderBy(u => u.CreatedAt)
            .Select(u => new UserSummary(u.Id, u.Email!, u.DisplayName, u.IsApproved, u.CreatedAt))
            .ToArrayAsync(ct);
        await Send.OkAsync(users, ct);
    }
}
