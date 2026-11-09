using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Admin;

namespace Velomine.Server.Features.Accounts;

/// <summary>The ID token and optional access token the phone got from the provider's public client.</summary>
public sealed record ExchangeSsoTokenRequest(string IdToken, string? AccessToken);

public sealed class ExchangeSsoTokenValidator : Validator<ExchangeSsoTokenRequest>
{
    public ExchangeSsoTokenValidator()
    {
        RuleFor(x => x.IdToken).NotEmpty().MaximumLength(8192);
        RuleFor(x => x.AccessToken).MaximumLength(8192);
    }
}

/// <summary>Validates a provider ID token, applies the same account rules as the web, and issues Velomine bearer tokens.</summary>
public sealed class ExchangeSsoToken(
    SsoTokenValidator validator,
    UserManager<User> users,
    SignInManager<User> signIn,
    VelomineDbContext db,
    SettingsReader settings,
    TimeProvider clock,
    IOptions<SsoOptions> sso,
    ILogger<ExchangeSsoToken> logger) : Endpoint<ExchangeSsoTokenRequest>
{
    public override void Configure()
    {
        Post("accounts/sso/token");
        AllowAnonymous();
        Options(b => b.RequireRateLimiting("anonymous"));
        Description(
            d => d.Accepts<ExchangeSsoTokenRequest>("application/json")
                .Produces<TokenResponse>(200, "application/json")
                .ProducesProblem(400)
                .Produces(401)
                .Produces(403)
                .Produces(423)
                .ProducesProblem(429)
                .ProducesProblem(502),
            clearDefaults: true);
    }

    public override async Task HandleAsync(ExchangeSsoTokenRequest req, CancellationToken ct)
    {
        if (!sso.Value.AppSsoEnabled)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        SsoIdentity? identity;
        try
        {
            identity = await validator.ValidateAsync(req.IdToken, req.AccessToken, ct);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            logger.LogWarning("The single sign-on provider could not be reached ({Exception}).", ex.GetType().Name);
            await Send.ResponseAsync(new { error = "provider_unavailable" }, 502, ct);
            return;
        }

        if (identity is null)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        var user = await users.FindByLoginAsync(SsoOptions.Scheme, identity.Subject);
        if (user is null)
        {
            var error = await SsoAccounts.LinkOrCreateAsync(db, users, settings, clock, sso.Value, identity, ct);
            if (error is not null)
            {
                await Send.ResponseAsync(new { error }, 400, ct);
                return;
            }

            user = await users.FindByLoginAsync(SsoOptions.Scheme, identity.Subject);
        }

        if (user is null)
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

        // Writes the access and refresh tokens as the response, like login and refresh do.
        await HttpContext.SignInAsync(IdentityConstants.BearerScheme, await signIn.CreateUserPrincipalAsync(user));
    }
}
