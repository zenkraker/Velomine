using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Velomine.Server.Features.Bikes;

/// <summary>
/// A job the member does again and again on a bike (lube the chain, top up the sealant), due when the first of its
/// limits is reached. It counts exactly as a part does: the rides on the bike since <see cref="LastDoneOn"/>,
/// worked out on request and never stored.
/// </summary>
public sealed class MaintenanceReminder
{
    public Guid Id { get; set; }

    public Guid BikeId { get; set; }

    public string Name { get; set; } = "";

    /// <summary>Due after this distance, these riding hours or these months since it was last done: whichever comes first. At least one is set.</summary>
    public double? IntervalDistanceM { get; set; }

    public double? IntervalHours { get; set; }

    public int? IntervalMonths { get; set; }

    /// <summary>The day it was last done, or the day counting started. Rides on this day count (as a part's fitting day does).</summary>
    public DateOnly LastDoneOn { get; set; }

    /// <summary>A paused reminder is kept but neither shows a state nor notifies.</summary>
    public bool IsPaused { get; set; }

    /// <summary>The level the member was last told about in this cycle (soon or due), so each is sent once. Null until the first.</summary>
    public string? NotifiedStatus { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public uint Version { get; set; }
}

public sealed record MaintenanceReminderResponse(
    Guid Id,
    string Name,
    double? IntervalDistanceM,
    double? IntervalHours,
    int? IntervalMonths,
    DateOnly LastDoneOn,
    bool IsPaused,
    double UsedDistanceM,
    double UsedHours,
    double UsedMonths,
    int? Percent,
    string Status);

/// <summary>Where a reminder stands. Status is ok, soon or due, or paused.</summary>
public static class MaintenanceProgress
{
    public static ComponentWear Compute(MaintenanceReminder reminder, IEnumerable<RideUse> bikeRides, DateOnly today)
    {
        var wear = BikeWear.Measure(reminder.LastDoneOn, null, reminder.IntervalDistanceM, reminder.IntervalHours, reminder.IntervalMonths, bikeRides, today);
        return wear with { Status = reminder.IsPaused ? "paused" : wear.Status == "worn" ? "due" : wear.Status };
    }

    public static MaintenanceReminderResponse Response(MaintenanceReminder r, ComponentWear w) => new(
        r.Id, r.Name, r.IntervalDistanceM, r.IntervalHours, r.IntervalMonths, r.LastDoneOn, r.IsPaused,
        w.DistanceM, w.Hours, w.Months, w.Percent, w.Status);

    /// <summary>Most urgent first: due, soon, fine, paused; the fullest bar first within each.</summary>
    public static MaintenanceReminderResponse[] Sorted(IEnumerable<(MaintenanceReminder Reminder, ComponentWear Wear)> items) =>
        [.. items
            .OrderBy(x => Rank(x.Wear.Status))
            .ThenByDescending(x => x.Wear.Percent ?? -1)
            .ThenBy(x => x.Reminder.Name, StringComparer.CurrentCultureIgnoreCase)
            .Select(x => Response(x.Reminder, x.Wear))];

    private static int Rank(string status) => status switch { "due" => 0, "soon" => 1, "ok" => 2, _ => 3 };
}

/// <summary>A common job offered when adding a reminder, with an interval to start from. The app words the name.</summary>
public sealed record MaintenanceJob(string Id, double? IntervalDistanceM, double? IntervalHours, int? IntervalMonths);

/// <summary>The common jobs, and which kinds of bike they make sense for. Nothing is added unless the member picks it.</summary>
public static class MaintenanceJobs
{
    private static readonly string[] Suspension = ["mountain", "ebike", "other"];
    private static readonly string[] NotTrack = ["road", "gravel", "mountain", "ebike", "timetrial", "city", "other"];
    private static readonly string[] Tubeless = ["road", "gravel", "mountain", "ebike", "timetrial", "other"];
    private static readonly string[] Electronic = ["road", "gravel", "mountain", "ebike", "timetrial", "other"];

    private static readonly (MaintenanceJob Job, string[] Kinds)[] Catalogue =
    [
        (new("chain_lube", 300_000, null, null), BikeKinds.All),
        (new("chain_wear_check", 1_000_000, null, null), BikeKinds.All),
        (new("sealant_top_up", null, null, 3), Tubeless),
        (new("brake_bleed", null, null, 12), NotTrack),
        (new("fork_service", null, 50, 12), Suspension),
        (new("shock_service", null, 50, 12), Suspension),
        (new("bolt_check", null, null, 3), BikeKinds.All),
        (new("shifting_battery_charge", null, null, 2), Electronic),
    ];

    public static MaintenanceJob[] For(string kind) => [.. Catalogue.Where(c => c.Kinds.Contains(kind)).Select(c => c.Job)];
}

public sealed class MaintenanceReminderConfiguration : IEntityTypeConfiguration<MaintenanceReminder>
{
    public void Configure(EntityTypeBuilder<MaintenanceReminder> reminder)
    {
        reminder.ToTable("maintenance_reminders", "bikes", t =>
        {
            t.HasCheckConstraint("ck_maintenance_reminders_has_interval",
                "interval_distance_m IS NOT NULL OR interval_hours IS NOT NULL OR interval_months IS NOT NULL");
            t.HasCheckConstraint("ck_maintenance_reminders_positive_intervals",
                "(interval_distance_m IS NULL OR interval_distance_m > 0) AND (interval_hours IS NULL OR interval_hours > 0) AND (interval_months IS NULL OR interval_months > 0)");
        });
        reminder.HasKey(r => r.Id);
        reminder.Property(r => r.Name).HasMaxLength(100);
        reminder.Property(r => r.NotifiedStatus).HasMaxLength(8);
        reminder.Property(r => r.Version).IsRowVersion();
        reminder.HasOne<Bike>().WithMany().HasForeignKey(r => r.BikeId).OnDelete(DeleteBehavior.Cascade);
        reminder.HasIndex(r => r.BikeId);
    }
}
