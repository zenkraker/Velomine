using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Privacy;

public sealed class UpdatePrivacyRequest
{
    public required bool HideHeartRate { get; set; }

    public required bool HidePower { get; set; }

    public required bool HideCadence { get; set; }

    public required bool HideSpeed { get; set; }

    public required bool HideElevation { get; set; }

    public required bool HideTemperature { get; set; }

    /// <summary>Metres hidden at the start of every ride. 0 is off.</summary>
    public required int TrimStartM { get; set; }

    /// <summary>Metres hidden at the end of every ride. 0 is off.</summary>
    public required int TrimEndM { get; set; }
}

public sealed class UpdatePrivacyValidator : Validator<UpdatePrivacyRequest>
{
    public UpdatePrivacyValidator()
    {
        RuleFor(x => x.TrimStartM).InclusiveBetween(0, PrivacyValues.MaxTrimM);
        RuleFor(x => x.TrimEndM).InclusiveBetween(0, PrivacyValues.MaxTrimM);
    }
}

/// <summary>Sets every stream switch and both trims at once; the zones have their own endpoints.</summary>
public sealed class UpdatePrivacy(VelomineDbContext db, TimeProvider time)
    : Endpoint<UpdatePrivacyRequest, PrivacyResponse>
{
    public override void Configure()
    {
        Put("privacy/settings");
        Description(d => d.Accepts<UpdatePrivacyRequest>("application/json").Produces<PrivacyResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdatePrivacyRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var settings = await db.PrivacySettings.FirstOrDefaultAsync(s => s.UserId == userId, ct);
        if (settings is null)
        {
            settings = new PrivacySettings { UserId = userId };
            db.PrivacySettings.Add(settings);
        }

        settings.HideHeartRate = req.HideHeartRate;
        settings.HidePower = req.HidePower;
        settings.HideCadence = req.HideCadence;
        settings.HideSpeed = req.HideSpeed;
        settings.HideElevation = req.HideElevation;
        settings.HideTemperature = req.HideTemperature;
        settings.TrimStartM = req.TrimStartM;
        settings.TrimEndM = req.TrimEndM;
        settings.UpdatedAt = time.GetUtcNow();
        await db.SaveChangesAsync(ct);

        var zones = await db.PrivacyZones.AsNoTracking()
            .Where(z => z.UserId == userId)
            .OrderBy(z => z.Name)
            .ToListAsync(ct);
        await Send.OkAsync(PrivacyResponse.From(settings, zones), ct);
    }
}
