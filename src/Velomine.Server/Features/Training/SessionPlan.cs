namespace Velomine.Server.Features.Training;

/// <summary>One block of a session with the minutes it gets on the day.</summary>
public sealed record PlannedBlock(RecipeBlock Block, int Minutes);

/// <summary>
/// A session's shape on a day: the recipe scaled to the day's minutes, and the effort it plans to cost. Both are pure
/// arithmetic on the recipe, so nothing about a session's targets is stored.
/// </summary>
public static class SessionPlan
{
    /// <summary>
    /// The recipe's blocks in <paramref name="minutes"/>: the warm-up and the cool-down keep their length and the work,
    /// recovery and steady blocks take up the rest, unless the day is shorter than them, when the whole session scales.
    /// A day shorter than the recipe's least length gets R02 instead — except the gentle base recipes, which ride by
    /// feel and scale to any day, because the fallback would show the watt and heart-rate targets they have none of.
    /// </summary>
    public static (Recipe Recipe, PlannedBlock[] Blocks) For(Recipe recipe, int minutes)
    {
        var chosen = minutes < recipe.LeastMinutes && !WeekPlanner.BaseRecipes.Contains(recipe.Code)
            ? Recipes.ByCode(Recipes.FallbackCode)
            : recipe;
        return (chosen, Scale(chosen, minutes));
    }

    /// <summary>
    /// A session's planned effort score: P3's form summed over its blocks, `Σ(hours × IF² × 100)`, each block's IF from
    /// its % FTP. Velomine's own (see `docs/training-models.md`, *Session recipes*).
    /// </summary>
    public static double PlannedScore(IEnumerable<PlannedBlock> blocks) =>
        Math.Round(blocks.Sum(b => b.Minutes / 60.0 * Math.Pow(Intensity(b.Block), 2) * 100), 1);

    /// <summary>The planned effort score of a stored session, from its recipe code and the day's minutes.</summary>
    public static double PlannedScore(string recipe, int minutes) => PlannedScore(For(Recipes.ByCode(recipe), minutes).Blocks);

    /// <summary>The minutes a stored session plans, which is the day's minutes unless the recipe had to fall back.</summary>
    public static int PlannedMinutes(string recipe, int minutes) => For(Recipes.ByCode(recipe), minutes).Blocks.Sum(b => b.Minutes);

    /// <summary>
    /// A block's intensity factor: the middle of its % FTP band (the drafts work their TSS from the aim inside the
    /// zone), or the middle of its feel band over 7 where it has no FTP target, because an hour ridden at feel 7 is one
    /// hour at the threshold (F1).
    /// </summary>
    public static double Intensity(RecipeBlock block) =>
        block.PercentFtp is { } ftp ? ftp.Middle / 100 : block.Feel.Middle / 7.0;

    private static PlannedBlock[] Scale(Recipe recipe, int minutes)
    {
        var fixedMinutes = recipe.Blocks.Where(b => !RecipeRoles.Scales(b.Role)).Sum(b => b.Minutes);
        // A day too short for the fixed blocks and a minute of each other block scales the whole session, so the day's
        // minutes are never run over: ten minutes of R02 is two easy minutes and eight steady ones.
        var wholeSession = minutes < fixedMinutes + recipe.Blocks.Count(b => RecipeRoles.Scales(b.Role));
        var scalable = recipe.Blocks.Select(b => wholeSession || RecipeRoles.Scales(b.Role)).ToArray();
        var nominal = recipe.Blocks.Where((_, i) => scalable[i]).Sum(b => b.Minutes);
        if (nominal <= 0) return [.. recipe.Blocks.Select(b => new PlannedBlock(b, b.Minutes))];
        // A minute each at least, so a very short day still keeps every block of the session.
        var available = wholeSession
            ? Math.Max(minutes, 0)
            : Math.Max(minutes - fixedMinutes, scalable.Count(s => s));

        var planned = new List<PlannedBlock>(recipe.Blocks.Length);
        int longest = -1, assigned = 0;
        for (var i = 0; i < recipe.Blocks.Length; i++)
        {
            var block = recipe.Blocks[i];
            if (!scalable[i])
            {
                planned.Add(new(block, block.Minutes));
                continue;
            }

            var scaled = (int)Math.Round(available * block.Minutes / (double)nominal);
            planned.Add(new(block, scaled));
            assigned += scaled;
            if (longest < 0 || scaled > planned[longest].Minutes) longest = planned.Count - 1;
        }

        // Rounding is a minute out per block at worst; the longest block carries the difference so the day is exact.
        if (longest >= 0) planned[longest] = planned[longest] with { Minutes = planned[longest].Minutes + available - assigned };
        return [.. planned];
    }
}
