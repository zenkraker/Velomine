using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Training;

namespace Velomine.Server.Tests.Training;

/// <summary>
/// The numbers of "make today easy" (`docs/training-models.md`, W6): the answers that trigger it, the endurance session
/// a hard day becomes, where the replaced hard session may go, and the subject a training notice keeps. Pure functions,
/// no database: the week is a list of sessions.
/// </summary>
public sealed class SessionAdaptationTests
{
    private static readonly DateOnly Monday = new(2026, 11, 23);
    private static readonly DateOnly Tuesday = Monday.AddDays(1);
    private static readonly DateOnly Wednesday = Monday.AddDays(2);
    private static readonly DateOnly Thursday = Monday.AddDays(3);
    private static readonly DateOnly Friday = Monday.AddDays(4);
    private static readonly DateOnly Saturday = Monday.AddDays(5);
    private static readonly DateOnly Sunday = Monday.AddDays(6);

    private static MemberClock Clock(DateOnly today) => new(TimeZoneInfo.Utc, DayOfWeek.Monday, today);

    private static TrainingSession Session(
        DateOnly date, string recipe = "R05", int minutes = 60,
        string state = TrainingSessionStates.Planned) => new()
        {
            Id = Guid.CreateVersion7(),
            LocalDate = date,
            Recipe = recipe,
            Minutes = minutes,
            BlockPercents = [91],
            State = state,
        };

    [Fact]
    public void SessionAdaptation_ShouldNameSleep_WhenSleepIsTheWorstAnswer()
    {
        // F2's items are 1–5 with higher better, so sleep 1 is its worst, and it is named before fatigue and soreness.
        Assert.Equal(TrainingEasyReasons.SleptPoorly, SessionAdaptation.CheckInReason(1, 5, 5));
    }

    [Fact]
    public void SessionAdaptation_ShouldNameFatigue_WhenOnlyFatigueIsAtItsWorst()
    {
        Assert.Equal(TrainingEasyReasons.Tired, SessionAdaptation.CheckInReason(3, 5, 2));
    }

    [Fact]
    public void SessionAdaptation_ShouldNameSoreness_WhenOnlySorenessIsAtItsWorst()
    {
        Assert.Equal(TrainingEasyReasons.Sore, SessionAdaptation.CheckInReason(4, 4, 5));
    }

    [Fact]
    public void SessionAdaptation_ShouldSayNothing_WhenNoAnswerIsAtItsWorst()
    {
        // Sleep 1, fatigue 5 and soreness 5 are the triggers; one step away from each is not.
        Assert.Null(SessionAdaptation.CheckInReason(2, 4, 5 - 1));
        Assert.Null(SessionAdaptation.CheckInReason(null, 4, 4));
    }

    [Fact]
    public void SessionAdaptation_ShouldReplaceAHardDayWithZoneTwoAtFeelThreeToFour_WhenItIsMadeEasy()
    {
        // W6: the replacement is R02 — P4's zone 2 (56–75 % FTP in its main set) at feel 3–4 — at the same minutes.
        var recipe = Recipes.ByCode(SessionAdaptation.EasyRecipe);
        var targets = SessionTargets.For(recipe, 90, 250, null);

        var main = Assert.Single(targets.Blocks, block => block.Role == RecipeRoles.Main);
        Assert.False(recipe.IsQuality);
        Assert.InRange(main.FeelLow, 3, 3);
        Assert.InRange(main.FeelHigh, 4, 4);
        Assert.InRange(main.WattsLow!.Value, 140, 188); // 56–75 % of 250 W
        Assert.InRange(main.WattsHigh!.Value, 140, 188);
        // The same length as the session it replaces, never longer.
        Assert.Equal(90, targets.Minutes);
    }

    [Fact]
    public void SessionAdaptation_ShouldRefuseTheDayBesideAHardDay_WhenTheSessionIsHard()
    {
        var hard = Session(Thursday);
        var week = new[] { Session(Tuesday), Session(Wednesday, "R06") };

        Assert.Equal(MoveRefusals.NextToHard, SessionAdaptation.Refusal(week, hard, Thursday, Clock(Thursday)));
    }

    [Fact]
    public void SessionAdaptation_ShouldRefuseTheDayBesideTheLongRide_WhenTheSessionIsHard()
    {
        var hard = Session(Wednesday);
        var week = new[] { Session(Sunday, "R03", 180) };

        Assert.Equal(MoveRefusals.NextToLongRide, SessionAdaptation.Refusal(week, hard, Saturday, Clock(Thursday)));
    }

    [Fact]
    public void SessionAdaptation_ShouldAllowTheDayBesideAnEasyDay_WhenTheSessionIsHard()
    {
        var hard = Session(Wednesday);
        var week = new[] { Session(Tuesday, "R02") };

        Assert.Null(SessionAdaptation.Refusal(week, hard, Thursday, Clock(Thursday)));
    }

    [Fact]
    public void SessionAdaptation_ShouldRefuseTheDayThatAlreadyRides_WhenTheSessionMoves()
    {
        var session = Session(Tuesday, "R02");
        var week = new[] { Session(Thursday) };

        Assert.Equal(MoveRefusals.HasSession, SessionAdaptation.Refusal(week, session, Thursday, Clock(Thursday)));
    }

