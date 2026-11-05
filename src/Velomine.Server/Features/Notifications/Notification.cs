using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Notifications;

/// <summary>What a notification is about. The app writes the sentence; the server sends the type and what it refers to.</summary>
public static class NotificationTypes
{
    /// <summary>An uploaded ride has been read. Refers to the ride.</summary>
    public const string RideReady = "ride_ready";

    /// <summary>An uploaded file could not be used. Refers to the ride, whose error says why.</summary>
    public const string RideFailed = "ride_failed";

    /// <summary>The ride was already uploaded and is hidden. Refers to the new ride; its duplicateOf is the original.</summary>
    public const string RideDuplicate = "ride_duplicate";

    /// <summary>For admins: someone signed up and waits for approval. Refers to that account.</summary>
    public const string SignUpWaiting = "signup_waiting";

    /// <summary>A part has used 80 % of one of its limits. Refers to the bike and the part.</summary>
    public const string PartSoon = "part_soon";

    /// <summary>A part has reached one of its limits. Refers to the bike and the part.</summary>
    public const string PartWorn = "part_worn";
}

public sealed class Notification
{
    public Guid Id { get; set; }

    /// <summary>Who it is for.</summary>
    public Guid UserId { get; set; }

    public string Type { get; set; } = "";

    /// <summary>A short name for what it is about, kept as it was then: a file name, "Chain on Road bike", a person's name.</summary>
    public string Subject { get; set; } = "";

    public Guid? RideId { get; set; }

    public Guid? BikeId { get; set; }

    public Guid? ComponentId { get; set; }

    /// <summary>The account it is about (sign-ups).</summary>
    public Guid? AboutUserId { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? ReadAt { get; set; }
}

public sealed class NotificationConfiguration : IEntityTypeConfiguration<Notification>
{
    public void Configure(EntityTypeBuilder<Notification> n)
    {
        n.ToTable("notifications", "notifications");
        n.HasKey(x => x.Id);
        n.Property(x => x.Type).HasMaxLength(32);
        n.Property(x => x.Subject).HasMaxLength(300);

        // When what a notification is about goes away, so does the notification.
        n.HasOne<User>().WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        n.HasOne<User>().WithMany().HasForeignKey(x => x.AboutUserId).OnDelete(DeleteBehavior.Cascade);
        n.HasOne<Ride>().WithMany().HasForeignKey(x => x.RideId).OnDelete(DeleteBehavior.Cascade);
        n.HasOne<Bike>().WithMany().HasForeignKey(x => x.BikeId).OnDelete(DeleteBehavior.Cascade);
        n.HasOne<BikeComponent>().WithMany().HasForeignKey(x => x.ComponentId).OnDelete(DeleteBehavior.Cascade);

        n.HasIndex(x => new { x.UserId, x.CreatedAt });
        n.HasIndex(x => x.RideId);
        n.HasIndex(x => x.BikeId);
        n.HasIndex(x => x.ComponentId);
        n.HasIndex(x => x.AboutUserId);
    }
}
