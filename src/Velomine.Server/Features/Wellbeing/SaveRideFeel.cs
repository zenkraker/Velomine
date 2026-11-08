using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Wellbeing;

public sealed class SaveRideFeelRequest
{
    public Guid Id { get; set; }

    /// <summary>1 easy, 10 maximal.</summary>
    public required int Rpe { get; set; }

    /// <summary>Optional note, private to the owner.</summary>
    public string? Notes { get; set; }
}

public sealed class SaveRideFeelValidator : Validator<SaveRideFeelRequest>
{
    public SaveRideFeelValidator()
    {
        RuleFor(x => x.Rpe).InclusiveBetween(1, 10);
        RuleFor(x => x.Notes).MaximumLength(500);
    }
}

/// <summary>How hard a ride felt, with an optional note. Only the owner can write it.</summary>
public sealed class SaveRideFeel(VelomineDbContext db, TimeProvider time)
    : Endpoint<SaveRideFeelRequest, RideFeelResponse>
{
    public override void Configure()
    {
        Put("rides/{id}/feel");
        Description(d => d.Accepts<SaveRideFeelRequest>("application/json").Produces<RideFeelResponse>(200).ProducesProblem(400).Produces(401).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(SaveRideFeelRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        if (!await WellbeingRules.HasConsentAsync(db, userId, ct))
        {
            AddError("Accept the wellbeing terms first.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var ride = await db.Rides.AsNoTracking()
            .Where(r => r.Id == req.Id && r.UserId == userId)
            .Select(r => new { r.Status })
            .FirstOrDefaultAsync(ct);
        if (ride is null || ride.Status != RideStatus.Ready)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var feel = await db.RideFeels.FirstOrDefaultAsync(f => f.RideId == req.Id, ct);
        if (feel is null)
        {
            feel = new RideFeel { RideId = req.Id };
            db.RideFeels.Add(feel);
        }

        feel.Rpe = req.Rpe;
        feel.Notes = string.IsNullOrWhiteSpace(req.Notes) ? null : req.Notes.Trim();
        feel.UpdatedAt = time.GetUtcNow();
        await db.SaveChangesAsync(ct);

        await Send.OkAsync(new RideFeelResponse(false, feel.Rpe, feel.Notes), ct);
    }
}
