using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;
using Velomine.Server.Features.Wellbeing;

namespace Velomine.Server.Features.Coach;

public sealed class CoachWellbeingRequest
{
    public Guid ClubId { get; set; }

    public Guid UserId { get; set; }

    /// <summary>How many days to show, ending today: 7 to 366, default 30.</summary>
    [QueryParam]
    public int? Days { get; set; }
}

public sealed class CoachWellbeingValidator : Validator<CoachWellbeingRequest>
{
    public CoachWellbeingValidator() => RuleFor(x => x.Days).InclusiveBetween(7, 366).When(x => x.Days.HasValue);
}

/// <summary>
/// An athlete's check-in scores and per-ride RPE, only when wellbeing was shared. Free-text notes are never
/// returned here: they stay with the member.
/// </summary>
public sealed class GetCoachWellbeing(VelomineDbContext db, TimeProvider time)
    : Endpoint<CoachWellbeingRequest, CoachWellbeingResponse>
{
    public override void Configure()
    {
        Get("clubs/{clubId}/athletes/{userId}/wellbeing");
        Description(d => d.Produces<CoachWellbeingResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CoachWellbeingRequest req, CancellationToken ct)
    {
        var viewerId = User.UserId();
        if (!await SharingRules.CanViewAsync(db, req.ClubId, viewerId, req.UserId, DataTypes.Wellbeing, ct))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var clock = await MemberClock.ForAsync(db, req.UserId, time, ct);
        var from = clock.Today.AddDays(-((req.Days ?? 30) - 1));

        var checkIns = await db.DailyCheckIns.AsNoTracking()
            .Where(c => c.UserId == req.UserId && c.LocalDate >= from && c.LocalDate <= clock.Today)
            .OrderBy(c => c.LocalDate)
            .ToListAsync(ct);

        var rides = await (
                from f in db.RideFeels.AsNoTracking()
                join r in db.Rides.AsNoTracking() on f.RideId equals r.Id
                where r.UserId == req.UserId && r.Status == RideStatus.Ready
                select new { f.RideId, f.Rpe, r.StartTime, r.UtcOffsetMinutes })
            .ToListAsync(ct);
        var rpes = rides
            .Where(r => r.StartTime is not null)
            .Select(r => new CoachRpeResponse(
                r.RideId,
                clock.LocalDateOf(r.StartTime!.Value, r.UtcOffsetMinutes),
                r.Rpe))
            .Where(r => r.Date >= from && r.Date <= clock.Today)
            .OrderBy(r => r.Date)
            .ToArray();

        await SharingRules.RecordViewAsync(
            db, time, req.UserId, req.ClubId, viewerId,
            await CoachQueries.ViewerNameAsync(db, viewerId, ct), ViewKinds.Wellbeing, ct);
        await Send.OkAsync(new CoachWellbeingResponse(
            [.. checkIns.Select(CheckInResponse.From)],
            rpes), ct);
    }
}
