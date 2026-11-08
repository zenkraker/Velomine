using Velomine.Server.Features.Analytics;

namespace Velomine.Server.Tests.Analytics;

public sealed class PeriodsTests
{
    private static readonly DateOnly Wednesday = new(2026, 11, 4);

    [Theory]
    [InlineData(DayOfWeek.Monday, "2026-11-02")]
    [InlineData(DayOfWeek.Sunday, "2026-11-01")]
    [InlineData(DayOfWeek.Saturday, "2026-10-31")]
    [InlineData(DayOfWeek.Wednesday, "2026-11-04")]
    [InlineData(DayOfWeek.Thursday, "2026-10-29")]
    public void StartOf_ShouldStartTheWeekOnTheMembersFirstDay_WhenGivenAnyFirstDay(DayOfWeek first, string expected) =>
        Assert.Equal(DateOnly.Parse(expected), Periods.StartOf(Wednesday, Periods.Week, first));

    [Fact]
    public void StartOf_ShouldReturnTheFirstOfTheMonthOrYear_WhenGivenMonthOrYear()
    {
        Assert.Equal(new DateOnly(2026, 11, 1), Periods.StartOf(Wednesday, Periods.Month, DayOfWeek.Monday));
        Assert.Equal(new DateOnly(2026, 1, 1), Periods.StartOf(Wednesday, Periods.Year, DayOfWeek.Monday));
    }

    [Fact]
    public void Periods_ShouldStepOnePeriod_WhenGoingToTheNextOrPrevious()
    {
        Assert.Equal(new DateOnly(2026, 11, 9), Periods.Next(new DateOnly(2026, 11, 2), Periods.Week));
        Assert.Equal(new DateOnly(2026, 2, 1), Periods.Next(new DateOnly(2026, 1, 1), Periods.Month));
        Assert.Equal(new DateOnly(2025, 12, 1), Periods.Previous(new DateOnly(2026, 1, 1), Periods.Month));
        Assert.Equal(new DateOnly(2025, 1, 1), Periods.Previous(new DateOnly(2026, 1, 1), Periods.Year));
    }
}
