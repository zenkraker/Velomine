using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Velomine.Server.Features.Bikes;

public sealed class BikeConfiguration : IEntityTypeConfiguration<Bike>, IEntityTypeConfiguration<BikeComponent>, IEntityTypeConfiguration<Part>,
    IEntityTypeConfiguration<CatalogueMeta>, IEntityTypeConfiguration<PartContribution>,
    IEntityTypeConfiguration<CatalogueConflict>, IEntityTypeConfiguration<BikeTemplate>, IEntityTypeConfiguration<BikeTemplatePart>
{
    public void Configure(EntityTypeBuilder<Bike> bike)
    {
        bike.ToTable("bikes", "bikes");
        bike.HasKey(b => b.Id);
        bike.Property(b => b.Name).HasMaxLength(100);
        bike.Property(b => b.Brand).HasMaxLength(100);
        bike.Property(b => b.Model).HasMaxLength(100);
        bike.Property(b => b.BuildSpec).HasMaxLength(60);
        bike.Property(b => b.FrameSize).HasMaxLength(24);
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
        component.Property(c => c.Mpn).HasMaxLength(64);
        component.Property(c => c.Gtin).HasMaxLength(14);
        component.Property(c => c.Version).IsRowVersion();
        component.HasIndex(c => c.BikeId);
        component.HasIndex(c => c.PartId);
        // A part leaving the catalogue must never take a bike's history with it.
        component.HasOne<Part>().WithMany().HasForeignKey(c => c.PartId).OnDelete(DeleteBehavior.SetNull);
    }

    public void Configure(EntityTypeBuilder<Part> part)
    {
        part.ToTable("parts", "bikes");
        part.HasKey(p => p.Id);
        part.Property(p => p.Key).HasMaxLength(300);
        part.Property(p => p.Type).HasMaxLength(48);
        part.Property(p => p.Brand).HasMaxLength(100);
        part.Property(p => p.Model).HasMaxLength(100);
        part.Property(p => p.Mpn).HasMaxLength(64);
        part.Property(p => p.Gtin).HasMaxLength(14);
        part.Property(p => p.Source).HasMaxLength(16);
        part.Property(p => p.Status).HasMaxLength(16);
        part.Property(p => p.Version).IsRowVersion();
        part.HasIndex(p => p.Key).IsUnique();
        part.HasIndex(p => new { p.Type, p.Brand });
    }

    public void Configure(EntityTypeBuilder<CatalogueMeta> meta)
    {
        meta.ToTable("catalogue_meta", "bikes");
        meta.HasKey(m => m.Id);
        meta.Property(m => m.Id).ValueGeneratedNever();
        meta.Property(m => m.SourceUrl).HasMaxLength(500);
    }

    public void Configure(EntityTypeBuilder<PartContribution> contribution)
    {
        contribution.ToTable("part_contributions", "bikes");
        contribution.HasKey(c => c.Id);
        contribution.Property(c => c.Key).HasMaxLength(300);
        contribution.Property(c => c.Type).HasMaxLength(48);
        contribution.Property(c => c.Brand).HasMaxLength(100);
        contribution.Property(c => c.Model).HasMaxLength(100);
        contribution.Property(c => c.Mpn).HasMaxLength(64);
        contribution.Property(c => c.Gtin).HasMaxLength(14);
        contribution.Property(c => c.PayloadHash).HasMaxLength(64);
        contribution.Property(c => c.Status).HasMaxLength(16);
        contribution.Property(c => c.Reason).HasMaxLength(500);
        contribution.HasIndex(c => new { c.Key, c.PayloadHash }).IsUnique();
        contribution.HasIndex(c => new { c.Status, c.NextAttemptAt });
    }

    public void Configure(EntityTypeBuilder<CatalogueConflict> conflict)
    {
        conflict.ToTable("catalogue_conflicts", "bikes");
        conflict.HasKey(c => c.Id);
        conflict.Property(c => c.Key).HasMaxLength(300);
        conflict.Property(c => c.Type).HasMaxLength(48);
        conflict.Property(c => c.LocalBrand).HasMaxLength(100);
        conflict.Property(c => c.LocalModel).HasMaxLength(100);
        conflict.Property(c => c.LocalMpn).HasMaxLength(64);
        conflict.Property(c => c.LocalGtin).HasMaxLength(14);
        conflict.Property(c => c.SharedBrand).HasMaxLength(100);
        conflict.Property(c => c.SharedModel).HasMaxLength(100);
        conflict.Property(c => c.SharedMpn).HasMaxLength(64);
        conflict.Property(c => c.SharedGtin).HasMaxLength(14);
        conflict.Property(c => c.IncomingHash).HasMaxLength(64);
        conflict.Property(c => c.Status).HasMaxLength(16);
        conflict.HasIndex(c => c.Key);
        conflict.HasIndex(c => c.Key).IsUnique().HasFilter("status = 'pending'").HasDatabaseName("ux_catalogue_conflicts_one_pending_per_key");
    }

    public void Configure(EntityTypeBuilder<BikeTemplate> template)
    {
        template.ToTable("bike_templates", "bikes");
        template.HasKey(t => t.Id);
        template.Property(t => t.Name).HasMaxLength(100);
        template.Property(t => t.Version).IsRowVersion();
        template.HasOne(t => t.Owner).WithMany().HasForeignKey(t => t.UserId).OnDelete(DeleteBehavior.Cascade);
        template.HasMany(t => t.Parts).WithOne().HasForeignKey(p => p.TemplateId).OnDelete(DeleteBehavior.Cascade);
        template.HasIndex(t => t.UserId);
    }

    public void Configure(EntityTypeBuilder<BikeTemplatePart> part)
    {
        part.ToTable("bike_template_parts", "bikes");
        part.HasKey(p => p.Id);
        part.Property(p => p.Type).HasMaxLength(48);
        part.Property(p => p.Brand).HasMaxLength(100);
        part.Property(p => p.Model).HasMaxLength(100);
        part.Property(p => p.Mpn).HasMaxLength(64);
        part.Property(p => p.Gtin).HasMaxLength(14);
        part.HasIndex(p => p.TemplateId);
    }
}
