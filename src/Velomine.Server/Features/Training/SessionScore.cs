using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Training;

/// <summary>The main set's target in the ride's leading signal, and what the ride averaged in it.</summary>
public sealed record MainSetTarget(string Signal, int Target, int? Average);

/// <summary>
/// What a done session's ride did against the plan, and the score it earned: Velomine's own 0–100 (L7 in
/// `docs/training-models.md`). Computed on read from the session and the ride's stored numbers, never stored, so a ride
/// read again scores with its new numbers and no parser version moves.
/// </summary>
public sealed record SessionResult(
    int Score,
    int PlannedMinutes,
    double DoneMinutes,
    double PlannedEffort,
    double? DoneEffort,
    double? MainSetShare,
    MainSetTarget? MainSet);

/// <summary>One main-set band of a session, in the leading signal's own numbers (watts or bpm).</summary>
public readonly record struct MainBand(int Low, int High);

/// <summary>
/// Velomine's session score, from the time a session planned against the time ridden, the effort score it planned
/// against the ride's L1 score, and the share of the main set ridden inside its target. The weights are Velomine's own
/// and are never presented as a published method (see `docs/training-models.md`, *L7 — Session score*).
/// </summary>
public static class SessionScore
{
    /// <summary>Time done against time planned, when the ride carries the leading signal.</summary>
    public const double TimeWeight = 0.4;

    /// <summary>Effort score done against effort planned, when the ride carries the leading signal.</summary>
    public const double EffortWeight = 0.4;

    /// <summary>Time in target on the main set, when the ride carries the leading signal.</summary>
    public const double TargetWeight = 0.2;

    /// <summary>Without the leading signal there is no time in target to measure: time and effort share it.</summary>
    public const double TimeWeightWithoutTarget = 0.5;

    /// <summary>See <see cref="TimeWeightWithoutTarget"/>.</summary>
    public const double EffortWeightWithoutTarget = 0.5;

    /// <summary>A sample gap longer than this is not time ridden: the same cut every other stream sum makes.</summary>
    private const double MaxSampleGapS = 30;

    /// <summary>The score, 0 to 100, from the three shares; the target one is null without the leading signal.</summary>
    public static int Score(double timeShare, double effortShare, double? targetShare) =>
        (int)Math.Round(100 * (targetShare is { } target
            ? TimeWeight * timeShare + EffortWeight * effortShare + TargetWeight * target
            : TimeWeightWithoutTarget * timeShare + EffortWeightWithoutTarget * effortShare));

    /// <summary>
    /// How much of a plan a ride did: never more than all of it, so a longer or harder ride cannot pay for a part the
    /// rider left out.
    /// </summary>
    public static double Share(double done, double planned) =>
        planned <= 0 ? 0 : Math.Clamp(done / planned, 0, 1);

    /// <summary>
    /// The share of the main set's planned minutes the ride spent inside the main set's bands: the seconds of the
    /// stream in any of them, over the planned main-set seconds, capped at the whole set. Null when the ride has no
    /// such stream, which is what leaves the score weighing time and effort alone.
    /// </summary>
    public static double? MainSetShare(
        IReadOnlyList<MainBand> bands,
        int plannedMinutes,
        IReadOnlyList<double>? time,
        IReadOnlyList<short?>? values)
    {
        if (bands.Count == 0 || plannedMinutes <= 0 || time is null || values is null) return null;
        double inside = 0;
        var count = Math.Min(time.Count, values.Count);
        for (var i = 0; i + 1 < count; i++)
        {
            var dt = time[i + 1] - time[i];
            if (dt <= 0 || dt > MaxSampleGapS) continue;
            if (values[i] is { } value && bands.Any(b => value >= b.Low && value <= b.High)) inside += dt;
        }
        return Math.Clamp(inside / (plannedMinutes * 60.0), 0, 1);
    }

