using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Training;

namespace Velomine.Server.Tests.Training;

/// <summary>
/// The week's plan as pure functions: the rules of `docs/training-models.md` *The planned week* on known setups. No
/// database, no clock and no configuration: a test states the rider's history and reads the sessions that come back, and
/// every safety limit is checked on the week that is produced.
/// </summary>
public sealed class WeekPlannerTests
{
    /// <summary>Monday 23 November 2026, the first day of a week that starts on Monday.</summary>
    private static readonly DateOnly Monday = new(2026, 11, 23);

    private static readonly DateOnly Tuesday = Monday.AddDays(1);
    private static readonly DateOnly Thursday = Monday.AddDays(3);
    private static readonly DateOnly Friday = Monday.AddDays(4);
    private static readonly DateOnly Saturday = Monday.AddDays(5);
    private static readonly DateOnly Sunday = Monday.AddDays(6);

    private static int[] Days(params DayOfWeek[] days) => [.. days.Select(d => (int)d)];

    /// <summary>A rider who has been riding for three months, at 400 a week, and finished last week.</summary>
    private static PlannerHistory History(
        int weeksOfRides = 12,
        double[]? normalWeeks = null,
        int weeksSinceLighter = 0,
        bool recordedAsLighter = false,
        bool lastWeekFullyDone = true,
        int? daysSinceLastRide = 1,
        string[]? readiness = null,
        double? recentHours = null) =>
        new(weeksOfRides,
            normalWeeks ?? [400, 400, 400, 400],
            weeksSinceLighter,
            recordedAsLighter,
            lastWeekFullyDone,
            daysSinceLastRide,
            readiness ?? [Readiness.Normal, Readiness.Normal, Readiness.Normal],
            recentHours);

    private static PlannerInput Input(
        DateOnly today,
        int[] freeDays,
        int hours = 6,
        string goal = TrainingGoals.Fitter,
        int? age = 38,
        PlannerHistory? history = null,
        FixedSession[]? fixedSessions = null,
        SpentDay[]? spent = null,
        DayOfWeek firstDayOfWeek = DayOfWeek.Monday,
        int? longRideDay = null) =>
        new(today,
            firstDayOfWeek,
            freeDays,
            longRideDay,
            hours,
            goal,
            age,
            history ?? History(),
            fixedSessions ?? [],
            spent ?? []);

    private static PlannedSession[] Hard(PlannedWeek week) =>
        [.. week.Sessions.Where(s => Recipes.ByCode(s.Recipe).IsQuality)];

    private static DateOnly? LongRideDay(PlannedWeek week) =>
        week.Sessions.FirstOrDefault(s => s.Recipe == "R03")?.LocalDate;

    /// <summary>Every loaded day of the week: its hard days, and the long ride when it carries enough of the load.</summary>
    private static List<DateOnly> LoadedDays(PlannedWeek week)
    {
        var loaded = Hard(week).Select(s => s.LocalDate).ToList();
        if (week.LongRideIsLoaded && LongRideDay(week) is { } longRide) loaded.Add(longRide);
        return loaded;
    }

    /// <summary>
    /// The limit every kept week holds: no two hard days in a row, none beside the long ride, no two loaded in a row —
    /// counting the sessions the rider already has this week, which the planner may not move.
    /// </summary>
    private static void AssertSpacing(PlannedWeek week, params FixedSession[] fixedSessions)
    {
        var hard = Hard(week).Select(s => s.LocalDate)
            .Concat(fixedSessions.Where(s => Recipes.ByCode(s.Recipe).IsQuality).Select(s => s.LocalDate))
            .Order().ToArray();
        Assert.True(hard.Length <= 2, $"{hard.Length} hard days");
        for (var i = 1; i < hard.Length; i++)
            Assert.True(Math.Abs(hard[i].DayNumber - hard[i - 1].DayNumber) > 1, "two hard days in a row");
        if (LongRideDay(week) is { } longRide)
            Assert.All(hard, day => Assert.True(
                Math.Abs(day.DayNumber - longRide.DayNumber) > 1, "a hard day beside the long ride"));

        var loaded = LoadedDays(week)
            .Concat(fixedSessions.Where(s => Recipes.ByCode(s.Recipe).IsQuality || s.Recipe is "R03" or "R16")
                .Select(s => s.LocalDate))
            .Order().ToArray();
        Assert.True(loaded.Distinct().Count() <= 3, "more than three loaded days");
        for (var i = 1; i < loaded.Length; i++)
            Assert.True(Math.Abs(loaded[i].DayNumber - loaded[i - 1].DayNumber) > 1, "two loaded days in a row");
    }

