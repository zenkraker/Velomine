using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Training;

/// <summary>An event as the API shows it. <see cref="Date"/> is the rider's local date; distances are metres.</summary>
public sealed record EventResponse(
    Guid Id,
    string Name,
    DateOnly Date,
    string Kind,
    double? DistanceM,
    double? ElevationGainM,
    string? Notes,
    Guid? RideId,
    DateTimeOffset CreatedAt)
{
    public static EventResponse From(TrainingEvent e) =>
        new(e.Id, e.Name, e.Date, e.Kind, e.DistanceM, e.ElevationGainM, e.Notes, e.RideId, e.CreatedAt);
}

/// <summary>What the rider types for an event: everything but its id and the ride it turned out to be.</summary>
public class EventRequest
{
    public required string Name { get; set; }

    /// <summary>The local date, <c>yyyy-MM-dd</c>.</summary>
    public DateOnly Date { get; set; }

    /// <summary>race, sportive, tour or other.</summary>
    public string Kind { get; set; } = TrainingEventKinds.Race;

    /// <summary>In metres.</summary>
    public double? DistanceM { get; set; }

    /// <summary>In metres.</summary>
    public double? ElevationGainM { get; set; }

    public string? Notes { get; set; }
}

public sealed class EventRequestValidator : Validator<EventRequest>
{
    public EventRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().WithMessage("Give the event a name.").Length(1, 100);
        RuleFor(x => x.Kind).Must(k => TrainingEventKinds.All.Contains(k))
            .WithMessage("Choose race, sportive, tour or other.");
        RuleFor(x => x.Date).NotEmpty().WithMessage("Choose the date of the event.");
        RuleFor(x => x.DistanceM).GreaterThanOrEqualTo(0).LessThanOrEqualTo(1_000_000);
        RuleFor(x => x.ElevationGainM).GreaterThanOrEqualTo(0).LessThanOrEqualTo(30_000);
        RuleFor(x => x.Notes).MaximumLength(500);
    }
}

/// <summary>The rider's events, the next ones first and then the past ones, newest first. At most 100.</summary>
public sealed record ListEventsResponse(EventResponse[] Events);

public sealed class ListEvents(VelomineDbContext db, TimeProvider time) : EndpointWithoutRequest<ListEventsResponse>
{
    private const int MaxShown = 100;

    public override void Configure()
    {
        Get("training/events");
        Description(d => d.Produces<ListEventsResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var today = (await MemberClock.ForAsync(db, userId, time, ct)).Today;

        // One query with a single limit: the next ones first (soonest first), then the past ones newest first.
        var events = await db.Events.AsNoTracking()
            .Where(e => e.UserId == userId)
            .OrderBy(e => e.Date >= today ? 0 : 1)
            .ThenBy(e => e.Date >= today ? e.Date : DateOnly.MaxValue)
            .ThenByDescending(e => e.Date)
            .ThenBy(e => e.Id)
            .Take(MaxShown)
            .ToListAsync(ct);
        await Send.OkAsync(new ListEventsResponse([.. events.Select(EventResponse.From)]), ct);
    }
}

public sealed class AddEvent(VelomineDbContext db, TimeProvider time) : Endpoint<EventRequest, EventResponse>
{
    public override void Configure()
    {
        Post("training/events");
        Description(d => d.Accepts<EventRequest>("application/json").Produces<EventResponse>(201)
            .ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(EventRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var e = new TrainingEvent { Id = Guid.CreateVersion7(), UserId = userId, CreatedAt = time.GetUtcNow() };
        Apply(e, req);
        db.Events.Add(e);
        // The rider's only ride of that day fills the event by itself; another event of the day leaves the choice
        // to them.
        await EventRideLink.ForEventAsync(db, await MemberClock.ForAsync(db, userId, time, ct), e, ct);
        await db.SaveChangesAsync(ct);
        await Send.ResponseAsync(EventResponse.From(e), 201, ct);
    }

    /// <summary>The rider's own fields, as both adding and changing write them.</summary>
    internal static void Apply(TrainingEvent e, EventRequest req)
    {
        e.Name = req.Name.Trim();
        e.Date = req.Date;
        e.Kind = req.Kind;
        e.DistanceM = req.DistanceM;
        e.ElevationGainM = req.ElevationGainM;
        e.Notes = string.IsNullOrWhiteSpace(req.Notes) ? null : req.Notes.Trim();
    }
}
