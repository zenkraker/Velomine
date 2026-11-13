using FastEndpoints;
using FluentValidation;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Features.Accounts;

public sealed record RegisterRequest(string Email, string Password, string DisplayName);

/// <summary>IsApproved: may sign in now. EmailConfirmationRequired: a verification email was sent and must be opened first.</summary>
public sealed record RegisterResponse(Guid Id, bool IsApproved, bool EmailConfirmationRequired);

public sealed class RegisterValidator : Validator<RegisterRequest>
{
    public RegisterValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(256);
        RuleFor(x => x.DisplayName).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Password).NotEmpty();
    }
}

/// <summary>
/// Creates an account and starts its solo trial. When email is configured, the address must be confirmed before the
/// member can sign in, and the verification message is sent after the answer; without SMTP there is no message and
/// no gate.
/// </summary>
public sealed class Register(
    UserManager<User> users,
    VelomineDbContext db,
    SettingsReader settings,
    TimeProvider clock,
    EmailVerificationLinks links,
    IEmailSender sender,
    IOptions<SmtpOptions> smtp,
    ILogger<Register> logger) : Endpoint<RegisterRequest, RegisterResponse>
{
    public override void Configure()
    {
        Post("accounts/register");
        AllowAnonymous();
        Options(b => b.RequireRateLimiting("anonymous"));
        Description(d => d.Accepts<RegisterRequest>("application/json").Produces<RegisterResponse>(201).ProducesProblem(400).Produces(403).ProducesProblem(429), clearDefaults: true);
    }

    public override async Task HandleAsync(RegisterRequest req, CancellationToken ct)
    {
        var effective = await settings.GetAsync(ct);
        if (!effective.SignUpEnabled)
        {
            await Send.ForbiddenAsync(ct);
            return;
        }

        var user = new User
        {
            UserName = req.Email,
            Email = req.Email,
            DisplayName = req.DisplayName,
            IsApproved = !effective.RequireAdminApproval,
            SoloTrialEndsAt = ClubPlan.Today(clock).AddDays(ClubPlan.TrialDays),
            CreatedAt = clock.GetUtcNow(),
        };
        var result = await users.CreateAsync(user, req.Password);
        if (!result.Succeeded)
        {
            foreach (var error in result.Errors) AddError(error.Description, error.Code);
            await Send.ErrorsAsync(400, ct);
            return;
        }

        await users.AddToRoleAsync(user, Accounts.Roles.Member);
        await Notify.SignUpWaitingAsync(db, users, clock, user);

        // Prepare the link before answering (it writes the security stamp), but never wait for SMTP.
        var verify = EmailVerification.Required(smtp);
        if (verify) SendVerificationInBackground(await links.CreateAsync(user), user);

        await Send.ResponseAsync(new RegisterResponse(user.Id, user.IsApproved, verify), 201, ct);
    }

    private void SendVerificationInBackground(string? link, User user)
    {
        if (link is null) return;
        // The account is new and has no language yet, so this follows the app's English fallback, not the request's.
        using var language = EmailLanguage.Use(user.Language);
        var content = EmailVerificationEmail.Confirmation(link);
        var mail = new OutgoingEmail(user.Email!, content.Subject, content.Text, content.Html);
        _ = Task.Run(async () =>
        {
            try
            {
                var sent = await sender.SendAsync([mail], CancellationToken.None);
                if (sent.Failure is not null || sent.Results[0].Outcome != EmailOutcome.Sent)
                    logger.LogWarning("Could not send an email verification message ({Exception}).", sent.Failure?.GetType().Name ?? "refused");
            }
            catch (Exception ex)
            {
                logger.LogWarning("Could not send an email verification message ({Exception}).", ex.GetType().Name);
            }
        });
    }
}
