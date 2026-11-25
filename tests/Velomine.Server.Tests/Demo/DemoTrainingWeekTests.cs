using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Demo;
using Velomine.Server.Features.Training;

namespace Velomine.Server.Tests.Demo;

/// <summary>
/// The shape of the demo rider's seeded week, on every day of the week it can be seeded on: the rules the demo needs
/// (today open and makeable easy, sessions behind today to have been ridden and skipped, a free day to move one to) and
/// the planner's own safety limits (W1).
/// </summary>
public sealed class DemoTrainingWeekTests
{
    private static readonly DateOnly Monday = new(2026, 11, 23);

    private static DateOnly Day(DayOfWeek day) => Monday.AddDays(((int)day - (int)DayOfWeek.Monday + 7) % 7);

    [Theory]
    [InlineData(DayOfWeek.Monday)]
    [InlineData(DayOfWeek.Tuesday)]
    [InlineData(DayOfWeek.Wednesday)]
    [InlineData(DayOfWeek.Thursday)]
    [InlineData(DayOfWeek.Friday)]
    [InlineData(DayOfWeek.Saturday)]
    [InlineData(DayOfWeek.Sunday)]
    public void DemoTrainingWeek_ShouldGiveTheVisitorAWeekToTry_WhenSeededOnAnyDayOfTheWeek(DayOfWeek weekday)
    {
        var today = Day(weekday);
        var week = DemoTrainingWeek.For(today, DayOfWeek.Monday, TrainingGoals.Fitter);
        var sessions = week.Sessions.ToDictionary(s => s.LocalDate);

        // Today's session is the one a visitor can make easy: a hard day, or the long ride.
        var todays = Assert.Contains(today, sessions);
        Assert.True(SessionAdaptation.IsReplacedByEasy(todays.Recipe), $"today is {todays.Recipe}");
        var weekStart = Periods.StartOf(today, Periods.Week, DayOfWeek.Monday);
        // The day before it and three days back carry a session, so the week shows what was ridden and what was not.
        Assert.Contains(today.AddDays(-1), sessions.Keys);
        Assert.Contains(today.AddDays(-2), sessions.Keys);
        Assert.Contains(today.AddDays(-3), sessions.Keys);
        // A day after today in this week is left free, so the move sheet has somewhere to offer. On the week's own last
        // day there is no day after today, in the demo as in the product.
        if (today != weekStart.AddDays(6))
            Assert.Contains(Enumerable.Range(1, 6).Select(today.AddDays).Where(day => day <= weekStart.AddDays(6)),
                day => !sessions.ContainsKey(day));
        // The days behind today hold more than one session, so the demo has ridden sessions and a score to show.
        Assert.True(week.Sessions.Count(s => s.LocalDate < today) >= 2);

        // The planner's limits: a hard day is never two days running and never beside the long ride, and there are two.
        var hard = week.Sessions.Where(s => Recipes.ByCode(s.Recipe).IsQuality).ToArray();
        Assert.InRange(hard.Length, 1, WeekPlanner.HardDays(week.HoursPerWeek, TrainingGoals.Fitter));
        var longRide = Assert.Single(week.Sessions, s => s.Recipe == "R03");
        Assert.All(hard, s =>
        {
            Assert.NotEqual(1, Math.Abs(s.LocalDate.DayNumber - longRide.LocalDate.DayNumber));
            Assert.DoesNotContain(hard, other => Math.Abs(other.LocalDate.DayNumber - s.LocalDate.DayNumber) == 1);
        });
        // The long ride is the week's last ride from today on, and never the rest day.
        Assert.True(longRide.LocalDate >= today);
        Assert.Equal(longRide.LocalDate, sessions.Keys.Where(day => day >= today).Max());
        // A day is a session, never nothing: every minute the week plans is a minute a session carries.
        Assert.All(week.Sessions, s => Assert.InRange(s.Minutes, WeekPlanner.MinimumDayMinutes, WeekPlanner.MaxDayMinutes));
        Assert.InRange(week.HoursPerWeek, 1, 30);
        Assert.All(week.Days, day => Assert.InRange(day, 0, 6));
        Assert.Equal(week.Days.Length, week.Days.Distinct().Count());
    }

    [Theory]
    [InlineData(DayOfWeek.Monday)]
    [InlineData(DayOfWeek.Wednesday)]
    [InlineData(DayOfWeek.Sunday)]
    public void DemoTrainingWeek_ShouldStayInsideTheRidersHours_WhenTheWeekIsShort(DayOfWeek weekday)
    {
        var week = DemoTrainingWeek.For(Day(weekday), DayOfWeek.Monday, TrainingGoals.Fitter);

        Assert.True(week.Sessions.Sum(s => s.Minutes) <= week.HoursPerWeek * 60);
    }
}
