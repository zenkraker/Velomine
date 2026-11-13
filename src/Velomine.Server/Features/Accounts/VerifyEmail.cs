using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;
using Velomine.Server.Features.Admin;

namespace Velomine.Server.Features.Accounts;

public sealed record VerifyEmailRequest(string Email, string Token);

public sealed class VerifyEmailValidator : Validator<VerifyEmailRequest>
{
    public VerifyEmailValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(256);
        RuleFor(x => x.Token).NotEmpty().MaximumLength(2048);
    }
}

/// <summary>
/// Confirms the address from the link in the verification email. Identity's token works once and expires after
/// <see cref="EmailVerificationLinks.Lifetime"/>. With email off there is nothing to confirm, so the answer is the
/// same 503 the other email endpoints give.
/// </summary>
public sealed class VerifyEmail(
    UserManager<User> users,
    IOptions<SmtpOptions> smtp,
    PasswordResetThrottle throttle) : Endpoint<VerifyEmailRequest>
{
    public override void Configure()
    {
        Post("accounts/email/verify");
        AllowAnonymous();
        Options(b => b.RequireRateLimiting("anonymous"));
        Description(d => d.Accepts<VerifyEmailRequest>("application/json").Produces(204).ProducesProblem(400)
            .ProducesProblem(429).ProducesProblem(503), clearDefaults: true);
    }

    public override async Task HandleAsync(VerifyEmailRequest req, CancellationToken ct)
    {
        if (!throttle.AllowedForEmail(req.Email))
        {
            await Send.ResponseAsync(new { error = "too_many_requests" }, 429, ct);
            return;
        }

        if (!EmailVerification.Required(smtp))
        {
            await Send.ResponseAsync(new { error = "email_not_configured" }, 503, ct);
            return;
        }

        if (await users.FindByEmailAsync(req.Email.Trim()) is not { } user || user.EmailConfirmed)
        {
            // Identity hands a token for a confirmed address a pass; the link works once, so it is spent here.
            await InvalidTokenAsync(ct);
            return;
        }

        var result = await users.ConfirmEmailAsync(user, req.Token);
        if (!result.Succeeded)
        {
            await InvalidTokenAsync(ct);
            return;
        }

        await Send.NoContentAsync(ct);
    }

    private async Task InvalidTokenAsync(CancellationToken ct)
    {
        AddError("The link is not valid or has expired. Ask for a new one.", "invalid_token");
        await Send.ErrorsAsync(400, ct);
    }
}
