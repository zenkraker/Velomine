using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

/// <summary>What the phone app got back from the browser (code) and the secret it made when it started (codeVerifier).</summary>
public sealed record ExchangeSsoCodeRequest(string Code, string CodeVerifier);

public sealed class ExchangeSsoCodeValidator : Validator<ExchangeSsoCodeRequest>
{
    public ExchangeSsoCodeValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(128);
        // RFC 7636: 43 to 128 characters.
        RuleFor(x => x.CodeVerifier).NotEmpty().MinimumLength(43).MaximumLength(128);
    }
}

/// <summary>Turns the one-time code from a browser sign-in into the same bearer tokens a password sign-in gives the app.</summary>
public sealed class ExchangeSsoCode(SsoAppCodes codes, UserManager<User> users, SignInManager<User> signIn)
    : Endpoint<ExchangeSsoCodeRequest>
{
    public override void Configure()
    {
        Post("accounts/sso/token");
        AllowAnonymous();
        Description(d => d.Accepts<ExchangeSsoCodeRequest>("application/json").Produces<TokenResponse>(200, "application/json").ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(ExchangeSsoCodeRequest req, CancellationToken ct)
    {
        if (codes.Redeem(req.Code, req.CodeVerifier) is not { } userId
            || await users.FindByIdAsync(userId.ToString()) is not { } user
            || !await signIn.CanSignInAsync(user)
            || await users.IsLockedOutAsync(user))
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        // Writes the access and refresh tokens as the response, like login and refresh do.
        await HttpContext.SignInAsync(IdentityConstants.BearerScheme, await signIn.CreateUserPrincipalAsync(user));
    }
}
