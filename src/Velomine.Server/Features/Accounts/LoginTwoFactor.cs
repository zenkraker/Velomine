using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

/// <summary>The challenge from login and the code from the authenticator app (or one recovery code).</summary>
public sealed record LoginTwoFactorRequest(string Challenge, string Code, bool UseCookies = false, bool RememberMe = true, string? DeviceLabel = null);

public sealed class LoginTwoFactorValidator : Validator<LoginTwoFactorRequest>
{
    public LoginTwoFactorValidator()
    {
        RuleFor(x => x.Challenge).NotEmpty().MaximumLength(2048);
        RuleFor(x => x.Code).NotEmpty().MaximumLength(64);
        RuleFor(x => x.DeviceLabel).MaximumLength(60);
    }
}

/// <summary>
/// The second step of a sign-in. The challenge proves the password was just checked; the code is the second factor.
/// A wrong code counts toward the same lockout as a wrong password.
/// </summary>
public sealed class LoginTwoFactor(
    UserManager<User> users,
    SignInManager<User> signIn,
    SessionSignIn sessions,
    TwoFactorChallenges challenges) : Endpoint<LoginTwoFactorRequest>
{
    public override void Configure()
    {
        Post("accounts/login/two-factor");
        AllowAnonymous();
        Options(b => b.RequireRateLimiting("anonymous"));
        Description(
            d => d.Accepts<LoginTwoFactorRequest>("application/json")
                .Produces<TokenResponse>(200, "application/json")
                .Produces(204)
                .ProducesProblem(400)
                .Produces(401)
                .Produces(403)
                .Produces(423)
                .ProducesProblem(429),
            clearDefaults: true);
    }

    public override async Task HandleAsync(LoginTwoFactorRequest req, CancellationToken ct)
    {
        if (challenges.Read(req.Challenge) is not { } userId
            || await users.FindByIdAsync(userId.ToString()) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        if (await users.IsLockedOutAsync(user))
        {
            await Send.ResponseAsync(new { error = "locked_out" }, 423, ct);
            return;
        }

        if (!await signIn.CanSignInAsync(user))
        {
            await Send.ResponseAsync(new { error = "not_approved" }, 403, ct);
            return;
        }

        var valid = await users.VerifyTwoFactorTokenAsync(user, users.Options.Tokens.AuthenticatorTokenProvider, req.Code)
            || (await users.RedeemTwoFactorRecoveryCodeAsync(user, req.Code)).Succeeded;

        if (!valid)
        {
            await users.AccessFailedAsync(user);
            if (await users.IsLockedOutAsync(user))
            {
                await Send.ResponseAsync(new { error = "locked_out" }, 423, ct);
                return;
            }

            await Send.UnauthorizedAsync(ct);
            return;
        }

        await users.ResetAccessFailedCountAsync(user);
        await sessions.SignInAsync(
            user,
            req.UseCookies ? IdentityConstants.ApplicationScheme : IdentityConstants.BearerScheme,
            isPersistent: req.UseCookies && req.RememberMe,
            req.DeviceLabel,
            ct);
    }
}
