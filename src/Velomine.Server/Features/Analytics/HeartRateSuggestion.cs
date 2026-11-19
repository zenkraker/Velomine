using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Analytics;

/// <summary>The states a heart-rate suggestion can be in.</summary>
public static class HeartRateSuggestionStatuses
{
    public const string Open = "open";
    public const string Accepted = "accepted";
    public const string Dismissed = "dismissed";
    public const string Replaced = "replaced";
}

/// <summary>What a ride did to a heart-rate number, as <see cref="Velomine.Server.Features.Rides.RideResponse.HeartRateNote"/> says it.</summary>
public static class HeartRateNotes
{
    public const string MaxMeasured = "max_measured";
    public const string ThresholdMeasured = "threshold_measured";
    public const string MaxSuggested = "max_suggested";
    public const string ThresholdSuggested = "threshold_suggested";
}

/// <summary>
/// A maximum or threshold heart rate a ride suggests, for a number the rider typed themselves. At most one per member
/// and kind is <c>open</c> (a partial unique index says so); accepting it sets the number as measured from that ride.
/// </summary>
public sealed class HeartRateSuggestion
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public Guid RideId { get; set; }

    /// <summary><see cref="HeartRateKinds.Max"/> or <see cref="HeartRateKinds.Threshold"/>.</summary>
    public string Kind { get; set; } = HeartRateKinds.Max;

    public int Bpm { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    /// <summary>One of <see cref="HeartRateSuggestionStatuses"/>.</summary>
    public string Status { get; set; } = HeartRateSuggestionStatuses.Open;
}

public sealed class HeartRateSuggestionConfiguration : IEntityTypeConfiguration<HeartRateSuggestion>
{
    public void Configure(EntityTypeBuilder<HeartRateSuggestion> b)
    {
        b.ToTable("heart_rate_suggestions", "analytics", t =>
        {
            t.HasCheckConstraint("ck_heart_rate_suggestions_kind", "kind IN ('max', 'threshold')");
            t.HasCheckConstraint("ck_heart_rate_suggestions_bpm", "bpm BETWEEN 80 AND 230");
            t.HasCheckConstraint("ck_heart_rate_suggestions_status", "status IN ('open', 'accepted', 'dismissed', 'replaced')");
        });
        b.HasKey(s => s.Id);
        b.HasIndex(s => s.UserId);
        b.HasIndex(s => s.RideId);
        // One open suggestion per member and kind: a new one replaces the last, never queues beside it.
        b.HasIndex(s => new { s.UserId, s.Kind }).HasFilter("status = 'open'").IsUnique()
            .HasDatabaseName("ux_heart_rate_suggestions_open_user_kind");
        b.HasOne<User>().WithMany().HasForeignKey(s => s.UserId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne<Ride>().WithMany().HasForeignKey(s => s.RideId).OnDelete(DeleteBehavior.Cascade);
    }
}

/// <summary>
/// Looks at a ride that was just read for the first time and uses, or suggests, a higher maximum and threshold heart
/// rate (Friel's 30-minute test for the threshold). Runs only from <see cref="RideIngestionService"/>: a re-read and a
/// duplicate never get here. Everything it writes joins the caller's SaveChanges.
/// </summary>
public static class HeartRateDetection
{
    private const int MedianWindowS = 5;
    private const int MinMaxCandidate = 120;
    private const int MaxMaxCandidate = 220;
    private const int MaxAgeDaysMax = 365;
    private const int MaxAgeDaysThreshold = 42;
    private const int MaxRisePerSecond = 10;
    private const int RiseWindowS = 10;
    private const int ThresholdWindowS = 30 * 60;
    private const int ThresholdStepS = 60;
    private const int ThresholdLastPartS = 20 * 60;
    private const double MinPresentShare = 0.90;

