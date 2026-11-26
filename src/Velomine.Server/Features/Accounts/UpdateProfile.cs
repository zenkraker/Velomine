using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Changing the profile: every field is sent each time except the two heart rates, which are only set when they arrive.
/// Null clears a profile value as it always did; clearing a heart rate goes through its DELETE endpoint.
/// </summary>
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
    /// <summary>Left out or null keeps the current maximum.</summary>
    int? MaxHeartRate = null,
    /// <summary>Left out or null keeps the current threshold.</summary>
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
        // The two heart rates are set only: a released app does not send them at all, and saving its profile must not
        // wipe a number it cannot see. Clearing goes through DELETE /accounts/me/heart-rate/{kind}.
        if (req.MaxHeartRate is { } maxHr) await setHeartRate.SetAsync(user, HeartRateKinds.Max, maxHr, HeartRateSources.Manual, null, ct);
        if (req.ThresholdHeartRate is { } thresholdHr)
        {
            // The maximum is applied first, so two numbers arriving together are judged in the order they are read.
            if (HeartRates.ThresholdProblem(HeartRateKinds.Threshold, thresholdHr, HeartRates.For(user, time).Max) is { } problem)
            {
                await Send.ResultAsync(TypedResults.Problem(problem, statusCode: StatusCodes.Status400BadRequest));
                return;
            }
            await setHeartRate.SetAsync(user, HeartRateKinds.Threshold, thresholdHr, HeartRateSources.Manual, null, ct);
        }
        await db.SaveChangesAsync(ct);

        await Send.OkAsync(await GetProfile.ProfileOfAsync(db, user, time, ct), ct);
    }
}
