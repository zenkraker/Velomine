using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Admin;

/// <summary>What the server actually does: the saved setting if there is one, else the environment value.</summary>
public sealed record EffectiveSettings(bool SignUpEnabled, bool RequireAdminApproval, bool ClubCreationEnabled);

public sealed class SettingsReader(VelomineDbContext db, IOptions<AccountsOptions> accounts)
{
    public async Task<ServerSettings?> SavedAsync(CancellationToken ct) =>
        await db.Set<ServerSettings>().AsNoTracking().FirstOrDefaultAsync(ct);

    public async Task<EffectiveSettings> GetAsync(CancellationToken ct)
    {
        var saved = await SavedAsync(ct);
        return new EffectiveSettings(
            saved?.SignUpEnabled ?? accounts.Value.SignUpEnabled,
            saved?.RequireAdminApproval ?? accounts.Value.RequireAdminApproval,
            saved?.ClubCreationEnabled ?? accounts.Value.ClubCreationEnabled);
    }
}
