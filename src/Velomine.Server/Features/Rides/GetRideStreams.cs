using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Rides;

public sealed class RideStreamsRequest
{
    public Guid Id { get; set; }

    /// <summary>The most points to return, 10 to 5000. Default 1500. A longer ride is averaged down to this many points.</summary>
    public int? MaxPoints { get; set; }
}

/// <summary>
/// The samples of a ride as aligned arrays: element i of every array belongs to the same moment.
/// A signal the ride does not have is null; a missing value inside one is a null element.
/// Time is in seconds since the start, distance in metres, speed in metres per second.
/// </summary>
public sealed record RideStreamsResponse(
    double[] Time,
    double?[]? Latitude,
    double?[]? Longitude,
    float?[]? Altitude,
    float?[]? Speed,
    float?[]? Distance,
    short?[]? HeartRate,
    short?[]? Power,
    short?[]? Cadence,
    short?[]? Temperature);

public sealed class RideStreamsValidator : Validator<RideStreamsRequest>
{
    public RideStreamsValidator() => RuleFor(x => x.MaxPoints).InclusiveBetween(10, 5000).When(x => x.MaxPoints.HasValue);
}

public sealed class GetRideStreams(VelomineDbContext db) : Endpoint<RideStreamsRequest, RideStreamsResponse>
{
    public override void Configure()
    {
        Get("rides/{id}/streams");
        Description(d => d.Produces<RideStreamsResponse>(200).Produces(401).Produces(404).ProducesProblem(409).ProducesProblem(400), clearDefaults: true);
    }

    public override async Task HandleAsync(RideStreamsRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var ride = await db.Rides.AsNoTracking().Where(r => r.Id == req.Id && r.UserId == userId).Select(r => new { r.Status }).FirstOrDefaultAsync(ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var streams = ride.Status == RideStatus.Ready ? await db.RideStreams.AsNoTracking().FirstOrDefaultAsync(s => s.RideId == req.Id, ct) : null;
        if (streams is null)
        {
            AddError("The ride has no samples: it is still being read, or the file could not be used.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var s = StreamSampling.Reduce(streams, req.MaxPoints ?? 1500);
        await Send.OkAsync(new RideStreamsResponse(s.Time, s.Latitude, s.Longitude, s.Altitude, s.Speed, s.Distance, s.HeartRate, s.Power, s.Cadence, s.Temperature), ct);
    }
}
