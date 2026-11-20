using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

/// <summary>Upper bounds of every zone but the open-ended top one, as fractions of the reference.</summary>
public sealed record SetZonesRequest(double[] Bounds);

public sealed class SetZonesValidator : Validator<SetZonesRequest>
{
    public SetZonesValidator()
    {
        RuleFor(x => x.Bounds)
            .Must(b => b is { Length: > 0 })
            .WithMessage("Send the bounds as fractions of the reference.")
            .Must(b => b is not null && b.All(v => v >= ZoneSets.MinBound && v <= ZoneSets.MaxBound))
            .WithMessage($"Use bounds between {ZoneSets.MinBound} and {ZoneSets.MaxBound}.")
            // Two decimals, so a bound is a percentage the rider can read back.
            .Must(b => b is not null && b.All(v => Math.Abs(v * 100 - Math.Round(v * 100)) < 1e-9))
            .WithMessage("Use at most two decimals.")
            .Must(b => b is not null && b.Zip(b.Skip(1), (lower, upper) => lower < upper).All(rising => rising))
            .WithMessage("Use bounds that rise.");
    }
}

/// <summary>
/// Sets the rider's own bounds for one set, and answers with all three as they are now. The bounds are fractions of
/// the reference, so they follow the FTP or the heart rate when it changes. Nothing stored at read changes: TRIMP keeps
/// the standard bounds.
/// </summary>
public sealed class SetZones(VelomineDbContext db, TimeProvider time) : Endpoint<SetZonesRequest, ZonesResponse>
{
    public override void Configure()
    {
        Put("accounts/me/zones/{set}");
        Description(d => d
            .Accepts<SetZonesRequest>("application/json")
            .Produces<ZonesResponse>(200)
            .ProducesProblem(400)
            .Produces(401)
            .Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(SetZonesRequest req, CancellationToken ct)
    {
        var set = Route<string>("set")!;
        if (!ZoneSets.IsKnown(set))
        {
            await Send.NotFoundAsync(ct);
            return;
        }
        if (req.Bounds.Length != ZoneSets.BoundCount(set))
        {
            await Send.ResultAsync(TypedResults.Problem(
                $"Use {ZoneSets.BoundCount(set)} bounds for {set}.",
                statusCode: StatusCodes.Status400BadRequest));
            return;
        }

        var user = await db.Users.FirstAsync(u => u.Id == User.UserId(), ct);
        switch (set)
        {
            case ZoneSets.Power:
                user.PowerZoneBounds = req.Bounds;
                break;
            case ZoneSets.HeartRateMax:
                user.HeartRateMaxZoneBounds = req.Bounds;
                break;
            default:
                user.HeartRateThresholdZoneBounds = req.Bounds;
                break;
        }
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(ZoneSets.Of(user, time), ct);
    }
}

/// <summary>Back to automatic: the set's own bounds are removed and the standard ones apply again.</summary>
public sealed class ResetZones(VelomineDbContext db, TimeProvider time) : EndpointWithoutRequest<ZonesResponse>
{
    public override void Configure()
    {
        Delete("accounts/me/zones/{set}");
        Description(d => d.Produces<ZonesResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var set = Route<string>("set")!;
        if (!ZoneSets.IsKnown(set))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var user = await db.Users.FirstAsync(u => u.Id == User.UserId(), ct);
        switch (set)
        {
            case ZoneSets.Power:
                user.PowerZoneBounds = null;
                break;
            case ZoneSets.HeartRateMax:
                user.HeartRateMaxZoneBounds = null;
                break;
            default:
                user.HeartRateThresholdZoneBounds = null;
                break;
        }
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(ZoneSets.Of(user, time), ct);
    }
}
