using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Routes;

namespace Velomine.Server.Features.Clubs;

/// <summary>
/// A ride the club plans: the club's data, not the planner's. A coach or the owner writes it, every member sees it,
/// and it stays when the planner's account goes.
/// </summary>
public sealed class PlannedRide
{
    public Guid Id { get; set; }

    public Guid ClubId { get; set; }

    /// <summary>The coach or owner who planned it; null once that account is gone.</summary>
    public Guid? CreatedByUserId { get; set; }

    public string Title { get; set; } = "";

    /// <summary>The instant of the start. The offset it was planned with is kept beside it so eight o'clock stays eight.</summary>
    public DateTimeOffset StartsAt { get; set; }

    /// <summary>The local offset at the meeting point when it was planned, in minutes from UTC.</summary>
    public int UtcOffsetMinutes { get; set; }

    public string MeetingName { get; set; } = "";

    public double MeetingLatitude { get; set; }

    public double MeetingLongitude { get; set; }

    /// <summary>A route from the club library, while its owner keeps it shared.</summary>
    public Guid? RouteId { get; set; }

    public string Pace { get; set; } = RidePaces.Steady;

    public bool NoDrop { get; set; }

    public string? Notes { get; set; }

    /// <summary>Null means no limit.</summary>
    public int? MaxRiders { get; set; }

    public DateTimeOffset? CancelledAt { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset UpdatedAt { get; set; }

    public List<RideSignUp> SignUps { get; set; } = [];
}

/// <summary>A member saying "I'm in". It goes with the account and with the ride.</summary>
public sealed class RideSignUp
{
    public Guid PlannedRideId { get; set; }

    public PlannedRide PlannedRide { get; set; } = null!;

    public Guid UserId { get; set; }

    public User User { get; set; } = null!;

    public DateTimeOffset CreatedAt { get; set; }
}

/// <summary>
/// A member's private calendar address. Only the SHA-256 of the secret is kept: the address is shown once when it
/// is made and can be replaced, which stops the old one.
/// </summary>
public sealed class CalendarFeed
{
    public Guid UserId { get; set; }

    public Guid ClubId { get; set; }

    public byte[] TokenHash { get; set; } = [];

    public DateTimeOffset CreatedAt { get; set; }
}

public static class RidePaces
{
    public const string Easy = "easy";
    public const string Steady = "steady";
    public const string Fast = "fast";

    public static readonly string[] All = [Easy, Steady, Fast];

    /// <summary>Used only to guess an end time for the calendar feed: kilometres an hour.</summary>
    public static double Kmh(string pace) => pace switch
    {
        Easy => 20,
        Fast => 32,
        _ => 26,
    };
}

public sealed class CalendarConfiguration : IEntityTypeConfiguration<PlannedRide>, IEntityTypeConfiguration<RideSignUp>,
    IEntityTypeConfiguration<CalendarFeed>
{
    public void Configure(EntityTypeBuilder<PlannedRide> ride)
    {
        ride.ToTable("planned_rides", "calendar", t =>
        {
            t.HasCheckConstraint("ck_planned_rides_title", "char_length(btrim(title)) > 0");
            t.HasCheckConstraint("ck_planned_rides_pace", "pace IN ('easy', 'steady', 'fast')");
            t.HasCheckConstraint("ck_planned_rides_offset", "utc_offset_minutes BETWEEN -840 AND 840");
            t.HasCheckConstraint("ck_planned_rides_meeting", "char_length(btrim(meeting_name)) > 0");
            t.HasCheckConstraint("ck_planned_rides_latitude", "meeting_latitude BETWEEN -90 AND 90");
            t.HasCheckConstraint("ck_planned_rides_longitude", "meeting_longitude BETWEEN -180 AND 180");
            t.HasCheckConstraint("ck_planned_rides_max_riders", "max_riders IS NULL OR max_riders > 0");
        });
        ride.HasKey(r => r.Id);
        ride.Property(r => r.Title).HasMaxLength(160);
        ride.Property(r => r.MeetingName).HasMaxLength(200);
        ride.Property(r => r.Pace).HasMaxLength(16);
        ride.Property(r => r.Notes).HasMaxLength(2000);

        ride.HasOne<Club>().WithMany().HasForeignKey(r => r.ClubId).OnDelete(DeleteBehavior.Cascade);
        ride.HasOne<User>().WithMany().HasForeignKey(r => r.CreatedByUserId).OnDelete(DeleteBehavior.SetNull);
        // A route withdrawn and deleted leaves the ride standing, without one.
        ride.HasOne<CyclingRoute>().WithMany().HasForeignKey(r => r.RouteId).OnDelete(DeleteBehavior.SetNull);

        ride.HasIndex(r => new { r.ClubId, r.StartsAt });
    }

    public void Configure(EntityTypeBuilder<RideSignUp> signUp)
    {
        signUp.ToTable("ride_sign_ups", "calendar");
        signUp.HasKey(s => new { s.PlannedRideId, s.UserId });
        signUp.HasOne(s => s.PlannedRide).WithMany(r => r.SignUps).HasForeignKey(s => s.PlannedRideId)
            .OnDelete(DeleteBehavior.Cascade);
        signUp.HasOne(s => s.User).WithMany().HasForeignKey(s => s.UserId).OnDelete(DeleteBehavior.Cascade);
        signUp.HasIndex(s => s.UserId);
    }

    public void Configure(EntityTypeBuilder<CalendarFeed> feed)
    {
        feed.ToTable("calendar_feeds", "calendar");
        feed.HasKey(f => f.UserId);
        feed.HasOne<User>().WithMany().HasForeignKey(f => f.UserId).OnDelete(DeleteBehavior.Cascade);
        feed.HasOne<Club>().WithMany().HasForeignKey(f => f.ClubId).OnDelete(DeleteBehavior.Cascade);
        feed.HasIndex(f => f.TokenHash).IsUnique();
    }
}
