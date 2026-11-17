using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

/// <summary>What the member tells Velomine about themselves. Null means not set. The FTP's date and source come from its history.</summary>
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
    string? FtpSource = null);

public sealed class GetProfile(VelomineDbContext db) : EndpointWithoutRequest<ProfileResponse>
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
        await Send.OkAsync(await ProfileOfAsync(db, user, ct), ct);
    }

    /// <summary>The profile, with when and how the current FTP was set: both null when the rider has no FTP.</summary>
    public static async Task<ProfileResponse> ProfileOfAsync(VelomineDbContext db, User u, CancellationToken ct)
    {
        var newest = u.FtpW is null
            ? null
            : await db.FtpHistory.AsNoTracking()
                .Where(h => h.UserId == u.Id)
                .OrderByDescending(h => h.SetAt).ThenByDescending(h => h.Id)
                .Select(h => new { h.SetAt, h.Source })
                .FirstOrDefaultAsync(ct);
        return ProfileOf(u) with { FtpSetAt = newest?.SetAt, FtpSource = newest?.Source };
    }

    public static ProfileResponse ProfileOf(User u) =>
        new(u.DisplayName, u.FtpW, u.WeightKg, u.BirthYear, u.MaxHeartRate, u.TimeZone, WeekDays.Name(u.FirstDayOfWeek), u.EmailNotifications, u.PasswordHash is not null, u.EmailAccountNotifications, u.EmailTrainingNotifications, u.SoloTrialEndsAt);
}
