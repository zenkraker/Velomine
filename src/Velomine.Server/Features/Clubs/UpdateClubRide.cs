using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Features.Clubs;

public sealed class UpdateClubRideRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    public required string Title { get; set; }

    public required DateTimeOffset StartsAt { get; set; }

    public required int UtcOffsetMinutes { get; set; }

    public required string MeetingName { get; set; }

    public required double Latitude { get; set; }

    public required double Longitude { get; set; }

    public Guid? RouteId { get; set; }

    /// <summary>easy, steady or fast.</summary>
    public required string Pace { get; set; }

    public bool NoDrop { get; set; }

    public string? Notes { get; set; }

    public int? MaxRiders { get; set; }
}

public sealed class UpdateClubRideValidator : Validator<UpdateClubRideRequest>
{
    public UpdateClubRideValidator()
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
/// A coach or the owner changes one of the club's rides. Only a change of time or meeting point tells the riders who
/// are in; one notification for the event, however many fields moved. Dropping the limit never un-says anybody.
/// </summary>
public sealed class UpdateClubRide(VelomineDbContext db, TimeProvider time)
    : Endpoint<UpdateClubRideRequest, ClubRideDetailResponse>
{
    public override void Configure()
    {
        Put("club/rides/{id}");
        Description(d => d.Accepts<UpdateClubRideRequest>("application/json").Produces<ClubRideDetailResponse>(200)
            .ProducesProblem(400).Produces(401).Produces(403).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateClubRideRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var membership = await db.ClubMemberships.FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (membership is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var ride = await CalendarQueries.RideAsync(db, membership.ClubId, req.Id, ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (!CalendarQueries.CanPlan(membership.Role))
        {
            await Send.ForbiddenAsync(ct);
            return;
        }

        if (!await CalendarQueries.RouteInLibraryAsync(db, membership.ClubId, req.RouteId, ct))
        {
            AddError("Choose a route from your club's library.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        var latitude = Math.Round(req.Latitude, 6);
        var longitude = Math.Round(req.Longitude, 6);
        var meetingName = req.MeetingName.Trim();
        var startsAt = CalendarQueries.WholeSeconds(req.StartsAt);
        var timeOrPlaceMoved = ride.StartsAt != startsAt
            || ride.MeetingName != meetingName
            || ride.MeetingLatitude != latitude
            || ride.MeetingLongitude != longitude;

        ride.Title = req.Title.Trim();
        ride.StartsAt = startsAt;
        ride.UtcOffsetMinutes = req.UtcOffsetMinutes;
        ride.MeetingName = meetingName;
        ride.MeetingLatitude = latitude;
        ride.MeetingLongitude = longitude;
        ride.RouteId = req.RouteId;
        ride.Pace = req.Pace;
        ride.NoDrop = req.NoDrop;
        ride.Notes = string.IsNullOrWhiteSpace(req.Notes) ? null : req.Notes.Trim();
        ride.MaxRiders = req.MaxRiders;
        ride.UpdatedAt = time.GetUtcNow();

        if (timeOrPlaceMoved)
            await CalendarQueries.NotifyAsync(db, time, ride, NotificationTypes.ClubRideChanged, userId, everyone: false, ct);

        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await CalendarQueries.DetailAsync(db, ride, userId, membership.Role, ct), ct);
    }
}
