using FastEndpoints;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Deleting your own account is confirmed: with your password, or, for an account that has none (it signs in through
/// single sign-on), by typing your email address.
/// </summary>
public sealed record DeleteMyAccountRequest(string? Password, string? ConfirmEmail);

public sealed class DeleteMyAccount(UserManager<User> users, SignInManager<User> signIn, AccountDeletion deletion)
    : Endpoint<DeleteMyAccountRequest>
{
    public override void Configure()
    {
        Post("accounts/me/delete");
        Description(d => d.Accepts<DeleteMyAccountRequest>("application/json").Produces(204).ProducesProblem(403).Produces(401).ProducesProblem(409).Produces(423), clearDefaults: true);
    }

    public override async Task HandleAsync(DeleteMyAccountRequest req, CancellationToken ct)
    {
        if (await users.GetUserAsync(User) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        var confirmed = false;
        if (await users.HasPasswordAsync(user))
        {
            switch (await PasswordCheck.RunAsync(signIn, user, req.Password))
            {
                case PasswordCheck.Result.LockedOut:
                    await Send.ResponseAsync(new { error = "locked_out" }, 423, ct);
                    return;
                case PasswordCheck.Result.Ok:
                    confirmed = true;
                    break;
            }
        }
        else
        {
            confirmed = string.Equals(req.ConfirmEmail?.Trim(), user.Email, StringComparison.OrdinalIgnoreCase);
        }
        if (!confirmed)
        {
            AddError("That does not match. Nothing was deleted.");
            await Send.ErrorsAsync(403, ct);
            return;
        }

        // The server never ends up with nobody in charge.
        if (await users.IsInRoleAsync(user, Accounts.Roles.Admin) && (await users.GetUsersInRoleAsync(Accounts.Roles.Admin)).Count <= 1)
        {
            AddError("You are the only admin. Make someone else an admin first.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var result = await deletion.DeleteAsync(user.Id, ct);
        if (result == AccountDeletionResult.SoleClubOwner)
        {
            AddError("You are the only owner of your club. Make another member the owner first.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        await HttpContext.SignOutAsync(IdentityConstants.ApplicationScheme); // the browser's cookie belongs to nobody now
        await Send.NoContentAsync(ct);
    }
}
