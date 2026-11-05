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

        if (await deletion.DeleteAsync(req.Id, ct)) await Send.NoContentAsync(ct);
        else await Send.NotFoundAsync(ct);
    }
}
