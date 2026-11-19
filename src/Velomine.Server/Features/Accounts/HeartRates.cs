using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Data;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Accounts;

/// <summary>How a heart-rate number was set: typed by the rider, measured in a ride, or cleared back to the estimate.</summary>
public static class HeartRateSources
{
    public const string Manual = "manual";
    public const string Measured = "measured";
    public const string Cleared = "cleared";
}

/// <summary>The two numbers: the maximum and the threshold.</summary>
public static class HeartRateKinds
{
    public const string Max = "max";
    public const string Threshold = "threshold";

    /// <summary>The kind the path names, or false for anything else.</summary>
    public static bool TryParse(string? kind, out string parsed)
    {
        parsed = kind == Threshold ? Threshold : Max;
        return kind is not null && (kind == Max || kind == Threshold);
    }

    /// <summary>Whether a value is inside the range of that number: the maximum 120–230, the threshold 90–220.</summary>
    public static bool InRange(string kind, int bpm) => kind == Max
        ? bpm is >= HeartRates.MinMax and <= HeartRates.MaxMax
        : bpm is >= HeartRates.MinThreshold and <= HeartRates.MaxThreshold;
}

/// <summary>
/// One heart-rate number in use: its value and where it came from (null when neither set nor estimated), and from
/// which ride when a ride measured it.
/// </summary>
public sealed record HeartRate(int? Bpm, string? Source, Guid? RideId = null);

/// <summary>
/// The member's two heart-rate numbers. A set value is the one the rider typed or a ride measured; without one the
/// maximum is Tanaka's estimate from the birth year and the threshold 89 % of it. An estimate is never stored.
/// </summary>
public static class HeartRates
{
    public const int MinMax = 120;
    public const int MaxMax = 230;
    public const int MinThreshold = 90;
    public const int MaxThreshold = 220;

    /// <summary>
    /// The one rule a threshold keeps against the maximum: it stays below the maximum in use, or the caller answers
    /// 400 with this reason. A maximum lowered below a threshold afterwards is the rider's own business.
    /// </summary>
    public static string? ThresholdProblem(string kind, int bpm, HeartRate? max) =>
        kind == HeartRateKinds.Threshold && max?.Bpm is { } maxBpm && bpm >= maxBpm
            ? $"The threshold must be below the maximum in use ({maxBpm} bpm)."
            : null;

    /// <summary>
    /// The two numbers with where each came from and which ride measured it, read from the account's own columns: no
    /// history lookup. A value whose source column is null reads as typed, which is what the backfill left set.
    /// </summary>
    public static (HeartRate? Max, HeartRate? Threshold) For(User user, TimeProvider time)
    {
        var max = user.MaxHeartRateBpm is { } typed
            ? new HeartRate(typed, user.MaxHeartRateSource ?? HeartRateSources.Manual, user.MaxHeartRateRideId)
            : User.EstimateMaxHeartRate(user.BirthYear, time) is { } estimated
                ? new HeartRate(estimated, FtpSources.Estimate)
                : null;
        var threshold = user.ThresholdHeartRateBpm is { } set
            ? new HeartRate(set, user.ThresholdHeartRateSource ?? HeartRateSources.Manual, user.ThresholdHeartRateRideId)
            : max?.Bpm is { } m
                ? new HeartRate((int)Math.Round(m * 0.89), FtpSources.Estimate)
                : null;
        return (max, threshold);
    }
}

/// <summary>
/// One value a heart-rate number has had, when it was set and how. Written in the same save as a change of the set
/// value; <c>cleared</c> says the rider went back to the estimate and carries the value it held.
/// </summary>
public sealed class HeartRateHistory
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    /// <summary><see cref="HeartRateKinds.Max"/> or <see cref="HeartRateKinds.Threshold"/>.</summary>
    public string Kind { get; set; } = HeartRateKinds.Max;

    public int Bpm { get; set; }

    public DateTimeOffset SetAt { get; set; }

    /// <summary>Position among the rows of one kind at the same <see cref="SetAt"/>, so the order is total.</summary>
    public int Sequence { get; set; }

    /// <summary><see cref="HeartRateSources.Manual"/>, <see cref="HeartRateSources.Measured"/> or <see cref="HeartRateSources.Cleared"/>.</summary>
    public string Source { get; set; } = HeartRateSources.Manual;

    /// <summary>The ride a <c>measured</c> value came from; null for every other source.</summary>
    public Guid? RideId { get; set; }
}

