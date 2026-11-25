namespace Velomine.Server.Tests.Training;

using Velomine.Server.Features.Training;

/// <summary>
/// The fifteen session recipes: their codes, their quality flag, the goals that draw on them, and the words the rider
/// reads (`docs/design/pages/training/TrainingNames.md`; decisions, *Wording*).
/// </summary>
public sealed class RecipesTests
{
    [Fact]
    public void Recipes_ShouldHoldTheFifteenChosenRecipes_WhenTheCatalogueIsRead()
    {
        string[] expected = ["R01", "R02", "R03", "R04", "R05", "R06", "R07", "R08", "R09", "R10", "R12", "R14", "R15", "R16", "R17"];

        Assert.Equal(expected, Recipes.All.Select(r => r.Code));
        Assert.Equal(expected.Length, Recipes.All.Select(r => r.Code).Distinct().Count());
        Assert.All(Recipes.All, recipe =>
        {
            Assert.NotEmpty(recipe.Blocks);
            Assert.True(recipe.LeastMinutes > 0);
        });
    }

    [Theory]
    [InlineData("R01", false)]
    [InlineData("R02", false)]
    [InlineData("R03", false)]
    [InlineData("R04", false)]
    [InlineData("R05", true)]
    [InlineData("R06", true)]
    [InlineData("R07", true)]
    [InlineData("R08", true)]
    [InlineData("R09", true)]
    [InlineData("R10", true)]
    [InlineData("R12", false)]
    [InlineData("R14", false)]
    [InlineData("R15", false)]
    [InlineData("R16", false)]
    [InlineData("R17", true)]
    public void Recipe_ShouldBeQuality_WhenItsMainSetStartsAtEightyEightPercent(string code, bool quality) =>
        Assert.Equal(quality, Recipes.ByCode(code).IsQuality);

    [Fact]
    public void Recipes_ShouldGiveEveryGoalItsOwnRecipe_WhenTheGoalsAreRead()
    {
        Assert.All(Recipes.All, recipe => Assert.All(recipe.Goals, goal => Assert.Contains(goal, TrainingGoals.All)));
        Assert.All(TrainingGoals.All, goal => Assert.Contains(Recipes.All, recipe => recipe.Goals.Contains(goal)));

        // Keeping fitness needs one short hard session: the keep goal has a quality recipe of its own.
        Assert.Contains(Recipes.All, recipe => recipe.Goals.Contains(TrainingGoals.Keep) && recipe.IsQuality);
        // The gentle base recipes start a rider off, which is the aerobic goal (research §3, §5 rule 1).
        Assert.All(["R14", "R15", "R16"], code => Assert.Equal([TrainingGoals.Aerobic], Recipes.ByCode(code).Goals));
        // The long ride is every goal's, because the planner hands R03 to every week outside the gentle base block.
        Assert.All(TrainingGoals.All, goal => Assert.Contains(goal, Recipes.ByCode("R03").Goals));
    }

    [Fact]
    public void Recipe_ShouldKeepEveryPercentageAndFeelInsideItsScale_WhenEveryBlockIsRead() =>
        Assert.All(Recipes.All, recipe => Assert.All(recipe.Blocks, block =>
        {
            Assert.Contains(block.Role, new[] { RecipeRoles.Warmup, RecipeRoles.Main, RecipeRoles.Recovery, RecipeRoles.Cooldown });
            Assert.True(block.Minutes > 0);
            Assert.InRange(block.Feel.Low, 1, 10);
            Assert.InRange(block.Feel.High, block.Feel.Low, 10);
            if (block.PercentFtp is { } ftp)
            {
                Assert.InRange(ftp.Low, 1, 150);
                Assert.InRange(ftp.High, ftp.Low, 150);
            }

            if (block.PercentThresholdHeartRate is { } heartRate)
            {
                Assert.InRange(heartRate.Low, 1, 150);
                Assert.InRange(heartRate.High, heartRate.Low, 150);
            }
        }));

    [Fact]
    public void Recipe_ShouldNameTheSweetSpotRecipeStrongAndSteady_WhenTheRiderReadsIt()
    {
        var recipe = Recipes.ByCode("R05");

        Assert.Equal("Strong and steady", recipe.EnglishName);
        Assert.Equal("Forte e costante", recipe.ItalianName);
        Assert.Equal("Sweet spot", recipe.TechnicalName);
    }

    [Fact]
    public void Recipe_ShouldKeepTheTechnicalTermOutOfTheRidersWords_WhenAnyTextIsRead()
    {
        // The technical names are what coaching calls the recipe; only the "Coaches call this …" line may show them.
        var riderText = Recipes.All
            .SelectMany(r => new[] { r.EnglishName, r.ItalianName, r.EnglishLine, r.ItalianLine })
            .ToArray();

        Assert.All(riderText, text => Assert.DoesNotContain("sweet spot", text, StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void Recipe_ShouldUseNoBannedWording_WhenTheRiderReadsAnyText()
    {
        // Decisions, *Wording*: none of these may appear in words the rider reads.
        string[] banned = ["polarised is best", "proven FTP builder", "fat-burning", "faster recovery", "junk miles"];

        var riderText = Recipes.All
            .SelectMany(r => new[] { r.EnglishName, r.ItalianName, r.EnglishLine, r.ItalianLine })
            .Concat([SessionNotes.AddPowerMeter.English, SessionNotes.AddPowerMeter.Italian,
                SessionNotes.SetFtp.English, SessionNotes.SetFtp.Italian,
                SessionNotes.HeartRateLags.English, SessionNotes.HeartRateLags.Italian])
            .ToArray();

        Assert.All(riderText, text => Assert.All(banned, phrase =>
            Assert.DoesNotContain(phrase, text, StringComparison.OrdinalIgnoreCase)));
    }
}
