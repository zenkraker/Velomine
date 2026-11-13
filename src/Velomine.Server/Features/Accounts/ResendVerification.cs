using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Features.Accounts;

public sealed record ResendVerificationRequest(string Email);

public sealed class ResendVerificationValidator : Validator<ResendVerificationRequest>
{
    public ResendVerificationValidator() =>
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(256);
}

/// <summary>
/// Sends the confirmation link again to an account that has not confirmed its address. The answer is always 202
/// when email is set up, whether or not the address has an account: like a password reset, it must not tell a
/// stranger who is registered. Email off is the server-wide 503.
/// </summary>
public sealed class ResendVerification(
    UserManager<User> users,
    IEmailSender sender,
    IOptions<SmtpOptions> smtp,
    EmailVerificationLinks links,
    PasswordResetThrottle throttle,
    ILogger<ResendVerification> logger) : Endpoint<ResendVerificationRequest>
{
    public override void Configure()
    {
        Post("accounts/email/resend");
        AllowAnonymous();
        Options(b => b.RequireRateLimiting("anonymous"));
        Description(d => d.Accepts<ResendVerificationRequest>("application/json").Produces(202).ProducesProblem(400)
            .ProducesProblem(429).ProducesProblem(503), clearDefaults: true);
    }

    public override async Task HandleAsync(ResendVerificationRequest req, CancellationToken ct)
    {
        if (!throttle.Allowed("resend", HttpContext))
        {
            await Send.ResponseAsync(new { error = "too_many_requests" }, 429, ct);
            return;
        }

        if (!EmailVerification.Required(smtp))
        {
            await Send.ResponseAsync(new { error = "email_not_configured" }, 503, ct);
            return;
        }

        var user = await users.FindByEmailAsync(req.Email.Trim());
        // An account already confirmed, or one with no password (single sign-on proved the address), needs nothing.
        if (user is not null && !user.EmailConfirmed && await users.HasPasswordAsync(user))
        {
            using var language = EmailLanguage.Use(user.Language);
            try
            {
                if (await links.CreateAsync(user) is { } link)
                {
                    var content = EmailVerificationEmail.Confirmation(link);
                    SendInBackground(new OutgoingEmail(user.Email!, content.Subject, content.Text, content.Html));
                }
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                // Never log the token. The member can try again.
                logger.LogWarning("Could not prepare an email verification message ({Exception}).", ex.GetType().Name);
            }
        }

        await Send.ResponseAsync(new { }, 202, ct);
    }

    // Send after answering: waiting for SMTP here would make a registered address measurably slower.
    private void SendInBackground(OutgoingEmail mail) => _ = Task.Run(async () =>
    {
        try
        {
            var result = await sender.SendAsync([mail], CancellationToken.None);
            if (result.Failure is not null || result.Results[0].Outcome != EmailOutcome.Sent)
                logger.LogWarning("Could not send an email verification message ({Exception}).", result.Failure?.GetType().Name ?? "refused");
        }
        catch (Exception ex)
        {
            logger.LogWarning("Could not send an email verification message ({Exception}).", ex.GetType().Name);
        }
    });
}
