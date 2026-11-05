using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Analytics;

/// <summary>What a goal counts. Targets are in SI units: metres, seconds, or a number of rides.</summary>
public static class GoalMetrics
{
    public const string Distance = "distance";
    public const string Elevation = "elevation";
    public const string Time = "time";
    public const string Rides = "rides";

    public static readonly string[] All = [Distance, Elevation, Time, Rides];

    public static double Measure(string metric, IReadOnlyCollection<RideDay> rides) => metric switch
    {
        Distance => rides.Sum(r => r.DistanceM),
        Elevation => rides.Sum(r => r.ElevationGainM),
        Time => rides.Sum(r => r.MovingS),
        Rides => rides.Count,
        _ => throw new ArgumentOutOfRangeException(nameof(metric), metric, "Not a goal metric."),
    };
}

/// <summary>A target for each week, month or year. Progress is never stored: it is worked out from the rides when asked for.</summary>
public sealed class Goal
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string Period { get; set; } = Periods.Week;

    public string Metric { get; set; } = GoalMetrics.Distance;

    public double Target { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public uint Version { get; set; }

    public User? Owner { get; set; }
}

public sealed class GoalConfiguration : IEntityTypeConfiguration<Goal>
{
    public void Configure(EntityTypeBuilder<Goal> goal)
    {
        goal.ToTable("goals", "analytics", t =>
        {
            t.HasCheckConstraint("ck_goals_period", "period IN ('week', 'month', 'year')");
            t.HasCheckConstraint("ck_goals_metric", "metric IN ('distance', 'elevation', 'time', 'rides')");
            t.HasCheckConstraint("ck_goals_target", "target > 0");
        });
        goal.HasKey(g => g.Id);
        goal.Property(g => g.Period).HasMaxLength(8);
        goal.Property(g => g.Metric).HasMaxLength(16);
        goal.Property(g => g.Version).IsRowVersion();
        goal.HasOne(g => g.Owner).WithMany().HasForeignKey(g => g.UserId).OnDelete(DeleteBehavior.Cascade);
        // One goal per period and metric: "100 km a week" and "400 km a month" can live together, two weekly distances cannot.
        goal.HasIndex(g => new { g.UserId, g.Period, g.Metric }).IsUnique();
    }
}