    /// <summary>
    /// The smoothed heart rate at 1 Hz over moving time, or null when the ride holds none: a gap the pause threshold
    /// makes a pause, or a second whose sample has no heart rate, is left out rather than counted.
    /// </summary>
    public static double[]? Smoothed(IReadOnlyList<Sample> samples, IReadOnlyList<PauseInterval> pauses)
    {
        var pause = RideMetrics.PauseThresholdS(samples);
        var result = new List<double>();
        for (var i = 0; i + 1 < samples.Count; i++)
        {
            var dt = samples[i + 1].T - samples[i].T;
            if (dt <= 0 || dt > pause || pauses.Any(p => p.StartS < samples[i + 1].T && p.EndS > samples[i].T)) continue;
            if (samples[i].HeartRate is not { } bpm) continue;
            // At least the second the sample lasted, so a sub-second record still holds one.
            var seconds = Math.Max((int)Math.Round(dt), 1);
            for (var s = 0; s < seconds; s++) result.Add(bpm);
        }

        if (result.Count == 0) return null;

        // A 5-second rolling median: one sample a strap lost contact for disappears; a held value stays.
        var smoothed = new double[result.Count];
        var half = MedianWindowS / 2;
        for (var i = 0; i < result.Count; i++)
            smoothed[i] = Median(result[Math.Max(0, i - half)..Math.Min(result.Count, i + half + 1)]);
        return smoothed;
    }

    /// <summary>The highest smoothed value, when it is plausible: in range and not a jump a heart cannot make.</summary>
    public static int? MaxCandidate(double[] smoothed)
    {
        if (smoothed.Length == 0) return null;
        var peak = 0;
        for (var i = 1; i < smoothed.Length; i++)
            if (smoothed[i] > smoothed[peak]) peak = i;

        var bpm = (int)Math.Round(smoothed[peak]);
        if (bpm < MinMaxCandidate || bpm > MaxMaxCandidate) return null;
        // A strap losing contact jumps; a heart does not.
        for (var i = Math.Max(1, peak - RiseWindowS + 1); i <= peak; i++)
            if (smoothed[i] - smoothed[i - 1] > MaxRisePerSecond) return null;
        return bpm;
    }

    /// <summary>
    /// Friel's 30-minute test on any ride: the 30-minute window with the highest mean smoothed heart rate, of which the
    /// last 20 minutes are averaged. A window under the 90 % heart rate coverage gives way to the next best.
    /// </summary>
    public static int? ThresholdCandidate(double[] smoothed)
    {
        var enough = (int)Math.Ceiling(ThresholdWindowS * MinPresentShare);
        int? best = null;
        double bestMean = 0;
        // Every window that fits, counted up front: the last one ends on the final second.
        var windows = (smoothed.Length - ThresholdWindowS) / ThresholdStepS + 1;
        for (var i = 0; i < windows; i++)
        {
            var start = i * ThresholdStepS;
            var window = smoothed.Skip(start).Take(ThresholdWindowS).ToList();
            if (window.Count < enough) continue;
            var mean = window.Average();
            if (best is not null && mean <= bestMean) continue;
            best = (int)Math.Round(smoothed.Skip(start + ThresholdWindowS - ThresholdLastPartS).Take(ThresholdLastPartS).Average());
            bestMean = mean;
        }

        return best;
    }

    /// <summary>
    /// Uses what the ride shows, or stages the question, without saving. Only a higher number counts; a typed number is
    /// never replaced, only suggested. Returns the note the ride carries.
    /// </summary>
    public static async Task<string?> AddAsync(
        VelomineDbContext db, TimeProvider time, MemberClock clock, User user, Ride ride,
        IReadOnlyList<Sample> samples, IReadOnlyList<PauseInterval> pauses, SetHeartRateValue setValue, CancellationToken ct)
    {
        if (ride.Status != RideStatus.Ready || ride.StartTime is not { } start) return null;
        if (Smoothed(samples, pauses) is not { } smoothed) return null;

        var today = clock.Today;
        var localDate = clock.LocalDateOf(start, ride.UtcOffsetMinutes);
        return await StepMaxAsync(db, time, user, ride, smoothed, today, localDate, setValue, ct)
            ?? await StepThresholdAsync(db, time, user, ride, smoothed, today, localDate, setValue, ct);
    }

