using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;
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
        Options(b => b.RequireRateLimiting("anonymous"));
        Description(d => d.Accepts<ForgotPasswordRequest>("application/json").Produces(202).ProducesProblem(400)
            .ProducesProblem(429).ProducesProblem(503), clearDefaults: true);
    }

    public override async Task HandleAsync(ForgotPasswordRequest req, CancellationToken ct)
    {
        if (!throttle.Allowed("forgot", HttpContext))
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
            // The member chose a language in the app; the email uses it, and follows the app's English fallback.
            using var language = EmailLanguage.Use(user.Language);
            try
            {
                OutgoingEmail mail;
                if (await users.HasPasswordAsync(user))
                {
                    var link = await links.CreateAsync(user);
                    var content = PasswordResetEmail.Reset(link);
                    mail = new OutgoingEmail(user.Email!, content.Subject, content.Text, content.Html);
                }
                else
                {
                    var content = sso.Value.Enabled
                        ? PasswordResetEmail.Sso(sso.Value.DisplayName)
                        : PasswordResetEmail.NoPassword();
                    mail = new OutgoingEmail(user.Email!, content.Subject, content.Text, content.Html);
                }

                // Send after answering: waiting for SMTP here would make a registered address measurably slower.
                SendInBackground(mail);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                // Never log the token. The member can try again; a failed address lookup is not revealed.
                logger.LogWarning("Could not prepare a password reset email ({Exception}).", ex.GetType().Name);
            }
        }

        await Send.ResponseAsync(new { }, 202, ct);
    }

    private void SendInBackground(OutgoingEmail mail) => _ = Task.Run(async () =>
    {
        try
        {
            var result = await sender.SendAsync([mail], CancellationToken.None);
            if (result.Failure is not null || result.Results[0].Outcome != EmailOutcome.Sent)
                logger.LogWarning("Could not send a password reset email ({Exception}).", result.Failure?.GetType().Name ?? "refused");
        }
        catch (Exception ex)
        {
            logger.LogWarning("Could not send a password reset email ({Exception}).", ex.GetType().Name);
        }
    });
}
