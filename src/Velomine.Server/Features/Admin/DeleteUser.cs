using FastEndpoints;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Admin;

/// <summary>Deletes an account and all its data, including the original ride files nothing else uses. It cannot be undone.</summary>
public sealed class DeleteUser(AccountDeletion deletion) : Endpoint<UserIdRequest>
{
    public override void Configure()
    {
        Delete("admin/users/{id}");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Produces(204).Produces(401).Produces(403).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(UserIdRequest req, CancellationToken ct)
    {
        if (req.Id == User.UserId())
        {
            AddError("You cannot delete your own account here. Use your profile.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        switch (await deletion.DeleteAsync(req.Id, ct))
        {
            case AccountDeletionResult.Deleted:
                await Send.NoContentAsync(ct);
                return;
            case AccountDeletionResult.SoleClubOwner:
                AddError("That account is the only owner of its club. Make another member the owner first.");
                await Send.ErrorsAsync(409, ct);
                return;
            default:
                await Send.NotFoundAsync(ct);
                return;
        }
    }
}
