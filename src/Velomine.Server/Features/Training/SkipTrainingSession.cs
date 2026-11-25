using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Demo;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Notifications.Email;

namespace Velomine.Server.Features.Training;

public sealed class SkipTrainingSessionRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    /// <summary>One of <see cref="TrainingSkipReasons"/> when the rider said why; null when they did not.</summary>
    public string? Reason { get; set; }

    /// <summary>The answer to "Skip the rest of this week?": every session left this week goes, and none of them moves.</summary>
    public bool RestOfWeek { get; set; }
}

public sealed class SkipTrainingSessionValidator : Validator<SkipTrainingSessionRequest>
{
    public SkipTrainingSessionValidator() => RuleFor(x => x.Reason)
        .Must(reason => reason is null || TrainingSkipReasons.All.Contains(reason))
        .WithMessage("Use one of the reasons the app offers, or leave it out.");
}

/// <summary>
/// Skipping a session, with the reason the rider chose when they gave one, or the rest of the week after it. A skipped
/// session stays where it is and is never piled onto a later day; the week the answer carries says how many have been
/// skipped, which is what the app offers the rest of the week from. Owner only: the session is the caller's own, and the
/// demo refuses the rest of the week, which one visitor would empty for the next one until 03:00 UTC.
/// </summary>
public sealed class SkipTrainingSession(VelomineDbContext db, TimeProvider time, IOptions<DemoOptions> demo)
    : Endpoint<SkipTrainingSessionRequest, TrainingWeeksResponse>
{
    public override void Configure()
    {
        Post("training/sessions/{id}/skip");
        Description(d => d.Accepts<SkipTrainingSessionRequest>("application/json")
            .Produces<TrainingWeeksResponse>(200).ProducesProblem(400).ProducesProblem(401).Produces(404)
            .ProducesProblem(409).ProducesProblem(403), clearDefaults: true);
    }

    public override async Task HandleAsync(SkipTrainingSessionRequest req, CancellationToken ct)
    {
        // The rest of the week would leave the demo with no session until the 03:00 UTC reset: one day is a thing to
        // try, the whole week is what every later visitor inherits (DemoLock).
        if (req.RestOfWeek && demo.Value.Enabled)
        {
            await Send.ResultAsync(Results.Problem(DemoLock.Problem()));
            return;
        }

        var userId = User.UserId();
        var plan = await db.TrainingPlans.FirstOrDefaultAsync(p => p.UserId == userId && p.IsOn, ct);
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        var session = await db.TrainingSessions.FirstOrDefaultAsync(s => s.Id == req.Id && s.UserId == userId, ct);
        if (plan is null || user is null || session is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (session.State is TrainingSessionStates.Done or TrainingSessionStates.Missed)
        {
            AddError("That session is already behind.");
            await Send.ErrorsAsync(StatusCodes.Status409Conflict, ct);
            return;
        }

        var clock = MemberClock.For(user.TimeZone, user.FirstDayOfWeek, time);
        var weekStart = Periods.StartOf(session.LocalDate, Periods.Week, clock.FirstDayOfWeek);
        var weekEnd = weekStart.AddDays(6);
        var week = await db.TrainingSessions
            .Where(s => s.UserId == userId && s.LocalDate >= weekStart && s.LocalDate <= weekEnd)
            .OrderBy(s => s.LocalDate).ThenBy(s => s.Id)
            .ToListAsync(ct);

        Skip(session, req.Reason);
        // The rest of the week goes when the rider says so, and the answer offers it from the second skip on: a second
        // skipped session usually means the week is not going to happen. Nothing is moved to a later day.
        var open = week.Where(s => s.Id != session.Id && s.LocalDate >= session.LocalDate
            && s.State is TrainingSessionStates.Planned or TrainingSessionStates.Moved
                or TrainingSessionStates.Easy).ToList();
        if (req.RestOfWeek)
            foreach (var other in open) Skip(other, req.Reason);

        // One notification for the change the rider made, not one per session it took with it.
        var recipe = Recipes.ByCode(session.Recipe);
        var name = EmailLanguage.Resolve(user.Language) == "it" ? recipe.ItalianName : recipe.EnglishName;
        Notify.Add(db, time, user.Id, NotificationTypes.TrainingSkipped,
            TrainingNoticeSubject.Skipped(name, session.LocalDate), trainingSessionId: session.Id);

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateConcurrencyException)
        {
            // The night's planning removed and re-added the week's sessions, so the row this skip changed is gone: the
            // rider reads the sentence the app already gives when the week refuses the skip.
            AddError("That session is already behind.");
            await Send.ErrorsAsync(StatusCodes.Status409Conflict, ct);
            return;
        }
        await Send.OkAsync(await TrainingWeekView.OfAsync(db, user, plan, clock, time, ct), ct);
    }

    /// <summary>One session skipped, with its reason kept as the rider gave it; it stays on its own day.</summary>
    private static void Skip(TrainingSession session, string? reason)
    {
        session.State = TrainingSessionStates.Skipped;
        session.SkipReason = reason;
    }
}
