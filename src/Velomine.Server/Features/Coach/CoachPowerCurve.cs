using FastEndpoints;
using FluentValidation;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Features.Coach;

public sealed class CoachPowerCurveRequest
{
    public Guid ClubId { get; set; }

    public Guid UserId { get; set; }

    /// <summary>How many days to cover, ending today: 7 to 730, default 90.</summary>
    [QueryParam]
    public int? Days { get; set; }
}

public sealed class CoachPowerCurveValidator : Validator<CoachPowerCurveRequest>
{
    public CoachPowerCurveValidator() => RuleFor(x => x.Days).InclusiveBetween(7, 730).When(x => x.Days.HasValue);
}

/// <summary>An athlete's power curve, read-only and only when training was shared. No weight-derived metrics.</summary>
public sealed class GetCoachPowerCurve(VelomineDbContext db, TimeProvider time)
    : Endpoint<CoachPowerCurveRequest, PowerCurveResponse>
{
    public override void Configure()
    {
        Get("clubs/{clubId}/athletes/{userId}/power-curve");
        Description(d => d.Produces<PowerCurveResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CoachPowerCurveRequest req, CancellationToken ct)
    {
        var viewerId = User.UserId();
        if (!await SharingRules.CanViewAsync(db, req.ClubId, viewerId, req.UserId, DataTypes.Analytics, ct))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var clock = await MemberClock.ForAsync(db, req.UserId, time, ct);
        var privacy = await PrivacyRules.LoadCurrentAsync(db, req.UserId, ct);
        if (privacy.HidePower)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var curve = await FitnessQueries.PowerCurveAsync(
            db, clock, req.UserId, req.Days ?? 90, includeBodyMetrics: false, ct);
        await SharingRules.RecordViewAsync(
            db, time, req.UserId, req.ClubId, viewerId,
            await CoachQueries.ViewerNameAsync(db, viewerId, ct), ViewKinds.PowerCurve, ct);
        await Send.OkAsync(curve, ct);
    }
}
