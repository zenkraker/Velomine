namespace Velomine.Server.Features.Analytics;

/// <summary>Weeks, months and years on the member's calendar: weeks start on the member's first day of the week.</summary>
public static class Periods
{
    public const string Week = "week";
    public const string Month = "month";
    public const string Year = "year";

    public static readonly string[] All = [Week, Month, Year];

    public static DateOnly StartOf(DateOnly day, string period, DayOfWeek firstDayOfWeek) => period switch
    {
        Week => day.AddDays(-(((int)day.DayOfWeek - (int)firstDayOfWeek + 7) % 7)),
        Month => new DateOnly(day.Year, day.Month, 1),
        Year => new DateOnly(day.Year, 1, 1),
        _ => throw new ArgumentOutOfRangeException(nameof(period), period, "Not a period."),
    };

    /// <summary>The first day of the next period.</summary>
    public static DateOnly Next(DateOnly start, string period) => period switch
    {
        Week => start.AddDays(7),
        Month => start.AddMonths(1),
        Year => start.AddYears(1),
        _ => throw new ArgumentOutOfRangeException(nameof(period), period, "Not a period."),
    };

    public static DateOnly Previous(DateOnly start, string period) => period switch
    {
        Week => start.AddDays(-7),
        Month => start.AddMonths(-1),
        Year => start.AddYears(-1),
        _ => throw new ArgumentOutOfRangeException(nameof(period), period, "Not a period."),
    };
}
