namespace Velomine.Server.Tests.Training;

using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Training;

/// <summary>
/// A session's targets from today's numbers: watts from the FTP in use (P6), heart rate from the threshold in use
/// (H3), feel from F1. R05's main set is 88–94 % of FTP and 91–97 % of the threshold, and its warm-up 55–70 % and
/// 80–88 %. The heart-rate numbers are the ones <see cref="HeartRates.For"/> gives: a threshold the rider set, or
/// 89 % of the maximum (H2) — 169 for a typed maximum of 190, which is the estimate the app marks as one.
/// </summary>
public sealed class SessionTargetsTests
{
    private static readonly HeartRate SetThreshold = new(170, HeartRateSources.Manual);

    /// <summary>What HeartRates.For gives a rider with a typed maximum of 190 and no threshold.</summary>
    private static readonly HeartRate EstimatedThreshold = new(169, FtpSources.Estimate);

    [Fact]
    public void SessionTargets_ShouldMultiplyTheBlocksPercentagesByTheFtp_WhenTheRiderHasOne()
    {
        var session = SessionTargets.For(Recipes.ByCode("R05"), 70, ftpW: 300, SetThreshold);

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
        var session = SessionTargets.For(Recipes.ByCode("R05"), 70, ftpW: 300, SetThreshold);

        // 91 % of 170 = 154.7 and 97 % of 170 = 164.9.
        Assert.Equal((155, 165), (session.Blocks[1].HeartRateLow, session.Blocks[1].HeartRateHigh));
        Assert.Equal((136, 150), (session.Blocks[0].HeartRateLow, session.Blocks[0].HeartRateHigh));
        Assert.False(session.HeartRateEstimated);
    }

    [Fact]
    public void SessionTargets_ShouldMarkTheHeartRateEstimated_WhenTheThresholdIsEightyNinePercentOfTheMaximum()
    {
        var session = SessionTargets.For(Recipes.ByCode("R05"), 70, ftpW: 300, EstimatedThreshold);

        // The threshold in use is H2's estimate, 89 % of 190 = 169.1 bpm; 91 % of it is 153.8 and 97 % is 163.9.
        Assert.Equal((154, 164), (session.Blocks[1].HeartRateLow, session.Blocks[1].HeartRateHigh));
        Assert.True(session.HeartRateEstimated);
    }

    [Fact]
    public void SessionTargets_ShouldGiveNoWattTarget_WhenTheRiderHasNoFtpAndNoPowerMeter()
    {
        var session = SessionTargets.For(Recipes.ByCode("R05"), 70, ftpW: null, SetThreshold);

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
    public void SessionTargets_ShouldAskForAnFtp_WhenTheRiderHasAPowerMeterButNoFtp()
    {
        var session = SessionTargets.For(Recipes.ByCode("R05"), 70, ftpW: null, SetThreshold, hasPowerMeter: true);

        Assert.All(session.Blocks, block => Assert.Null(block.WattsLow));
        var note = Assert.Single(session.Notes);
        Assert.Equal("set_ftp", note.Code);
        Assert.Equal("Set your FTP for watt targets", note.English);
        Assert.Equal("Imposta il tuo FTP per gli obiettivi in watt", note.Italian);
    }

    [Fact]
    public void SessionTargets_ShouldLeaveHeartRateOffAnEffortOfTwoMinutes_WhenTheSessionHasOne()
    {
        // R09's main set is 30 seconds hard, and its recovery 15 seconds easy.
        var session = SessionTargets.For(Recipes.ByCode("R09"), 50, ftpW: 300, SetThreshold);

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
    public void SessionTargets_ShouldKeepHeartRateBelowTheMaximum_WhenTheEffortIsAVO2Interval()
    {
        // R08's efforts are five minutes long: heart rate is a target, and it stops at the threshold rather than asking
        // for a beat the rider's maximum cannot reach.
        var session = SessionTargets.For(Recipes.ByCode("R08"), 70, ftpW: 300, SetThreshold);

        Assert.Equal((160, 170), (session.Blocks[1].HeartRateLow, session.Blocks[1].HeartRateHigh));
        Assert.Empty(session.Notes);
    }

    [Fact]
    public void SessionTargets_ShouldFallBackToTheEasyRide_WhenTheDayIsShorterThanTheRecipe()
    {
        var session = SessionTargets.For(Recipes.ByCode("R07"), 45, ftpW: 300, SetThreshold);

        Assert.Equal("R02", session.Recipe.Code);
        Assert.Equal(45, session.Minutes);
        Assert.Equal(35, session.Blocks[^1].Minutes);
    }
}
