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

    /// <summary>Entered by the member; heart rate zones are percentages of it.</summary>
    public int? MaxHeartRate { get; set; }

    /// <summary>An IANA time zone such as "Europe/Rome". Null means UTC. Decides what "today" and "this week" are.</summary>
    public string? TimeZone { get; set; }

    /// <summary>The day weekly totals and goals start on.</summary>
    public DayOfWeek FirstDayOfWeek { get; set; } = DayOfWeek.Monday;

    /// <summary>Also email this member their notifications, when the server can send email.</summary>
    public bool EmailNotifications { get; set; } = true;

    /// <summary>When the member accepted the wellbeing terms; null means they have not started.</summary>
    public DateTimeOffset? WellbeingConsentAt { get; set; }

    /// <summary>The consent text version they accepted. A new version asks again.</summary>
    public int? WellbeingConsentVersion { get; set; }
}

public static class Roles
{
    public const string Admin = "admin";
    public const string Member = "member";
    public const string Coach = "coach";

    public static readonly string[] All = [Admin, Member, Coach];
}
