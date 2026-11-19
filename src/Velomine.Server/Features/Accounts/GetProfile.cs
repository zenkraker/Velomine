using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// What the member tells Velomine about themselves. Null means not set. The FTP's date and source come from its
/// history, and a test FTP also names the ride it came from, whose own start time is the day of the effort. The two
/// heart rates are the values in use, each with where it came from and, when it was set, when and from which ride.
/// </summary>
public sealed record ProfileResponse(
    string DisplayName,
    int? FtpW,
    double? WeightKg,
    int? BirthYear,
    int? MaxHeartRate,
    string? TimeZone,
    string FirstDayOfWeek,
    bool EmailNotifications,
    bool HasPassword,
    bool EmailAccountNotifications,
    bool EmailTrainingNotifications,
    DateOnly? SoloTrialEndsAt,
    DateTimeOffset? FtpSetAt = null,
    string? FtpSource = null,
    Guid? FtpRideId = null,
    string? MaxHeartRateSource = null,
    DateTimeOffset? MaxHeartRateSetAt = null,
    Guid? MaxHeartRateRideId = null,
    int? ThresholdHeartRate = null,
    string? ThresholdHeartRateSource = null,
    DateTimeOffset? ThresholdHeartRateSetAt = null,
    Guid? ThresholdHeartRateRideId = null);

public sealed class GetProfile(VelomineDbContext db, TimeProvider time) : EndpointWithoutRequest<ProfileResponse>
{
    public override void Configure()
    {
        Get("accounts/me/profile");
        Description(d => d.Produces<ProfileResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var user = await db.Users.AsNoTracking().FirstAsync(u => u.Id == userId, ct);
        await Send.OkAsync(await ProfileWithSourcesAsync(db, user, time, ct), ct);
    }

    /// <summary>
    /// The profile, with when and how the current FTP was set (both null when the rider has no FTP) and, when the
    /// newest row is a test, the ride it came from. The two heart rates come from <see cref="HeartRates"/>.
    /// </summary>
    public static async Task<ProfileResponse> ProfileOfAsync(VelomineDbContext db, User u, TimeProvider time, CancellationToken ct)
    {
        var newest = u.FtpW is null
            ? null
            : await db.FtpHistory.AsNoTracking()
                .Where(h => h.UserId == u.Id)
                .OrderByDescending(h => h.SetAt).ThenByDescending(h => h.Id)
                .Select(h => new { h.SetAt, h.Source, h.RideId })
                .FirstOrDefaultAsync(ct);
        var (max, threshold) = HeartRates.For(u, time);
        var setTimes = await db.HeartRateHistory.AsNoTracking()
            .Where(h => h.UserId == u.Id && h.Source != HeartRateSources.Cleared)
            .GroupBy(h => h.Kind)
            .Select(g => new { Kind = g.Key, SetAt = g.Max(h => h.SetAt) })
            .ToDictionaryAsync(x => x.Kind, x => x.SetAt, ct);
        return ProfileOf(u, time) with
        {
            FtpSetAt = newest?.SetAt,
            FtpSource = newest?.Source,
            FtpRideId = newest is { Source: FtpSources.Test } ? newest.RideId : null,
            MaxHeartRateSource = max?.Source,
            MaxHeartRateSetAt = max is { Source: not FtpSources.Estimate } ? setTimes.GetValueOrDefault(HeartRateKinds.Max) : null,
            MaxHeartRateRideId = max?.RideId,
            ThresholdHeartRate = threshold?.Bpm,
            ThresholdHeartRateSource = threshold?.Source,
            ThresholdHeartRateSetAt = threshold is { Source: not FtpSources.Estimate } ? setTimes.GetValueOrDefault(HeartRateKinds.Threshold) : null,
            ThresholdHeartRateRideId = threshold?.RideId,
        };
    }

    /// <summary>
    /// Where each set number came from: the newest history row says whether the rider typed it or a ride measured it,
    /// and which ride. An estimate keeps its source.
    /// </summary>
    public static async Task<ProfileResponse> ProfileWithSourcesAsync(
        VelomineDbContext db, User user, TimeProvider time, CancellationToken ct)
    {
        var profile = await ProfileOfAsync(db, user, time, ct);
        var (max, threshold) = HeartRates.For(user, time);
        var maxNow = await HeartRates.LatestAsync(db, user.Id, HeartRateKinds.Max, max, ct);
        var thresholdNow = await HeartRates.LatestAsync(db, user.Id, HeartRateKinds.Threshold, threshold, ct);
        return profile with
        {
            MaxHeartRateSource = maxNow?.Source,
            ThresholdHeartRateSource = thresholdNow?.Source,
        };
    }

    public static ProfileResponse ProfileOf(User u, TimeProvider time) => new(
        u.DisplayName,
        u.FtpW,
        u.WeightKg,
        u.BirthYear,
        HeartRates.For(u, time).Max?.Bpm,
        u.TimeZone,
        WeekDays.Name(u.FirstDayOfWeek),
        u.EmailNotifications,
        u.PasswordHash is not null,
        u.EmailAccountNotifications,
        u.EmailTrainingNotifications,
        u.SoloTrialEndsAt);
}
