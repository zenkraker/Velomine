using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Analytics;

public sealed class CreateGoalRequest
{
    /// <summary>week, month or year.</summary>
    public required string Period { get; set; }

    /// <summary>distance (metres), elevation (metres), time (riding seconds) or rides (a count).</summary>
    public required string Metric { get; set; }

    public required double Target { get; set; }
}

/// <summary>Changing a goal's target. To count something else, delete the goal and add another.</summary>
public sealed class UpdateGoalRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    public required double Target { get; set; }
}

public sealed class CreateGoalValidator : Validator<CreateGoalRequest>
{
    public CreateGoalValidator()
    {
        RuleFor(x => x.Period).Must(p => Periods.All.Contains(p)).WithMessage("Choose week, month or year.");
        RuleFor(x => x.Metric).Must(m => GoalMetrics.All.Contains(m)).WithMessage("Choose distance, elevation, time or rides.");
        RuleFor(x => x.Target).GreaterThan(0).LessThanOrEqualTo(GoalLimits.MaxTarget);
    }
}

public sealed class UpdateGoalValidator : Validator<UpdateGoalRequest>
{
    public UpdateGoalValidator() => RuleFor(x => x.Target).GreaterThan(0).LessThanOrEqualTo(GoalLimits.MaxTarget);
}

public static class GoalLimits
{
    /// <summary>Enough for 100,000 km or a year of seconds; stops typing mistakes such as an extra few zeros.</summary>
    public const double MaxTarget = 100_000_000;
}

public sealed class CreateGoal(VelomineDbContext db, TimeProvider time) : Endpoint<CreateGoalRequest, GoalResponse>
{
    public override void Configure()
    {
        Post("analytics/goals");
        Description(d => d.Accepts<CreateGoalRequest>("application/json").Produces<GoalResponse>(201).ProducesProblem(400).Produces(401).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(CreateGoalRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        if (await db.Set<Goal>().AnyAsync(g => g.UserId == userId && g.Period == req.Period && g.Metric == req.Metric, ct))
        {
            AddError("You already have a goal for that. Change its target instead.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var goal = new Goal
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            Period = req.Period,
            Metric = req.Metric,
            Target = req.Target,
            CreatedAt = time.GetUtcNow(),
        };
        db.Add(goal);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException
        { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            // Two requests passed the check together; the unique index is the real guard.
            AddError("You already have a goal for that. Change its target instead.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        await Send.ResponseAsync((await GoalProgress.ForAsync(db, userId, clock, [goal], ct))[0], 201, ct);
    }
}

public sealed class UpdateGoal(VelomineDbContext db, TimeProvider time) : Endpoint<UpdateGoalRequest, GoalResponse>
{
    public override void Configure()
    {
        Put("analytics/goals/{id}");
        Description(d => d.Accepts<UpdateGoalRequest>("application/json").Produces<GoalResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateGoalRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var goal = await db.Set<Goal>().FirstOrDefaultAsync(g => g.Id == req.Id && g.UserId == userId, ct);
        if (goal is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        goal.Target = req.Target;
        await db.SaveChangesAsync(ct);

        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        await Send.OkAsync((await GoalProgress.ForAsync(db, userId, clock, [goal], ct))[0], ct);
    }
}
