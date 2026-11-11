using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Rides.Import;

public enum RideImportStatus
{
    /// <summary>Saved, waiting to be extracted or being extracted.</summary>
    Processing,
    Completed,
    /// <summary>The archive could not be used; <see cref="RideImport.Error"/> says why.</summary>
    Failed,
}

/// <summary>One member's upload of another app's export archive. The rides it creates point back at it.</summary>
public sealed class RideImport
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    /// <summary>Where the archive came from, such as "strava".</summary>
    public string Source { get; set; } = "";

    public string ArchiveSha256 { get; set; } = "";

    public string FileName { get; set; } = "";

    public RideImportStatus Status { get; set; }

    /// <summary>How many activities the archive lists; the rides it produced are counted when read.</summary>
    public int Total { get; set; }

    /// <summary>A short code such as "not_a_strava_export" when <see cref="Status"/> is Failed.</summary>
    public string? Error { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? FinishedAt { get; set; }

    public User? Owner { get; set; }
}

public sealed class RideImportConfiguration : IEntityTypeConfiguration<RideImport>
{
    public void Configure(EntityTypeBuilder<RideImport> import)
    {
        import.ToTable("imports", "rides");
        import.HasKey(i => i.Id);
        import.Property(i => i.Source).HasMaxLength(16);
        import.Property(i => i.ArchiveSha256).HasMaxLength(64);
        import.Property(i => i.FileName).HasMaxLength(256);
        import.Property(i => i.Status).HasConversion<string>().HasMaxLength(16);
        import.Property(i => i.Error).HasMaxLength(64);

        import.HasOne(i => i.Owner).WithMany().HasForeignKey(i => i.UserId).OnDelete(DeleteBehavior.Cascade);
        // Uploading the same archive twice is a retry, not a second import.
        import.HasIndex(i => new { i.UserId, i.ArchiveSha256 }).IsUnique();
        import.HasIndex(i => new { i.UserId, i.CreatedAt });
    }
}
