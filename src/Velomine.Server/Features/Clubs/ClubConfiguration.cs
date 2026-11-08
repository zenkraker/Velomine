using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Velomine.Server.Features.Clubs;

public sealed class ClubConfiguration : IEntityTypeConfiguration<Club>, IEntityTypeConfiguration<ClubMembership>
{
    public void Configure(EntityTypeBuilder<Club> club)
    {
        club.ToTable("clubs", "clubs", t =>
            t.HasCheckConstraint("ck_clubs_join_code", "char_length(join_code) >= 6"));
        club.HasKey(c => c.Id);
        club.Property(c => c.Name).HasMaxLength(100);
        club.Property(c => c.JoinCode).HasMaxLength(16);
        club.HasIndex(c => c.Name).IsUnique();
        club.HasIndex(c => c.JoinCode).IsUnique();
    }

    public void Configure(EntityTypeBuilder<ClubMembership> membership)
    {
        membership.ToTable("memberships", "clubs", t =>
            t.HasCheckConstraint("ck_club_memberships_role", "role IN ('owner', 'coach', 'member')"));
        membership.HasKey(m => m.Id);
        membership.Property(m => m.Role).HasMaxLength(16);
        membership.HasOne(m => m.Club).WithMany(c => c.Memberships).HasForeignKey(m => m.ClubId).OnDelete(DeleteBehavior.Cascade);
        membership.HasOne(m => m.User).WithMany().HasForeignKey(m => m.UserId).OnDelete(DeleteBehavior.Cascade);
        // One club per account, riders and coaches alike.
        membership.HasIndex(m => m.UserId).IsUnique();
        membership.HasIndex(m => m.ClubId);
    }
}
