using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Velomine.Server.Features.Rides;

public sealed class RideConfiguration : IEntityTypeConfiguration<Ride>, IEntityTypeConfiguration<RideStreams>
{
    public void Configure(EntityTypeBuilder<Ride> ride)
    {
        ride.ToTable("rides", "rides");
        ride.HasKey(r => r.Id);
        ride.Property(r => r.Status).HasConversion<string>().HasMaxLength(16);
        ride.Property(r => r.SpeedSource).HasConversion<string>().HasMaxLength(16);
        ride.Property(r => r.Error).HasMaxLength(64);
        ride.Property(r => r.IdempotencyKey).HasMaxLength(128);
        ride.Property(r => r.FileSha256).HasMaxLength(64);
        ride.Property(r => r.FileName).HasMaxLength(256);
        ride.Property(r => r.DedupKey).HasMaxLength(128);
        ride.Property(r => r.Device).HasMaxLength(128);
        ride.Property(r => r.Version).IsRowVersion();

        ride.HasOne(r => r.Owner).WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
        ride.HasOne(r => r.Streams).WithOne().HasForeignKey<RideStreams>(s => s.RideId).OnDelete(DeleteBehavior.Cascade);

        ride.HasIndex(r => new { r.UserId, r.IdempotencyKey }).IsUnique();
        ride.HasIndex(r => new { r.UserId, r.DedupKey });
        ride.HasIndex(r => new { r.UserId, r.StartTime });
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
}
