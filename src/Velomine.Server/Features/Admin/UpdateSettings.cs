using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Admin;

/// <summary>
/// Saving overrides the environment values for the settings. Only these can be changed here; SMTP and
/// single sign-on are set with environment variables. Maps are always on, so there is nothing to switch off.
/// </summary>
/// <remarks>ClubCreationEnabled left out keeps the saved value, so an older admin screen never switches it off by mistake.</remarks>
public sealed record UpdateSettingsRequest(bool SignUpEnabled, bool RequireAdminApproval, bool? ClubCreationEnabled = null);

public sealed class UpdateSettings(VelomineDbContext db, SettingsReader settings, IOptions<SmtpOptions> smtp, IOptions<SsoOptions> sso)
    : Endpoint<UpdateSettingsRequest, SettingsResponse>
{
    public override void Configure()
    {
        Put("admin/settings");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Accepts<UpdateSettingsRequest>("application/json").Produces<SettingsResponse>(200).Produces(401).Produces(403), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateSettingsRequest req, CancellationToken ct)
    {
        var row = await db.Set<ServerSettings>().FirstOrDefaultAsync(ct);
        if (row is null) db.Add(row = new ServerSettings());

        row.SignUpEnabled = req.SignUpEnabled;
        row.RequireAdminApproval = req.RequireAdminApproval;
        if (req.ClubCreationEnabled is { } clubCreation) row.ClubCreationEnabled = clubCreation;
        await db.SaveChangesAsync(ct);

        await Send.OkAsync(await GetSettings.StatusAsync(settings, smtp.Value, sso.Value, ct), ct);
    }
}
