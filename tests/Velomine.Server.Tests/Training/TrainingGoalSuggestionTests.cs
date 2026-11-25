using Velomine.Server.Features.Training;

namespace Velomine.Server.Tests.Training;

/// <summary>
/// The goal the setup pre-selects (docs/training-models.md G1): each rule against a hand-worked history, the first
/// match winning. A history states its counts directly, so the expected goal comes from the rule and not from a ride.
/// </summary>
public sealed class TrainingGoalSuggestionTests
{
    private static readonly DateOnly Today = new(2026, 11, 24);

    /// <summary>An established rider with power: the starting point each test spoils in one way.</summary>
    private static TrainingHistory Established(bool riderSetAnFtp = true) => new(
        Today: Today,
        WeeksOfRides: 52,
        RidesInLast4Weeks: 16,
        MinutesInLast4Weeks: 1200,
        EmptyWeeksInLast4: 0,
        DaysSinceLastRide: 1,
        RidesInLast8Weeks: 32,
        HoursInLast8Weeks: 32,
        ActiveWeeksInLast8: 8,
        RiderSetAnFtp: riderSetAnFtp,
        RidesWithPowerInLast8Weeks: 32,
        NextEventDate: null);

    [Fact]
    public void GoalSuggestion_ShouldPickAerobicExercise_WhenThereAreFewerThanFourWeeksOfRides()
    {
        var suggestion = TrainingGoalSuggestion.For(TrainingHistory.Empty(Today) with { WeeksOfRides = 3 });

        Assert.Equal(TrainingGoals.Aerobic, suggestion.Goal);
        Assert.Equal(TrainingGoalReasons.NotEnoughRiding, suggestion.Reason);
    }

    [Fact]
    public void GoalSuggestion_ShouldPickAerobicExercise_WhenTheLastFourWeeksAreUnderOneHundredAndFiftyMinutes()
    {
        // 4 weeks, 12 rides, 140 minutes a week: 560 minutes in the four weeks, one short of the WHO floor.
        var suggestion = TrainingGoalSuggestion.For(Established() with { RidesInLast4Weeks = 12, MinutesInLast4Weeks = 4 * 140 });

        Assert.Equal(TrainingGoals.Aerobic, suggestion.Goal);
        Assert.Equal(TrainingGoalReasons.RegularRiding, suggestion.Reason);
    }

    [Fact]
    public void GoalSuggestion_ShouldPickAerobicExercise_WhenTwoOfTheLastFourWeeksAreEmpty()
    {
        var suggestion = TrainingGoalSuggestion.For(Established() with { EmptyWeeksInLast4 = 2 });

        Assert.Equal(TrainingGoals.Aerobic, suggestion.Goal);
        Assert.Equal(TrainingGoalReasons.RegularRiding, suggestion.Reason);
    }

    [Fact]
    public void GoalSuggestion_ShouldPickTheEvent_WhenAnEventIsWithinTwentyWeeks()
    {
        // 140 days is twenty weeks; the same ride history is "get fitter" without the event.
        var suggestion = TrainingGoalSuggestion.For(Established() with { NextEventDate = Today.AddDays(140) });

        Assert.Equal(TrainingGoals.Event, suggestion.Goal);
        Assert.Equal(TrainingGoalReasons.EventSoon, suggestion.Reason);
        // The same rides without the event are the established rider's own goal.
        Assert.Equal(TrainingGoals.Faster, TrainingGoalSuggestion.For(Established()).Goal);
    }

    [Fact]
    public void GoalSuggestion_ShouldPickGetFitter_WhenTheLastRideWasTenDaysAgo()
    {
        var suggestion = TrainingGoalSuggestion.For(Established() with { DaysSinceLastRide = 10 });

        Assert.Equal(TrainingGoals.Fitter, suggestion.Goal);
        Assert.Equal(TrainingGoalReasons.AfterBreak, suggestion.Reason);
    }

    [Fact]
    public void GoalSuggestion_ShouldPickGetFaster_WhenAnEstablishedRiderHasPowerInHalfTheRecentRides()
    {
        var suggestion = TrainingGoalSuggestion.For(Established() with { RidesWithPowerInLast8Weeks = 16 });

        Assert.Equal(TrainingGoals.Faster, suggestion.Goal);
        Assert.Equal(TrainingGoalReasons.PowerRides, suggestion.Reason);
    }

    [Fact]
    public void GoalSuggestion_ShouldPickGetFitter_WhenAnEstablishedRiderHasNotSetAnFtp()
    {
        var suggestion = TrainingGoalSuggestion.For(Established(riderSetAnFtp: false));

        Assert.Equal(TrainingGoals.Fitter, suggestion.Goal);
        Assert.Equal(TrainingGoalReasons.RegularRider, suggestion.Reason);
    }

    [Fact]
    public void GoalSuggestion_ShouldPickGetFitter_WhenThreeHoursAWeeksIsAllTheRiderHas()
    {
        // 24 hours over 8 weeks is 3 a week, under the 4 that an established rider needs.
        var suggestion = TrainingGoalSuggestion.For(Established() with { HoursInLast8Weeks = 24 });

        Assert.Equal(TrainingGoals.Fitter, suggestion.Goal);
        Assert.Equal(TrainingGoalReasons.RegularRider, suggestion.Reason);
    }
}
