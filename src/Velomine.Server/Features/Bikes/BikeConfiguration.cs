using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Velomine.Server.Features.Bikes;

public sealed class BikeConfiguration : IEntityTypeConfiguration<Bike>, IEntityTypeConfiguration<BikeComponent>
{
    public void Configure(EntityTypeBuilder<Bike> bike)
    {
        bike.ToTable("bikes", "bikes");
        bike.HasKey(b => b.Id);
        bike.Property(b => b.Name).HasMaxLength(100);
        bike.Property(b => b.Brand).HasMaxLength(100);
        bike.Property(b => b.Model).HasMaxLength(100);
        bike.Property(b => b.Kind).HasMaxLength(16);
        bike.Property(b => b.Version).IsRowVersion();

        bike.HasOne(b => b.Owner).WithMany().HasForeignKey(b => b.UserId).OnDelete(DeleteBehavior.Cascade);
        bike.HasMany(b => b.Components).WithOne().HasForeignKey(c => c.BikeId).OnDelete(DeleteBehavior.Cascade);

        bike.HasIndex(b => b.UserId);
        // At most one default bike per member, enforced by the database.
        bike.HasIndex(b => b.UserId).IsUnique().HasFilter("is_default").HasDatabaseName("ux_bikes_one_default_per_user");
    }

    public void Configure(EntityTypeBuilder<BikeComponent> component)
    {
        component.ToTable("bike_components", "bikes");
        component.HasKey(c => c.Id);
        component.Property(c => c.Type).HasMaxLength(48);
        component.Property(c => c.Brand).HasMaxLength(100);
        component.Property(c => c.Model).HasMaxLength(100);
        component.Property(c => c.Version).IsRowVersion();
        component.HasIndex(c => c.BikeId);
    }
}
