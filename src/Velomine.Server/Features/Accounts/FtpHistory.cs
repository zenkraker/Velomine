using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Data;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Accounts;

/// <summary>How an FTP was set: typed by the rider, adopted from the estimate, accepted from a ride, or before history was kept.</summary>
public static class FtpSources
{
    public const string Manual = "manual";
    public const string Estimate = "estimate";
    public const string Test = "test";
    public const string Earlier = "earlier";

    /// <summary>The sources a rider may send with a new FTP; <c>test</c> comes from accepting a ride's suggestion.</summary>
    public static readonly string[] Chosen = [Manual, Estimate];
}

/// <summary>
/// One FTP the member has had, when it was set and how. Written by <see cref="SetFtpValue"/> in the same save as
/// the rider's new FTP; the newest row is the current one.
/// </summary>
public sealed class FtpHistory
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public int Watts { get; set; }

    public DateTimeOffset SetAt { get; set; }

    /// <summary>One of <see cref="FtpSources.Manual"/>, <see cref="FtpSources.Estimate"/>, <see cref="FtpSources.Test"/> or <see cref="FtpSources.Earlier"/>.</summary>
    public string Source { get; set; } = FtpSources.Manual;

    /// <summary>The ride a <c>test</c> FTP came from; null for every other source.</summary>
    public Guid? RideId { get; set; }
}

public sealed class FtpHistoryConfiguration : IEntityTypeConfiguration<FtpHistory>
{
    public void Configure(EntityTypeBuilder<FtpHistory> b)
    {
        b.ToTable("ftp_history", t =>
        {
            t.HasCheckConstraint("ck_ftp_history_watts", "watts BETWEEN 30 AND 1000");
            t.HasCheckConstraint("ck_ftp_history_source", "source IN ('manual', 'estimate', 'test', 'earlier')");
        });
        b.HasKey(h => h.Id);
        // The newest row is the current FTP, so the order is total even when two rows share an instant.
        b.HasIndex(h => new { h.UserId, h.SetAt, h.Id }).IsDescending(false, true, true);
        b.HasOne<User>().WithMany().HasForeignKey(h => h.UserId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne<Ride>().WithMany().HasForeignKey(h => h.RideId).OnDelete(DeleteBehavior.SetNull);
    }
}

/// <summary>
/// The one way an FTP changes: sets the value and stages its history row. The caller's own <c>SaveChangesAsync</c>
/// writes both, and nothing is written when the number is the one already set.
/// </summary>
public sealed class SetFtpValue(VelomineDbContext db, TimeProvider time)
{
    public void Set(User user, int watts, string source, Guid? rideId = null)
    {
        if (user.FtpW == watts) return;
        user.FtpW = watts;
        db.FtpHistory.Add(new FtpHistory
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Watts = watts,
            SetAt = time.GetUtcNow(),
            Source = source,
            RideId = rideId,
        });
    }
}
