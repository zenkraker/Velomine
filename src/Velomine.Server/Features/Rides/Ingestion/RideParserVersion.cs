namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// The generation of the code that turns an original ride file into numbers. Raise <see cref="Current"/> by one in
/// the same change as any fix to parsing or to a ride metric that should reach rides already stored: the server then
/// reads every older ride again from its original file in the background (<see cref="RideReparseService"/>).
/// A change that must not touch history leaves it alone.
/// </summary>
public static class RideParserVersion
{
    public const int Current = 1;

    /// <summary>Marks a ride as just read with the current parser and records the profile its training load came from.</summary>
    public static void StampRead(this Ride ride, int? ftpW, int? maxHeartRate)
    {
        ride.ParserVersion = Current;
        ride.ReparseFailedVersion = null;
        ride.LoadFtpW = ftpW ?? 0;
        ride.LoadMaxHeartRate = maxHeartRate ?? 0;
    }

    /// <summary>
    /// The FTP a ride's stored intensity factor and TSS were worked out from, for rides read before it was recorded.
    /// Searches the whole numbers near normalized power / intensity factor for the one that reproduces the stored
    /// values; null when nothing does (no power load was stored, or it came from different numbers).
    /// </summary>
    public static int? RecoverFtp(int? normalizedPowerW, double? movingS, double? intensityFactor, double? tss)
    {
        if (normalizedPowerW is not { } np || np <= 0 || movingS is not { } moving || moving <= 0
            || intensityFactor is not { } intensity || intensity <= 0)
            return null;

        var guess = (int)Math.Round(np / intensity);
        var reach = (int)Math.Ceiling(guess * 0.012) + 1; // intensity is stored to two decimals
        int? sameIntensity = null;
        for (var step = 0; step <= reach; step++)
        {
            foreach (var ftp in step == 0 ? new[] { guess } : new[] { guess - step, guess + step })
            {
                if (ftp <= 0) continue;
                var (i, t) = TrainingLoad.PowerLoad(np, moving, ftp);
                if (i != intensity) continue;
                if (tss is null || t == tss) return ftp;
                sameIntensity ??= ftp;
            }
        }
        return sameIntensity;
    }
}
