using Velomine.Server.Features.Training;

namespace Velomine.Server.Tests.Training;

/// <summary>
/// Which session a ride ticked, and which one it asks about. The rule is one ride per plan: the day's closest by
/// duration wins, then the higher effort score, and a ride of the day before or after asks within a quarter of both.
/// </summary>
public sealed class SessionMatchTests
{
    /// <summary>A Monday, a Tuesday and the days around them.</summary>
    private static readonly DateOnly Sunday = new(2026, 11, 22);
    private static readonly DateOnly Monday = new(2026, 11, 23);
    private static readonly DateOnly Tuesday = Monday.AddDays(1);
    private static readonly DateOnly Wednesday = Monday.AddDays(2);

    /// <summary>R05 in a one-hour day plans 3 600 s of riding and an effort score of 57.8.</summary>
    private const double PlannedS = 3600;
    private const double PlannedEffort = 57.8;

    private static TrainingSession Session(
        DateOnly date,
        string state = TrainingSessionStates.Planned,
        Guid? rideId = null,
        Guid? question = null,
        string recipe = "R05",
        int minutes = 60) => new()
        {
            Id = Guid.CreateVersion7(),
            LocalDate = date,
            Recipe = recipe,
            Minutes = minutes,
            BlockPercents = [91],
            State = state,
            RideId = rideId,
            QuestionRideId = question,
        };

    private static MatchRide Ride(DateOnly date, double movingS, double? effort, Guid? id = null) =>
        new(id ?? Guid.CreateVersion7(), date, movingS, effort);

    [Fact]
    public void SessionMatch_ShouldTickTheSessionOfItsDay_WhenTheRideIsReady()
    {
        var session = Session(Tuesday);
        var ride = Ride(Tuesday, 4200, 60);

        var match = SessionMatch.Decide([session], [ride], ride);

        Assert.NotNull(match);
        Assert.Equal(session.Id, match.Value.Session.Id);
        Assert.False(match.Value.Asks);
    }

    [Fact]
    public void SessionMatch_ShouldTakeTheClosestByDuration_WhenTheDayHasSeveralRides()
    {
        var session = Session(Tuesday);
        var near = Ride(Tuesday, PlannedS + 120, 55);
        var far = Ride(Tuesday, PlannedS + 900, 55);
        MatchRide[] day = [far, near];

        Assert.True(SessionMatch.Decide([session], day, near) is { Asks: false });
        // The further ride arrived first in time but the session is not its: the closest one is.
        Assert.Null(SessionMatch.Decide([session], day, far));
    }

    [Fact]
    public void SessionMatch_ShouldTakeTheHigherEffortScore_WhenTwoRidesAreAsCloseInDuration()
    {
        var session = Session(Tuesday);
        var hard = Ride(Tuesday, PlannedS + 300, 80);
        var easy = Ride(Tuesday, PlannedS - 300, 50);
        MatchRide[] day = [easy, hard];

        Assert.True(SessionMatch.Decide([session], day, hard) is { Asks: false });
        Assert.Null(SessionMatch.Decide([session], day, easy));
    }

    [Fact]
    public void SessionMatch_ShouldAskAboutTheOpenSessionOfTheDayBefore_WhenTheRideIsCloseToIt()
    {
        var session = Session(Monday);
        var ride = Ride(Tuesday, PlannedS - 600, PlannedEffort - 5);

        var match = SessionMatch.Decide([session], [ride], ride);

        Assert.NotNull(match);
        Assert.Equal(session.Id, match.Value.Session.Id);
        Assert.True(match.Value.Asks);
    }

    [Fact]
    public void SessionMatch_ShouldAskNothing_WhenTheRideIsNotWithinAQuarterOfTheSession()
    {
        var before = Session(Monday);
        var after = Session(Wednesday);
        TrainingSession[] sessions = [before, after];

        // A third longer than planned, and a third harder: neither is the session.
        Assert.Null(SessionMatch.Decide(sessions, [], Ride(Tuesday, PlannedS * 1.3, PlannedEffort)));
        Assert.Null(SessionMatch.Decide(sessions, [], Ride(Tuesday, PlannedS, PlannedEffort * 1.3)));
        // Inside a quarter of both: it asks.
        Assert.NotNull(SessionMatch.Decide(sessions, [], Ride(Tuesday, PlannedS * 1.2, PlannedEffort * 1.2)));
    }

