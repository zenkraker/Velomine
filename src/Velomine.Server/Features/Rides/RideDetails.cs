using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;

namespace Velomine.Server.Features.Rides;

/// <summary>Builds the detailed ride the member and their coach both read, including load worked out on the way.</summary>
public static class RideDetails
{
    /// <summary>
    /// The detailed ride with its W′ balance, from the rider's current fit over the last 90 days as of this request.
    /// </summary>
    public static async Task<RideResponse> BuildAsync(VelomineDbContext db, TimeProvider time, Ride ride, CancellationToken ct)
    {
        var response = Build(ride, time);
        if (ride.Streams is not { } streams) return response;

        var clock = await MemberClock.ForAsync(db, ride.UserId, time, ct);
        var balance = WPrimeBalance.ForRide(streams, await FitnessQueries.CriticalPowerAsync(db, clock, ride.UserId, ct));
        return balance is null ? response : response with { MinWPrimeBalanceJ = (int?)balance.MinJ, WPrimeJ = balance.WPrimeJ };
    }

    public static RideResponse Build(Ride ride, TimeProvider time)
    {
        var response = RideResponse.From(ride);
        if (ride.Streams is not { } streams || ride.Owner is not { } owner) return response;

        // Rides read before the profile had these values have no stored load; work it out now.
        var (intensityFactor, tss) = TrainingLoad.PowerLoad(ride.NormalizedPowerW, ride.MovingS ?? 0, owner.FtpW);
        if (response.Tss is null && tss is not null)
            response = response with { Tss = tss, IntensityFactor = intensityFactor };

        var (maxHeartRate, thresholdHeartRate) = HeartRates.For(owner, time);
        if (streams.HeartRate is { } heartRate)
        {
            // TRIMP is the older score, stored at read on the maximum model: recompute it the same way here.
            if (maxHeartRate?.Bpm is { } maxBpm)
            {
                var trimpSeconds = TrainingLoad.ZoneSeconds(
                    heartRate,
                    streams.Time,
                    maxBpm,
                    TrainingLoad.HeartRateFloor,
                    TrainingLoad.HeartRateBounds);
                response = response with { Trimp = response.Trimp ?? TrainingLoad.Trimp(trimpSeconds) };
            }

            // Neither model has a chart floor: a beat below the first bound is zone 1, counted from 0.
            if (TrainingLoad.HeartRateZoneFor(maxHeartRate, thresholdHeartRate, owner.HeartRateMaxZoneBounds, owner.HeartRateThresholdZoneBounds) is { } zoneModel)
            {
                response = response with
                {
                    HeartRateZones = TrainingLoad.Zones(heartRate, streams.Time, zoneModel.Bpm, 0, zoneModel.Bounds),
                    HeartRateZoneModel = zoneModel.Model,
                    HeartRateZoneReferenceBpm = zoneModel.Bpm,
                    HeartRateZoneReferenceSource = zoneModel.Source,
                };
            }
        }

        if (owner.FtpW is { } ftpW && streams.Power is { } power)
        {
            response = response with
            {
                PowerZones = TrainingLoad.Zones(power, streams.Time, ftpW, 0, owner.PowerZoneBounds ?? TrainingLoad.PowerBounds),
            };
        }

        return response;
    }
}
