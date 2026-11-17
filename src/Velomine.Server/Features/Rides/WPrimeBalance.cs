using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Rides.Ingestion;
using Velomine.Server.Features.Sharing;

namespace Velomine.Server.Features.Rides;

/// <summary>
/// How much W′ is left through a ride (Skiba et al. 2015, differential form): above critical power the balance drops by
/// the watts over it; below it the balance recovers a share of what is missing, in proportion to how easy the second
/// was. Pauses carry the balance over unchanged, and it may go below 0 when the rider beat the model.
/// </summary>
public static class WPrimeBalance
{
    /// <summary>
    /// The balance of one ride for the rider's current fit: over the last 90 days as of this request. Null when the
    /// rider has no fit, the ride has no power, or the viewer has no analytics grant.
    /// </summary>
    public static async Task<WPrimeRide?> ForCoachAsync(
        VelomineDbContext db, TimeProvider time, Guid clubId, Guid viewerId, Guid userId, RideStreams streams, CancellationToken ct) =>
        await SharingRules.CanViewAsync(db, clubId, viewerId, userId, DataTypes.Analytics, ct)
            ? ForRide(streams, await FitnessQueries.CriticalPowerAsync(db, await MemberClock.ForAsync(db, userId, time, ct), userId, ct))
            : null;

    /// <summary>
    /// The balance for the stored samples, second by second as normalized power reads them. A sample shows the balance
    /// of its stretch after the seconds up to it, and a stretch holds the balance it ended on.
    /// </summary>
    public static WPrimeRide? ForRide(RideStreams streams, CriticalPowerEstimate? cp)
    {
        if (cp is null || streams.Power is not { } power || streams.Time.Length < 2) return null;

        var samples = new Sample[streams.Time.Length];
        for (var i = 0; i < samples.Length; i++)
            samples[i] = new Sample(streams.Time[i], Power: power.Length > i ? power[i] : null);

        var seconds = RideMetrics.Seconds(samples, s => s.Power, RideMetrics.PauseThresholdS(samples));
        if (seconds.Length == 0) return null;

        var wPrime = cp.WPrimeJ;
        double balance = wPrime, lowest = wPrime;
        var perSample = new int?[samples.Length];
        var stretch = 0;
        for (var i = 0; i < seconds.Length; i++)
        {
            var (secondsStretch, _, last, value) = seconds[i];
            if (i > 0 && secondsStretch != stretch)
            {
                // A stretch ended: it holds the balance it ended on, up to its last sample.
                for (var s = seconds[i - 1].First; s <= seconds[i - 1].Last && s < perSample.Length; s++)
                    perSample[s] = (int)Math.Round(balance);
            }

            var over = value - cp.CpW;
            balance = over > 0 ? balance - over : balance + (wPrime - balance) * -over / wPrime;
            balance = Math.Min(balance, wPrime);
            lowest = Math.Min(lowest, balance);
            perSample[last] = (int)Math.Round(balance);
            stretch = secondsStretch;
        }

        // After the ride the balance is what it ended on: the last reading, and a stop, show that.
        for (var i = 0; i < perSample.Length; i++)
            perSample[i] ??= i > 0 ? perSample[i - 1] : (int)Math.Round(balance);

        return new WPrimeRide(perSample, (int)Math.Round(lowest), wPrime);
    }

    /// <summary>The balance after every second of riding, in joules. The whole formula, on its own.</summary>
    public static double[] Series(IReadOnlyList<double> power1Hz, CriticalPowerEstimate cp)
    {
        var wPrime = (double)cp.WPrimeJ;
        var balance = wPrime;
        var result = new double[power1Hz.Count];
        for (var i = 0; i < power1Hz.Count; i++)
        {
            var over = power1Hz[i] - cp.CpW;
            balance = over > 0 ? balance - over : balance + (wPrime - balance) * -over / wPrime;
            result[i] = Math.Min(balance, wPrime);
        }

        return result;
    }
}

/// <summary>A ride's balance: one entry per stored sample, the lowest it got, and the W′ it started from.</summary>
public sealed record WPrimeRide(int?[] PerSample, int? MinJ, int WPrimeJ);