    private static async Task<string?> StepMaxAsync(
        VelomineDbContext db, TimeProvider time, User user, Ride ride, double[] smoothed,
        DateOnly today, DateOnly localDate, SetHeartRateValue setValue, CancellationToken ct)
    {
        if (localDate < today.AddDays(-MaxAgeDaysMax)) return null;
        if (MaxCandidate(smoothed) is not { } candidate) return null;
        var (max, _) = HeartRates.For(user, time);
        var maxNow = await HeartRates.LatestAsync(db, user.Id, HeartRateKinds.Max, max, ct);
        // A lower number never replaces anything; with no number in use, any ride in range is news.
        if (maxNow?.Bpm is { } inUse && candidate < inUse + 1) return null;

        if (maxNow?.Source == HeartRateSources.Manual)
            return await SuggestAsync(db, time, ride, HeartRateKinds.Max, candidate, ct) ? HeartRateNotes.MaxSuggested : null;

        await setValue.SetAsync(user, HeartRateKinds.Max, candidate, HeartRateSources.Measured, ride.Id, ct);
        if (ride.NotifiesMember)
            Notify.Add(db, time, ride.UserId, NotificationTypes.HeartRateMeasured, $"Maximum {candidate} bpm", rideId: ride.Id);
        return HeartRateNotes.MaxMeasured;
    }

    private static async Task<string?> StepThresholdAsync(
        VelomineDbContext db, TimeProvider time, User user, Ride ride, double[] smoothed,
        DateOnly today, DateOnly localDate, SetHeartRateValue setValue, CancellationToken ct)
    {
        if (localDate < today.AddDays(-MaxAgeDaysThreshold)) return null;
        if (ThresholdCandidate(smoothed) is not { } candidate) return null;
        var (max, threshold) = HeartRates.For(user, time);
        var maxNow = await HeartRates.LatestAsync(db, user.Id, HeartRateKinds.Max, max, ct);
        // The threshold is always below the maximum, after this ride's own step has run.
        if (maxNow?.Bpm is { } maxBpm && candidate >= maxBpm) return null;
        if (threshold?.Bpm is { } inUse && candidate < inUse + 1) return null;

        if (threshold?.Source == HeartRateSources.Manual)
            return await SuggestAsync(db, time, ride, HeartRateKinds.Threshold, candidate, ct)
                ? HeartRateNotes.ThresholdSuggested
                : null;

        await setValue.SetAsync(user, HeartRateKinds.Threshold, candidate, HeartRateSources.Measured, ride.Id, ct);
        if (ride.NotifiesMember)
            Notify.Add(db, time, ride.UserId, NotificationTypes.HeartRateMeasured, $"Threshold {candidate} bpm", rideId: ride.Id);
        return HeartRateNotes.ThresholdMeasured;
    }

    /// <summary>Stages the question for one number, replacing the open one when this ride shows more. False when nothing is staged.</summary>
    private static async Task<bool> SuggestAsync(
        VelomineDbContext db, TimeProvider time, Ride ride, string kind, int bpm, CancellationToken ct)
    {
        var open = await db.HeartRateSuggestions
            .Where(s => s.UserId == ride.UserId && s.Kind == kind && s.Status == HeartRateSuggestionStatuses.Open)
            .OrderByDescending(s => s.CreatedAt).ThenByDescending(s => s.Id)
            .ToListAsync(ct);
        var existing = open.FirstOrDefault();
        // The unique index allows one open row; two can only be here because a change is already in progress.
        foreach (var older in open.Skip(1)) older.Status = HeartRateSuggestionStatuses.Replaced;

        if (existing is not null && bpm <= existing.Bpm) return false;

        if (existing is not null) existing.Status = HeartRateSuggestionStatuses.Replaced;
        db.HeartRateSuggestions.Add(new HeartRateSuggestion
        {
            Id = Guid.CreateVersion7(),
            UserId = ride.UserId,
            RideId = ride.Id,
            Kind = kind,
            Bpm = bpm,
            CreatedAt = time.GetUtcNow(),
            Status = HeartRateSuggestionStatuses.Open,
        });
        if (ride.NotifiesMember)
            Notify.Add(db, time, ride.UserId, NotificationTypes.HeartRateSuggested,
                $"{(kind == HeartRateKinds.Max ? "Maximum" : "Threshold")} {bpm} bpm", rideId: ride.Id);
        return true;
    }

    private static double Median(List<double> values)
    {
        values.Sort();
        var middle = values.Count / 2;
        return values.Count % 2 == 1 ? values[middle] : (values[middle - 1] + values[middle]) / 2;
    }
}
