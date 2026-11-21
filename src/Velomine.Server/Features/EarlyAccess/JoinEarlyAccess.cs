using System.Net.Mail;
using System.Text;
using FastEndpoints;
using FluentValidation;
using Microsoft.Extensions.Options;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Feedback;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Features.EarlyAccess;

/// <summary>The early-access form's fields, posted as application/x-www-form-urlencoded.</summary>
public sealed class JoinEarlyAccessRequest
{
    public const string RiderValue = "rider";
    public const string ClubValue = "club";

    public string? Email { get; set; }

    public string? Who { get; set; }

    public string? Club { get; set; }

    public string? Consent { get; set; }
}

public sealed class JoinEarlyAccessValidator : Validator<JoinEarlyAccessRequest>
{
    private const int ShortText = 200;

    public JoinEarlyAccessValidator()
    {
        RuleFor(x => x.Email).NotEmpty().MaximumLength(ShortText)
            .Must(v => v is not null && MailAddress.TryCreate(v.Trim(), out var a) && a.Address == v.Trim() && a.Host.Contains('.'))
            .WithMessage("Enter a plain email address.");
        RuleFor(x => x.Who).Must(v => v is JoinEarlyAccessRequest.RiderValue or JoinEarlyAccessRequest.ClubValue);
        RuleFor(x => x.Club).MaximumLength(ShortText);
        RuleFor(x => x.Consent).NotEmpty();
    }
}

/// <summary>
/// The site's early-access list. The sign-up is emailed to <c>Velomine:Feedback:Address</c> and stored nowhere: the
/// list is that mailbox. The caller is a browser form, so every outcome is a 303 to a static page of the site:
/// /early-access/sent/, or /early-access/not-sent/?reason=invalid, unavailable (the address or email is not set up,
/// or sending failed) or busy (rate limit, answered by the limiter). Never log anything from the body.
/// </summary>
public sealed class JoinEarlyAccess(
    IEmailSender sender,
    IOptions<SmtpOptions> smtp,
    IOptions<FeedbackOptions> feedback,
    ILogger<JoinEarlyAccess> logger) : Endpoint<JoinEarlyAccessRequest>
{
    public const string RateLimitPolicy = "early-access";
    public const string Path = "early-access";
    public const string SentPage = "/early-access/sent/";
    public const string NotSentPage = "/early-access/not-sent/";

    public override void Configure()
    {
        Post(Path);
        AllowAnonymous();
        AllowFormData(urlEncoded: true);
        DontThrowIfValidationFails();
        Options(b => b.RequireRateLimiting(RateLimitPolicy));
        Description(d => d
            .WithName("joinEarlyAccess")
            .Accepts<JoinEarlyAccessRequest>("application/x-www-form-urlencoded")
            .Produces(303)
            .Produces(429),
            clearDefaults: true);
        Summary(s =>
        {
            s.Summary = "Join the early-access list by email";
            s.Description = "For the site's early-access form. Fields: email (required, at most 200 characters), who (required: rider or club), "
                + "club (optional, club name and town, at most 200 characters) and consent (required, any value). Nothing is stored: "
                + "the sign-up is emailed to the operator's feedback address. Always answers 303 See Other with a Location header: "
                + "/early-access/sent/ when the email was sent, otherwise /early-access/not-sent/?reason=invalid (validation failed), "
                + "reason=unavailable (no feedback address or email is configured, or sending failed) or reason=busy (rate limit of 5 per hour "
                + "per network address, answered with the same redirect, status 303, by the limiter).";
        });
    }

    public override async Task HandleAsync(JoinEarlyAccessRequest req, CancellationToken ct)
    {
        if (ValidationFailed)
        {
            await RedirectAsync(NotSentPage + "?reason=invalid", ct);
            return;
        }

        if (!feedback.Value.Configured || !smtp.Value.Configured)
        {
            await RedirectAsync(NotSentPage + "?reason=unavailable", ct);
            return;
        }

        var mail = new OutgoingEmail(feedback.Value.Address!.Trim(), "Velomine early access", Format(req));
        try
        {
            var result = await sender.SendAsync([mail], ct);
            if (result.Failure is not null || result.Results[0].Outcome != EmailOutcome.Sent)
            {
                // The sign-up is never logged; only the kind of failure.
                logger.LogWarning("Could not send an early-access email ({Exception}).", result.Failure?.GetType().Name ?? "refused");
                await RedirectAsync(NotSentPage + "?reason=unavailable", ct);
                return;
            }
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            logger.LogWarning("Could not send an early-access email ({Exception}).", ex.GetType().Name);
            await RedirectAsync(NotSentPage + "?reason=unavailable", ct);
            return;
        }

        await RedirectAsync(SentPage, ct);
    }

    private async Task RedirectAsync(string location, CancellationToken ct)
    {
        HttpContext.Response.Headers.Location = feedback.Value.PageUrl(location);
        await Send.StringAsync(string.Empty, 303, cancellation: ct);
    }

    private static string Format(JoinEarlyAccessRequest r)
    {
        var text = new StringBuilder();
        text.Append("Email\n").Append(r.Email!.Trim()).Append("\n\n");
        text.Append("Who\n").Append(r.Who == JoinEarlyAccessRequest.ClubValue ? "My club might try it as a pilot" : "A rider, for myself").Append("\n\n");
        text.Append("Club name and town\n").Append(string.IsNullOrWhiteSpace(r.Club) ? "(none)" : r.Club.Trim()).Append("\n\n");
        text.Append("Consent\nAgreed to be told when the cloud opens, and about a pilot if club.\n");
        return text.ToString();
    }
}
