using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Import;
using Velomine.Server.Features.Sharing;
using Velomine.Server.Features.Wellbeing;

namespace Velomine.Server.Data;

/// <summary>
/// The one DbContext. Each feature area keeps its tables in its own PostgreSQL schema:
/// accounts is the default here; other areas name their schema in their own entity configuration.
/// </summary>
public sealed partial class VelomineDbContext(DbContextOptions<VelomineDbContext> options)
    : IdentityDbContext<User, IdentityRole<Guid>, Guid>(options)
{
    public DbSet<Ride> Rides => Set<Ride>();

    public DbSet<RideStreams> RideStreams => Set<RideStreams>();

    public DbSet<RidePowerBest> RidePowerBests => Set<RidePowerBest>();

    public DbSet<RideLap> RideLaps => Set<RideLap>();

    public DbSet<RideImport> RideImports => Set<RideImport>();

    public DbSet<Bike> Bikes => Set<Bike>();

    public DbSet<BikeComponent> BikeComponents => Set<BikeComponent>();

    public DbSet<Part> Parts => Set<Part>();

    public DbSet<CatalogueMeta> CatalogueMeta => Set<CatalogueMeta>();

    public DbSet<CatalogueSettings> CatalogueSettings => Set<CatalogueSettings>();

    public DbSet<PartContribution> PartContributions => Set<PartContribution>();

    public DbSet<CatalogueConflict> CatalogueConflicts => Set<CatalogueConflict>();

    public DbSet<BikeTemplate> BikeTemplates => Set<BikeTemplate>();

    public DbSet<BikeTemplatePart> BikeTemplateParts => Set<BikeTemplatePart>();

    public DbSet<Goal> Goals => Set<Goal>();

    public DbSet<ServerSettings> ServerSettings => Set<ServerSettings>();

    public DbSet<Notification> Notifications => Set<Notification>();

    public DbSet<Club> Clubs => Set<Club>();

    public DbSet<ClubMembership> ClubMemberships => Set<ClubMembership>();

    public DbSet<ClubJoinRequest> ClubJoinRequests => Set<ClubJoinRequest>();

    public DbSet<ShareGrant> ShareGrants => Set<ShareGrant>();

    public DbSet<ShareView> ShareViews => Set<ShareView>();

    public DbSet<DailyCheckIn> DailyCheckIns => Set<DailyCheckIn>();

    public DbSet<RideFeel> RideFeels => Set<RideFeel>();

    public DbSet<PrivacySettings> PrivacySettings => Set<PrivacySettings>();

    public DbSet<PrivacyZone> PrivacyZones => Set<PrivacyZone>();

    public DbSet<UserSession> UserSessions => Set<UserSession>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        builder.HasDefaultSchema("accounts");

        builder.Entity<User>().ToTable("users", t =>
        {
            t.HasCheckConstraint("ck_users_first_day_of_week", "first_day_of_week BETWEEN 0 AND 6");
            t.HasCheckConstraint("ck_users_ftp_w", "ftp_w BETWEEN 30 AND 1000");
            t.HasCheckConstraint("ck_users_weight_kg", "weight_kg BETWEEN 20 AND 300");
            t.HasCheckConstraint("ck_users_max_heart_rate", "max_heart_rate BETWEEN 100 AND 240");
            t.HasCheckConstraint("ck_users_birth_year", "birth_year IS NULL OR birth_year BETWEEN 1900 AND 2200");
        });
        builder.Entity<User>().Property(u => u.TimeZone).HasMaxLength(64);
        builder.Entity<User>().Property(u => u.Language).HasMaxLength(8);
        builder.Entity<IdentityRole<Guid>>().ToTable("roles");
        builder.Entity<IdentityUserRole<Guid>>().ToTable("user_roles");
        builder.Entity<IdentityUserClaim<Guid>>().ToTable("user_claims");
        builder.Entity<IdentityUserLogin<Guid>>().ToTable("user_logins");
        builder.Entity<IdentityUserToken<Guid>>().ToTable("user_tokens");
        builder.Entity<IdentityRoleClaim<Guid>>().ToTable("role_claims");

        // Each feature area's entity configurations live in its own folder and name their own schema.
        builder.ApplyConfigurationsFromAssembly(typeof(VelomineDbContext).Assembly);

        SnakeCaseNames(builder);
    }

    // EF Core has no built-in snake_case naming; the postgres skill asks for it.
    private static void SnakeCaseNames(ModelBuilder builder)
    {
        foreach (var entity in builder.Model.GetEntityTypes())
        {
            foreach (var property in entity.GetProperties())
            {
                // A uint concurrency token is PostgreSQL's built-in "xmin" column; Npgsql names it later, so leave it alone.
                if (property.IsConcurrencyToken && property.ClrType == typeof(uint)) continue;
                property.SetColumnName(Snake(property.GetColumnName()));
            }
            foreach (var key in entity.GetKeys())
                key.SetName(Snake(key.GetName()!));
            foreach (var foreignKey in entity.GetForeignKeys())
                foreignKey.SetConstraintName(Snake(foreignKey.GetConstraintName()!));
            foreach (var index in entity.GetIndexes())
                index.SetDatabaseName(Snake(index.GetDatabaseName()!));
        }
    }

    private static string Snake(string name) => WordBoundary().Replace(name, "$1_$2").ToLowerInvariant();

    [GeneratedRegex("([a-z0-9])([A-Z])")]
    private static partial Regex WordBoundary();
}
