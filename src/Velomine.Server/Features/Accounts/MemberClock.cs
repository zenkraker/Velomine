using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Dates as the member lives them: "today", the day a ride counts on, and where a week starts.
/// Totals, goals and part wear all use this, so they agree with each other and with the member's calendar.
/// </summary>
public sealed record MemberClock(TimeZoneInfo Zone, DayOfWeek FirstDayOfWeek, DateOnly Today)
{
    public static TimeZoneInfo ZoneOf(string? id) =>
        id is not null && TimeZoneInfo.TryFindSystemTimeZoneById(id, out var zone) ? zone : TimeZoneInfo.Utc;

    public static MemberClock For(string? timeZone, DayOfWeek firstDayOfWeek, TimeProvider time)
    {
        var zone = ZoneOf(timeZone);
        return new MemberClock(zone, firstDayOfWeek, DateOnly.FromDateTime(TimeZoneInfo.ConvertTime(time.GetUtcNow(), zone).DateTime));
    }

    public static async Task<MemberClock> ForAsync(VelomineDbContext db, Guid userId, TimeProvider time, CancellationToken ct)
    {
        var user = await db.Users.AsNoTracking().Where(u => u.Id == userId)
            .Select(u => new { u.TimeZone, u.FirstDayOfWeek }).FirstOrDefaultAsync(ct);
        return For(user?.TimeZone, user?.FirstDayOfWeek ?? DayOfWeek.Monday, time);
    }

    /// <summary>
    /// The day a ride counts on: where the rider was when it started (a night ride in Rome is not "yesterday").
    /// FIT files say their offset; for files that do not (GPX, TCX) the member's own time zone is used.
    /// </summary>
    public DateOnly LocalDateOf(DateTimeOffset start, int? utcOffsetMinutes) => utcOffsetMinutes is { } offset
        ? DateOnly.FromDateTime(start.UtcDateTime.AddMinutes(offset))
        : DateOnly.FromDateTime(TimeZoneInfo.ConvertTime(start, Zone).DateTime);
}

/// <summary>Days of the week as the API spells them.</summary>
public static class WeekDays
{
    public static string Name(DayOfWeek day) => day.ToString().ToLowerInvariant();

    public static bool TryParse(string? name, out DayOfWeek day) =>
        Enum.TryParse(name, ignoreCase: true, out day) && Enum.IsDefined(day) && !int.TryParse(name, out _);
}
