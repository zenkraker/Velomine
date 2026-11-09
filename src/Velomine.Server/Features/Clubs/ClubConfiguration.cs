using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Velomine.Server.Features.Clubs;

public sealed class ClubConfiguration : IEntityTypeConfiguration<Club>, IEntityTypeConfiguration<ClubMembership>,
    IEntityTypeConfiguration<ClubJoinRequest>
{
    public void Configure(EntityTypeBuilder<Club> club)
    {
        club.ToTable("clubs", "clubs", t =>
        {
            t.HasCheckConstraint("ck_clubs_join_code", "char_length(join_code) >= 6");
            t.HasCheckConstraint("ck_clubs_location", "(latitude IS NULL) = (longitude IS NULL)");
            t.HasCheckConstraint("ck_clubs_latitude", "latitude IS NULL OR (latitude BETWEEN -90 AND 90)");
            t.HasCheckConstraint("ck_clubs_longitude", "longitude IS NULL OR (longitude BETWEEN -180 AND 180)");
        });
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

    public void Configure(EntityTypeBuilder<ClubJoinRequest> request)
    {
        request.ToTable("join_requests", "clubs", t =>
            t.HasCheckConstraint("ck_club_join_requests_note", "note IS NULL OR char_length(note) <= 300"));
        request.HasKey(r => r.Id);
        request.Property(r => r.Note).HasMaxLength(300);
        request.HasOne(r => r.Club).WithMany().HasForeignKey(r => r.ClubId).OnDelete(DeleteBehavior.Cascade);
        request.HasOne(r => r.User).WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
        // One pending request per rider: asking another club moves the existing one.
        request.HasIndex(r => r.UserId).IsUnique();
        request.HasIndex(r => r.ClubId);
    }
}
