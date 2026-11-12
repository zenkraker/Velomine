using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Velomine.Server.Features.Supporter;

/// <summary>The supporter feature's tables, in their own schema. A licence is the member's or the club's, never both.</summary>
public sealed class SupporterConfiguration : IEntityTypeConfiguration<Licence>
{
    public void Configure(EntityTypeBuilder<Licence> licence)
    {
        licence.ToTable("licences", "supporter", t =>
        {
            t.HasCheckConstraint("ck_supporter_licences_holder", "(user_id IS NULL) <> (club_id IS NULL)");
            t.HasCheckConstraint("ck_supporter_licences_serial", "serial > 0");
        });
        licence.HasKey(l => l.Id);
        licence.Property(l => l.Holder).HasMaxLength(100).IsRequired();
        licence.HasOne<Accounts.User>().WithMany().HasForeignKey(l => l.UserId).OnDelete(DeleteBehavior.Cascade);
        licence.HasOne<Clubs.Club>().WithMany().HasForeignKey(l => l.ClubId).OnDelete(DeleteBehavior.Cascade);
        // One rider licence per account and one club licence per club, and a serial can be activated once.
        licence.HasIndex(l => l.UserId).IsUnique();
        licence.HasIndex(l => l.ClubId).IsUnique();
        licence.HasIndex(l => l.Serial).IsUnique();
    }
}
