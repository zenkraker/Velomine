using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Rides;

public sealed class RideIdRequest
{
    public Guid Id { get; set; }
}

/// <summary>A member's own ride. Someone else's ride looks exactly like a ride that does not exist.</summary>
public sealed class GetRide(VelomineDbContext db) : Endpoint<RideIdRequest, RideResponse>
{
    public override void Configure() => Get("rides/{id}");

    public override async Task HandleAsync(RideIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var ride = await db.Rides.AsNoTracking()
            .Include(r => r.Streams)
            .Include(r => r.Owner)
            .FirstOrDefaultAsync(r => r.Id == req.Id && r.UserId == userId, ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var response = RideResponse.From(ride);
        if (ride.Streams is { } streams && ride.Owner is { } owner)
        {
            // Rides read before the profile had these values have no stored load; work it out now.
            var (intensityFactor, tss) = TrainingLoad.PowerLoad(ride.NormalizedPowerW, ride.MovingS ?? 0, owner.FtpW);
            if (response.Tss is null && tss is not null)
            {
                response = response with { Tss = tss, IntensityFactor = intensityFactor };
            }

            if (owner.MaxHeartRate is { } maxHeartRate && streams.HeartRate is { } heartRate)
            {
                var seconds = TrainingLoad.ZoneSeconds(
                    heartRate,
                    streams.Time,
                    maxHeartRate,
                    TrainingLoad.HeartRateFloor,
                    TrainingLoad.HeartRateBounds);
                response = response with
                {
                    HeartRateZones = TrainingLoad.Zones(
                        seconds,
                        maxHeartRate,
                        TrainingLoad.HeartRateFloor,
                        TrainingLoad.HeartRateBounds),
                    Trimp = response.Trimp ?? TrainingLoad.Trimp(seconds),
                };
            }
            if (owner.FtpW is { } ftpW && streams.Power is { } power)
            {
                response = response with
                {
                    PowerZones = TrainingLoad.Zones(
                        power,
                        streams.Time,
                        ftpW,
                        0,
                        TrainingLoad.PowerBounds),
                };
            }
        }

        await Send.OkAsync(response, ct);
    }
}
