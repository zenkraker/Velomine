using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Training;

/// <summary>The goals auto training offers, as the API spells them. The rider's names are in TrainingNames.md.</summary>
public static class TrainingGoals
{
    public const string Aerobic = "aerobic";
    public const string Fitter = "fitter";
    public const string Faster = "faster";
    public const string Event = "event";
    public const string Keep = "keep";

    public static readonly string[] All = [Aerobic, Fitter, Faster, Event, Keep];
}

/// <summary>How a planned session went, as the API spells it.</summary>
public static class TrainingSessionStates
{
    public const string Planned = "planned";
    public const string Done = "done";
    /// <summary>Made easy on the day (the easy replacement of a hard session).</summary>
    public const string Easy = "easy";
    public const string Moved = "moved";
    public const string Skipped = "skipped";
    public const string Missed = "missed";

    public static readonly string[] All = [Planned, Done, Easy, Moved, Skipped, Missed];
}

/// <summary>Why the rider skipped a session, as the API spells it.</summary>
public static class TrainingSkipReasons
{
    public const string Tired = "tired";
    public const string Ill = "ill";
    public const string NoTime = "no_time";
    public const string Other = "other";

    public static readonly string[] All = [Tired, Ill, NoTime, Other];
}

/// <summary>
/// The rider's auto-training setup: one plan per member, so the key is the member. No owner or author column: a
/// coach-written plan, if it ever comes, adds one in its own additive migration. <see cref="LastPlannedFor"/> is the
/// local date the week was last written, so the sweep finds who is due.
/// </summary>
public sealed class TrainingPlan
{
    public Guid UserId { get; set; }

    /// <summary>One of <see cref="TrainingGoals"/>.</summary>
    public string Goal { get; set; } = TrainingGoals.Fitter;

    /// <summary>The days the rider can ride, as <see cref="DayOfWeek"/> numbers, at least one.</summary>
    public int[] Days { get; set; } = [];

    public int HoursPerWeek { get; set; }

    /// <summary>The long-ride day as a <see cref="DayOfWeek"/> number; null is "Velomine picks".</summary>
    public int? LongRideDay { get; set; }

    /// <summary>The local date this plan was last written for; null until the first planning run.</summary>
    public DateOnly? LastPlannedFor { get; set; }

    /// <summary>
    /// The weeks the planner made lighter, newest first, at most the four the ramp's mean looks back over. The cycle
    /// counts the weeks it built since the last one, and the mean leaves them out.
    /// </summary>
    public DateOnly[] LighterWeeks { get; set; } = [];

    /// <summary>False when the rider turned auto training off: the setup stays, so turning it on is pre-filled.</summary>
    public bool IsOn { get; set; }

    public DateTimeOffset UpdatedAt { get; set; }
}

/// <summary>
/// One planned session on one of the rider's local days. It keeps its recipe and its block percentages (never watts,
/// which follow the FTP in use when shown), its state, the reason it was skipped and the ride that was it. The score is
/// computed on read from that ride, never stored.
/// </summary>
public sealed class TrainingSession
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public DateOnly LocalDate { get; set; }

    /// <summary>The recipe code, such as <c>R05</c>.</summary>
    public string Recipe { get; set; } = "";

    /// <summary>The minutes the day gets: a session's length on the day, which the planner, the week and the score read.</summary>
    public int Minutes { get; set; }

    /// <summary>The main set's blocks as a percentage of FTP, in order; the recipe gives their lengths.</summary>
    public int[] BlockPercents { get; set; } = [];

    /// <summary>One of <see cref="TrainingSessionStates"/>.</summary>
    public string State { get; set; } = TrainingSessionStates.Planned;

    /// <summary>One of <see cref="TrainingSkipReasons"/> when the rider skipped it.</summary>
    public string? SkipReason { get; set; }

    /// <summary>The ride that was this session; null until one is linked.</summary>
    public Guid? RideId { get; set; }

    public DateTimeOffset CreatedAt { get; set; }
}

public sealed class TrainingPlanConfiguration : IEntityTypeConfiguration<TrainingPlan>
{
    public void Configure(EntityTypeBuilder<TrainingPlan> b)
    {
        b.ToTable("plans", "training", t =>
        {
            t.HasCheckConstraint("ck_training_plans_goal", "goal IN ('aerobic', 'fitter', 'faster', 'event', 'keep')");
            t.HasCheckConstraint("ck_training_plans_days", "cardinality(days) BETWEEN 1 AND 7 AND days <@ ARRAY[0,1,2,3,4,5,6]::integer[]");
            t.HasCheckConstraint("ck_training_plans_hours", "hours_per_week BETWEEN 1 AND 30");
            t.HasCheckConstraint("ck_training_plans_long_ride_day", "long_ride_day IS NULL OR long_ride_day BETWEEN 0 AND 6");
        });
        // One plan per member: the member is the key.
        b.HasKey(p => p.UserId);
        // The sweep reads the plans that are on and due; nothing else reads this table by date.
        b.HasIndex(p => p.LastPlannedFor).HasFilter("is_on");
        b.HasOne<User>().WithMany().HasForeignKey(p => p.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}

public sealed class TrainingSessionConfiguration : IEntityTypeConfiguration<TrainingSession>
{
    public void Configure(EntityTypeBuilder<TrainingSession> b)
    {
        b.ToTable("sessions", "training", t =>
        {
            t.HasCheckConstraint("ck_training_sessions_recipe", "length(recipe) BETWEEN 2 AND 8");
            // PostgreSQL forbids a subquery in a check, so the elements' range is the recipe's own business; here a
            // session has at least one block and at most twenty.
            t.HasCheckConstraint("ck_training_sessions_blocks", "cardinality(block_percents) BETWEEN 1 AND 20");
            // A session planned before the column existed reads 0; the planner always writes the day's minutes.
            t.HasCheckConstraint("ck_training_sessions_minutes", "minutes BETWEEN 0 AND 1440");
            t.HasCheckConstraint("ck_training_sessions_state",
                "state IN ('planned', 'done', 'easy', 'moved', 'skipped', 'missed')");
            t.HasCheckConstraint("ck_training_sessions_skip_reason",
                "skip_reason IS NULL OR skip_reason IN ('tired', 'ill', 'no_time', 'other')");
            // Only a skipped session has a reason.
            t.HasCheckConstraint("ck_training_sessions_skip_reason_only_when_skipped",
                "skip_reason IS NULL OR state = 'skipped'");
        });
        b.HasKey(s => s.Id);
        // One session per day: a second sweep or a race can never plan the same day twice.
        b.HasIndex(s => new { s.UserId, s.LocalDate }).IsUnique();
        b.HasOne<User>().WithMany().HasForeignKey(s => s.UserId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne<Ride>().WithMany().HasForeignKey(s => s.RideId).OnDelete(DeleteBehavior.SetNull);
    }
}
