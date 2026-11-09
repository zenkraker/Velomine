using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Rides;

public sealed class SetRideTypeRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    /// <summary>road, gravel, mountain or track; null to leave it unsaid.</summary>
    public string? Discipline { get; set; }

    /// <summary>none or ebike; null to leave it unsaid.</summary>
    public string? Assist { get; set; }

    /// <summary>outdoor, indoor or virtual; null to leave it unsaid.</summary>
    public string? Environment { get; set; }

    /// <summary>True for a commute; null when not stated.</summary>
    public bool? Commute { get; set; }
}

public sealed class SetRideTypeValidator : Validator<SetRideTypeRequest>
{
    public SetRideTypeValidator()
    {
        RuleFor(x => x.Discipline).Must(v => v is null || Disciplines.All.Contains(v))
            .WithMessage("Choose road, gravel, mountain or track, or leave it empty.");
        RuleFor(x => x.Assist).Must(v => v is null || Assists.All.Contains(v))
            .WithMessage("Choose none or ebike, or leave it empty.");
        RuleFor(x => x.Environment).Must(v => v is null || Environments.All.Contains(v))
            .WithMessage("Choose outdoor, indoor or virtual, or leave it empty.");
    }
}

/// <summary>The rider's own classification of a ride. Each dimension is independent, and null means "not said".</summary>
public sealed class SetRideType(VelomineDbContext db) : Endpoint<SetRideTypeRequest, RideResponse>
{
    public override void Configure()
    {
        Put("rides/{id}/type");
        Description(d => d
            .Accepts<SetRideTypeRequest>("application/json")
            .Produces<RideResponse>(200)
            .ProducesProblem(400)
            .Produces(401)
            .Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(SetRideTypeRequest req, CancellationToken ct)
    {
        var ride = await db.Rides.FirstOrDefaultAsync(r => r.Id == req.Id && r.UserId == User.UserId(), ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        ride.Discipline = req.Discipline;
        ride.Assist = req.Assist;
        ride.Environment = req.Environment;
        ride.Commute = req.Commute;
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(RideResponse.From(ride), ct);
    }
}
