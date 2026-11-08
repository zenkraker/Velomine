using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Rides;

/// <summary>Builds the detailed ride the member and their coach both read, including load worked out on the way.</summary>
public static class RideDetails
{
    public static RideResponse Build(Ride ride)
    {
        var response = RideResponse.From(ride);
        if (ride.Streams is not { } streams || ride.Owner is not { } owner) return response;

        // Rides read before the profile had these values have no stored load; work it out now.
        var (intensityFactor, tss) = TrainingLoad.PowerLoad(ride.NormalizedPowerW, ride.MovingS ?? 0, owner.FtpW);
        if (response.Tss is null && tss is not null)
            response = response with { Tss = tss, IntensityFactor = intensityFactor };

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
                PowerZones = TrainingLoad.Zones(power, streams.Time, ftpW, 0, TrainingLoad.PowerBounds),
            };
        }

        return response;
    }
}
