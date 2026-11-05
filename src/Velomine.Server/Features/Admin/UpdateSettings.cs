using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Server;

namespace Velomine.Server.Features.Admin;

/// <summary>
/// Saving overrides the environment values. An empty MapTileUrl means "no map background".
/// Only these four can be changed here; SMTP and single sign-on are set with environment variables.
/// </summary>
public sealed record UpdateSettingsRequest(bool SignUpEnabled, bool RequireAdminApproval, string? MapTileUrl, string? MapAttribution);

public sealed class UpdateSettingsValidator : Validator<UpdateSettingsRequest>
{
    public UpdateSettingsValidator()
    {
        RuleFor(x => x.MapTileUrl)
            .MaximumLength(500)
            .Must(u => string.IsNullOrWhiteSpace(u) || new MapOptions { TileUrl = u }.UsableTileUrl is not null)
            .WithMessage("Use an http or https address with {z}, {x} and {y}, for example https://tile.openstreetmap.org/{z}/{x}/{y}.png");
        RuleFor(x => x.MapAttribution).MaximumLength(200);
    }
}

public sealed class UpdateSettings(VelomineDbContext db, SettingsReader settings, IOptions<SmtpOptions> smtp, IOptions<SsoOptions> sso)
    : Endpoint<UpdateSettingsRequest, SettingsResponse>
{
    public override void Configure()
    {
        Put("admin/settings");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Accepts<UpdateSettingsRequest>("application/json").Produces<SettingsResponse>(200).ProducesProblem(400).Produces(401).Produces(403), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateSettingsRequest req, CancellationToken ct)
    {
        var row = await db.Set<ServerSettings>().FirstOrDefaultAsync(ct);
        if (row is null) db.Add(row = new ServerSettings());

        row.SignUpEnabled = req.SignUpEnabled;
        row.RequireAdminApproval = req.RequireAdminApproval;
        row.MapTileUrl = req.MapTileUrl?.Trim() ?? "";
        row.MapAttribution = string.IsNullOrWhiteSpace(req.MapAttribution) ? null : req.MapAttribution.Trim();
        await db.SaveChangesAsync(ct);

        await Send.OkAsync(await GetSettings.StatusAsync(settings, smtp.Value, sso.Value, ct), ct);
    }
}
