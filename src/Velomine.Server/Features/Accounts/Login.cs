using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// UseCookies: true for the web app (cookie session), false for the mobile app (bearer tokens). RememberMe: keep the
/// web cookie after the browser closes. TwoFactorCode or TwoFactorRecoveryCode: sent with the password when the account
/// has a second factor, as Identity's own login takes them.
/// </summary>
public sealed record LoginRequest(
    string Email,
    string Password,
    bool UseCookies = false,
    bool RememberMe = true,
    string? TwoFactorCode = null,
    string? TwoFactorRecoveryCode = null);

public sealed class LoginValidator : Validator<LoginRequest>
{
    public LoginValidator()
    {
        RuleFor(x => x.Email).NotEmpty();
        RuleFor(x => x.Password).NotEmpty();
        RuleFor(x => x.TwoFactorCode).MaximumLength(64);
        RuleFor(x => x.TwoFactorRecoveryCode).MaximumLength(64);
    }
}

/// <summary>
/// Signs in with Identity's own sequence (the one its /login endpoint uses): password, then the authenticator or
/// recovery code when the account has a second factor. A wrong code counts toward the same lockout as a wrong password.
/// </summary>
public sealed class Login(UserManager<User> users, SignInManager<User> signIn) : Endpoint<LoginRequest>
{
    public override void Configure()
    {
        Post("accounts/login");
        AllowAnonymous();
        Options(b => b.RequireRateLimiting("anonymous"));
        Description(
            d => d.Accepts<LoginRequest>("application/json")
                .Produces<TokenResponse>(200, "application/json")
                .Produces(204)
                .ProducesProblem(400)
                .Produces(401)
                .Produces(403)
                .Produces(423)
                .ProducesProblem(429),
            clearDefaults: true);
    }

    public override async Task HandleAsync(LoginRequest req, CancellationToken ct)
    {
        if (await users.FindByEmailAsync(req.Email.Trim()) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        // On success the cookie or the token pair is written as the response.
        signIn.AuthenticationScheme = req.UseCookies ? IdentityConstants.ApplicationScheme : IdentityConstants.BearerScheme;
        var isPersistent = req.UseCookies && req.RememberMe;
        var result = await signIn.PasswordSignInAsync(user, req.Password, isPersistent, lockoutOnFailure: true);

        if (result.RequiresTwoFactor)
        {
            if (!string.IsNullOrEmpty(req.TwoFactorCode))
                result = await signIn.TwoFactorAuthenticatorSignInAsync(req.TwoFactorCode, isPersistent, rememberClient: false);
            else if (!string.IsNullOrEmpty(req.TwoFactorRecoveryCode))
                result = await signIn.TwoFactorRecoveryCodeSignInAsync(req.TwoFactorRecoveryCode);
        }

        if (result.Succeeded) return;

        if (result.RequiresTwoFactor) await Send.ResponseAsync(new { error = "two_factor_required" }, 401, ct);
        else if (result.IsLockedOut) await Send.ResponseAsync(new { error = "locked_out" }, 423, ct);
        else if (result.IsNotAllowed) await Send.ResponseAsync(new { error = Refusal(user) }, 403, ct);
        else await Send.UnauthorizedAsync(ct);
    }

    /// <summary>Why the account may not sign in, as the app words it: approval first, then the unconfirmed address.</summary>
    public static string Refusal(User user) => user.IsApproved ? "email_not_confirmed" : "not_approved";
}
