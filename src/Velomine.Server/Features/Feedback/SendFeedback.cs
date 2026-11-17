using System.Net.Mail;
using System.Text;
using FastEndpoints;
using FluentValidation;
using Microsoft.Extensions.Options;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Features.Feedback;

/// <summary>
/// Bound from "Velomine:Feedback" (environment: VELOMINE__FEEDBACK__ADDRESS). The address that receives what visitors
/// write in the site's feedback form. Optional: without it, or without email, the form sends nothing.
/// </summary>
public sealed class FeedbackOptions
{
    public string? Address { get; set; }

    public bool Configured => !string.IsNullOrWhiteSpace(Address);
}

public sealed class FeedbackOptionsValidator : IValidateOptions<FeedbackOptions>
{
    public ValidateOptionsResult Validate(string? name, FeedbackOptions o) =>
        !o.Configured || (MailAddress.TryCreate(o.Address, out var a) && a.Address == o.Address!.Trim())
            ? ValidateOptionsResult.Success
            : ValidateOptionsResult.Fail("VELOMINE__FEEDBACK__ADDRESS must be a plain email address such as feedback@example.org.");
}

public static class FeedbackSetup
{
    public static IServiceCollection AddFeedback(this IServiceCollection services)
    {
        services.AddSingleton<IValidateOptions<FeedbackOptions>, FeedbackOptionsValidator>();
        services.AddOptions<FeedbackOptions>().BindConfiguration("Velomine:Feedback").ValidateOnStart();
        return services;
    }
}

/// <summary>The feedback form's fields, posted as application/x-www-form-urlencoded. Checkbox groups repeat the field name.</summary>
public sealed class SendFeedbackRequest
{
    public static readonly string[] WhoOptions =
        ["A rider without a club", "A rider in a club or team", "A coach", "Someone who runs a club", "A self-hoster"];

    public static readonly string[] TriedOptions =
    [
        "The public demo", "Self-hosting it on my own server", "The Android app", "Uploading my own ride file",
        "Importing a Strava export", "Only the website",
    ];

    public static readonly string[] UseOptions =
        ["Yes, now", "Yes, once what I need is there", "Yes, once what I listed above is there", "Maybe", "No", "Not sure yet"];

    /// <summary>The one box at the top of the form: what is wrong, confusing or missing. Enough on its own.</summary>
    public string? Message { get; set; }

    public List<string>? Who { get; set; }

    public List<string>? Tried { get; set; }

    public string? Today { get; set; }

    public string? Worked { get; set; }

    public string? Broke { get; set; }

    public string? Numbers { get; set; }

    public string? Missing { get; set; }

    public string? Use { get; set; }

    public string? Why { get; set; }

    public string? Device { get; set; }
}

public sealed class SendFeedbackValidator : Validator<SendFeedbackRequest>
{
    private const int LongText = 2000;
    private const int ShortText = 200;

    public SendFeedbackValidator()
    {
        RuleForEach(x => x.Who).Must(v => SendFeedbackRequest.WhoOptions.Contains(v));
        RuleForEach(x => x.Tried).Must(v => SendFeedbackRequest.TriedOptions.Contains(v));
        RuleFor(x => x.Use).Must(v => string.IsNullOrEmpty(v) || SendFeedbackRequest.UseOptions.Contains(v));
        RuleFor(x => x.Today).MaximumLength(ShortText);
        RuleFor(x => x.Device).MaximumLength(ShortText);
        RuleFor(x => x.Message).MaximumLength(LongText);
        RuleFor(x => x.Worked).MaximumLength(LongText);
        RuleFor(x => x.Broke).MaximumLength(LongText);
        RuleFor(x => x.Numbers).MaximumLength(LongText);
        RuleFor(x => x.Missing).MaximumLength(LongText);
        RuleFor(x => x.Why).MaximumLength(LongText);
        RuleFor(x => x).Must(x => new[] { x.Message, x.Worked, x.Broke, x.Numbers, x.Missing, x.Why }.Any(t => !string.IsNullOrWhiteSpace(t)))
            .WithMessage("Fill in at least one written answer.");
    }
}

