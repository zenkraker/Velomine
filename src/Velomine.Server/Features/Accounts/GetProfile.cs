using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

/// <summary>What the member tells Velomine about themselves. Null means not set.</summary>
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
    bool EmailTrainingNotifications);

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
        await Send.OkAsync(ProfileOf(user), ct);
    }

    public static ProfileResponse ProfileOf(User u) =>
        new(u.DisplayName, u.FtpW, u.WeightKg, u.BirthYear, u.MaxHeartRate, u.TimeZone, WeekDays.Name(u.FirstDayOfWeek), u.EmailNotifications, u.PasswordHash is not null, u.EmailAccountNotifications, u.EmailTrainingNotifications);
}
