using FastEndpoints;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

public sealed class ApproveUserRequest
{
    public Guid Id { get; set; }
}

public sealed class ApproveUser(UserManager<User> users) : Endpoint<ApproveUserRequest>
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
        await Send.NoContentAsync(ct);
    }
}