/// <summary>
/// The site's anonymous feedback form. The answers are emailed to <c>Velomine:Feedback:Address</c> and stored nowhere;
/// there is no reply address, no Reply-To and no visitor address anywhere in the message. The caller is a browser form,
/// so every outcome is a 303 to a static page of the site: /feedback/sent/, or /feedback/not-sent/?reason=invalid,
/// unavailable (feedback or email is not set up, or sending failed) or busy (rate limit, answered by the limiter).
/// Never log anything from the body.
/// </summary>
public sealed class SendFeedback(
    IEmailSender sender,
    IOptions<SmtpOptions> smtp,
    IOptions<FeedbackOptions> feedback,
    ILogger<SendFeedback> logger) : Endpoint<SendFeedbackRequest>
{
    public const string RateLimitPolicy = "feedback";
    public const string Path = "feedback";
    public const string SentPage = "/feedback/sent/";
    public const string NotSentPage = "/feedback/not-sent/";

    public override void Configure()
    {
        Post(Path);
        AllowAnonymous();
        AllowFormData(urlEncoded: true);
        DontThrowIfValidationFails();
        Options(b => b.RequireRateLimiting(RateLimitPolicy));
        Description(d => d
            .WithName("sendFeedback")
            .Accepts<SendFeedbackRequest>("application/x-www-form-urlencoded")
            .Produces(303)
            .Produces(429),
            clearDefaults: true);
        Summary(s =>
        {
            s.Summary = "Send anonymous feedback by email";
            s.Description = "For the site's feedback form. Fields: message (the main answer), who (repeated, optional, one of the listed options), "
                + "tried (repeated), today, worked, broke, numbers, missing, use, why, device. At least one of message, worked, broke, numbers, "
                + "missing and why is required; "
                + "text fields are at most 2000 characters, today and device 200. Nothing is stored and no reply address is taken. "
                + "Always answers 303 See Other with a Location header: /feedback/sent/ when the email was sent, otherwise "
                + "/feedback/not-sent/?reason=invalid (the answers did not pass validation), reason=unavailable (no feedback address or email is "
                + "configured, or sending failed) or reason=busy (rate limit of 5 per hour per network address, which is answered with the same redirect, "
                + "status 303, by the limiter).";
        });
    }

    public override async Task HandleAsync(SendFeedbackRequest req, CancellationToken ct)
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

        var mail = new OutgoingEmail(feedback.Value.Address!.Trim(), "Velomine feedback", Format(req));
        try
        {
            var result = await sender.SendAsync([mail], ct);
            if (result.Failure is not null || result.Results[0].Outcome != EmailOutcome.Sent)
            {
                // The answers are never logged; only the kind of failure.
                logger.LogWarning("Could not send a feedback email ({Exception}).", result.Failure?.GetType().Name ?? "refused");
                await RedirectAsync(NotSentPage + "?reason=unavailable", ct);
                return;
            }
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            logger.LogWarning("Could not send a feedback email ({Exception}).", ex.GetType().Name);
            await RedirectAsync(NotSentPage + "?reason=unavailable", ct);
            return;
        }

        await RedirectAsync(SentPage, ct);
    }

    private async Task RedirectAsync(string location, CancellationToken ct)
    {
        HttpContext.Response.Headers.Location = location;
        await Send.StringAsync(string.Empty, 303, cancellation: ct);
    }

    private static string Format(SendFeedbackRequest r)
    {
        var text = new StringBuilder();
        Line(text, "What is wrong, confusing or missing?", r.Message);
        Line(text, "Who are you?", string.Join(", ", r.Who ?? []));
        Line(text, "What did you try?", string.Join(", ", r.Tried ?? []));
        Line(text, "What do you use today?", r.Today);
        Line(text, "What worked well?", r.Worked);
        Line(text, "What broke or confused you?", r.Broke);
        Line(text, "Did the numbers look right?", r.Numbers);
        Line(text, "What is missing before you would use it for real?", r.Missing);
        Line(text, "Would you or your club use it?", r.Use);
        Line(text, "Why?", r.Why);
        Line(text, "Device and browser", r.Device);
        return text.ToString();
    }

    private static void Line(StringBuilder text, string question, string? answer)
    {
        var value = string.IsNullOrWhiteSpace(answer) ? "(no answer)" : answer.Trim();
        text.Append(question).Append('\n').Append(value).Append("\n\n");
    }
}
