using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Privacy;

public sealed class CreatePrivacyZoneRequest
{
    public required string Name { get; set; }

    public required double Latitude { get; set; }

    public required double Longitude { get; set; }

    /// <summary>200 to 1609 metres (one mile).</summary>
    public required int RadiusM { get; set; }
}

public sealed class CreatePrivacyZoneValidator : Validator<CreatePrivacyZoneRequest>
{
    public CreatePrivacyZoneValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(60)
            .Must(name => name.Trim().Length > 0).WithMessage("Give the place a name.");
        RuleFor(x => x.Latitude).InclusiveBetween(-90, 90);
        RuleFor(x => x.Longitude).InclusiveBetween(-180, 180);
        RuleFor(x => x.RadiusM).InclusiveBetween(PrivacyValues.MinRadiusM, PrivacyValues.MaxRadiusM);
    }
}

/// <summary>Saves a place whose surroundings every non-owner view hides. Ten per member.</summary>
public sealed class CreatePrivacyZone(VelomineDbContext db, TimeProvider time)
    : Endpoint<CreatePrivacyZoneRequest, PrivacyZoneResponse>
{
    public override void Configure()
    {
        Post("privacy/zones");
        Description(d => d.Accepts<CreatePrivacyZoneRequest>("application/json").Produces<PrivacyZoneResponse>(201).ProducesProblem(400).Produces(401).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(CreatePrivacyZoneRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var count = await db.PrivacyZones.CountAsync(z => z.UserId == userId, ct);
        if (count >= PrivacyValues.MaxZones)
        {
            AddError($"Save at most {PrivacyValues.MaxZones} places.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var zone = new PrivacyZone
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            Name = req.Name.Trim(),
            Latitude = req.Latitude,
            Longitude = req.Longitude,
            RadiusM = req.RadiusM,
            CreatedAt = time.GetUtcNow(),
        };
        db.PrivacyZones.Add(zone);
        await db.SaveChangesAsync(ct);
        await Send.ResponseAsync(
            new PrivacyZoneResponse(zone.Id, zone.Name, zone.Latitude, zone.Longitude, zone.RadiusM), 201, ct);
    }
}
