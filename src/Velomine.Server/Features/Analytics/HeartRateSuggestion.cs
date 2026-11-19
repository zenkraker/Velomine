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

    /// <summary>
    /// Whether the legacy column holds the maximum's note: it keeps the maximum first, and only falls back to the
    /// threshold's when the ride moved nothing else.
    /// </summary>
    public static bool IsMax(string? note) => note?.StartsWith("max_", StringComparison.Ordinal) == true;
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
/// A heart rate held once per wall-clock second: the value of the last sample at or before that second, and whether the
/// second was paused. A missing signal and a pause are different facts, so a window can tell them apart.
/// </summary>
public sealed record HeartRateSeries(double?[] Values, bool[] Paused);

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
    // 90 % of the window, in whole seconds: 1,620 of 1,800.
    private const int MinimumPresentS = ThresholdWindowS * 9 / 10;
    // shortcut: a ride spanning more than a day holds no effort worth scanning, and keeps the series small; lift it if
    // a longer record ever matters.
    private const int MaxSeriesSeconds = 24 * 60 * 60;

    /// <summary>
    /// The smoothed heart rate at 1 Hz by wall-clock second, or null when the ride holds none: a sample holds until the
    /// next one, a second in a pause or in a gap the pause threshold makes a pause is marked paused, and a second whose
    /// sample has no heart rate stays empty.
    /// </summary>
    public static HeartRateSeries? Smoothed(IReadOnlyList<Sample> samples, IReadOnlyList<PauseInterval> pauses)
    {
        // A sample at or before the one before it says nothing about the next second.
        var ordered = new List<Sample>(samples.Count);
        foreach (var sample in samples)
            if (ordered.Count == 0 || sample.T > ordered[^1].T) ordered.Add(sample);
        if (ordered.Count == 0) return null;

        var pause = RideMetrics.PauseThresholdS(samples);
        var first = Math.Floor(ordered[0].T);
        var span = Math.Min(Math.Floor(ordered[^1].T - first), MaxSeriesSeconds);
        var values = new double?[(int)span + 1];
        var paused = new bool[values.Length];
        var held = 0;
        for (var s = 0; s < values.Length; s++)
        {
            var second = first + s;
            while (held + 1 < ordered.Count && ordered[held + 1].T <= second) held++;
            var sample = ordered[held];
            var gap = held + 1 < ordered.Count ? ordered[held + 1].T - sample.T : 0;
            if (gap > pause || pauses.Any(p => p.StartS < second + 1 && p.EndS > second))
            {
                paused[s] = true;
                continue;
            }

            values[s] = sample.HeartRate;
        }

        // A 5-second rolling median over the present neighbours: one sample a strap lost contact for disappears; a held
        // value stays.
        var smoothed = new double?[values.Length];
        var half = MedianWindowS / 2;
        for (var i = 0; i < values.Length; i++)
        {
            var window = new List<double>(MedianWindowS);
            for (var j = Math.Max(0, i - half); j <= Math.Min(values.Length - 1, i + half); j++)
                if (values[j] is { } value) window.Add(value);
            if (window.Count > 0) smoothed[i] = Median(window);
        }

        return Array.Exists(smoothed, v => v is not null) ? new HeartRateSeries(smoothed, paused) : null;
    }

    /// <summary>The highest smoothed value, when it is plausible: in range and not a jump a heart cannot make.</summary>
    public static int? MaxCandidate(HeartRateSeries series)
    {
        // A paused second holds no effort, and its smoothed value only repeats its neighbours.
        var smoothed = new List<double>(series.Values.Length);
        for (var i = 0; i < series.Values.Length; i++)
            if (!series.Paused[i] && series.Values[i] is { } value) smoothed.Add(value);
        if (smoothed.Count == 0) return null;
        var peak = 0;
        for (var i = 1; i < smoothed.Count; i++)
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
    /// last 20 minutes are averaged. A window with a pause in it, or under the 90 % heart rate coverage, gives way to the
    /// next best.
    /// </summary>
    public static int? ThresholdCandidate(HeartRateSeries series)
    {
        var values = series.Values;
        if (values.Length < ThresholdWindowS) return null;
        // Every window that fits, counted up front: the last one ends on the final second.
        var windows = (values.Length - ThresholdWindowS) / ThresholdStepS + 1;

        // Prefix sums and counts keep one pass over a long ride linear.
        var sum = new double[values.Length + 1];
        var present = new int[values.Length + 1];
        var pauses = new int[values.Length + 1];
        for (var i = 0; i < values.Length; i++)
        {
            sum[i + 1] = sum[i] + (values[i] ?? 0);
            present[i + 1] = present[i] + (values[i] is null ? 0 : 1);
            pauses[i + 1] = pauses[i] + (series.Paused[i] ? 1 : 0);
        }

        int? best = null;
        double bestMean = 0;
        for (var i = 0; i < windows; i++)
        {
            var start = i * ThresholdStepS;
            var end = start + ThresholdWindowS;
            if (pauses[end] - pauses[start] > 0) continue;
            var count = present[end] - present[start];
            if (count < MinimumPresentS) continue;
            var mean = (sum[end] - sum[start]) / count;
            if (best is not null && mean <= bestMean) continue;
            var lastPart = end - ThresholdLastPartS;
            var lastCount = present[end] - present[lastPart];
            if (lastCount == 0) continue;
            best = (int)Math.Round((sum[end] - sum[lastPart]) / lastCount);
            bestMean = mean;
        }

        return best;
    }

    /// <summary>
    /// Uses what the ride shows for both numbers, or stages the question for each, without saving. Only a higher
    /// number counts; a typed number is never replaced, only suggested. The threshold is judged against the maximum
    /// this same ride leaves in use, so a maximum that was only suggested has not moved it. Returns the note for each
    /// number, in that order.
    /// </summary>
    public static async Task<(string? Max, string? Threshold)> AddAsync(
        VelomineDbContext db, TimeProvider time, MemberClock clock, User user, Ride ride,
        IReadOnlyList<Sample> samples, IReadOnlyList<PauseInterval> pauses, SetHeartRateValue setValue, CancellationToken ct)
    {
        if (ride.Status != RideStatus.Ready || ride.StartTime is not { } start) return (null, null);
        if (Smoothed(samples, pauses) is not { } series) return (null, null);

        var today = clock.Today;
        var localDate = clock.LocalDateOf(start, ride.UtcOffsetMinutes);
        var max = await StepMaxAsync(db, time, user, ride, series, today, localDate, setValue, ct);
        var threshold = await StepThresholdAsync(db, time, user, ride, series, today, localDate, setValue, ct);
        return (max, threshold);
    }

    private static async Task<string?> StepMaxAsync(
        VelomineDbContext db, TimeProvider time, User user, Ride ride, HeartRateSeries series,
        DateOnly today, DateOnly localDate, SetHeartRateValue setValue, CancellationToken ct)
    {
        if (localDate < today.AddDays(-MaxAgeDaysMax)) return null;
        if (MaxCandidate(series) is not { } candidate) return null;
        var (max, _) = HeartRates.For(user, time);
        // A lower number never replaces anything; with no number in use, any ride in range is news.
        if (max?.Bpm is { } inUse && candidate < inUse + 1) return null;

        if (max?.Source == HeartRateSources.Manual)
            return await SuggestAsync(db, time, ride, HeartRateKinds.Max, candidate, ct) ? HeartRateNotes.MaxSuggested : null;

        await setValue.SetAsync(user, HeartRateKinds.Max, candidate, HeartRateSources.Measured, ride.Id, ct);
        if (ride.NotifiesMember)
            Notify.Add(db, time, ride.UserId, NotificationTypes.HeartRateMeasured, $"Maximum {candidate} bpm", rideId: ride.Id);
        return HeartRateNotes.MaxMeasured;
    }

    private static async Task<string?> StepThresholdAsync(
        VelomineDbContext db, TimeProvider time, User user, Ride ride, HeartRateSeries series,
        DateOnly today, DateOnly localDate, SetHeartRateValue setValue, CancellationToken ct)
    {
        if (localDate < today.AddDays(-MaxAgeDaysThreshold)) return null;
        if (ThresholdCandidate(series) is not { } candidate) return null;
        var (max, threshold) = HeartRates.For(user, time);
        // The threshold is always below the maximum, after this ride's own step has run.
        if (max?.Bpm is { } maxBpm && candidate >= maxBpm) return null;
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
