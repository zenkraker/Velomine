using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Training;

public sealed class MakeSessionEasyRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }
}

/// <summary>
/// "Make today easy": today's hard session becomes an endurance one, at the same length, and nothing else in the week
/// moves — the rider asked for an easier day, not for the week to be rewritten. "Back to the plan" undoes it the same
/// day. Owner only: the session is the caller's own, so there is no path to another member's week.
/// </summary>
public sealed class MakeSessionEasy(VelomineDbContext db, TimeProvider time)
    : Endpoint<MakeSessionEasyRequest, TrainingWeeksResponse>
{
    public override void Configure()
    {
        Post("training/sessions/{id}/easy");
        Description(d => d.Produces<TrainingWeeksResponse>(200).ProducesProblem(401).Produces(404).ProducesProblem(409),
            clearDefaults: true);
    }

    public override async Task HandleAsync(MakeSessionEasyRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var plan = await db.TrainingPlans.FirstOrDefaultAsync(p => p.UserId == userId && p.IsOn, ct);
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        var session = await db.TrainingSessions.FirstOrDefaultAsync(s => s.Id == req.Id && s.UserId == userId, ct);
        if (plan is null || user is null || session is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var clock = MemberClock.For(user.TimeZone, user.FirstDayOfWeek, time);
        if (session.LocalDate != clock.Today)
        {
            AddError("Make easy is for today's session only.");
            await Send.ErrorsAsync(StatusCodes.Status409Conflict, ct);
            return;
        }

        if (!await SessionAdaptation.MakeEasyAsync(
                db, user, plan, clock, time, session, TrainingEasyReasons.Asked, moveTheHardSession: false, ct))
        {
            AddError("That session cannot be made easier.");
            await Send.ErrorsAsync(StatusCodes.Status409Conflict, ct);
            return;
        }

        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await TrainingWeekView.OfAsync(db, user, plan, clock, time, ct), ct);
    }
}

public sealed class BackToTrainingPlanRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }
}

/// <summary>
/// "Back to the plan": the same day, and only while the session is not ticked, today's endurance replacement becomes
/// the hard session it was again, and the copy a check-in moved to another day goes with it.
/// </summary>
public sealed class BackToTrainingPlan(VelomineDbContext db, TimeProvider time)
    : Endpoint<BackToTrainingPlanRequest, TrainingWeeksResponse>
{
    public override void Configure()
    {
        Delete("training/sessions/{id}/easy");
        Description(d => d.Produces<TrainingWeeksResponse>(200).ProducesProblem(401).Produces(404).ProducesProblem(409),
            clearDefaults: true);
    }

    public override async Task HandleAsync(BackToTrainingPlanRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var plan = await db.TrainingPlans.FirstOrDefaultAsync(p => p.UserId == userId && p.IsOn, ct);
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        var session = await db.TrainingSessions.FirstOrDefaultAsync(s => s.Id == req.Id && s.UserId == userId, ct);
        if (plan is null || user is null || session is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var clock = MemberClock.For(user.TimeZone, user.FirstDayOfWeek, time);
        if (session.LocalDate != clock.Today || !await SessionAdaptation.BackToPlanAsync(db, clock, session, ct))
        {
            AddError("That session cannot go back to the plan.");
            await Send.ErrorsAsync(StatusCodes.Status409Conflict, ct);
            return;
        }

        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await TrainingWeekView.OfAsync(db, user, plan, clock, time, ct), ct);
    }
}
