using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

/// <summary>The fields of a maintenance reminder.</summary>
public interface IReminderFields
{
    string Name { get; }
    double? IntervalDistanceM { get; }
    double? IntervalHours { get; }
    int? IntervalMonths { get; }
}

public sealed class CreateReminderRequest : IReminderFields
{
    /// <summary>From the address.</summary>
    public Guid BikeId { get; set; }

    /// <summary>What to do, such as "Lube the chain".</summary>
    public required string Name { get; set; }

    /// <summary>Due after this many metres on the bike, riding hours or months since it was last done: whichever comes first. At least one is needed.</summary>
    public double? IntervalDistanceM { get; set; }

    public double? IntervalHours { get; set; }

    public int? IntervalMonths { get; set; }

    /// <summary>The day it was last done, today or earlier. Leave out to start counting today.</summary>
    public DateOnly? LastDoneOn { get; set; }
}

/// <summary>Changing a reminder: all fields are sent each time. Marking it done is a separate call.</summary>
public sealed class UpdateReminderRequest : IReminderFields
{
    /// <summary>From the address.</summary>
    public Guid BikeId { get; set; }

    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    public required string Name { get; set; }

    public double? IntervalDistanceM { get; set; }

    public double? IntervalHours { get; set; }

    public int? IntervalMonths { get; set; }

    /// <summary>A paused reminder keeps its place but shows no state and sends no notifications.</summary>
    public bool IsPaused { get; set; }
}

public class ReminderFieldsValidator<T> : Validator<T> where T : IReminderFields
{
    public ReminderFieldsValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x).Must(x => x.IntervalDistanceM.HasValue || x.IntervalHours.HasValue || x.IntervalMonths.HasValue)
            .WithMessage("Set at least one of distance, hours or months.");
        RuleFor(x => x.IntervalDistanceM).InclusiveBetween(1, 10_000_000).When(x => x.IntervalDistanceM.HasValue);
        RuleFor(x => x.IntervalHours).InclusiveBetween(0.1, 100_000).When(x => x.IntervalHours.HasValue);
        RuleFor(x => x.IntervalMonths).InclusiveBetween(1, 600).When(x => x.IntervalMonths.HasValue);
    }
}

public sealed class CreateReminderValidator : ReminderFieldsValidator<CreateReminderRequest>;

public sealed class UpdateReminderValidator : ReminderFieldsValidator<UpdateReminderRequest>;

public sealed class CreateReminder(VelomineDbContext db, TimeProvider time) : Endpoint<CreateReminderRequest, BikeDetailResponse>
{
    public override void Configure()
    {
        Post("bikes/{bikeId}/reminders");
        Description(d => d.Accepts<CreateReminderRequest>("application/json").Produces<BikeDetailResponse>(201).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CreateReminderRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var bike = await db.Bikes.Include(b => b.Components).FirstOrDefaultAsync(b => b.Id == req.BikeId && b.UserId == userId, ct);
        if (bike is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var lastDone = req.LastDoneOn ?? clock.Today;
        if (lastDone > clock.Today)
        {
            ThrowError("The day it was last done cannot be in the future.");
            return;
        }

        db.MaintenanceReminders.Add(new MaintenanceReminder
        {
            Id = Guid.CreateVersion7(),
            BikeId = bike.Id,
            Name = req.Name.Trim(),
            IntervalDistanceM = req.IntervalDistanceM,
            IntervalHours = req.IntervalHours,
            IntervalMonths = req.IntervalMonths,
            LastDoneOn = lastDone,
            CreatedAt = time.GetUtcNow(),
        });
        await db.SaveChangesAsync(ct);
        await Send.CreatedAtAsync<GetBike>(new { id = bike.Id }, await BikeQueries.DetailAsync(db, bike, clock, ct), cancellation: ct);
    }
}

public sealed class UpdateReminder(VelomineDbContext db, TimeProvider time) : Endpoint<UpdateReminderRequest, BikeDetailResponse>
{
    public override void Configure()
    {
        Put("bikes/{bikeId}/reminders/{id}");
        Description(d => d.Accepts<UpdateReminderRequest>("application/json").Produces<BikeDetailResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateReminderRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var bike = await db.Bikes.Include(b => b.Components).FirstOrDefaultAsync(b => b.Id == req.BikeId && b.UserId == userId, ct);
        var reminder = bike is null ? null : await db.MaintenanceReminders.FirstOrDefaultAsync(r => r.Id == req.Id && r.BikeId == bike.Id, ct);
        if (bike is null || reminder is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        reminder.Name = req.Name.Trim();
        reminder.IntervalDistanceM = req.IntervalDistanceM;
        reminder.IntervalHours = req.IntervalHours;
        reminder.IntervalMonths = req.IntervalMonths;
        reminder.IsPaused = req.IsPaused;

        // Longer intervals can take a reminder back below a level it was already told about: it may then tell again.
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var wear = BikeWear.Measure(reminder.LastDoneOn, null, reminder.IntervalDistanceM, reminder.IntervalHours, reminder.IntervalMonths,
            await BikeQueries.RideUsesAsync(db, bike.Id, clock, ct), clock.Today);
        MaintenanceNotifications.Rearm(reminder, wear.Status);

        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await BikeQueries.DetailAsync(db, bike, clock, ct), ct);
    }
}
