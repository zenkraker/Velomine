using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Training;

/// <summary>The kinds of event a rider trains for, as the API and the app spell them.</summary>
public static class TrainingEventKinds
{
    public const string Race = "race";
    public const string Sportive = "sportive";
    public const string Tour = "tour";
    public const string Other = "other";

    public static readonly string[] All = [Race, Sportive, Tour, Other];
}

/// <summary>
/// A race, sportive or tour the rider is training for. <see cref="Date"/> is a local date, like the day a ride counts
/// on. <see cref="RideId"/> is the ride that was it, filled in when the rider's only ride that day is read.
/// </summary>
public sealed class TrainingEvent
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string Name { get; set; } = "";

    public DateOnly Date { get; set; }

    /// <summary>One of <see cref="TrainingEventKinds"/>.</summary>
    public string Kind { get; set; } = TrainingEventKinds.Race;

    public double? DistanceM { get; set; }

    public double? ElevationGainM { get; set; }

    public string? Notes { get; set; }

    /// <summary>The ride that was this event; null until it is linked.</summary>
    public Guid? RideId { get; set; }

    public DateTimeOffset CreatedAt { get; set; }
}

public sealed class TrainingEventConfiguration : IEntityTypeConfiguration<TrainingEvent>
{
    public void Configure(EntityTypeBuilder<TrainingEvent> b)
    {
        b.ToTable("events", "training", t =>
        {
            t.HasCheckConstraint("ck_events_kind", "kind IN ('race', 'sportive', 'tour', 'other')");
            t.HasCheckConstraint("ck_events_name_length", "length(name) BETWEEN 1 AND 100");
            t.HasCheckConstraint("ck_events_notes_length", "notes IS NULL OR length(notes) <= 500");
            t.HasCheckConstraint("ck_events_distance_m", "distance_m IS NULL OR distance_m >= 0");
            t.HasCheckConstraint("ck_events_elevation_gain_m", "elevation_gain_m IS NULL OR elevation_gain_m >= 0");
        });
        b.HasKey(e => e.Id);
        b.Property(e => e.Name).IsRequired();
        b.HasIndex(e => new { e.UserId, e.Date });
        b.HasOne<User>().WithMany().HasForeignKey(e => e.UserId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne<Ride>().WithMany().HasForeignKey(e => e.RideId).OnDelete(DeleteBehavior.SetNull);
    }
}