    /// <summary>
    /// The results of a range of sessions whose rides are known, keyed by session id. The streams are read only for the
    /// sessions whose ride carries the leading signal, and nothing is written.
    /// </summary>
    public static async Task<Dictionary<Guid, SessionResult>> ForAsync(
        VelomineDbContext db,
        IReadOnlyList<TrainingSession> sessions,
        User user,
        TimeProvider time,
        CancellationToken ct)
    {
        var done = sessions.Where(s => s.RideId is not null).ToList();
        if (done.Count == 0) return [];
        var rideIds = done.Select(s => s.RideId!.Value).ToList();
        var rides = (await db.Rides.AsNoTracking()
                .Where(r => rideIds.Contains(r.Id))
                .Select(r => new { r.Id, r.MovingS, r.AvgPowerW, r.AvgHeartRate, r.Tss, r.HrTss, r.EstimatedTss })
                .ToListAsync(ct))
            .ToDictionary(r => r.Id);
        var feels = await db.RideFeels.AsNoTracking()
            .Where(f => rideIds.Contains(f.RideId))
            .Select(f => new { f.RideId, f.Rpe })
            .ToListAsync(ct);
        var threshold = HeartRates.For(user, time).Threshold;

        // The main set of each session as it is shown on the day: the same recipe scaled to the same minutes, the
        // blocks' bands from the FTP and the threshold heart rate in use.
        var plans = done.ToDictionary(
            s => s.Id,
            s =>
            {
                var recipe = Recipes.ByCode(s.Recipe);
                var planned = SessionPlan.For(recipe, s.Minutes).Blocks;
                var targets = SessionTargets.For(recipe, s.Minutes, user.FtpW, threshold).Blocks;
                return (
                    PlannedMinutes: planned.Sum(b => b.Minutes),
                    PlannedEffort: SessionPlan.PlannedScore(planned),
                    MainMinutes: planned.Where(b => b.Block.Role == RecipeRoles.Main).Sum(b => b.Minutes),
                    Main: targets.Where(b => b.Role == RecipeRoles.Main).ToArray());
            });

        var streams = (await db.RideStreams.AsNoTracking()
                .Where(s => rideIds.Contains(s.RideId))
                .Select(s => new { s.RideId, s.Time, s.Power, s.HeartRate })
                .ToListAsync(ct))
            .ToDictionary(s => s.RideId);

        var results = new Dictionary<Guid, SessionResult>(done.Count);
        foreach (var session in done)
        {
            var ride = rides.GetValueOrDefault(session.RideId!.Value);
            if (ride is null) continue;
            var plan = plans[session.Id];
            var (effort, _) = TrainingLoad.Effort(
                ride.Tss, ride.HrTss, TrainingLoad.FeelScore(ride.MovingS, feels.FirstOrDefault(f => f.RideId == ride.Id)?.Rpe),
                ride.EstimatedTss);
            streams.TryGetValue(ride.Id, out var stream);

            // The leading signal is what the rider could follow, and what the score checks: watts when the ride has
            // power and every main block has a watt band, else heart rate, else nothing (the gentle base recipes ride
            // by feel, and then only time and effort can be scored).
            var power = stream?.Power is not null && plan.Main.Length > 0
                && plan.Main.All(b => b.WattsLow is not null && b.WattsHigh is not null);
            var heartRate = !power && stream?.HeartRate is not null && plan.Main.Length > 0
                && plan.Main.All(b => b.HeartRateLow is not null && b.HeartRateHigh is not null);

            MainBand[] bands = power
                ? [.. plan.Main.Select(b => new MainBand(b.WattsLow!.Value, b.WattsHigh!.Value))]
                : heartRate ? [.. plan.Main.Select(b => new MainBand(b.HeartRateLow!.Value, b.HeartRateHigh!.Value))] : [];
            var signal = power ? EffortSources.Power : heartRate ? EffortSources.HeartRate : null;
            var average = power ? ride.AvgPowerW : heartRate ? ride.AvgHeartRate : null;
            var share = power
                ? MainSetShare(bands, plan.MainMinutes, stream?.Time, stream?.Power)
                : heartRate ? MainSetShare(bands, plan.MainMinutes, stream?.Time, stream?.HeartRate) : null;

            var target = signal is null ? null : new MainSetTarget(signal, (int)Math.Round(WeightedMiddle(plan.Main, bands)), average);
            results[session.Id] = new SessionResult(
                Score(Share(ride.MovingS ?? 0, plan.PlannedMinutes * 60.0), effort is { } doneEffort ? Share(doneEffort, plan.PlannedEffort) : 0, share),
                plan.PlannedMinutes,
                Math.Round((ride.MovingS ?? 0) / 60.0, 1),
                plan.PlannedEffort,
                effort,
                share is null ? null : Math.Round(share.Value, 2),
                target);
        }
        return results;
    }

    /// <summary>The middle of the main set's bands, each block's own weight by its minutes.</summary>
    private static double WeightedMiddle(BlockTarget[] main, MainBand[] bands)
    {
        double sum = 0, minutes = 0;
        for (var i = 0; i < bands.Length; i++)
        {
            sum += main[i].Minutes * (bands[i].Low + bands[i].High) / 2.0;
            minutes += main[i].Minutes;
        }
        return minutes > 0 ? sum / minutes : 0;
    }
}
