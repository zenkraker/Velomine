using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

public sealed record SetHeartRateRequest(int Bpm);

public sealed class SetHeartRateValidator : Validator<SetHeartRateRequest>
{
    public SetHeartRateValidator()
    {
        // The range of each kind is checked in the handler: the maximum 120–230, the threshold 90–220.
        RuleFor(x => x.Bpm).InclusiveBetween(HeartRates.MinThreshold, HeartRates.MaxMax);
    }
}

/// <summary>
/// Sets the maximum or the threshold heart rate the rider typed, keeps the change in its history and answers with the
/// whole profile. A threshold at or above the maximum in use is refused.
/// </summary>
public sealed class SetHeartRate(VelomineDbContext db, SetHeartRateValue setValue, TimeProvider time)
    : Endpoint<SetHeartRateRequest, ProfileResponse>
{
    public override void Configure()
    {
        Put("accounts/me/heart-rate/{kind}");
        Description(d => d
            .Accepts<SetHeartRateRequest>("application/json")
            .Produces<ProfileResponse>(200)
            .ProducesProblem(400)
            .Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(SetHeartRateRequest req, CancellationToken ct)
    {
        var raw = Route<string>("kind")!;
        if (!HeartRateKinds.TryParse(raw, out var kind))
        {
            await Send.ResultAsync(TypedResults.Problem("Use max or threshold.", statusCode: StatusCodes.Status400BadRequest));
            return;
        }
        if (!HeartRateKinds.InRange(kind, req.Bpm))
        {
            await Send.ResultAsync(TypedResults.Problem(
                $"Use a maximum of {HeartRates.MinMax}–{HeartRates.MaxMax} bpm or a threshold of {HeartRates.MinThreshold}–{HeartRates.MaxThreshold} bpm.",
                statusCode: StatusCodes.Status400BadRequest));
            return;
        }

        var userId = User.UserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, ct);
        if (HeartRates.ThresholdProblem(kind, req.Bpm, HeartRates.For(user, time).Max) is { } problem)
        {
            await Send.ResultAsync(TypedResults.Problem(problem, statusCode: StatusCodes.Status400BadRequest));
            return;
        }

        await setValue.SetAsync(user, kind, req.Bpm, HeartRateSources.Manual, null, ct);
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await GetProfile.ProfileOfAsync(db, user, time, ct), ct);
    }
}

/// <summary>Back to the estimate: the set value is removed and its history says it was cleared.</summary>
public sealed class ClearHeartRate(VelomineDbContext db, SetHeartRateValue setValue, TimeProvider time)
    : EndpointWithoutRequest<ProfileResponse>
{
    public override void Configure()
    {
        Delete("accounts/me/heart-rate/{kind}");
        Description(d => d.Produces<ProfileResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        if (!HeartRateKinds.TryParse(Route<string>("kind")!, out var kind))
        {
            await Send.ResultAsync(TypedResults.Problem("Use max or threshold.", statusCode: StatusCodes.Status400BadRequest));
            return;
        }

        var userId = User.UserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, ct);
        await setValue.ClearAsync(user, kind, ct);
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await GetProfile.ProfileOfAsync(db, user, time, ct), ct);
    }
}
