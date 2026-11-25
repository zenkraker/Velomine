namespace Velomine.Server.Tests.Training;

using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Training;

/// <summary>
/// A session's targets from today's numbers: watts from the FTP in use (P6), heart rate through the zone model in use
/// (H3), feel from F1. R05's main set is 88–94 % of FTP and 91–97 % of threshold heart rate, and its warm-up 55–70 % and
/// 80–88 %.
/// </summary>
public sealed class SessionTargetsTests
{
    private static readonly HeartRateZoneReference Threshold =
        new(HeartRateZoneModels.Threshold, 170, HeartRateSources.Manual, TrainingLoad.ThresholdHeartRateBounds);

    private static readonly HeartRateZoneReference Maximum =
        new(HeartRateZoneModels.Max, 190, HeartRateSources.Manual, TrainingLoad.HeartRateBounds);

    [Fact]
    public void SessionTargets_ShouldMultiplyTheBlocksPercentagesByTheFtp_WhenTheRiderHasOne()
    {
        var session = SessionTargets.For(Recipes.ByCode("R05"), 70, ftpW: 300, Threshold);

        var main = session.Blocks[1];
        Assert.Equal(264, main.WattsLow);
        Assert.Equal(282, main.WattsHigh);
        Assert.Equal(5, main.FeelLow);
        Assert.Equal(6, main.FeelHigh);
        Assert.Equal((165, 210), (session.Blocks[0].WattsLow, session.Blocks[0].WattsHigh));
        Assert.Empty(session.Notes);
    }

    [Fact]
    public void SessionTargets_ShouldReadTheBlocksAgainstTheThreshold_WhenTheRiderSetOne()
    {
        var session = SessionTargets.For(Recipes.ByCode("R05"), 70, ftpW: 300, Threshold);

        // 91 % of 170 = 154.7 and 97 % of 170 = 164.9.
        Assert.Equal((155, 165), (session.Blocks[1].HeartRateLow, session.Blocks[1].HeartRateHigh));
        Assert.Equal((136, 150), (session.Blocks[0].HeartRateLow, session.Blocks[0].HeartRateHigh));
    }

    [Fact]
    public void SessionTargets_ShouldUseEightyNinePercentOfTheMaximum_WhenTheRiderHasNoThreshold()
    {
        var session = SessionTargets.For(Recipes.ByCode("R05"), 70, ftpW: 300, Maximum);

        // The threshold in use is H2's estimate, 89 % of 190 = 169.1 bpm; 91 % of it is 153.8 and 97 % is 163.9.
        Assert.Equal(169, SessionTargets.ThresholdHeartRate(Maximum));
        Assert.Equal((154, 164), (session.Blocks[1].HeartRateLow, session.Blocks[1].HeartRateHigh));
    }

    [Fact]
    public void SessionTargets_ShouldGiveNoWattTarget_WhenTheRiderHasNoFtp()
    {
        var session = SessionTargets.For(Recipes.ByCode("R05"), 70, ftpW: null, Threshold);

        Assert.All(session.Blocks, block =>
        {
            Assert.Null(block.WattsLow);
            Assert.Null(block.WattsHigh);
        });
        var note = Assert.Single(session.Notes);
        Assert.Equal("Add a power meter for watt targets", note.English);
        Assert.Equal("Aggiungi un misuratore di potenza per gli obiettivi in watt", note.Italian);
        // Heart rate and feel are still there.
        Assert.Equal(155, session.Blocks[1].HeartRateLow);
        Assert.Equal(5, session.Blocks[1].FeelLow);
    }

    [Fact]
    public void SessionTargets_ShouldLeaveHeartRateOffAnEffortOfTwoMinutes_WhenTheSessionHasOne()
    {
        // R09's main set is 30 seconds hard, and its recovery 15 seconds easy.
        var session = SessionTargets.For(Recipes.ByCode("R09"), 50, ftpW: 300, Threshold);

        Assert.Equal(RecipeRoles.Main, session.Blocks[1].Role);
        Assert.Null(session.Blocks[1].HeartRateLow);
        Assert.Null(session.Blocks[1].HeartRateHigh);
        Assert.Equal((345, 375), (session.Blocks[1].WattsLow, session.Blocks[1].WattsHigh));
        Assert.Equal((8, 9), (session.Blocks[1].FeelLow, session.Blocks[1].FeelHigh));
        // The warm-up is long enough to ride by heart rate.
        Assert.Equal(136, session.Blocks[0].HeartRateLow);
        var note = Assert.Single(session.Notes);
        Assert.Equal("Heart rate lags here: go by watts and feel", note.English);
    }

    [Fact]
    public void SessionTargets_ShouldKeepHeartRate_WhenTheEffortIsLongerThanTwoMinutes()
    {
        // R08's efforts are five minutes long: heart rate is a target, late in each effort.
        var session = SessionTargets.For(Recipes.ByCode("R08"), 70, ftpW: 300, Threshold);

        Assert.Equal((175, 195), (session.Blocks[1].HeartRateLow, session.Blocks[1].HeartRateHigh));
        Assert.Empty(session.Notes);
    }

    [Fact]
    public void SessionTargets_ShouldFallBackToTheEasyRide_WhenTheDayIsShorterThanTheRecipe()
    {
        var session = SessionTargets.For(Recipes.ByCode("R07"), 45, ftpW: 300, Threshold);

        Assert.Equal("R02", session.Recipe.Code);
        Assert.Equal(45, session.Minutes);
        Assert.Equal(35, session.Blocks[^1].Minutes);
    }
}
