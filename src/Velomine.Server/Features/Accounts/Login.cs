using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// UseCookies: true for the web app (cookie session), false for the mobile app (bearer tokens). RememberMe: keep the
/// web cookie after the browser closes. DeviceLabel is what the member sees in the session list; older clients leave it out.
/// </summary>
public sealed record LoginRequest(string Email, string Password, bool UseCookies = false, bool RememberMe = true, string? DeviceLabel = null);

public sealed class LoginValidator : Validator<LoginRequest>
{
    public LoginValidator()
    {
        RuleFor(x => x.Email).NotEmpty();
        RuleFor(x => x.Password).NotEmpty();
        RuleFor(x => x.DeviceLabel).MaximumLength(60);
    }
}

public sealed class Login(
    UserManager<User> users,
    SignInManager<User> signIn,
    SessionSignIn sessions,
    TwoFactorChallenges challenges) : Endpoint<LoginRequest>
{
    public override void Configure()
    {
        Post("accounts/login");
        AllowAnonymous();
        Options(b => b.RequireRateLimiting("anonymous"));
        Description(
            d => d.Accepts<LoginRequest>("application/json")
                .Produces<TokenResponse>(200, "application/json")
                .Produces<TwoFactorRequiredResponse>(202, "application/json")
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
        // The password is checked here instead of PasswordSignInAsync so the session row exists before the cookie or
        // the token pair is written, which is what carries the session id.
        if (await users.FindByEmailAsync(req.Email.Trim()) is not { } user)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        var result = await signIn.CheckPasswordSignInAsync(user, req.Password, lockoutOnFailure: true);

        // CheckPasswordSignInAsync only proves the password; the second factor is decided here.
        if (result.Succeeded && user.TwoFactorEnabled)
        {
            await Send.ResponseAsync(new TwoFactorRequiredResponse(true, challenges.Issue(user.Id)), 202, ct);
            return;
        }

        if (result.Succeeded)
        {
            await sessions.SignInAsync(
                user,
                req.UseCookies ? IdentityConstants.ApplicationScheme : IdentityConstants.BearerScheme,
                isPersistent: req.UseCookies && req.RememberMe,
                req.DeviceLabel,
                ct);
            return;
        }

        if (result.IsLockedOut) await Send.ResponseAsync(new { error = "locked_out" }, 423, ct);
        else if (result.IsNotAllowed) await Send.ResponseAsync(new { error = "not_approved" }, 403, ct);
        else await Send.UnauthorizedAsync(ct);
    }
}
