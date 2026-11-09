using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Velomine.Server.Features.Admin;

/// <summary>
/// What an admin can change in the app. One row. A null value means "use the environment default"; once saved, a value
/// overrides the environment. Nothing secret is kept here: SMTP and single sign-on come from environment variables only.
/// </summary>
public sealed class ServerSettings
{
    public const int OnlyRow = 1;

    public int Id { get; set; } = OnlyRow;

    public bool? SignUpEnabled { get; set; }

    public bool? RequireAdminApproval { get; set; }

    // No longer read or written: maps are always on (see MapOptions). Kept for one release before the
    // columns are dropped, as the migration rule asks.

    public string? MapTileUrl { get; set; }

    public string? MapAttribution { get; set; }

    /// <summary>
    /// When the server first saw SMTP configured. Only notifications created after this are emailed, so turning email on
    /// never sends a backlog. A timestamp, not a credential.
    /// </summary>
    public DateTimeOffset? EmailStartedAt { get; set; }
}

public sealed class ServerSettingsConfiguration : IEntityTypeConfiguration<ServerSettings>
{
    public void Configure(EntityTypeBuilder<ServerSettings> settings)
    {
        settings.ToTable("server_settings", "admin", t => t.HasCheckConstraint("ck_server_settings_one_row", "id = 1"));
        settings.HasKey(s => s.Id);
        settings.Property(s => s.Id).ValueGeneratedNever();
        settings.Property(s => s.MapTileUrl).HasMaxLength(500);
        settings.Property(s => s.MapAttribution).HasMaxLength(200);
    }
}
