using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;

namespace Velomine.Server.Features.Training;

public sealed class MoveTrainingSessionRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    /// <summary>The day to move it to, on the member's own calendar.</summary>
    public required DateOnly LocalDate { get; set; }
}

public sealed class MoveTrainingSessionValidator : Validator<MoveTrainingSessionRequest>
{
    public MoveTrainingSessionValidator() => RuleFor(x => x.LocalDate).NotEmpty();
}

/// <summary>
/// Moving a session by hand: to any day left this week, a day the rider can ride or not. A hard day is refused next to
/// another hard day or next to the long ride, and the refusal names that and the nearest day that works (W1); the day
/// the rider gives it is kept, because the nightly planning never rewrites a session that was moved.
/// </summary>
public sealed class MoveTrainingSession(VelomineDbContext db, TimeProvider time)
    : Endpoint<MoveTrainingSessionRequest, TrainingWeeksResponse>
{
    public override void Configure()
    {
        Post("training/sessions/{id}/move");
        Description(d => d.Accepts<MoveTrainingSessionRequest>("application/json")
            .Produces<TrainingWeeksResponse>(200).ProducesProblem(400).ProducesProblem(401).Produces(404)
            .ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(MoveTrainingSessionRequest req, CancellationToken ct)
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
        var weekStart = Periods.StartOf(clock.Today, Periods.Week, clock.FirstDayOfWeek);
        var weekEnd = weekStart.AddDays(6);
        if (session.State is not (TrainingSessionStates.Planned or TrainingSessionStates.Moved)
            || req.LocalDate < clock.Today || req.LocalDate > weekEnd || req.LocalDate == session.LocalDate)
        {
            AddError("Move a session still to be ridden to another day of this week.");
            await Send.ErrorsAsync(StatusCodes.Status409Conflict, ct);
            return;
        }

        var week = await db.TrainingSessions.AsNoTracking()
            .Where(s => s.UserId == userId && s.LocalDate >= weekStart.AddDays(-1) && s.LocalDate <= weekEnd.AddDays(1))
            .ToListAsync(ct);
        if (SessionAdaptation.Refusal(week, session, req.LocalDate) is { } refusal)
        {
            var nearest = SessionAdaptation.Days(week, session, clock)
                .Where(d => d.Allowed)
                .OrderBy(d => Math.Abs(d.LocalDate.DayNumber - req.LocalDate.DayNumber))
                .ThenBy(d => d.LocalDate.DayNumber)
                .FirstOrDefault();
            AddError(refusal switch
            {
                MoveRefusals.NextToHard => "A hard day cannot sit next to another hard day.",
                MoveRefusals.NextToLongRide => "A hard day cannot sit next to the long ride.",
                MoveRefusals.HasSession => "That day already has a session.",
                _ => "The week cannot carry another loaded day.",
            } + (nearest is { } day ? $" The nearest day that works is {day.LocalDate:yyyy-MM-dd}." : " No other day of this week works."));
            await Send.ErrorsAsync(StatusCodes.Status409Conflict, ct);
            return;
        }

        SessionAdaptation.Move(user, time, db, session, req.LocalDate);
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await TrainingWeekView.OfAsync(db, user, plan, clock, time, ct), ct);
    }
}