    [Fact]
    public void SessionMatch_ShouldAskNothing_WhenTheRideHasNoEffortScore()
    {
        var session = Session(Monday);

        Assert.Null(SessionMatch.Decide([session], [], Ride(Tuesday, PlannedS, null)));
    }

    [Fact]
    public void SessionMatch_ShouldNotAsk_WhenTheSessionIsAlreadyAskingAboutAnotherRide()
    {
        var session = Session(Monday, question: Guid.CreateVersion7());

        Assert.Null(SessionMatch.Decide([session], [], Ride(Tuesday, PlannedS, PlannedEffort)));
    }

    [Fact]
    public void SessionMatch_ShouldNotAsk_WhenTheRideHasNoSessionOfItsNeighbouringDay()
    {
        // Sessions two days away, and a rest day that is not one: nothing to ask about.
        Assert.Null(SessionMatch.Decide([Session(Sunday)], [], Ride(Tuesday, PlannedS, PlannedEffort)));
    }

    [Fact]
    public void SessionMatch_ShouldNotAsk_WhenTheRidesDayAlreadyHasASessionOfItsOwn()
    {
        var own = Session(Tuesday);
        var beside = Session(Monday);

        var match = SessionMatch.Decide([own, beside], [], Ride(Tuesday, PlannedS, PlannedEffort));

        Assert.NotNull(match);
        Assert.Equal(own.Id, match.Value.Session.Id);
        Assert.False(match.Value.Asks);
    }

    [Fact]
    public void SessionMatch_ShouldNotReTick_WhenTheRideAlreadyTickedsTheSession()
    {
        var ride = Ride(Tuesday, PlannedS, PlannedEffort);
        var session = Session(Tuesday, TrainingSessionStates.Done, rideId: ride.Id);

        Assert.Null(SessionMatch.Decide([session], [ride], ride));
    }

    [Fact]
    public void SessionMatch_ShouldReTickWithTheCloserRide_WhenTheSecondRideOfTheDayIsCloser()
    {
        var ticked = Ride(Tuesday, PlannedS + 1200, PlannedEffort);
        var session = Session(Tuesday, TrainingSessionStates.Done, rideId: ticked.Id);
        var closer = Ride(Tuesday, PlannedS + 60, PlannedEffort);
        MatchRide[] day = [ticked, closer];

        var match = SessionMatch.Decide([session], day, closer);

        Assert.NotNull(match);
        Assert.Equal(session.Id, match.Value.Session.Id);
        Assert.Null(SessionMatch.Decide([session], day, ticked));
    }

    [Fact]
    public void SessionMatch_ShouldTickAnEasySessionOfTheDay_WhenTheRideIsReady()
    {
        // A session made easy is still the session the rider rides: the ride of its day is ticked against it, and the
        // session stays easy — never asked about, and never thrown away.
        var easy = Session(Tuesday, TrainingSessionStates.Easy);
        var ride = Ride(Tuesday, PlannedS, PlannedEffort);

        var match = SessionMatch.Decide([easy], [ride], ride);

        Assert.NotNull(match);
        Assert.Equal(easy.Id, match.Value.Session.Id);
        Assert.False(match.Value.Asks);
    }

    [Fact]
    public void SessionMatch_ShouldNotAskAboutAnEasySessionOfAnotherDay_WhenTheRideIsBesideIt()
    {
        // The question moves the session to the ride's day, and a session made easy on its own day is not moved.
        var easy = Session(Monday, TrainingSessionStates.Easy);

        Assert.Null(SessionMatch.Decide([easy], [], Ride(Tuesday, PlannedS, PlannedEffort)));
    }
}
