using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Training;

/// <summary>
/// The three answers of the setup. <see cref="LongRideDay"/> null means "Velomine picks"; <see cref="MaxHeartRateKnown"/>
/// false is "I don't know". <see cref="BirthYear"/> is sent when the account has none, and <see cref="TimeZone"/> the
/// device's, kept only when the account has none, so midnight and 07:00 are the rider's and not UTC.
/// </summary>
public sealed record SaveTrainingPlanRequest(
    string Goal,
    string[] Days,
    int HoursPerWeek,
    string? LongRideDay,
    bool MaxHeartRateKnown,
    int? MaxHeartRate,
    int? BirthYear,
    string? TimeZone,
    int? UtcOffsetMinutes = null);

public sealed class SaveTrainingPlanValidator : Validator<SaveTrainingPlanRequest>
{
    public SaveTrainingPlanValidator()
    {
        RuleFor(x => x.Goal).Must(g => TrainingGoals.All.Contains(g))
            .WithMessage("Choose one of the goals the setup offers.");
        RuleFor(x => x.Days).NotEmpty().WithMessage("Choose at least one day you can ride.");
        RuleFor(x => x.Days).Must(d => d.Distinct().Count() == d.Length)
            .WithMessage("Choose each day once.");
        RuleFor(x => x.Days).Must(d => d.All(day => WeekDays.TryParse(day, out _)))
            .WithMessage("Use days such as monday or sunday.");
        RuleFor(x => x.HoursPerWeek).InclusiveBetween(1, 30)
            .WithMessage("Enter the hours you can ride in a week: 1 to 30.");
        RuleFor(x => x.LongRideDay).Must(d => d is null || WeekDays.TryParse(d, out _))
            .WithMessage("Use a day such as saturday, or leave it to Velomine.");
        RuleFor(x => x.LongRideDay).Must((req, d) => d is null || req.Days.Contains(d))
            .WithMessage("The long ride must be on one of the days you can ride.");
        RuleFor(x => x.MaxHeartRate).InclusiveBetween(HeartRates.MinMax, HeartRates.MaxMax)
            .When(x => x.MaxHeartRate is not null);
        RuleFor(x => x.BirthYear).InclusiveBetween(1900, DateTime.UtcNow.Year - 10)
            .When(x => x.BirthYear is not null)
            .WithMessage("Enter a year of birth from 1900 to ten years ago.");
        RuleFor(x => x.UtcOffsetMinutes).InclusiveBetween(-14 * 60, 14 * 60)
            .When(x => x.UtcOffsetMinutes is not null);
        RuleFor(x => x.TimeZone).MaximumLength(64)
            .Must(z => z is null || TimeZoneInfo.TryFindSystemTimeZoneById(z, out _))
            .WithMessage("Use a time zone name such as Europe/Rome.");
    }
}

/// <summary>
/// Starting auto training, and changing the setup afterwards: both are this save. A typed maximum goes through the
/// heart-rate rules (<see cref="SetHeartRateValue"/>), never a copy, and the plan is on afterwards.
/// </summary>
public sealed class SaveTrainingPlan(
    VelomineDbContext db, SetHeartRateValue setHeartRate, TimeProvider time)
    : Endpoint<SaveTrainingPlanRequest, TrainingPlanResponse>
{
    public override void Configure()
    {
        Put("training/plan");
        Description(d => d.Accepts<SaveTrainingPlanRequest>("application/json")
            .Produces<TrainingPlanResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(SaveTrainingPlanRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, ct);

        // The 2:1 cycle from 50 works from the age, so the setup cannot be finished without a year of birth.
        if (req.BirthYear is { } birthYear) user.BirthYear = birthYear;
        else if (user.BirthYear is null)
        {
            await Send.ResultAsync(TypedResults.Problem(
                "Enter your year of birth.", statusCode: StatusCodes.Status400BadRequest));
            return;
        }

        // An account with no time zone yet takes the device's, so the rider's own midnight and 07:00 apply.
        if (user.TimeZone is null && DeviceZone.Of(req.TimeZone, req.UtcOffsetMinutes, time) is { } zone)
            user.TimeZone = zone;

        var max = HeartRates.For(user, time).Max;
        if (req.MaxHeartRate is { } bpm)
            await setHeartRate.SetAsync(user, HeartRateKinds.Max, bpm, HeartRateSources.Manual, null, ct);
        // "I don't know" takes back a number the rider typed; a measured one stays, because Velomine knows it.
        else if (!req.MaxHeartRateKnown && max is { Source: HeartRateSources.Manual })
            await setHeartRate.ClearAsync(user, HeartRateKinds.Max, ct);
        else if (req.MaxHeartRateKnown && max is null or { Source: FtpSources.Estimate })
        {
            await Send.ResultAsync(TypedResults.Problem(
                "Enter your maximum heart rate, or choose I don't know.", statusCode: StatusCodes.Status400BadRequest));
            return;
        }

        var days = req.Days.Select(day =>
        {
            WeekDays.TryParse(day, out var parsed);
            return (int)parsed;
        }).Order().ToArray();

        var plan = await db.TrainingPlans.FirstOrDefaultAsync(p => p.UserId == userId, ct);
        if (plan is null)
        {
            plan = new TrainingPlan { UserId = userId };
            db.TrainingPlans.Add(plan);
        }

        Apply(plan, req, days, time);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException
        { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            // Two saves at once: the other one created the plan first. The same answers go onto that row.
            db.Entry(plan).State = EntityState.Detached;
            plan = await db.TrainingPlans.FirstAsync(p => p.UserId == userId, ct);
            Apply(plan, req, days, time);
            await db.SaveChangesAsync(ct);
        }

        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        await Send.OkAsync(await TrainingPlanView.OfAsync(db, user, clock, time, ct), ct);
    }

    /// <summary>The rider's answers, as starting and changing both write them.</summary>
    private static void Apply(TrainingPlan plan, SaveTrainingPlanRequest req, int[] days, TimeProvider time)
    {
        plan.Goal = req.Goal;
        plan.Days = days;
        plan.HoursPerWeek = req.HoursPerWeek;
        plan.LongRideDay = req.LongRideDay is { } longRide && WeekDays.TryParse(longRide, out var longRideDay)
            ? (int)longRideDay
            : null;
        plan.IsOn = true;
        plan.UpdatedAt = time.GetUtcNow();
    }
}
