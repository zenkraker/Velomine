using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Velomine.Server.Features.Sharing;

public sealed class SharingConfiguration : IEntityTypeConfiguration<ShareGrant>, IEntityTypeConfiguration<ShareView>
{
    public void Configure(EntityTypeBuilder<ShareGrant> grant)
    {
        grant.ToTable("grants", "sharing", t =>
        {
            t.HasCheckConstraint("ck_share_grants_data_type", "data_type IN ('rides', 'analytics', 'routes', 'wellbeing')");
            t.HasCheckConstraint("ck_share_grants_audience", "audience IN ('coaches', 'club')");
        });
        grant.HasKey(g => g.Id);
        grant.Property(g => g.DataType).HasMaxLength(16);
        grant.Property(g => g.Audience).HasMaxLength(16);
        grant.HasOne<Accounts.User>().WithMany().HasForeignKey(g => g.MemberId).OnDelete(DeleteBehavior.Cascade);
        // One choice per kind of data: the member's club is where it applies.
        grant.HasIndex(g => new { g.MemberId, g.DataType }).IsUnique();
        grant.HasIndex(g => g.ClubId);
    }

    public void Configure(EntityTypeBuilder<ShareView> view)
    {
        view.ToTable("view_log", "sharing");
        view.HasKey(v => v.Id);
        view.Property(v => v.ViewerName).HasMaxLength(100);
        view.Property(v => v.What).HasMaxLength(24);
        view.HasOne<Accounts.User>().WithMany().HasForeignKey(v => v.MemberId).OnDelete(DeleteBehavior.Cascade);
        view.HasIndex(v => new { v.MemberId, v.At });
    }
}
