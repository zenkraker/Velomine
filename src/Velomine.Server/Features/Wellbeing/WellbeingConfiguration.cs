using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Wellbeing;

public sealed class WellbeingConfiguration : IEntityTypeConfiguration<DailyCheckIn>, IEntityTypeConfiguration<RideFeel>
{
    public void Configure(EntityTypeBuilder<DailyCheckIn> checkIn)
    {
        checkIn.ToTable("daily_check_ins", "wellbeing", t =>
        {
            t.HasCheckConstraint("ck_daily_check_ins_fatigue", "fatigue BETWEEN 1 AND 5");
            t.HasCheckConstraint("ck_daily_check_ins_soreness", "soreness BETWEEN 1 AND 5");
            t.HasCheckConstraint("ck_daily_check_ins_mood", "mood BETWEEN 1 AND 5");
            t.HasCheckConstraint("ck_daily_check_ins_stress", "stress BETWEEN 1 AND 5");
            t.HasCheckConstraint("ck_daily_check_ins_motivation", "motivation BETWEEN 1 AND 5");
        });
        checkIn.HasKey(c => c.Id);
        checkIn.HasIndex(c => new { c.UserId, c.LocalDate }).IsUnique();
        checkIn.HasOne<User>().WithMany().HasForeignKey(c => c.UserId).OnDelete(DeleteBehavior.Cascade);
    }

    public void Configure(EntityTypeBuilder<RideFeel> feel)
    {
        feel.ToTable("ride_feel", "wellbeing", t =>
            t.HasCheckConstraint("ck_ride_feel_rpe", "rpe BETWEEN 1 AND 10"));
        feel.HasKey(f => f.RideId);
        feel.Property(f => f.Notes).HasMaxLength(500);
        feel.HasOne<Ride>().WithOne().HasForeignKey<RideFeel>(f => f.RideId).OnDelete(DeleteBehavior.Cascade);
    }
}
