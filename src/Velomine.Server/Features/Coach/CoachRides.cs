using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Features.Coach;

public sealed class CoachRidesRequest
{
    public Guid ClubId { get; set; }

    public Guid UserId { get; set; }

    /// <summary>The Next value from the previous page. Omit for the newest rides.</summary>
    [QueryParam]
    public string? Cursor { get; set; }

    /// <summary>How many rides to return, 1 to 200. Default 50.</summary>
    [QueryParam]
    public int? Limit { get; set; }
}

public sealed class CoachRidesValidator : Validator<CoachRidesRequest>
{
    public CoachRidesValidator() => RuleFor(x => x.Limit).InclusiveBetween(1, 200).When(x => x.Limit.HasValue);
}

public sealed class CoachRideRequest
{
    public Guid ClubId { get; set; }

    public Guid UserId { get; set; }

    public Guid RideId { get; set; }
}

public sealed class CoachRideStreamsRequest
{
    public Guid ClubId { get; set; }

    public Guid UserId { get; set; }

    public Guid RideId { get; set; }

    /// <summary>The most points to return, 10 to 5000. Default 1500.</summary>
    [QueryParam]
    public int? MaxPoints { get; set; }
}

public sealed class CoachRideStreamsValidator : Validator<CoachRideStreamsRequest>
{
    public CoachRideStreamsValidator() => RuleFor(x => x.MaxPoints).InclusiveBetween(10, 5000).When(x => x.MaxPoints.HasValue);
}

/// <summary>An athlete's rides, newest first. Ride numbers only: training load needs the analytics grant, and the route needs its own.</summary>
public sealed class ListCoachRides(VelomineDbContext db, TimeProvider time)
    : Endpoint<CoachRidesRequest, ListRidesResponse>
{
    public override void Configure()
    {
        Get("clubs/{clubId}/athletes/{userId}/rides");
        Description(d => d.Produces<ListRidesResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CoachRidesRequest req, CancellationToken ct)
    {
        var viewerId = User.UserId();
        if (!await SharingRules.CanViewAsync(db, req.ClubId, viewerId, req.UserId, DataTypes.Rides, ct))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var canAnalytics = await SharingRules.CanViewAsync(db, req.ClubId, viewerId, req.UserId, DataTypes.Analytics, ct);
        var limit = req.Limit ?? 50;
        var query = db.Rides.AsNoTracking()
            .Where(r => r.UserId == req.UserId && r.Status != RideStatus.Duplicate);

        if (req.Cursor is not null)
        {
            if (!RideCursor.TryParse(req.Cursor, out var lastTime, out var lastId))
            {
                AddError(r => r.Cursor!, RideCursor.InvalidMessage);
                await Send.ErrorsAsync(400, ct);
                return;
            }

            query = RideCursor.Apply(query, lastTime, lastId);
        }

        var (page, next) = await RideCursor.PageAsync(query, limit, ct);

        await SharingRules.RecordViewAsync(
            db, time, req.UserId, req.ClubId, viewerId,
            await CoachQueries.ViewerNameAsync(db, viewerId, ct), ViewKinds.Rides, ct);
        await Send.OkAsync(new ListRidesResponse(
            [.. page.Select(r => canAnalytics ? RideResponse.From(r) : RideResponse.From(r).WithoutTrainingLoad())], next), ct);
    }
}

/// <summary>One of the athlete's rides, read-only, with training load only when analytics is shared too.</summary>
public sealed class GetCoachRide(VelomineDbContext db, TimeProvider time)
    : Endpoint<CoachRideRequest, RideResponse>
{
    public override void Configure()
    {
        Get("clubs/{clubId}/athletes/{userId}/rides/{rideId}");
        Description(d => d.Produces<RideResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CoachRideRequest req, CancellationToken ct)
    {
        var viewerId = User.UserId();
        if (!await SharingRules.CanViewAsync(db, req.ClubId, viewerId, req.UserId, DataTypes.Rides, ct))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var canAnalytics = await SharingRules.CanViewAsync(db, req.ClubId, viewerId, req.UserId, DataTypes.Analytics, ct);
        var ride = await db.Rides.AsNoTracking()
            .Include(r => r.Streams)
            .Include(r => r.Owner)
            .FirstOrDefaultAsync(r => r.Id == req.RideId && r.UserId == req.UserId, ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        await SharingRules.RecordViewAsync(
            db, time, req.UserId, req.ClubId, viewerId,
            await CoachQueries.ViewerNameAsync(db, viewerId, ct), ViewKinds.Ride, ct);
        await Send.OkAsync(
            canAnalytics ? RideDetails.Build(ride) : RideResponse.From(ride).WithoutTrainingLoad(), ct);
    }
}

/// <summary>The athlete's samples. Position is included only when routes were shared too.</summary>
public sealed class GetCoachRideStreams(VelomineDbContext db, TimeProvider time)
    : Endpoint<CoachRideStreamsRequest, RideStreamsResponse>
{
    public override void Configure()
    {
        Get("clubs/{clubId}/athletes/{userId}/rides/{rideId}/streams");
        Description(d => d.Produces<RideStreamsResponse>(200).ProducesProblem(400).Produces(401).Produces(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(CoachRideStreamsRequest req, CancellationToken ct)
    {
        var viewerId = User.UserId();
        if (!await SharingRules.CanViewAsync(db, req.ClubId, viewerId, req.UserId, DataTypes.Rides, ct))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var status = await db.Rides.AsNoTracking()
            .Where(r => r.Id == req.RideId && r.UserId == req.UserId)
            .Select(r => (RideStatus?)r.Status)
            .FirstOrDefaultAsync(ct);
        if (status is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var streams = status == RideStatus.Ready
            ? await db.RideStreams.AsNoTracking().FirstOrDefaultAsync(s => s.RideId == req.RideId, ct)
            : null;
        if (streams is null)
        {
            AddError("The ride has no samples: it is still being read, or the file could not be used.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var showRoute = await SharingRules.CanViewAsync(db, req.ClubId, viewerId, req.UserId, DataTypes.Routes, ct);
        var reduced = StreamSampling.Reduce(streams, req.MaxPoints ?? 1500);
        var response = new RideStreamsResponse(
            reduced.Time,
            reduced.Latitude,
            reduced.Longitude,
            reduced.Altitude,
            reduced.Speed,
            reduced.Distance,
            reduced.HeartRate,
            reduced.Power,
            reduced.Cadence,
            reduced.Temperature);

        await SharingRules.RecordViewAsync(
            db, time, req.UserId, req.ClubId, viewerId,
            await CoachQueries.ViewerNameAsync(db, viewerId, ct),
            showRoute ? ViewKinds.Route : ViewKinds.Ride, ct);
        await Send.OkAsync(PrivacyRules.ForViewer(response, showRoute), ct);
    }
}