    [Fact]
    public void PlannedWeek_ShouldSumItsSessionsScores_WhenTheLoadIsRead()
    {
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday)));

        Assert.Equal(3, week.Sessions.Length);
        Assert.Equal(Math.Round(week.Sessions.Sum(s => s.Score), 1), week.Load);
        Assert.All(week.Sessions, session => Assert.True(session.Score > 0));
    }

    [Fact]
    public void WeekPlanner_ShouldPlanTwoHardDays_WhenTheRiderHasFourHoursOrMore()
    {
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday), hours: 6));

        Assert.Equal(2, Hard(week).Length);
        // The gentle goals: sweet spot first, then a longer hard session (research §3, *Which goal uses which recipe*).
        Assert.Equal(["R05", "R08"], Hard(week).Select(s => s.Recipe));
        AssertSpacing(week);
    }

    [Fact]
    public void WeekPlanner_ShouldPlanOneHardDay_WhenTheRiderHasLessThanFourHours()
    {
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday), hours: 3));

        Assert.Single(Hard(week));
        AssertSpacing(week);
    }

    [Fact]
    public void WeekPlanner_ShouldPlanNoHardDay_WhenTheGoalIsToRideMoreRegularly()
    {
        var week = WeekPlanner.Plan(Input(
            Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday), goal: TrainingGoals.Aerobic));

        Assert.Empty(Hard(week));
    }

    [Fact]
    public void WeekPlanner_ShouldKeepHardDaysApartAndOffTheLongRide_WhenTheDaysAreClose()
    {
        // Four days that adjoin: a hard day can only sit where a whole day separates it from the others.
        foreach (var days in new[]
                 {
                     Days(DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday),
                     Days(DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Friday, DayOfWeek.Sunday),
                     Days(DayOfWeek.Monday, DayOfWeek.Wednesday, DayOfWeek.Friday, DayOfWeek.Sunday),
                     Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Saturday, DayOfWeek.Sunday),
                     Days(DayOfWeek.Monday, DayOfWeek.Wednesday, DayOfWeek.Saturday),
                 })
        {
            var week = WeekPlanner.Plan(Input(Monday, days, hours: 8));
            AssertSpacing(week);
        }
    }

    [Fact]
    public void WeekPlanner_ShouldGiveUpTheLongRide_WhenTheOnlyDayLeftIsBesideAHardDayAlreadyRidden()
    {
        // Saturday's hard session is done, and Sunday is the last free weekend day: it would sit next to it, which W1
        // forbids, so the week has a quiet Sunday instead of a long ride and two loaded days in a row.
        var done = new FixedSession(Monday.AddDays(5), "R05", 60, TrainingSessionStates.Done);
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Saturday, DayOfWeek.Sunday), hours: 6,
            fixedSessions: [done]));

        Assert.DoesNotContain(week.Sessions, s => s.Recipe == "R03");
        Assert.Equal(Sunday, Assert.Single(week.Sessions).LocalDate);
        AssertSpacing(week, done);
    }

    [Fact]
    public void WeekPlanner_ShouldKeepTheLongRideAndDropTheHardDay_WhenNoEasyDayIsLeftToDrop()
    {
        // Free Monday, Wednesday and Saturday, Wednesday the rider's own long-ride day, one hour a week planned on
        // Wednesday: the hour holds Wednesday at its floor and nothing more, and no easy day is left to go. The hard day
        // is the day that goes — the long ride never is, and the week keeps Wednesday's day (W1, W4).
        var week = WeekPlanner.Plan(Input(Monday.AddDays(2),
            Days(DayOfWeek.Monday, DayOfWeek.Wednesday, DayOfWeek.Saturday), hours: 1,
            longRideDay: (int)DayOfWeek.Wednesday));

        Assert.Equal(Monday.AddDays(2), Assert.Single(week.Sessions).LocalDate);
        Assert.DoesNotContain(week.Sessions, s => Recipes.ByCode(s.Recipe).IsQuality);
        Assert.True(week.Sessions.Sum(s => s.Minutes) <= 60, $"planned {week.Sessions.Sum(s => s.Minutes)} minutes");
    }

    [Fact]
    public void WeekPlanner_ShouldDropTheSecondHardDay_WhenTheDaysCannotKeepTheSpacing()
    {
        // Friday is the day before the long ride on Sunday? No: Saturday is. Friday is the day before Saturday, and
        // Saturday cannot be a hard day at all, so only Thursday is left — and the second hard day goes.
        var crowded = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Thursday, DayOfWeek.Friday, DayOfWeek.Sunday), hours: 8));
        Assert.Single(Hard(crowded));

        // Two days only, both beside the long ride: no hard day fits at all.
        var pair = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Saturday, DayOfWeek.Sunday), hours: 6));
        Assert.Empty(Hard(pair));
        AssertSpacing(pair);
    }

    [Fact]
    public void WeekPlanner_ShouldNeverPlanLoadedDaysInARow_WhenTheLongRideIsLoaded()
    {
        // Three hours over three days leaves the long ride carrying more than a third of the week: it is a loaded day,
        // and the hard day still never touches it.
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday), hours: 3));

        Assert.True(week.LongRideIsLoaded);
        AssertSpacing(week);
    }

    [Fact]
    public void LongRide_ShouldCountAsLoaded_WhenItCarriesOverAThirdOfTheWeek()
    {
        var shortWeek = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday), hours: 3));
        // Six days over ten hours: the long ride is a sixth of the days and carries under a third of the load.
        var longWeek = WeekPlanner.Plan(Input(Monday,
            Days(DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Thursday, DayOfWeek.Friday, DayOfWeek.Sunday),
            hours: 10));

        Assert.True(shortWeek.LongRideIsLoaded);
        Assert.False(longWeek.LongRideIsLoaded);
        // The flag is the rule itself: the long ride's score against the week's load, over 35 %.
        var longRide = Assert.Single(longWeek.Sessions, s => s.Recipe == "R03");
        Assert.Equal(longRide.Score / longWeek.Load > 0.35, longWeek.LongRideIsLoaded);
    }

    [Fact]
    public void WeekPlanner_ShouldPlanALighterWeek_WhenThreeWeeksWereBuilt()
    {
        var built = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday),
            history: History(weeksSinceLighter: 2)));
        var lighter = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday),
            history: History(weeksSinceLighter: 3)));

        Assert.False(built.IsLighterWeek);
        Assert.True(lighter.IsLighterWeek);
    }

    [Fact]
    public void WeekPlanner_ShouldPlanALighterWeekAfterTwo_WhenTheRiderIsFiftyOrOlder()
    {
        var days = Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday);

        var younger = WeekPlanner.Plan(Input(Monday, days, age: 49, history: History(weeksSinceLighter: 2)));
        var older = WeekPlanner.Plan(Input(Monday, days, age: 50, history: History(weeksSinceLighter: 2)));

        Assert.False(younger.IsLighterWeek);
        Assert.True(older.IsLighterWeek);
    }

    [Fact]
    public void WeekPlanner_ShouldPlanALighterWeekEarly_WhenTheLastThreeDaysWereInTheRestBand()
    {
        var days = Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday);
        var rested = WeekPlanner.Plan(Input(Monday, days,
            history: History(readiness: [Readiness.Rest, Readiness.Rest, Readiness.Rest])));
        var oneGoodMorning = WeekPlanner.Plan(Input(Monday, days,
            history: History(readiness: [Readiness.Rest, Readiness.Rest, Readiness.Easy])));

        Assert.True(rested.IsLighterWeek);
        Assert.False(oneGoodMorning.IsLighterWeek);
    }

    [Fact]
    public void WeekPlanner_ShouldKeepALighterWeekLighter_WhenItIsPlannedAgain()
    {
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday),
            history: History(recordedAsLighter: true)));

        Assert.True(week.IsLighterWeek);
    }

    [Fact]
    public void LighterWeek_ShouldCarrySixtyFivePercentOfTheLastNormalWeek_WhenItIsPlanned()
    {
        var days = Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday);
        var normal = WeekPlanner.Plan(Input(Monday, days));
        var lighter = WeekPlanner.Plan(Input(Monday, days,
            history: History(normalWeeks: [600, 500, 500, 500], weeksSinceLighter: 3)));

        Assert.True(lighter.IsLighterWeek);
        Assert.True(lighter.Load <= 0.65 * 600, $"lighter week carried {lighter.Load}");
        Assert.True(lighter.Load > 0);
        // The same days, shorter.
        Assert.Equal(normal.Sessions.Select(s => s.LocalDate), lighter.Sessions.Select(s => s.LocalDate));
        Assert.True(lighter.Sessions.Sum(s => s.Minutes) < normal.Sessions.Sum(s => s.Minutes));
    }

    [Fact]
    public void LighterWeek_ShouldKeepOneShortHardDay_WhenItIsPlanned()
    {
        var lighter = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday),
            history: History(normalWeeks: [600, 500, 500, 500], weeksSinceLighter: 3)));

        var hard = Assert.Single(Hard(lighter));
        Assert.True(hard.Minutes <= WeekPlanner.ShortHardSessionMinutes, $"{hard.Minutes} minutes");
        AssertSpacing(lighter);
    }

    [Fact]
    public void WeekPlanner_ShouldGrowTenPercent_WhenLastWeeksSessionsWereAllDone()
    {
        var days = Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday);
        var grown = WeekPlanner.Plan(Input(Monday, days, hours: 10,
            history: History(normalWeeks: [200, 200, 200, 200])));
        var held = WeekPlanner.Plan(Input(Monday, days, hours: 10,
            history: History(normalWeeks: [200, 200, 200, 200], lastWeekFullyDone: false)));

        Assert.True(grown.Load <= 220, $"grew to {grown.Load}");
        Assert.True(held.Load <= 200, $"grew to {held.Load}");
        Assert.True(held.Load < grown.Load);
    }

    [Fact]
    public void WeekPlanner_ShouldNeverGoOverTheRidersHours_WhenTheRampAllowsMore()
    {
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Monday, DayOfWeek.Wednesday, DayOfWeek.Friday),
            hours: 4, history: History(normalWeeks: [900, 900, 900, 900])));

        Assert.True(week.Sessions.Sum(s => s.Minutes) <= 4 * 60, $"{week.Sessions.Sum(s => s.Minutes)} minutes");
    }

    [Fact]
    public void WeekPlanner_ShouldStayInsideTheHours_WhenEveryDayIsFreeAndTheHoursAreSmall()
    {
        // Seven days at one hour and at three: the hard day's least length cannot push the week past the hours. At one
        // hour the days go, at three they shorten, and neither comes out longer than what the rider gave (W4).
        var everyDay = Days(DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Thursday,
            DayOfWeek.Friday, DayOfWeek.Saturday, DayOfWeek.Sunday);

        foreach (var hours in new[] { 1, 3 })
        {
            var week = WeekPlanner.Plan(Input(Monday, everyDay, hours: hours));
            var minutes = week.Sessions.Sum(s => s.Minutes);
            Assert.True(minutes <= hours * 60, $"{hours} h planned {minutes} minutes");
            // Hours too small for a floor on every day keep fewer days instead of padding the week with rides too
            // short to be one.
            Assert.All(week.Sessions, session => Assert.True(
                session.Minutes >= WeekPlanner.MinimumDayMinutes, $"a {session.Minutes}-minute day"));
        }
    }

    [Fact]
    public void WeekPlanner_ShouldPlanNothing_WhenTheWeeksHoursAreAlreadySpent()
    {
        // Two hours a week and a two-hour session already done: the hours are gone, so the week carries that session
        // and no token minute planned to fill Thursday.
        var done = new FixedSession(Tuesday, "R03", 120, TrainingSessionStates.Done);
        var week = WeekPlanner.Plan(Input(Thursday, Days(DayOfWeek.Thursday, DayOfWeek.Sunday), hours: 2,
            fixedSessions: [done]));

        Assert.Empty(week.Sessions);
        Assert.True(week.Load > 0, "the week still carries the session it spent");
    }

    [Fact]
    public void WeekPlanner_ShouldKeepASessionInsideADay_WhenTheHoursAreMoreThanADayHolds()
    {
        // One riding day holds the rider's hours, at any length the setup allows: over a day it is a day long, so the
        // row the sweep writes always passes the minutes check (W4).
        foreach (var hours in Enumerable.Range(1, 30))
        {
            var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Sunday), hours: hours,
                history: History(normalWeeks: [2000, 2000, 2000, 2000])));

            var session = Assert.Single(week.Sessions);
            Assert.Equal(Math.Min(hours * 60, WeekPlanner.MaxDayMinutes), session.Minutes);
        }
    }

    [Fact]
    public void NormalWeeks_ShouldLeaveOutLighterAndEmptyWeeks_WhenTheMeanIsTaken()
    {
        var loads = new Dictionary<DateOnly, double>
        {
            [Monday.AddDays(-7)] = 400,
            [Monday.AddDays(-14)] = 0,      // a break
            [Monday.AddDays(-21)] = 100,    // a lighter week
            [Monday.AddDays(-28)] = 300,
            [Monday.AddDays(-35)] = 200,
            [Monday.AddDays(-42)] = 100,
        };

        var normal = WeekPlanner.NormalWeeks(loads, Monday, [Monday.AddDays(-21)]);

        Assert.Equal([400, 300, 200, 100], normal);
    }

    [Fact]
    public void LoadCap_ShouldBeNoLimit_WhenThereIsNoNormalWeek()
    {
        Assert.Null(WeekPlanner.LoadCap(History(normalWeeks: []), isBaseBlock: false, isLighter: false));
        Assert.Null(WeekPlanner.LoadCap(History(), isBaseBlock: true, isLighter: false));
        Assert.Equal(440, WeekPlanner.LoadCap(History(), isBaseBlock: false, isLighter: false)!.Value, 3);
        Assert.Equal(260, WeekPlanner.LoadCap(History(weeksSinceLighter: 3), isBaseBlock: false, isLighter: true)!.Value, 3);
    }

    [Fact]
    public void WeekPlanner_ShouldPlanOnlyTheGentleBaseBlock_WhenTheRiderHasUnderFourWeeksOfRides()
    {
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday),
            hours: 6, history: History(weeksOfRides: 3, normalWeeks: [])));

        Assert.All(week.Sessions, session =>
        {
            Assert.Contains(session.Recipe, new[] { "R14", "R15", "R16" });
            var recipe = Recipes.ByCode(session.Recipe);
            // Feel targets only, and never a feel number above 6.
            Assert.All(recipe.Blocks, block =>
            {
                Assert.Null(block.PercentFtp);
                Assert.True(block.Feel.High <= 6, $"{recipe.Code} asks for feel {block.Feel.High}");
            });
        });
        // The long day of the base block is the long and easy one.
        Assert.Equal("R16", week.Sessions[^1].Recipe);
    }

    [Fact]
    public void BaseBlock_ShouldHaveNoRamp_WhenTheRecentWeeksWereShort()
    {
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday),
            hours: 8, history: History(weeksOfRides: 2, normalWeeks: [50, 50, 50, 50])));

        // No cap at all: the week is not held to 10 % of a mean the rider has not built yet.
        Assert.True(week.Load > 1.1 * 50, $"carried {week.Load}");
    }

    [Fact]
    public void BaseBlock_ShouldStartAgain_WhenTheRiderIsBackFromABreak()
    {
        var days = Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday);

        var back = WeekPlanner.Plan(Input(Monday, days, history: History(daysSinceLastRide: 14)));
        var riding = WeekPlanner.Plan(Input(Monday, days, history: History(daysSinceLastRide: 9)));

        // Back from a break the plan restarts from the real recent load: the gentle base block, not the old hours.
        Assert.All(back.Sessions, session => Assert.Contains(session.Recipe, WeekPlanner.BaseRecipes));
        Assert.DoesNotContain(riding.Sessions, session => WeekPlanner.BaseRecipes.Contains(session.Recipe));
    }

    [Fact]
    public void BaseBlock_ShouldKeepTheRecentWeeksHours_WhenTheRiderIsBackFromABreak()
    {
        // Twelve hours asked for, three hours a week before the break: back from it the week is the three, not the
        // twelve the setup still says (W5).
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday),
            hours: 12,
            history: History(weeksOfRides: 20, normalWeeks: [180, 180, 180, 180], daysSinceLastRide: 14,
                recentHours: 3)));

        Assert.All(week.Sessions, session => Assert.Contains(session.Recipe, WeekPlanner.BaseRecipes));
        // The week is the hours the recent weeks really took, not the twelve the setup still says.
        Assert.Equal(3 * 60, week.Sessions.Sum(s => s.Minutes));
    }

    [Fact]
    public void BaseBlock_ShouldPlanTheSetupHours_WhenTheRiderHasNeverRiddenMuch()
    {
        // A new rider has no recent weeks to restart from: the hours they gave are the week.
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday),
            hours: 4, history: History(weeksOfRides: 2, normalWeeks: [], daysSinceLastRide: 1, recentHours: null)));

        Assert.All(week.Sessions, session => Assert.Contains(session.Recipe, WeekPlanner.BaseRecipes));
        Assert.Equal(4 * 60, week.Sessions.Sum(s => s.Minutes));
    }

    [Fact]
    public void BaseBlock_ShouldKeepAShortDayGentle_WhenTheRiderHasThirtyMinuteDays()
    {
        // Six days at three hours are thirty-minute days: the gentle recipes ride by feel and scale to them, so no day
        // becomes the endurance fallback with the watt and heart-rate targets the base block must not show.
        var week = WeekPlanner.Plan(Input(Monday,
            Days(DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Thursday, DayOfWeek.Friday,
                DayOfWeek.Saturday),
            hours: 3, history: History(weeksOfRides: 2, normalWeeks: [])));

        Assert.All(week.Sessions, session =>
        {
            Assert.Contains(session.Recipe, WeekPlanner.BaseRecipes);
            Assert.All(Recipes.ByCode(session.Recipe).Blocks, block =>
            {
                Assert.Null(block.PercentFtp);
                Assert.Null(block.PercentThresholdHeartRate);
            });
        });
    }

    [Fact]
    public void WeekPlanner_ShouldScaleTheRestOfTheWeek_WhenItIsSwitchedOnMidWeek()
    {
        var week = WeekPlanner.Plan(Input(Thursday, Days(DayOfWeek.Monday, DayOfWeek.Wednesday, DayOfWeek.Friday), hours: 6));

        // One of the three free days is left, so a third of a six-hour week: two hours on Friday, the week's only day.
        var session = Assert.Single(week.Sessions);
        Assert.Equal(Friday, session.LocalDate);
        Assert.Equal(120, session.Minutes);
    }

    [Fact]
    public void WeekPlanner_ShouldPlanTodayAndLaterOnly_WhenTodayIsMidWeek()
    {
        var week = WeekPlanner.Plan(Input(Thursday, Days(DayOfWeek.Monday, DayOfWeek.Wednesday, DayOfWeek.Friday)));

        Assert.All(week.Sessions, session => Assert.True(session.LocalDate >= Thursday));
    }

    [Fact]
    public void WeekPlanner_ShouldPlanAroundThem_WhenTheRiderRodeWithoutASession()
    {
        // Monday's ride was not in the plan and cost 300: it is spent, and the week is still held to its cap of 385.
        var week = WeekPlanner.Plan(Input(Thursday, Days(DayOfWeek.Monday, DayOfWeek.Wednesday, DayOfWeek.Sunday),
            hours: 6, history: History(normalWeeks: [350, 350, 350, 350]), spent: [new SpentDay(Monday, 300)]));

        Assert.DoesNotContain(week.Sessions, s => s.LocalDate == Monday);
        Assert.True(week.Load <= 385, $"carried {week.Load}");
        Assert.InRange(week.Load, 300, 385);
    }

    [Fact]
    public void WeekPlanner_ShouldKeepTheFasterGoalsHardDaysToTheDocumentedRecipes_WhenTheDaysAreShort()
    {
        // A short day takes the shortest hard session the goal lists, and the goal's list ends at R08 (W1): never the
        // 30/15 or the anaerobic bursts, which the document gives no place in a faster week.
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday),
            hours: 3, goal: TrainingGoals.Faster));

        var hard = Assert.Single(Hard(week));
        Assert.Equal("R06", hard.Recipe);
        Assert.DoesNotContain(week.Sessions, s => s.Recipe is "R09" or "R10");
    }

    [Theory]
    [InlineData(TrainingGoals.Fitter, "R05,R08,R09")]
    [InlineData(TrainingGoals.Faster, "R05,R06,R07,R08")]
    [InlineData(TrainingGoals.Event, "R05,R06,R07,R08")]
    [InlineData(TrainingGoals.Keep, "R17")]
    [InlineData(TrainingGoals.Aerobic, "")]
    public void WeekPlanner_ShouldDrawTheGoalsHardDaysFromTheDocumentedRecipes_WhenTheWeekIsLongEnough(
        string goal, string documented)
    {
        // The order of a goal's hard-day recipes is the document's, the gentlest that fits the day first: R05 → R08 →
        // R09 for get fitter, R05 → R06 → R07 → R08 for get faster and for get ready, R17 for stay fit, none for ride
        // more regularly (W1).
        var expected = documented.Split(',', StringSplitOptions.RemoveEmptyEntries);

        Assert.Equal(expected, WeekPlanner.QualityPreferences(goal));

        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday),
            hours: 10, goal: goal, history: History(normalWeeks: [2000, 2000, 2000, 2000])));

        Assert.Equal(expected.Take(2), Hard(week).Select(s => s.Recipe));
    }

    [Fact]
    public void WeekPlanner_ShouldGiveOneMoreHardDay_WhenTheRiderAlreadyRodeOne()
    {
        // Monday's hard day is done, so only one is left, and it must keep a day from Monday: Thursday.
        var week = WeekPlanner.Plan(Input(Tuesday, Days(DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday),
            hours: 8, fixedSessions: [new FixedSession(Monday, "R05", 60, TrainingSessionStates.Done)]));

        var hard = Assert.Single(Hard(week));
        Assert.Equal(Thursday, hard.LocalDate);
        AssertSpacing(week);
    }

    [Fact]
    public void WeekPlanner_ShouldKeepTheLongRideOnce_WhenTheWeeksLongRideIsAlreadyDone()
    {
        var week = WeekPlanner.Plan(Input(Tuesday, Days(DayOfWeek.Monday, DayOfWeek.Sunday),
            fixedSessions: [new FixedSession(Monday, "R03", 150, TrainingSessionStates.Done)]));

        Assert.DoesNotContain(week.Sessions, s => s.Recipe == "R03");
    }

    [Fact]
    public void WeekPlanner_ShouldPutTheQuietDayBesideAHardOne_WhenTheDaysAllow()
    {
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Thursday,
            DayOfWeek.Friday, DayOfWeek.Sunday), hours: 8));

        var hard = Hard(week).Select(s => s.LocalDate).ToHashSet();
        Assert.All(week.Sessions.Where(s => s.Recipe == "R01"), session =>
            Assert.True(
                hard.Any(day => Math.Abs(day.DayNumber - session.LocalDate.DayNumber) == 1)
                || Math.Abs((LongRideDay(week) ?? session.LocalDate).DayNumber - session.LocalDate.DayNumber) == 1,
                $"{session.LocalDate} is a quiet day with nothing hard beside it"));
    }

    [Fact]
    public void TrainingNotes_ShouldKeepThePlannersWordsOffTheWeek_WhenTheRiderReadsIt()
    {
        // The planner's words are the owner's: TrainingNames.md, never "quality session", "base block" or a model's name.
        Assert.Equal("Easy week: your body gets stronger while it rests", TrainingNotes.EasyWeek.English);
        Assert.Equal("It gets more personal as your rides come in", TrainingNotes.MorePersonal.English);

        string[] banned = ["quality", "interval day", "base block", "polarised", "pyramidal", "sweet spot", "proven",
            "fat-burning", "faster recovery", "10 %", "block"];
        Assert.All(TrainingNotes.All, note => Assert.All(banned, word =>
            Assert.DoesNotContain(word, note.English, StringComparison.OrdinalIgnoreCase)));
        Assert.All(TrainingNotes.All, note =>
        {
            Assert.False(string.IsNullOrWhiteSpace(note.Italian));
            Assert.NotEqual(note.English, note.Italian);
        });
    }

    [Fact]
    public void WeekPlanner_ShouldStoreTheBlocksIntensity_WhenASessionIsPlanned()
    {
        var week = WeekPlanner.Plan(Input(Monday, Days(DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Sunday)));

        Assert.All(week.Sessions, session =>
        {
            var recipe = Recipes.ByCode(session.Recipe);
            Assert.Equal(recipe.Blocks.Length, session.BlockPercents.Length);
            Assert.All(session.BlockPercents, percent => Assert.InRange(percent, 1, 200));
        });
    }
}
