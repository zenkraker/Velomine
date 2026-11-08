using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Wellbeing;

public sealed class SaveCheckInRequest
{
    /// <summary>1 fresh, 5 exhausted.</summary>
    public required int Fatigue { get; set; }

    /// <summary>1 none, 5 severe.</summary>
    public required int Soreness { get; set; }

    /// <summary>1 low, 5 great.</summary>
    public required int Mood { get; set; }

    /// <summary>1 calm, 5 very stressed.</summary>
    public required int Stress { get; set; }

    /// <summary>1 none, 5 high.</summary>
    public required int Motivation { get; set; }
}

public sealed class SaveCheckInValidator : Validator<SaveCheckInRequest>
{
    public SaveCheckInValidator()
    {
        RuleFor(x => x.Fatigue).InclusiveBetween(1, 5);
        RuleFor(x => x.Soreness).InclusiveBetween(1, 5);
        RuleFor(x => x.Mood).InclusiveBetween(1, 5);
        RuleFor(x => x.Stress).InclusiveBetween(1, 5);
        RuleFor(x => x.Motivation).InclusiveBetween(1, 5);
    }
}

/// <summary>Today's check-in, created or replaced. One per member per local day.</summary>
public sealed class SaveCheckIn(VelomineDbContext db, TimeProvider time)
    : Endpoint<SaveCheckInRequest, CheckInResponse>
{
    public override void Configure()
    {
        Put("wellbeing/check-ins/today");
        Description(d => d.Accepts<SaveCheckInRequest>("application/json").Produces<CheckInResponse>(200).ProducesProblem(400).Produces(401).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(SaveCheckInRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        if (!await WellbeingRules.HasConsentAsync(db, userId, ct))
        {
            AddError("Accept the wellbeing terms first.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var now = time.GetUtcNow();
        var checkIn = await db.DailyCheckIns
            .FirstOrDefaultAsync(c => c.UserId == userId && c.LocalDate == clock.Today, ct);
        if (checkIn is null)
        {
            checkIn = new DailyCheckIn
            {
                Id = Guid.CreateVersion7(),
                UserId = userId,
                LocalDate = clock.Today,
                CreatedAt = now,
            };
            db.DailyCheckIns.Add(checkIn);
        }

        checkIn.Fatigue = req.Fatigue;
        checkIn.Soreness = req.Soreness;
        checkIn.Mood = req.Mood;
        checkIn.Stress = req.Stress;
        checkIn.Motivation = req.Motivation;
        checkIn.UpdatedAt = now;
        await db.SaveChangesAsync(ct);

        await Send.OkAsync(CheckInResponse.From(checkIn), ct);
    }
}
