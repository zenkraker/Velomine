using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Features.Accounts;

public sealed record ForgotPasswordRequest(string Email);

public sealed class ForgotPasswordValidator : Validator<ForgotPasswordRequest>
{
    public ForgotPasswordValidator() =>
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(256);
}

/// <summary>
/// Starts a password reset. The answer is always 202 when email is set up, whether or not the address has an account:
/// the response must not tell a stranger who is registered. Email off is a server-wide 503, not a guess.
/// </summary>
public sealed class ForgotPassword(
    UserManager<User> users,
    IEmailSender sender,
    IOptions<SmtpOptions> smtp,
    IOptions<SsoOptions> sso,
    PasswordResetLinks links,
    PasswordResetThrottle throttle,
    ILogger<ForgotPassword> logger) : Endpoint<ForgotPasswordRequest>
{
    public override void Configure()
    {
        Post("accounts/password/forgot");
        AllowAnonymous();
        Description(d => d.Accepts<ForgotPasswordRequest>("application/json").Produces(202).ProducesProblem(400)
            .ProducesProblem(429).ProducesProblem(503), clearDefaults: true);
    }

    public override async Task HandleAsync(ForgotPasswordRequest req, CancellationToken ct)
    {
        if (!throttle.Allowed("forgot", HttpContext, req.Email))
        {
            await Send.ResponseAsync(new { error = "too_many_requests" }, 429, ct);
            return;
        }

        if (!smtp.Value.Configured)
        {
            // Pretending it worked would leave a self-hosted club with no way back in.
            await Send.ResponseAsync(new { error = "email_not_configured" }, 503, ct);
            return;
        }

        var user = await users.FindByEmailAsync(req.Email.Trim());
        if (user is not null)
        {
            try
            {
                if (await users.HasPasswordAsync(user))
                {
                    var link = await links.CreateAsync(user, HttpContext.Request);
                    await sender.SendAsync(user.Email!, PasswordResetEmail.Subject, PasswordResetEmail.Body(link), ct);
                }
                else
                {
                    var body = sso.Value.Enabled
                        ? PasswordResetEmail.SsoBody(sso.Value.DisplayName)
                        : PasswordResetEmail.NoPasswordBody;
                    await sender.SendAsync(user.Email!, PasswordResetEmail.SsoSubject, body, ct);
                }
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                // Never log the token. The member can try again; a failed address lookup is not revealed.
                logger.LogWarning("Could not send a password reset email ({Reason}).", ex.Message);
            }
        }

        await Send.ResponseAsync(new { }, 202, ct);
    }
}
