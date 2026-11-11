using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Features.Clubs;

public sealed class PlanClubRideRequest
{
    public required string Title { get; set; }

    /// <summary>When it starts, as an instant. The app sends the time the member picked.</summary>
    public required DateTimeOffset StartsAt { get; set; }

    /// <summary>The local offset at the meeting point, in minutes from UTC, kept beside the instant.</summary>
    public required int UtcOffsetMinutes { get; set; }

    public required string MeetingName { get; set; }

    public required double Latitude { get; set; }

    public required double Longitude { get; set; }

    /// <summary>A route from the club's library, or none.</summary>
    public Guid? RouteId { get; set; }

    /// <summary>easy, steady or fast.</summary>
    public required string Pace { get; set; }

    /// <summary>Whether nobody is dropped.</summary>
    public bool NoDrop { get; set; }

    public string? Notes { get; set; }

    /// <summary>Leave it out for no limit.</summary>
    public int? MaxRiders { get; set; }
}

public sealed class PlanClubRideValidator : Validator<PlanClubRideRequest>
{
    public PlanClubRideValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(160);
        RuleFor(x => x.MeetingName).NotEmpty().MaximumLength(200);
        RuleFor(x => x.UtcOffsetMinutes).InclusiveBetween(-840, 840);
        RuleFor(x => x.Latitude).InclusiveBetween(-90, 90);
        RuleFor(x => x.Longitude).InclusiveBetween(-180, 180);
        RuleFor(x => x.Pace).Must(RidePaces.All.Contains).WithMessage("Choose easy, steady or fast.");
        RuleFor(x => x.Notes).MaximumLength(2000);
        RuleFor(x => x.MaxRiders).InclusiveBetween(1, 500).When(x => x.MaxRiders.HasValue);
    }
}

/// <summary>
/// A coach or the owner plans a ride for the club and every member hears about it: one notification for the event,
/// not one per field. The route must already be in the club's library.
/// </summary>
public sealed class PlanClubRide(VelomineDbContext db, TimeProvider time)
    : Endpoint<PlanClubRideRequest, ClubRideDetailResponse>
{
    public override void Configure()
    {
        Post("club/rides");
        Description(d => d.Accepts<PlanClubRideRequest>("application/json").Produces<ClubRideDetailResponse>(201)
            .ProducesProblem(400).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(PlanClubRideRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var membership = await db.ClubMemberships.FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (membership is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (!CalendarQueries.CanPlan(membership.Role))
        {
            await Send.ForbiddenAsync(ct);
            return;
        }

        if (req.StartsAt <= time.GetUtcNow())
        {
            AddError("Choose a start in the future.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        if (!await CalendarQueries.RouteInLibraryAsync(db, membership.ClubId, req.RouteId, ct))
        {
            AddError("Choose a route from your club's library.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        var ride = new PlannedRide
        {
            Id = Guid.CreateVersion7(),
            ClubId = membership.ClubId,
            CreatedByUserId = userId,
            Title = req.Title.Trim(),
            StartsAt = CalendarQueries.WholeSeconds(req.StartsAt),
            UtcOffsetMinutes = req.UtcOffsetMinutes,
            MeetingName = req.MeetingName.Trim(),
            MeetingLatitude = Math.Round(req.Latitude, 6),
            MeetingLongitude = Math.Round(req.Longitude, 6),
            RouteId = req.RouteId,
            Pace = req.Pace,
            NoDrop = req.NoDrop,
            Notes = string.IsNullOrWhiteSpace(req.Notes) ? null : req.Notes.Trim(),
            MaxRiders = req.MaxRiders,
            CreatedAt = time.GetUtcNow(),
            UpdatedAt = time.GetUtcNow(),
        };
        db.PlannedRides.Add(ride);
        await CalendarQueries.NotifyAsync(db, time, ride, NotificationTypes.ClubRidePlanned, userId, everyone: true, ct);
        await db.SaveChangesAsync(ct);

        await Send.ResponseAsync(await CalendarQueries.DetailAsync(db, ride, userId, membership.Role, ct), 201, ct);
    }
}
