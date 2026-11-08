using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Wellbeing;

/// <summary>The consent text version. Bump it when the wording changes so every member is asked again.</summary>
public static class WellbeingTerms
{
    public const int Version = 1;
}

/// <summary>The state checks every wellbeing slice shares.</summary>
public static class WellbeingRules
{
    public static async Task<bool> HasConsentAsync(VelomineDbContext db, Guid userId, CancellationToken ct) =>
        await db.Users.AsNoTracking()
            .AnyAsync(u => u.Id == userId && u.WellbeingConsentVersion == WellbeingTerms.Version, ct);
}

/// <summary>One day's check-in, on the member's own calendar. Values are 1–5, stored as entered.</summary>
public sealed class DailyCheckIn
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public DateOnly LocalDate { get; set; }

    /// <summary>1 fresh, 5 exhausted.</summary>
    public int Fatigue { get; set; }

    /// <summary>1 none, 5 severe.</summary>
    public int Soreness { get; set; }

    /// <summary>1 low, 5 great.</summary>
    public int Mood { get; set; }

    /// <summary>1 calm, 5 very stressed.</summary>
    public int Stress { get; set; }

    /// <summary>1 none, 5 high.</summary>
    public int Motivation { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset UpdatedAt { get; set; }
}

/// <summary>How hard a ride felt and an optional note. Private to the owner unless wellbeing is shared.</summary>
public sealed class RideFeel
{
    public Guid RideId { get; set; }

    /// <summary>1 easy, 10 maximal.</summary>
    public int Rpe { get; set; }

    public string? Notes { get; set; }

    public DateTimeOffset UpdatedAt { get; set; }
}
