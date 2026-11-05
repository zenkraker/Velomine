using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

/// <summary>Changing the profile: all fields are sent each time; null clears a value.</summary>
public sealed record UpdateProfileRequest(
    string DisplayName,
    int? FtpW,
    double? WeightKg,
    int? MaxHeartRate,
    string? TimeZone,
    string FirstDayOfWeek);

public sealed class UpdateProfileValidator : Validator<UpdateProfileRequest>
{
    public UpdateProfileValidator()
    {
        RuleFor(x => x.DisplayName).NotEmpty().MaximumLength(100);
        RuleFor(x => x.FtpW).InclusiveBetween(30, 1000);
        RuleFor(x => x.WeightKg).InclusiveBetween(20, 300);
        RuleFor(x => x.MaxHeartRate).InclusiveBetween(100, 240);
        RuleFor(x => x.TimeZone)
            .MaximumLength(64)
            .Must(z => z is null || TimeZoneInfo.TryFindSystemTimeZoneById(z, out _))
            .WithMessage("Use a time zone name such as Europe/Rome.");
        RuleFor(x => x.FirstDayOfWeek).Must(d => WeekDays.TryParse(d, out _)).WithMessage("Use a day such as monday or sunday.");
    }
}

public sealed class UpdateProfile(VelomineDbContext db) : Endpoint<UpdateProfileRequest, ProfileResponse>
{
    public override void Configure()
    {
        Put("accounts/me/profile");
        Description(d => d.Accepts<UpdateProfileRequest>("application/json").Produces<ProfileResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateProfileRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var user = await db.Users.FirstAsync(u => u.Id == userId, ct);
        WeekDays.TryParse(req.FirstDayOfWeek, out var firstDay);

        user.DisplayName = req.DisplayName.Trim();
        user.FtpW = req.FtpW;
        user.WeightKg = req.WeightKg is { } kg ? Math.Round(kg, 1) : null;
        user.MaxHeartRate = req.MaxHeartRate;
        user.TimeZone = string.IsNullOrWhiteSpace(req.TimeZone) ? null : req.TimeZone.Trim();
        user.FirstDayOfWeek = firstDay;
        await db.SaveChangesAsync(ct);

        await Send.OkAsync(GetProfile.ProfileOf(user), ct);
    }
}
