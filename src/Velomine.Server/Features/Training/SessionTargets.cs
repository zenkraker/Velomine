using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Training;

/// <summary>A line under a session's targets, in both languages: rider-facing text, so it lives beside the names.</summary>
public sealed record SessionNote(string Code, string English, string Italian);

/// <summary>The lines a session shows when a target cannot be given as a number.</summary>
public static class SessionNotes
{
    /// <summary>
    /// No power meter, so no watt target: the 2.5 W/kg stand-in is never one (*Estimated power*). The wording is
    /// `docs/design/pages/training/SessionPage.md`.
    /// </summary>
    public static readonly SessionNote AddPowerMeter = new(
        "add_power_meter",
        "Add a power meter for watt targets",
        "Aggiungi un misuratore di potenza per gli obiettivi in watt");

    /// <summary>
    /// A power meter but no FTP, so no watt target yet: the meter's watts are there, the reference they are read
    /// against is not. There is no watt number to show until the rider sets one or accepts a ride's.
    /// </summary>
    public static readonly SessionNote SetFtp = new(
        "set_ftp",
        "Set your FTP for watt targets",
        "Imposta il tuo FTP per gli obiettivi in watt");

    /// <summary>
    /// The session has efforts of 2 minutes or less, where heart rate lags by a minute or two. Its wording is
    /// `docs/design/pages/training/SessionPage.md`.
    /// </summary>
    public static readonly SessionNote HeartRateLags = new(
        "heart_rate_lags",
        "Heart rate lags here: go by watts and feel",
        "Qui la frequenza cardiaca arriva in ritardo: segui watt e sensazioni");
}

/// <summary>
/// One block with the day's numbers: watts from the FTP in use (P6), heart rate from the threshold in use (H3), feel
/// from F1. A null pair is a block with no target in that signal.
/// </summary>
public sealed record BlockTarget(
    string Role,
    int Minutes,
    int? WattsLow,
    int? WattsHigh,
    int? HeartRateLow,
    int? HeartRateHigh,
    int FeelLow,
    int FeelHigh);

/// <summary>
/// A session's targets for a day, worked out when it is shown and never stored: a session stores its recipe and the
/// block percentages, never watts.
/// </summary>
public sealed record SessionTargets(
    Recipe Recipe,
    int Minutes,
    BlockTarget[] Blocks,
    SessionNote[] Notes,
    bool HeartRateEstimated)
{
    /// <summary>
    /// The recipe scaled to the day, block by block, with the targets as ranges. The heart rate is read against the
    /// threshold in use, which is the value <see cref="HeartRates.For"/> gives — the one the rider set or a ride
    /// measured, else 89 % of the maximum (H2) — and <see cref="HeartRateEstimated"/> says when it is that estimate, so
    /// the app can mark every heart-rate number as estimated. Heart rate is left off an effort of two minutes or less,
    /// where it lags, and the session says so once.
    /// </summary>
    public static SessionTargets For(
        Recipe recipe,
        int minutes,
        int? ftpW,
        HeartRate? thresholdHeartRate,
        bool hasPowerMeter = false)
    {
        var (chosen, planned) = SessionPlan.For(recipe, minutes);
        var threshold = thresholdHeartRate?.Bpm;
        var notes = new List<SessionNote>();
        if (ftpW is null) notes.Add(hasPowerMeter ? SessionNotes.SetFtp : SessionNotes.AddPowerMeter);

        var lags = false;
        var blocks = planned.Select(plannedBlock =>
        {
            var block = plannedBlock.Block;
            var shortEffort = block.EffortSeconds is { } seconds && seconds <= 120;
            lags |= shortEffort;

            (int? Low, int? High) watts = ftpW is { } ftp && block.PercentFtp is { } percentFtp
                ? (Scale(percentFtp.Low, ftp), Scale(percentFtp.High, ftp))
                : (null, null);
            (int? Low, int? High) heartRate = !shortEffort && threshold is { } bpm && block.PercentThresholdHeartRate is { } percentHr
                ? (Scale(percentHr.Low, bpm), Scale(percentHr.High, bpm))
                : (null, null);

            return new BlockTarget(
                block.Role, plannedBlock.Minutes,
                watts.Low, watts.High, heartRate.Low, heartRate.High,
                block.Feel.Low, block.Feel.High);
        }).ToArray();

        if (lags) notes.Add(SessionNotes.HeartRateLags);
        var estimated = threshold is not null && thresholdHeartRate?.Source == FtpSources.Estimate;
        return new SessionTargets(chosen, planned.Sum(b => b.Minutes), blocks, [.. notes], estimated);
    }

    private static int Scale(int percent, int reference) => (int)Math.Round(percent / 100.0 * reference);
}
