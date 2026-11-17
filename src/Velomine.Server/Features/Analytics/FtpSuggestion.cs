using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Analytics;

/// <summary>Where a suggestion's number falls in the states it can be in.</summary>
public static class FtpSuggestionStatuses
{
    public const string Open = "open";
    public const string Accepted = "accepted";
    public const string Dismissed = "dismissed";
    public const string Replaced = "replaced";
}

/// <summary>
/// An FTP a ride suggests, from its best 20, 30 or 60 minutes. At most one per member is <c>open</c> (a partial
/// unique index says so); accepting it writes the FTP and its history row, and the suggestion records that.
/// </summary>
public sealed class FtpSuggestion
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public Guid RideId { get; set; }

    /// <summary>The suggested FTP in watts.</summary>
    public int Watts { get; set; }

    /// <summary><c>20min</c>, <c>30min</c> or <c>60min</c>: the effort it came from.</summary>
    public string Method { get; set; } = FtpSuggestionMethods.TwentyMinutes;

    /// <summary>The ride's best for that duration.</summary>
    public int EffortWatts { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    /// <summary>One of <see cref="FtpSuggestionStatuses"/>.</summary>
    public string Status { get; set; } = FtpSuggestionStatuses.Open;
}

public sealed class FtpSuggestionConfiguration : IEntityTypeConfiguration<FtpSuggestion>
{
    public void Configure(EntityTypeBuilder<FtpSuggestion> b)
    {
        b.ToTable("ftp_suggestions", "analytics", t =>
        {
            t.HasCheckConstraint("ck_ftp_suggestions_watts", "watts BETWEEN 30 AND 1000");
            t.HasCheckConstraint("ck_ftp_suggestions_effort_watts", "effort_watts BETWEEN 30 AND 1000");
            t.HasCheckConstraint("ck_ftp_suggestions_method", "method IN ('20min', '30min', '60min')");
            t.HasCheckConstraint("ck_ftp_suggestions_status", "status IN ('open', 'accepted', 'dismissed', 'replaced')");
        });
        b.HasKey(s => s.Id);
        b.HasIndex(s => s.UserId);
        b.HasIndex(s => s.RideId);
        // One open suggestion per member: a new one replaces the last, never queues beside it.
        b.HasIndex(s => s.UserId).HasFilter("status = 'open'").IsUnique().HasDatabaseName("ux_ftp_suggestions_open_user");
        b.HasOne<User>().WithMany().HasForeignKey(s => s.UserId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne<Ride>().WithMany().HasForeignKey(s => s.RideId).OnDelete(DeleteBehavior.Cascade);
    }
}

/// <summary>The three methods' names, as the API and the app spell them.</summary>
public static class FtpSuggestionMethods
{
    public const string TwentyMinutes = "20min";
    public const string ThirtyMinutes = "30min";
    public const string SixtyMinutes = "60min";
}

/// <summary>
/// Looks at a ride that was just read for the first time and stages a suggestion when it shows a higher FTP.
/// Runs only from <see cref="RideIngestionService"/>: a re-read and a duplicate never get here. Skipped for an e-bike,
/// without best efforts, or for a ride of more than 42 days ago on the member's calendar. A candidate replaces the
/// member's open suggestion only when it is higher; the row and its notification join the caller's SaveChanges.
/// </summary>
public static class FtpSuggestionDetection
{
    private const int MaxAgeDays = 42;

    /// <summary>The largest of 95 % of the 20 minutes, 97 % of the 30 and the 60 itself; a tie goes to the longer effort.</summary>
    public static (int Watts, string Method, int EffortWatts)? Candidate(Ride ride)
    {
        (int Watts, string Method, int Effort)[] attempts =
        [
            (1200, FtpSuggestionMethods.TwentyMinutes, 1200),
            (1800, FtpSuggestionMethods.ThirtyMinutes, 1800),
            (3600, FtpSuggestionMethods.SixtyMinutes, 3600),
        ];

        (int Watts, string Method, int Effort)? best = null;
        foreach (var (durationS, method, effortS) in attempts)
        {
            if (ride.PowerBests.FirstOrDefault(b => b.DurationS == durationS) is not { Watts: > 0 } bestEffort) continue;
            var watts = method switch
            {
                FtpSuggestionMethods.TwentyMinutes => (int)Math.Round(bestEffort.Watts * 0.95),
                FtpSuggestionMethods.ThirtyMinutes => (int)Math.Round(bestEffort.Watts * 0.97),
                _ => bestEffort.Watts,
            };
            // Later durations win a tie, so the longer effort is the one suggested.
            if (best is null || watts >= best.Value.Watts) best = (watts, method, bestEffort.Watts);
        }

        return best;
    }

    /// <summary>Stages the suggestion (and its notification, for a ride that notifies) without saving.</summary>
    public static async Task AddAsync(
        VelomineDbContext db, TimeProvider time, MemberClock clock, Ride ride, int? currentFtp, CancellationToken ct)
    {
        if (ride.Status != RideStatus.Ready || ride.Assist == Assists.EBike) return;
        if (ride.StartTime is not { } start) return;
        if (clock.LocalDateOf(start, ride.UtcOffsetMinutes) < clock.Today.AddDays(-MaxAgeDays)) return;
        if (Candidate(ride) is not { } candidate) return;

        // Offsets, not instants: the member's own order is what "newest" and "a tie goes to the longer effort" mean here.
        var open = await db.FtpSuggestions
            .Where(s => s.UserId == ride.UserId && s.Status == FtpSuggestionStatuses.Open)
            .OrderByDescending(s => s.CreatedAt).ThenByDescending(s => s.Id)
            .ToListAsync(ct);
        var existing = open.FirstOrDefault();
        // The unique index allows one open row; two can only be here because a change is already in progress.
        foreach (var older in open.Skip(1)) older.Status = FtpSuggestionStatuses.Replaced;

        if (currentFtp is { } ftp && candidate.Watts < ftp * 1.03) return;
        if (existing is not null && candidate.Watts <= existing.Watts) return;

        if (existing is not null) existing.Status = FtpSuggestionStatuses.Replaced;
        db.FtpSuggestions.Add(new FtpSuggestion
        {
            Id = Guid.CreateVersion7(),
            UserId = ride.UserId,
            RideId = ride.Id,
            Watts = candidate.Watts,
            Method = candidate.Method,
            EffortWatts = candidate.EffortWatts,
            CreatedAt = time.GetUtcNow(),
            Status = FtpSuggestionStatuses.Open,
        });
        if (ride.NotifiesMember)
            Notify.Add(db, time, ride.UserId, NotificationTypes.FtpSuggested, $"{candidate.Watts} W", rideId: ride.Id);
    }
}