    [Fact]
    public void SessionAdaptation_ShouldRefuseTheMove_WhenTheWeekAlreadyCarriesMoreLoadedDaysThanAllowed()
    {
        // A guard on W1's three loaded days: a week that already carries four takes nothing else, even an easy session,
        // because a week is never made heavier by a move. A week the planner writes never has four; this one does.
        var session = Session(Tuesday, "R02");
        TrainingSession[] week =
        [
            Session(Monday, "R05"), Session(Wednesday, "R05"), Session(Friday, "R05"), Session(Sunday, "R03", 240),
            session,
        ];

        Assert.True(SessionAdaptation.LongRideLoaded(week, Clock(Sunday), Sunday));
        Assert.Equal(MoveRefusals.TooManyLoadedDays, SessionAdaptation.Refusal(week, session, Thursday, Clock(Thursday)));
    }

    [Fact]
    public void SessionAdaptation_ShouldMoveTheHardSessionToTheFirstFreeDay_WhenTheWeekCanHoldIt()
    {
        // Monday is today's hard day and Wednesday has the week's other one, so Tuesday and Thursday are both out —
        // each sits next to a hard day. Friday is the first free day that keeps them apart and stays away from
        // Sunday's long ride, which refuses Saturday.
        var hard = Session(Monday);
        var week = new[] { hard, Session(Wednesday, "R06"), Session(Sunday, "R03", 180) };

        var date = SessionAdaptation.FreeDayFor(week, hard, [(int)DayOfWeek.Tuesday, (int)DayOfWeek.Thursday,
            (int)DayOfWeek.Friday, (int)DayOfWeek.Sunday], Clock(Monday));

        Assert.Equal(Friday, date);
    }

    [Fact]
    public void SessionAdaptation_ShouldDropTheHardSession_WhenNoFreeDayKeepsThemApart()
    {
        // The rider's only free days are Monday, the day being made easy, Tuesday — next to Wednesday's hard day — and
        // Sunday, the long ride's own day. Nothing is left, and the hard session is dropped rather than piled up.
        var hard = Session(Monday);
        var week = new[] { hard, Session(Wednesday, "R06"), Session(Sunday, "R03", 180) };

        Assert.Null(SessionAdaptation.FreeDayFor(week, hard, [(int)DayOfWeek.Monday, (int)DayOfWeek.Tuesday,
            (int)DayOfWeek.Sunday], Clock(Monday)));
    }

    [Fact]
    public void SessionAdaptation_ShouldOfferEveryDayLeftThisWeek_WhenTheSessionIsOpen()
    {
        var session = Session(Thursday);
        var week = new[] { session };

        var days = SessionAdaptation.Days(week, session, Clock(Monday));

        // Every day left this week, earlier than the session's own day or later, but not the day it already sits on.
        Assert.Equal([Monday, Tuesday, Wednesday, Friday, Saturday, Sunday], days.Select(d => d.LocalDate));
        Assert.All(days, day => Assert.Equal(day.Allowed, day.Reason is null));
    }

    [Fact]
    public void SessionAdaptation_ShouldReadTheLongRideAsThePlannerDid_WhenTheWeekIsJudged()
    {
        // One W1 rule: the long ride is loaded when it carries more than its share of the week's load — the planned
        // scores of its sessions plus what the week already spent — and never the days of the week next door, which the
        // window a move is judged against holds.
        var planned = PlanWeek(0);
        Assert.True(planned.LongRideIsLoaded);
        var window = planned.Sessions.Select(s => Session(s.LocalDate, s.Recipe, s.Minutes))
            .Append(Session(Sunday.AddDays(1)))
            .ToArray();

        Assert.Equal(planned.LongRideIsLoaded, SessionAdaptation.LongRideLoaded(window, Clock(Monday), Monday));

        // A day the week rode with no session planned is load it already spent, in both readings.
        var withSpent = PlanWeek(400);
        Assert.False(withSpent.LongRideIsLoaded);
        Assert.Equal(withSpent.LongRideIsLoaded,
            SessionAdaptation.LongRideLoaded(window, Clock(Monday), Monday, spentLoad: 400));
    }

    /// <summary>A week of eight hours on Monday, Wednesday and Sunday, with <paramref name="spentLoad"/> already ridden.</summary>
    private static PlannedWeek PlanWeek(double spentLoad) => WeekPlanner.Plan(new PlannerInput(
        Today: Monday,
        FirstDayOfWeek: DayOfWeek.Monday,
        FreeDays: [(int)DayOfWeek.Monday, (int)DayOfWeek.Wednesday, (int)DayOfWeek.Sunday],
        LongRideDay: null,
        HoursPerWeek: 8,
        Goal: TrainingGoals.Fitter,
        Age: null,
        History: new PlannerHistory(
            WeeksOfRides: 20,
            NormalWeekLoads: [],
            WeeksSinceLighter: 0,
            RecordedAsLighter: false,
            LastWeekFullyDone: true,
            DaysSinceLastRide: 1,
            RecentReadinessBands: []),
        Fixed: [],
        Spent: [new SpentDay(Tuesday, spentLoad)]));

    [Fact]
    public void TrainingNoticeSubject_ShouldKeepTheReasonAndTheDay_WhenASessionIsMadeEasy()
    {
        // The app and the email word the sentence from these fields; a reason alone is a session that was dropped.
        Assert.Equal("slept_poorly", TrainingNoticeSubject.Easy(TrainingEasyReasons.SleptPoorly, null));
        Assert.Equal("slept_poorly|2026-11-26",
            TrainingNoticeSubject.Easy(TrainingEasyReasons.SleptPoorly, new DateOnly(2026, 11, 26)));
        Assert.Equal("2026-11-26", TrainingNoticeSubject.Field("Strong and steady|2026-11-26", 1));
        Assert.Null(TrainingNoticeSubject.Field("Strong and steady", 1));
    }
}
