using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

/// <summary>UseCookies: true for the web app (cookie session), false for the mobile app (bearer tokens).</summary>
public sealed record LoginRequest(string Email, string Password, bool UseCookies = false);

public sealed class LoginValidator : Validator<LoginRequest>
{
    public LoginValidator()
    {
        RuleFor(x => x.Email).NotEmpty();
        RuleFor(x => x.Password).NotEmpty();
    }
}

public sealed class Login(SignInManager<User> signIn) : Endpoint<LoginRequest>
{
    public override void Configure()
    {
        Post("accounts/login");
        AllowAnonymous();
    }

    public override async Task HandleAsync(LoginRequest req, CancellationToken ct)
    {
        signIn.AuthenticationScheme = req.UseCookies ? IdentityConstants.ApplicationScheme : IdentityConstants.BearerScheme;
        var result = await signIn.PasswordSignInAsync(req.Email, req.Password, isPersistent: req.UseCookies, lockoutOnFailure: true);

        // On success the authentication handler has already written the response:
        // the cookie, or the bearer token JSON { access_token, refresh_token, expires_in }.
        if (result.Succeeded) return;

        if (result.IsLockedOut) await Send.ResponseAsync(new { error = "locked_out" }, 423, ct);
        else if (result.IsNotAllowed) await Send.ResponseAsync(new { error = "not_approved" }, 403, ct);
        else await Send.UnauthorizedAsync(ct);
    }
}
