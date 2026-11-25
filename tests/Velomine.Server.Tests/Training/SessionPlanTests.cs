namespace Velomine.Server.Tests.Training;

using Velomine.Server.Features.Training;

/// <summary>
/// A recipe scaled to the day and the effort it plans to cost. The numbers are hand-worked: R05's seventy minutes are
/// 15 min at 62.5 %, 40 at 91 %, 5 at 47.5 % and 10 at 47.5 %, and 15/60 × 0.625² × 100 = 9.7656, 40/60 × 0.91² × 100 =
/// 55.2067, 5/60 × 0.475² × 100 = 1.8802 and 10/60 × 0.475² × 100 = 3.7604, which sum to 70.6.
/// </summary>
public sealed class SessionPlanTests
{
    [Fact]
    public void SessionPlan_ShouldScaleTheMainSetToTheDay_WhenTheDayIsLonger()
    {
        var (recipe, blocks) = SessionPlan.For(Recipes.ByCode("R05"), 90);

        Assert.Equal("R05", recipe.Code);
        // Warm-up and cool-down keep their length; the 40 minutes of work and 5 of recovery become 58 and 7.
        Assert.Equal([15, 58, 7, 10], blocks.Select(b => b.Minutes));
        Assert.Equal(90, blocks.Sum(b => b.Minutes));
    }

    [Fact]
    public void SessionPlan_ShouldAddUpToTheDaysMinutes_WhenTheScalingRounds()
    {
        var (_, blocks) = SessionPlan.For(Recipes.ByCode("R05"), 63);

        Assert.Equal([15, 34, 4, 10], blocks.Select(b => b.Minutes));
        Assert.Equal(63, blocks.Sum(b => b.Minutes));
    }

    [Theory]
    [MemberData(nameof(EveryRecipe))]
    public void SessionPlan_ShouldFillTheLeastLengthWithWholeMinutes_WhenEveryRecipeIsPlannedAtIt(string code)
    {
        var recipe = Recipes.ByCode(code);

        var (chosen, blocks) = SessionPlan.For(recipe, recipe.LeastMinutes);

        Assert.Equal(code, chosen.Code);
        Assert.Equal(recipe.LeastMinutes, blocks.Sum(b => b.Minutes));
        Assert.All(blocks, block => Assert.True(block.Minutes >= 1, $"{code} {block.Block.Role} got {block.Minutes} min"));
    }

    public static TheoryData<string> EveryRecipe() => [.. Recipes.All.Select(r => r.Code)];

    [Fact]
    public void SessionPlan_ShouldFallBackToTheEasyRide_WhenTheDayIsShorterThanTheRecipe()
    {
        var (recipe, blocks) = SessionPlan.For(Recipes.ByCode("R07"), 45);

        Assert.Equal("R02", recipe.Code);
        Assert.Equal(45, blocks.Sum(b => b.Minutes));
        Assert.Equal([10, 35], blocks.Select(b => b.Minutes));
    }

    [Fact]
    public void SessionPlan_ShouldScaleTheWholeSession_WhenTheDayIsShorterThanTheFixedBlocks()
    {
        // Ten minutes cannot hold R02's ten-minute warm-up and a ride: both shrink, and the day is not run over.
        var (_, blocks) = SessionPlan.For(Recipes.ByCode("R02"), 10);

        Assert.Equal([2, 8], blocks.Select(b => b.Minutes));
        Assert.Equal(10, blocks.Sum(b => b.Minutes));
    }

    [Theory]
    [InlineData("R05", 70, 70.6)]
    [InlineData("R02", 60, 40.3)]
    [InlineData("R01", 40, 15.0)]
    [InlineData("R17", 45, 40.8)]
    public void SessionPlan_ShouldWorkOutThePlannedEffortScore_WhenTheBlocksAreKnown(string code, int minutes, double score)
    {
        var (_, blocks) = SessionPlan.For(Recipes.ByCode(code), minutes);

        Assert.Equal(score, SessionPlan.PlannedScore(blocks));
    }

    [Fact]
    public void SessionPlan_ShouldScoreAFeelBlockAtFeelOverSeven_WhenItHasNoFtpTarget()
    {
        // R14's 30 easy minutes are feel 3–4, so the middle is 3.5 and 0.5 h × (3.5/7)² × 100 = 12.5.
        var (_, blocks) = SessionPlan.For(Recipes.ByCode("R14"), 30);

        Assert.Equal(12.5, SessionPlan.PlannedScore(blocks));
    }
}
