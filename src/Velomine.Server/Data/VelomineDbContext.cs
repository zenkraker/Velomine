using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Data;

/// <summary>
/// The one DbContext. Each feature area keeps its tables in its own PostgreSQL schema:
/// accounts is the default here; other areas name their schema in their own entity configuration.
/// </summary>
public sealed partial class VelomineDbContext(DbContextOptions<VelomineDbContext> options)
    : IdentityDbContext<User, IdentityRole<Guid>, Guid>(options)
{
    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        builder.HasDefaultSchema("accounts");

        builder.Entity<User>().ToTable("users");
        builder.Entity<IdentityRole<Guid>>().ToTable("roles");
        builder.Entity<IdentityUserRole<Guid>>().ToTable("user_roles");
        builder.Entity<IdentityUserClaim<Guid>>().ToTable("user_claims");
        builder.Entity<IdentityUserLogin<Guid>>().ToTable("user_logins");
        builder.Entity<IdentityUserToken<Guid>>().ToTable("user_tokens");
        builder.Entity<IdentityRoleClaim<Guid>>().ToTable("role_claims");

        SnakeCaseNames(builder);
    }

    // EF Core has no built-in snake_case naming; the postgres skill asks for it.
    private static void SnakeCaseNames(ModelBuilder builder)
    {
        foreach (var entity in builder.Model.GetEntityTypes())
        {
            foreach (var property in entity.GetProperties())
                property.SetColumnName(Snake(property.GetColumnName()));
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
