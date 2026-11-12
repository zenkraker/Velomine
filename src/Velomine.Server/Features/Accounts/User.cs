using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

public sealed class User : IdentityUser<Guid>
{
    public string DisplayName { get; set; } = "";

    /// <summary>False until an admin approves the account, when the server requires approval.</summary>
    public bool IsApproved { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    /// <summary>Functional threshold power in watts, entered by the member. Needed for IF, TSS and power zones.</summary>
    public int? FtpW { get; set; }

    public double? WeightKg { get; set; }

    /// <summary>Year of birth; the maximum heart rate is estimated from the age it gives.</summary>
    public int? BirthYear { get; set; }

    /// <summary>
    /// The manual maximum heart rate from older versions. No longer read or written; the column stays for one
    /// release before it is dropped, as the migration rule asks.
    /// </summary>
    [Column("max_heart_rate")]
    public int? LegacyMaxHeartRate { get; set; }

    /// <summary>Tanaka's estimate, 208 - 0.7 x age. Null without a birth year.</summary>
    [NotMapped]
    public int? MaxHeartRate => EstimateMaxHeartRate(BirthYear);

    public static int? EstimateMaxHeartRate(int? birthYear) =>
        birthYear is { } year
            ? (int)Math.Round(208 - 0.7 * Math.Clamp(DateTime.UtcNow.Year - year, 10, 100))
            : null;

    /// <summary>The language chosen for this account, or null to follow the device. Applies on every device.</summary>
    public string? Language { get; set; }

    /// <summary>"metric" or "imperial". Display only: every value is stored in SI units.</summary>
    public string Units { get; set; } = "metric";
    /// <summary>An IANA time zone such as "Europe/Rome". Null means UTC. Decides what "today" and "this week" are.</summary>
    public string? TimeZone { get; set; }

    /// <summary>The day weekly totals and goals start on.</summary>
    public DayOfWeek FirstDayOfWeek { get; set; } = DayOfWeek.Monday;

    /// <summary>Also email this member their notifications, when the server can send email.</summary>
    public bool EmailNotifications { get; set; } = true;

    /// <summary>Also email about club and account events: join requests and approvals, sign-ups waiting.</summary>
    public bool EmailAccountNotifications { get; set; } = true;

    /// <summary>Also email about the member's own rides and parts. Off by default: the app already shows them.</summary>
    public bool EmailTrainingNotifications { get; set; }

    /// <summary>When the member accepted the wellbeing terms; null means they have not started.</summary>
    public DateTimeOffset? WellbeingConsentAt { get; set; }

    /// <summary>The consent text version they accepted. A new version asks again.</summary>
    public int? WellbeingConsentVersion { get; set; }

    /// <summary>When the member opted in to contributing crash and usage telemetry; null means never asked.</summary>
    public DateTimeOffset? TelemetryConsentAt { get; set; }

    /// <summary>The telemetry wording version they accepted. A new version asks again.</summary>
    public int? TelemetryConsentVersion { get; set; }

    /// <summary>Share crash reports and stack traces.</summary>
    public bool TelemetryCrash { get; set; }

    /// <summary>Share coarse performance and feature-usage data.</summary>
    public bool TelemetryUsage { get; set; }
}

public static class Roles
{
    public const string Admin = "admin";
    public const string Member = "member";
    public const string Coach = "coach";

    public static readonly string[] All = [Admin, Member, Coach];
}
