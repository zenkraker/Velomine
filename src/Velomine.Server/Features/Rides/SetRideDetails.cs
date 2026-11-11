using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Rides;

public sealed class SetRideDetailsRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    /// <summary>The member's name for the ride, up to 120 characters. Empty or only spaces clears it.</summary>
    public string? Title { get; set; }

    /// <summary>The member's words about the ride, up to 2,000 characters. Empty or only spaces clears it.</summary>
    public string? Description { get; set; }

    /// <summary>The ride's Version as the member last saw it. A different value means the ride changed meanwhile.</summary>
    public long Version { get; set; }
}

public sealed class SetRideDetailsValidator : Validator<SetRideDetailsRequest>
{
    public SetRideDetailsValidator()
    {
        RuleFor(x => RideText.Clean(x.Title)).MaximumLength(RideText.MaxTitle)
            .OverridePropertyName("title").WithMessage("The title can have up to 120 characters.");
        RuleFor(x => RideText.Clean(x.Description)).MaximumLength(RideText.MaxDescription)
            .OverridePropertyName("description").WithMessage("The description can have up to 2,000 characters.");
        RuleFor(x => x.Version).InclusiveBetween(0, (long)uint.MaxValue);
    }
}

/// <summary>
/// The member's title and description for a ride. Both replace what was there (so clearing works), and the ride's
/// concurrency token makes a second device or tab that saved first answer 409 instead of being overwritten.
/// </summary>
public sealed class SetRideDetails(VelomineDbContext db) : Endpoint<SetRideDetailsRequest, RideResponse>
{
    public override void Configure()
    {
        Put("rides/{id}/details");
        Description(d => d
            .Accepts<SetRideDetailsRequest>("application/json")
            .Produces<RideResponse>(200)
            .ProducesProblem(400)
            .Produces(401)
            .Produces(404)
            .ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(SetRideDetailsRequest req, CancellationToken ct)
    {
        var ride = await db.Rides.FirstOrDefaultAsync(r => r.Id == req.Id && r.UserId == User.UserId(), ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        db.Entry(ride).Property(r => r.Version).OriginalValue = (uint)req.Version;
        ride.Title = RideText.Clean(req.Title);
        ride.Description = RideText.Clean(req.Description);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateConcurrencyException)
        {
            AddError("The ride changed since you opened it. Reload it and try again.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        await Send.OkAsync(RideResponse.From(ride), ct);
    }
}
