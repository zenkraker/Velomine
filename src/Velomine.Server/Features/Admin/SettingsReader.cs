using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Server;

namespace Velomine.Server.Features.Admin;

/// <summary>What the server actually does: the saved setting if there is one, else the environment value.</summary>
public sealed record EffectiveSettings(bool SignUpEnabled, bool RequireAdminApproval, string? MapTileUrl, string? MapAttribution);

public sealed class SettingsReader(VelomineDbContext db, IOptions<AccountsOptions> accounts, IOptions<MapOptions> map)
{
    public async Task<ServerSettings?> SavedAsync(CancellationToken ct) =>
        await db.Set<ServerSettings>().AsNoTracking().FirstOrDefaultAsync(ct);

    public async Task<EffectiveSettings> GetAsync(CancellationToken ct)
    {
        var saved = await SavedAsync(ct);
        var tile = saved?.MapTileUrl ?? map.Value.TileUrl;
        // An unusable address (wrong placeholders, not http or https) is treated as no map, whatever its source.
        var usable = new MapOptions { TileUrl = tile }.UsableTileUrl;
        return new EffectiveSettings(
            saved?.SignUpEnabled ?? accounts.Value.SignUpEnabled,
            saved?.RequireAdminApproval ?? accounts.Value.RequireAdminApproval,
            usable,
            usable is null ? null : saved?.MapAttribution ?? map.Value.Attribution);
    }
}
