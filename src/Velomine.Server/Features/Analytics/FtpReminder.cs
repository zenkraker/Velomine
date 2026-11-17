using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Analytics;

/// <summary>
/// Why the FTP may be out of date: <c>stale</c>, <c>estimate_higher</c> or <c>missing</c>, and null when nothing
/// applies or the member asked not to be reminded yet. <see cref="FtpAgeDays"/> counts from the newest FTP the
/// member set; <see cref="EstimateW"/> is the power curve's FTP over the last 42 days.
/// </summary>
public sealed record FtpCheckResponse(
    string? Reason,
    int? FtpW,
    int? FtpAgeDays,
    int? EstimateW,
    string? EstimateMethod);

/// <summary>
/// The FTP reminder, worked out on the member's own calendar. Stale: the FTP is 42 days old and the member has
/// ridden with power in the last 28 days. Estimate higher: the 42-day estimate is 5 % or more above the FTP.
/// Nothing is stored; the snooze is the only state, and setting the FTP clears it. Owner only: a coach never sees it.
/// </summary>
public sealed class GetFtpCheck(VelomineDbContext db, TimeProvider time)
    : EndpointWithoutRequest<FtpCheckResponse>
{
    private const int StaleDays = 42;
    private const int PowerRideDays = 28;

    public override void Configure()
    {
        Get("analytics/ftp-check");
        Description(d => d.Produces<FtpCheckResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var user = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new { u.FtpW, u.FtpReminderSnoozedUntil })
            .FirstAsync(ct);
        var ftp = user.FtpW;
        var snoozed = user.FtpReminderSnoozedUntil is { } until && clock.Today < until;

        // The FTP's age is its newest history row, the one the profile shows.
        DateOnly? setOn = null;
        if (ftp is not null)
        {
            var setAt = await db.FtpHistory.AsNoTracking()
                .Where(h => h.UserId == userId)
                .OrderByDescending(h => h.SetAt).ThenByDescending(h => h.Id)
                .Select(h => (DateTimeOffset?)h.SetAt)
                .FirstOrDefaultAsync(ct);
            if (setAt is { } instant) setOn = DateOnly.FromDateTime(instant.UtcDateTime);
        }

        var ageDays = setOn is { } day ? clock.Today.DayNumber - day.DayNumber : (int?)null;
        var estimate = (await FitnessQueries.PowerCurveAsync(
            db, clock, userId, StaleDays, includeBodyMetrics: false, ct)).Ftp;

        var reason = await ReasonAsync(db, clock, userId, ftp, ageDays, estimate?.Watts, snoozed, ct);
        await Send.OkAsync(
            new FtpCheckResponse(
                reason,
                ftp,
                ageDays,
                estimate?.Watts,
                estimate?.Method),
            ct);
    }

    /// <summary>
    /// The first rule that applies: the estimate wins over stale when both do, because a higher number is the
    /// stronger claim. The rides are read only when the FTP is old enough for the stale rule to matter.
    /// </summary>
    private static async Task<string?> ReasonAsync(
        VelomineDbContext db,
        MemberClock clock,
        Guid userId,
        int? ftp,
        int? ageDays,
        int? estimateW,
        bool snoozed,
        CancellationToken ct)
    {
        if (snoozed) return null;

        if (ftp is not { } currentFtp)
            return estimateW is null ? null : FtpReminderReasons.Missing;

        if (estimateW is { } higher && higher >= currentFtp * 1.05)
            return FtpReminderReasons.EstimateHigher;

        if (ageDays is null || ageDays < StaleDays) return null;

        var now = clock.Today;
        var from = now.AddDays(-(PowerRideDays - 1));
        // Local dates are at most 14 hours from UTC, so a day either side catches every ride; the exact cut is below.
        var fromUtc = new DateTimeOffset(from.AddDays(-1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var toUtc = new DateTimeOffset(now.AddDays(1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var rides = await db.Rides.AsNoTracking()
            .Where(r => r.UserId == userId && r.Status == RideStatus.Ready
                && r.StartTime >= fromUtc && r.StartTime < toUtc
                && r.NormalizedPowerW != null)
            .Select(r => new { r.StartTime, r.UtcOffsetMinutes })
            .ToListAsync(ct);

        return rides.Any(r => clock.LocalDateOf(r.StartTime!.Value, r.UtcOffsetMinutes) >= from)
            ? FtpReminderReasons.Stale
            : null;
    }
}

/// <summary>What <see cref="GetFtpCheck"/> answers as its reason.</summary>
public static class FtpReminderReasons
{
    public const string Stale = "stale";
    public const string EstimateHigher = "estimate_higher";
    public const string Missing = "missing";
}

/// <summary>"Not now": the reminder stays quiet for fourteen days, counted on the member's calendar.</summary>
public sealed class SnoozeFtpCheck(VelomineDbContext db, TimeProvider time) : EndpointWithoutRequest
{
    public override void Configure()
    {
        Post("analytics/ftp-check/snooze");
        Description(d => d.Produces(204).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        await db.Users.Where(u => u.Id == userId)
            .ExecuteUpdateAsync(s => s.SetProperty(u => u.FtpReminderSnoozedUntil, clock.Today.AddDays(14)), ct);
        await Send.NoContentAsync(ct);
    }
}
