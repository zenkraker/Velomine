using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Training;

/// <summary>A line under a session's targets, in both languages: rider-facing text, so it lives beside the names.</summary>
public sealed record SessionNote(string Code, string English, string Italian);

/// <summary>The lines a session shows when a target cannot be given as a number.</summary>
public static class SessionNotes
{
    /// <summary>
    /// No power meter and no FTP, so no watt target: the 2.5 W/kg stand-in is never one (*Estimated power*). The
    /// wording is `docs/design/pages/training/SessionPage.md`.
    /// </summary>
    public static readonly SessionNote AddPowerMeter = new(
        "add_power_meter",
        "Add a power meter for watt targets",
        "Aggiungi un misuratore di potenza per gli obiettivi in watt");

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
/// One block with the day's numbers: watts from the FTP in use (P6), heart rate from the zone model in use (H3), feel
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
public sealed record SessionTargets(Recipe Recipe, int Minutes, BlockTarget[] Blocks, SessionNote[] Notes)
{
    /// <summary>
    /// The recipe scaled to the day, block by block, with the targets as ranges. Heart rate is left off an effort of two
    /// minutes or less, where it lags, and the session says so once.
    /// </summary>
    public static SessionTargets For(Recipe recipe, int minutes, int? ftpW, HeartRateZoneReference? heartRateZones)
    {
        var (chosen, planned) = SessionPlan.For(recipe, minutes);
        var threshold = ThresholdHeartRate(heartRateZones);
        var notes = new List<SessionNote>();
        if (ftpW is null) notes.Add(SessionNotes.AddPowerMeter);

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
        return new SessionTargets(chosen, planned.Sum(b => b.Minutes), blocks, [.. notes]);
    }

    /// <summary>
    /// The threshold heart rate the block percentages are read against, from the model in use (H3): the threshold itself
    /// when the rider set one, else 89 % of the maximum (H2). Null when the rider has neither.
    /// </summary>
    public static int? ThresholdHeartRate(HeartRateZoneReference? zones) => zones switch
    {
        null => null,
        { Model: HeartRateZoneModels.Threshold, Bpm: var threshold } => threshold,
        { Bpm: var max } => (int)Math.Round(max * 0.89),
    };

    private static int Scale(int percent, int reference) => (int)Math.Round(percent / 100.0 * reference);
}
