using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Privacy;

public sealed class PrivacyConfiguration : IEntityTypeConfiguration<PrivacySettings>, IEntityTypeConfiguration<PrivacyZone>
{
    public void Configure(EntityTypeBuilder<PrivacySettings> settings)
    {
        settings.ToTable("settings", "privacy", t =>
        {
            t.HasCheckConstraint(
                "ck_privacy_settings_trim",
                $"trim_start_m BETWEEN 0 AND {PrivacyValues.MaxTrimM} AND trim_end_m BETWEEN 0 AND {PrivacyValues.MaxTrimM}");
        });
        settings.HasKey(s => s.UserId);
        settings.HasOne<User>().WithOne().HasForeignKey<PrivacySettings>(s => s.UserId).OnDelete(DeleteBehavior.Cascade);
    }

    public void Configure(EntityTypeBuilder<PrivacyZone> zone)
    {
        zone.ToTable("zones", "privacy", t =>
        {
            t.HasCheckConstraint(
                "ck_privacy_zones_radius",
                $"radius_m BETWEEN {PrivacyValues.MinRadiusM} AND {PrivacyValues.MaxRadiusM}");
            t.HasCheckConstraint("ck_privacy_zones_latitude", "latitude BETWEEN -90 AND 90");
            t.HasCheckConstraint("ck_privacy_zones_longitude", "longitude BETWEEN -180 AND 180");
        });
        zone.HasKey(z => z.Id);
        zone.Property(z => z.Name).HasMaxLength(60);
        zone.HasOne<User>().WithMany().HasForeignKey(z => z.UserId).OnDelete(DeleteBehavior.Cascade);
        zone.HasIndex(z => z.UserId);
    }
}
