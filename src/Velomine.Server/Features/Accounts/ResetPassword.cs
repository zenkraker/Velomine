using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;

namespace Velomine.Server.Features.Accounts;

public sealed record ResetPasswordRequest(string Email, string Token, string NewPassword);

public sealed class ResetPasswordValidator : Validator<ResetPasswordRequest>
{
    public ResetPasswordValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(256);
        RuleFor(x => x.Token).NotEmpty().MaximumLength(2048);
        RuleFor(x => x.NewPassword).NotEmpty();
    }
}

/// <summary>
/// Finishes a password reset with the token from the email. Identity's token works once and expires after
/// <see cref="PasswordResetLinks.Lifetime"/>. The security stamp changes, so every existing session stops renewing.
/// </summary>
public sealed class ResetPassword(
    UserManager<User> users,
    UserSessions sessions,
    PasswordResetThrottle throttle) : Endpoint<ResetPasswordRequest>
{
    public override void Configure()
    {
        Post("accounts/password/reset");
        AllowAnonymous();
        Options(b => b.RequireRateLimiting("anonymous"));
        Description(d => d.Accepts<ResetPasswordRequest>("application/json").Produces(204).ProducesProblem(400)
            .ProducesProblem(429), clearDefaults: true);
    }

    public override async Task HandleAsync(ResetPasswordRequest req, CancellationToken ct)
    {
        if (!throttle.Allowed("reset", HttpContext))
        {
            await Send.ResponseAsync(new { error = "too_many_requests" }, 429, ct);
            return;
        }

        var user = await users.FindByEmailAsync(req.Email.Trim());

        // An account with no password signs in with single sign-on: it has no reset token to spend.
        if (user is null || !await users.HasPasswordAsync(user))
        {
            AddError("The link is not valid. Ask for a new one.", "invalid_token");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        var result = await users.ResetPasswordAsync(user, req.Token, req.NewPassword);
        if (!result.Succeeded)
        {
            if (result.Errors.Any(e => e.Code is "InvalidToken"))
            {
                AddError("The link is not valid or has expired. Ask for a new one.", "invalid_token");
            }
            else
            {
                foreach (var error in result.Errors) AddError(error.Description, error.Code);
            }

            await Send.ErrorsAsync(400, ct);
            return;
        }

        // ResetPasswordAsync already moves the stamp, but doing it here makes the guarantee explicit.
        await users.UpdateSecurityStampAsync(user);
        await sessions.RevokeAllAsync(user.Id, ct);
        await Send.NoContentAsync(ct);
    }
}