public sealed class HeartRateHistoryConfiguration : IEntityTypeConfiguration<HeartRateHistory>
{
    public void Configure(EntityTypeBuilder<HeartRateHistory> b)
    {
        b.ToTable("heart_rate_history", t =>
        {
            t.HasCheckConstraint("ck_heart_rate_history_kind", "kind IN ('max', 'threshold')");
            t.HasCheckConstraint("ck_heart_rate_history_bpm", "bpm BETWEEN 80 AND 230");
            t.HasCheckConstraint("ck_heart_rate_history_source", "source IN ('manual', 'measured', 'cleared')");
            // Only a measured number comes from a ride.
            t.HasCheckConstraint("ck_heart_rate_history_ride", "ride_id IS NULL OR source = 'measured'");
        });
        b.HasKey(h => h.Id);
        // The newest row is the current one, so the order is total. PostgreSQL keeps microseconds, and a clock that
        // does not tick writes new rows on the same instant, so set_at alone cannot separate two writes.
        b.HasIndex(h => new { h.UserId, h.Kind, h.SetAt, h.Sequence }).IsDescending(false, false, true, true);
        b.HasOne<User>().WithMany().HasForeignKey(h => h.UserId).OnDelete(DeleteBehavior.Cascade);
        b.HasOne<Ride>().WithMany().HasForeignKey(h => h.RideId).OnDelete(DeleteBehavior.SetNull);
    }
}

/// <summary>
/// The one way a heart-rate number changes: sets the value or puts it back to the estimate, and stages its history
/// row. The caller's own <c>SaveChangesAsync</c> writes all of it, and nothing is written for a number that is
/// unchanged.
/// </summary>
public sealed class SetHeartRateValue(VelomineDbContext db, TimeProvider time)
{
    public async Task SetAsync(User user, string kind, int bpm, string source, Guid? rideId, CancellationToken ct)
    {
        if (Current(user, kind) == bpm) return;
        Assign(user, kind, bpm, source, rideId);
        await AddAsync(user, kind, bpm, source, rideId, ct);
    }

    /// <summary>Back to the estimate: the history keeps the number that was set, marked <c>cleared</c>.</summary>
    public async Task ClearAsync(User user, string kind, CancellationToken ct)
    {
        if (Current(user, kind) is not { } was) return;
        Assign(user, kind, null, null, null);
        await AddAsync(user, kind, was, HeartRateSources.Cleared, null, ct);
    }

    private static int? Current(User user, string kind) =>
        kind == HeartRateKinds.Max ? user.MaxHeartRateBpm : user.ThresholdHeartRateBpm;

    /// <summary>The value, its source and the ride that measured it move together, so the three never disagree.</summary>
    private static void Assign(User user, string kind, int? bpm, string? source, Guid? rideId)
    {
        if (kind == HeartRateKinds.Max)
        {
            user.MaxHeartRateBpm = bpm;
            user.MaxHeartRateSource = source;
            user.MaxHeartRateRideId = rideId;
        }
        else
        {
            user.ThresholdHeartRateBpm = bpm;
            user.ThresholdHeartRateSource = source;
            user.ThresholdHeartRateRideId = rideId;
        }
    }

    /// <summary>
    /// The row of one change, after every earlier one of the same kind: a new row on the same instant takes the next
    /// place, so the newest row is the truth even when the clock does not tick between two writes.
    /// </summary>
    private async Task AddAsync(User user, string kind, int bpm, string source, Guid? rideId, CancellationToken ct)
    {
        var setAt = time.GetUtcNow();
        var previous = await db.HeartRateHistory.AsNoTracking()
            .Where(h => h.UserId == user.Id && h.Kind == kind && h.SetAt >= setAt)
            .OrderByDescending(h => h.SetAt).ThenByDescending(h => h.Sequence)
            .Select(h => new { h.SetAt, h.Sequence })
            .FirstOrDefaultAsync(ct);
        var sequence = 0;
        if (previous?.SetAt == setAt) sequence = previous.Sequence + 1;
        // A single tick is 100 ns and the column keeps microseconds: stepping by one would come back to the same
        // instant, so a changed time steps a microsecond.
        else if (previous is not null) setAt = previous.SetAt.AddTicks(10);
        db.HeartRateHistory.Add(new HeartRateHistory
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Kind = kind,
            Bpm = bpm,
            SetAt = setAt,
            Sequence = sequence,
            Source = source,
            RideId = rideId,
        });
    }
}
