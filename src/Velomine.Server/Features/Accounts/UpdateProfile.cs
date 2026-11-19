using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

/// <summary>Changing the profile: all fields are sent each time; null clears a value. EmailNotifications is kept when left out.</summary>
public sealed record UpdateProfileRequest(
    string DisplayName,
    int? FtpW,
    double? WeightKg,
    int? BirthYear,
    string? TimeZone,
    string FirstDayOfWeek,
    bool? EmailNotifications = null,
    bool? EmailAccountNotifications = null,
    bool? EmailTrainingNotifications = null,
    /// <summary>Left out keeps the current maximum; null goes back to the estimate.</summary>
    int? MaxHeartRate = null,
    /// <summary>Left out keeps the current threshold; null goes back to 89 % of the maximum.</summary>
    int? ThresholdHeartRate = null);

public sealed class UpdateProfileValidator : Validator<UpdateProfileRequest>
{
    public UpdateProfileValidator()
    {
        RuleFor(x => x.DisplayName).NotEmpty().MaximumLength(100);
        RuleFor(x => x.FtpW).InclusiveBetween(30, 1000);
        RuleFor(x => x.WeightKg).InclusiveBetween(20, 300);
        RuleFor(x => x.BirthYear)
            .InclusiveBetween(1900, DateTime.UtcNow.Year - 10)
            .WithMessage("Enter a year of birth from 1900 to ten years ago.");
        RuleFor(x => x.TimeZone)
            .MaximumLength(64)
            .Must(z => z is null || TimeZoneInfo.TryFindSystemTimeZoneById(z, out _))
            .WithMessage("Use a time zone name such as Europe/Rome.");
        RuleFor(x => x.FirstDayOfWeek).Must(d => WeekDays.TryParse(d, out _)).WithMessage("Use a day such as monday or sunday.");
        RuleFor(x => x.MaxHeartRate).InclusiveBetween(HeartRates.MinMax, HeartRates.MaxMax);
        RuleFor(x => x.ThresholdHeartRate).InclusiveBetween(HeartRates.MinThreshold, HeartRates.MaxThreshold);
    }
}

public sealed class UpdateProfile(VelomineDbContext db, SetFtpValue setFtp, SetHeartRateValue setHeartRate, TimeProvider time)
    : Endpoint<UpdateProfileRequest, ProfileResponse>
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
        if (req.FtpW is { } ftp) setFtp.Set(user, ftp, FtpSources.Manual);
        else user.FtpW = null; // clearing it is not a new FTP: history keeps the numbers that were set
        user.WeightKg = req.WeightKg is { } kg ? Math.Round(kg, 1) : null;
        user.BirthYear = req.BirthYear;
        user.TimeZone = string.IsNullOrWhiteSpace(req.TimeZone) ? null : req.TimeZone.Trim();
        user.FirstDayOfWeek = firstDay;
        user.EmailNotifications = req.EmailNotifications ?? user.EmailNotifications;
        user.EmailAccountNotifications = req.EmailAccountNotifications ?? user.EmailAccountNotifications;
        user.EmailTrainingNotifications = req.EmailTrainingNotifications ?? user.EmailTrainingNotifications;
        // The heart-rate fields are left out by an older app, which stays with what is set; a null goes to the estimate.
        if (req.MaxHeartRate is { } maxHr) await setHeartRate.SetAsync(user, HeartRateKinds.Max, maxHr, HeartRateSources.Manual, null, ct);
        else if (req.ThresholdHeartRate is not null) await setHeartRate.ClearAsync(user, HeartRateKinds.Max, ct);
        if (req.ThresholdHeartRate is { } thresholdHr) await setHeartRate.SetAsync(user, HeartRateKinds.Threshold, thresholdHr, HeartRateSources.Manual, null, ct);
        else if (req.MaxHeartRate is not null) await setHeartRate.ClearAsync(user, HeartRateKinds.Threshold, ct);
        await db.SaveChangesAsync(ct);

        await Send.OkAsync(await GetProfile.ProfileOfAsync(db, user, time, ct), ct);
    }
}
