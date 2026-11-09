using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Admin;

/// <summary>
/// Bound from "Velomine:Smtp" (environment: VELOMINE__SMTP__HOST, VELOMINE__SMTP__PORT, VELOMINE__SMTP__SECURITY,
/// VELOMINE__SMTP__USER, VELOMINE__SMTP__PASSWORD, VELOMINE__SMTP__FROM). Environment only,
/// by design: the password is never stored in the database or shown by the API.
/// Email is on when a host and a from address are set.
/// </summary>
public sealed class SmtpOptions
{
    public static readonly string[] SecurityModes = ["starttls", "ssl", "none"];

    public string? Host { get; set; }

    public int Port { get; set; } = 587;

    /// <summary>starttls (the usual port 587), ssl (port 465) or none (a local relay only).</summary>
    public string Security { get; set; } = "starttls";

    public string? User { get; set; }

    public string? Password { get; set; }

    /// <summary>The address emails come from, for example "Velomine &lt;velomine@club.example&gt;" or "velomine@club.example".</summary>
    public string? From { get; set; }

    public bool Configured => !string.IsNullOrWhiteSpace(Host) && !string.IsNullOrWhiteSpace(From);
}

public sealed class SmtpOptionsValidator : IValidateOptions<SmtpOptions>
{
    public ValidateOptionsResult Validate(string? name, SmtpOptions o)
    {
        if (string.IsNullOrWhiteSpace(o.Host) != string.IsNullOrWhiteSpace(o.From))
            return ValidateOptionsResult.Fail("VELOMINE__SMTP__HOST and VELOMINE__SMTP__FROM must be set together.");
        if (!SmtpOptions.SecurityModes.Contains(o.Security))
            return ValidateOptionsResult.Fail("VELOMINE__SMTP__SECURITY must be one of: " + string.Join(", ", SmtpOptions.SecurityModes) + ".");
        if (o.Port is < 1 or > 65535) return ValidateOptionsResult.Fail("VELOMINE__SMTP__PORT must be 1 to 65535.");
        return ValidateOptionsResult.Success;
    }
}
