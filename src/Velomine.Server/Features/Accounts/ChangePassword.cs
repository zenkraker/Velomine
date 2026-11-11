using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

public sealed record ChangePasswordRequest(string CurrentPassword, string NewPassword);

public sealed class ChangePasswordValidator : Validator<ChangePasswordRequest>
{
    public ChangePasswordValidator()
    {
        RuleFor(x => x.CurrentPassword).NotEmpty();
        RuleFor(x => x.NewPassword).NotEmpty();
    }
}

/// <summary>
/// Changes the password of a signed-in account. The current password is the confirmation; a single sign-on account has
/// none and is refused. The security stamp changes, so the app signs out on every device.
/// </summary>
public sealed class ChangePassword(UserManager<User> users, SignInManager<User> signIn, UserSessions sessions)
    : Endpoint<ChangePasswordRequest>
{
    public override void Configure()
    {
        Put("accounts/me/password");
        Description(d => d.Accepts<ChangePasswordRequest>("application/json").Produces(204).ProducesProblem(400)
            .Produces(401).ProducesProblem(409).Produces(423), clearDefaults: true);
    }

    public override async Task HandleAsync(ChangePasswordRequest req, CancellationToken ct)
    {
        if (await users.GetUserAsync(User) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        if (!await users.HasPasswordAsync(user))
        {
            AddError("This account signs in with single sign-on.", "no_password");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        switch (await PasswordCheck.RunAsync(signIn, user, req.CurrentPassword))
        {
            case PasswordCheck.Result.LockedOut:
                await Send.ResponseAsync(new { error = "locked_out" }, 423, ct);
                return;
            case PasswordCheck.Result.Wrong:
                AddError("The current password is not right.", "wrong_password");
                await Send.ErrorsAsync(400, ct);
                return;
        }

        var result = await users.ChangePasswordAsync(user, req.CurrentPassword, req.NewPassword);
        if (!result.Succeeded)
        {
            foreach (var error in result.Errors) AddError(error.Description, error.Code);
            await Send.ErrorsAsync(400, ct);
            return;
        }

        await users.UpdateSecurityStampAsync(user);
        await sessions.RevokeAllAsync(user.Id, ct);
        await Send.NoContentAsync(ct);
    }
}
