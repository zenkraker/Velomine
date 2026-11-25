using Velomine.Server.Features.Training;

namespace Velomine.Server.Tests.Training;

/// <summary>
/// Velomine's session score (L7): time 40 %, effort 40 % and time in target on the main set 20 % when the ride carries
/// the leading signal; without it, time 50 % and effort 50 %, so a rider without sensors still reaches 100.
/// </summary>
public sealed class SessionScoreTests
{
    [Fact]
    public void Score_ShouldBeOneHundred_WhenTheRideDidTheWholePlanInsideTheTarget()
    {
        Assert.Equal(100, SessionScore.Score(timeShare: 1, effortShare: 1, targetShare: 1));
    }

    [Fact]
    public void Score_ShouldWeighTimeFortyEffortFortyAndTargetTwenty_WhenTheRideHasTheSignal()
    {
        // Half the time, half the effort, half the main set in target: 20 + 20 + 10.
        Assert.Equal(50, SessionScore.Score(timeShare: 0.5, effortShare: 0.5, targetShare: 0.5));
        // A perfect ride that never found the target: 40 + 40 + 0.
        Assert.Equal(80, SessionScore.Score(timeShare: 1, effortShare: 1, targetShare: 0));
    }

    [Fact]
    public void Score_ShouldWeighTimeAndEffortFiftyFifty_WhenTheRideHasNoLeadingSignal()
    {
        // The gentle base recipes ride by feel: half the time at the planned effort is 25 + 50.
        Assert.Equal(75, SessionScore.Score(timeShare: 0.5, effortShare: 1, targetShare: null));
        Assert.Equal(100, SessionScore.Score(timeShare: 1, effortShare: 1, targetShare: null));
    }

    [Fact]
    public void Score_ShouldRoundToTheNearestWholeNumber_WhenTheSharesAreNotExact()
    {
        // An hour of R05 planned at 57.8 ridden at a steady 150 W: effort 36, so 40 + 40 × 36 / 57.8 + 0 = 64.9.
        Assert.Equal(65, SessionScore.Score(timeShare: 1, effortShare: SessionScore.Share(36, 57.8), targetShare: 0));
        // Nothing done at all is zero, never a negative score.
        Assert.Equal(0, SessionScore.Score(timeShare: 0, effortShare: 0, targetShare: 0));
    }

    [Fact]
    public void Share_ShouldNeverExceedOne_WhenTheRideIsLongerOrHarderThanThePlan()
    {
        Assert.Equal(1, SessionScore.Share(done: 7200, planned: 3600));
        Assert.Equal(0.5, SessionScore.Share(done: 1800, planned: 3600));
        Assert.Equal(0, SessionScore.Share(done: 600, planned: 0));
    }

    [Fact]
    public void MainSetShare_ShouldCountOnlyTheSecondsInsideTheBands_WhenTheStreamLeavesThem()
    {
        double[] time = [0, 10, 20, 30, 40];
        short?[] power = [228, 240, 210, 230, 228];
        MainBand[] bands = [new(220, 235)];

        // 10 s at 228 and 10 s at 230 are inside; 240 and 210 are not.
        Assert.Equal(20.0 / 60.0, SessionScore.MainSetShare(bands, plannedMinutes: 1, time, power)!.Value, 3);
    }

    [Fact]
    public void MainSetShare_ShouldBeTheWholeSet_WhenTheRideSpendsLongerInTarget()
    {
        double[] time = [0, 30, 60, 90, 120];
        short?[] power = [228, 230, 225, 232, 229];

        Assert.Equal(1, SessionScore.MainSetShare([new(220, 235)], plannedMinutes: 1, time, power));
    }

    [Fact]
    public void MainSetShare_ShouldCountAnyOfTheMainSetsBands_WhenTheSetHasTwo()
    {
        double[] time = [0, 10, 20, 30, 40];
        short?[] power = [150, 228, 150, 250, 150];
        MainBand[] bands = [new(220, 235), new(240, 260)];

        // 10 s in the first band and 10 s in the second, of a planned minute.
        Assert.Equal(20.0 / 60.0, SessionScore.MainSetShare(bands, plannedMinutes: 1, time, power)!.Value, 3);
    }

    [Fact]
    public void MainSetShare_ShouldBeNull_WhenTheRideHasNoSuchSignal()
    {
        double[] time = [0, 10, 20];

        Assert.Null(SessionScore.MainSetShare([new(220, 235)], plannedMinutes: 1, time, values: null));
        Assert.Null(SessionScore.MainSetShare([], plannedMinutes: 1, time, [228, 228, 228]));
    }

    [Fact]
    public void MainSetShare_ShouldLeaveOutAPause_WhenTheGapBetweenSamplesIsLong()
    {
        double[] time = [0, 10, 100, 110];
        short?[] power = [228, 228, 228, 228];

        // The 90 s gap is a pause: only the two ten-second stretches count.
        Assert.Equal(20.0 / 60.0, SessionScore.MainSetShare([new(220, 235)], plannedMinutes: 1, time, power)!.Value, 3);
    }
}
