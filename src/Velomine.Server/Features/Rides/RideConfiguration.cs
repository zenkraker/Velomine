using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides.Import;

namespace Velomine.Server.Features.Rides;

public sealed class RideConfiguration : IEntityTypeConfiguration<Ride>, IEntityTypeConfiguration<RideStreams>, IEntityTypeConfiguration<RidePowerBest>, IEntityTypeConfiguration<RideLap>
{
    public void Configure(EntityTypeBuilder<Ride> ride)
    {
        ride.ToTable("rides", "rides", t =>
        {
            t.HasCheckConstraint("ck_rides_title_length", "char_length(title) BETWEEN 1 AND 120");
            t.HasCheckConstraint("ck_rides_description_length", "char_length(description) BETWEEN 1 AND 2000");
            t.HasCheckConstraint(
                "ck_rides_privacy_trim",
                $"trim_start_m BETWEEN 0 AND {PrivacyValues.MaxTrimM} AND trim_end_m BETWEEN 0 AND {PrivacyValues.MaxTrimM}");
        });
        ride.HasKey(r => r.Id);
        ride.Property(r => r.Status).HasConversion<string>().HasMaxLength(16);
        ride.Property(r => r.SpeedSource).HasConversion<string>().HasMaxLength(16);
        ride.Property(r => r.Error).HasMaxLength(64);
        ride.Property(r => r.IdempotencyKey).HasMaxLength(128);
        ride.Property(r => r.FileSha256).HasMaxLength(64);
        ride.Property(r => r.FileName).HasMaxLength(256);
        ride.Property(r => r.DedupKey).HasMaxLength(128);
        ride.Property(r => r.Source).HasMaxLength(16);
        ride.Property(r => r.SourceId).HasMaxLength(64);
        ride.Property(r => r.Device).HasMaxLength(128);
        ride.Property(r => r.Discipline).HasMaxLength(16);
        ride.Property(r => r.Assist).HasMaxLength(16);
        ride.Property(r => r.Environment).HasMaxLength(16);
        ride.Property(r => r.Version).IsRowVersion();
        ride.Ignore(r => r.Privacy);

        ride.HasOne(r => r.Owner).WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
        ride.HasOne(r => r.Streams).WithOne().HasForeignKey<RideStreams>(s => s.RideId).OnDelete(DeleteBehavior.Cascade);
        ride.HasMany(r => r.Laps).WithOne().HasForeignKey(l => l.RideId).OnDelete(DeleteBehavior.Cascade);

        ride.HasOne<Bikes.Bike>().WithMany().HasForeignKey(r => r.BikeId).OnDelete(DeleteBehavior.SetNull);
        ride.HasIndex(r => r.BikeId);

        ride.HasOne<RideImport>().WithMany().HasForeignKey(r => r.ImportId).OnDelete(DeleteBehavior.SetNull);
        ride.HasIndex(r => r.ImportId);
        ride.Property(r => r.Quiet).HasDefaultValue(false);
        // One row per activity from another app: importing a newer export skips what is already here.
        ride.HasIndex(r => new { r.UserId, r.Source, r.SourceId })
            .IsUnique()
            .HasFilter("source IS NOT NULL")
            .HasDatabaseName("ux_rides_user_source");

        ride.HasIndex(r => new { r.UserId, r.IdempotencyKey }).IsUnique();
        ride.HasIndex(r => new { r.UserId, r.DedupKey })
            .IsUnique()
            .HasFilter("status IN ('Processing','Ready')")
            .HasDatabaseName("ux_rides_user_dedup_key");
        ride.HasIndex(r => new { r.UserId, r.StartTime });
        ride.HasIndex(r => new { r.UserId, r.Discipline });
        // The backfill reads only unprocessed rides; a partial index keeps each batch from scanning the history.
        ride.HasIndex(r => r.Id)
            .HasFilter("status = 'Ready' AND power_bests_backfilled_at IS NULL")
            .HasDatabaseName("ix_rides_power_bests_backfill");
        // The re-read picks the oldest parser version first, then the oldest upload; the partial index serves that order
        // without scanning rides that are already current.
        ride.HasIndex(r => new { r.ParserVersion, r.UploadedAt, r.Id })
            .HasFilter("status IN ('Ready','Failed')")
            .HasDatabaseName("ix_rides_reparse");
    }

    public void Configure(EntityTypeBuilder<RideStreams> streams)
    {
        streams.ToTable("ride_streams", "rides");
        streams.HasKey(s => s.RideId);
        streams.Property(s => s.Time).HasColumnType("double precision[]");
        streams.Property(s => s.Latitude).HasColumnType("double precision[]");
        streams.Property(s => s.Longitude).HasColumnType("double precision[]");
        streams.Property(s => s.Altitude).HasColumnType("real[]");
        streams.Property(s => s.Speed).HasColumnType("real[]");
        streams.Property(s => s.Distance).HasColumnType("real[]");
        streams.Property(s => s.HeartRate).HasColumnType("smallint[]");
        streams.Property(s => s.Power).HasColumnType("smallint[]");
        streams.Property(s => s.Cadence).HasColumnType("smallint[]");
        streams.Property(s => s.Temperature).HasColumnType("smallint[]");
    }

    public void Configure(EntityTypeBuilder<RidePowerBest> best)
    {
        best.ToTable("ride_power_bests", "rides");
        best.HasKey(b => new { b.RideId, b.DurationS });
        best.Property(b => b.Watts).IsRequired();
        best.HasOne<Ride>().WithMany(r => r.PowerBests).HasForeignKey(b => b.RideId).OnDelete(DeleteBehavior.Cascade);
    }

    public void Configure(EntityTypeBuilder<RideLap> lap)
    {
        lap.ToTable("ride_laps", "rides");
        lap.HasKey(l => new { l.RideId, l.Index });
    }
}
