using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Features.Clubs;

namespace Velomine.Server.Features.Routes;

public sealed class RouteConfiguration : IEntityTypeConfiguration<CyclingRoute>, IEntityTypeConfiguration<RouteLine>
{
    public void Configure(EntityTypeBuilder<CyclingRoute> route)
    {
        route.ToTable("routes", "routes", t =>
        {
            t.HasCheckConstraint("ck_routes_surface", "surface IN ('road', 'gravel', 'mountain', 'mixed')");
            t.HasCheckConstraint("ck_routes_distance_m", "distance_m >= 0");
            t.HasCheckConstraint("ck_routes_name", "char_length(btrim(name)) > 0");
        });
        route.HasKey(r => r.Id);
        route.Property(r => r.Name).HasMaxLength(120);
        route.Property(r => r.Description).HasMaxLength(1000);
        route.Property(r => r.Surface).HasMaxLength(16);

        // The route is the member's: it goes with the account. The club only borrows it, so when the club goes the
        // share ends and the route stays.
        route.HasOne(r => r.Owner).WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
        route.HasOne<Club>().WithMany().HasForeignKey(r => r.ClubId).OnDelete(DeleteBehavior.SetNull);
        route.HasOne(r => r.Line).WithOne().HasForeignKey<RouteLine>(l => l.RouteId).OnDelete(DeleteBehavior.Cascade);

        route.HasIndex(r => new { r.ClubId, r.CreatedAt });
        route.HasIndex(r => new { r.UserId, r.CreatedAt });
    }

    public void Configure(EntityTypeBuilder<RouteLine> line)
    {
        line.ToTable("route_lines", "routes", t =>
        {
            t.HasCheckConstraint("ck_route_lines_aligned",
                "cardinality(latitude) = cardinality(longitude) AND (elevation IS NULL OR cardinality(elevation) = cardinality(latitude))");
            t.HasCheckConstraint("ck_route_lines_points", "cardinality(latitude) >= 2");
        });
        line.HasKey(l => l.RouteId);
        line.Property(l => l.Latitude).HasColumnType("double precision[]");
        line.Property(l => l.Longitude).HasColumnType("double precision[]");
        line.Property(l => l.Elevation).HasColumnType("real[]");
    }
}
