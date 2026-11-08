namespace Velomine.Server.Features.Wellbeing;

/// <summary>One day's check-in as the member and their coaches see it.</summary>
public sealed record CheckInResponse(
    DateOnly Date,
    int Fatigue,
    int Soreness,
    int Mood,
    int Stress,
    int Motivation)
{
    public static CheckInResponse From(DailyCheckIn checkIn) =>
        new(checkIn.LocalDate, checkIn.Fatigue, checkIn.Soreness, checkIn.Mood, checkIn.Stress, checkIn.Motivation);
}

public sealed record CheckInsResponse(CheckInResponse[] CheckIns);

/// <summary>Today's state: whether the terms were accepted, and the check-in if there is one.</summary>
public sealed record WellbeingResponse(bool ConsentRequired, bool Consented, CheckInResponse? Today);

/// <summary>The member's or coach's view of one ride's effort. Notes are only ever returned to the owner.</summary>
public sealed record RideFeelResponse(bool ConsentRequired, int? Rpe, string? Notes);

/// <summary>What a coach may see: scores and effort, never the member's free-text notes.</summary>
public sealed record CoachRpeResponse(Guid RideId, DateOnly Date, int Rpe);

public sealed record CoachWellbeingResponse(CheckInResponse[] CheckIns, CoachRpeResponse[] Rides);
