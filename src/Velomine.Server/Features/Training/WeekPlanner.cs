using Velomine.Server.Features.Analytics;

namespace Velomine.Server.Features.Training;

/// <summary>
/// A session of this week the planner may not rewrite: it is in the past, or the rider has done, made easy, moved or
/// skipped it. Its recipe and minutes are what the week already carries, so its load counts and its day keeps its place.
/// </summary>
public sealed record FixedSession(DateOnly LocalDate, string Recipe, int Minutes, string State);

/// <summary>A day of this week already ridden without a planned session: its load is spent and the day is not planned.</summary>
public sealed record SpentDay(DateOnly LocalDate, double Load);

/// <summary>
/// What the planner reads about the rider's past: how long they have been riding, how the last normal weeks went, how
/// far into the build cycle they are, whether last week was finished, and how the last three mornings felt.
/// </summary>
public sealed record PlannerHistory(
    int WeeksOfRides,
    double[] NormalWeekLoads,
    int WeeksSinceLighter,
    bool RecordedAsLighter,
    bool LastWeekFullyDone,
    int? DaysSinceLastRide,
    string[] RecentReadinessBands,
    /// <summary>How many hours a week the recent normal weeks took: what the base block restarts from after a break.</summary>
    double? RecentNormalWeekHours = null);

/// <summary>
/// Everything a week is planned from: the rider's setup, the day it is planned on, and the week's own past. A week is
/// planned from the first day the sweep may write, so a week the run catches mid-way keeps the days it already has.
/// </summary>
public sealed record PlannerInput(
    DateOnly Today,
    DayOfWeek FirstDayOfWeek,
    int[] FreeDays,
    int? LongRideDay,
    int HoursPerWeek,
    string Goal,
    int? Age,
    PlannerHistory History,
    FixedSession[] Fixed,
    SpentDay[] Spent);

/// <summary>One planned session: its day, its recipe, the day's minutes and the block percentages that day carries.</summary>
public sealed record PlannedSession(DateOnly LocalDate, string Recipe, int Minutes, int[] BlockPercents, double Score);

/// <summary>
/// A planned week: its sessions, the load they plan (the sum of their effort scores plus what the week already spent),
/// whether it is a lighter week, and whether its long ride is a loaded day.
/// </summary>
public sealed record PlannedWeek(
    DateOnly WeekStart,
    PlannedSession[] Sessions,
    double Load,
    bool IsLighterWeek,
    bool LongRideIsLoaded);

/// <summary>
/// The week's plan, as pure functions (`docs/training-models.md`, *The planned week*): the setup, the last weeks and
/// today in, the sessions out. Nothing here reads a database, a clock or a configuration: the sweep loads, calls this
/// and saves. Every safety limit the planner keeps is checked here and proved by a test that a week breaking it is not
/// produced.
/// </summary>
public static class WeekPlanner
{
    /// <summary>The long ride takes two shares of the week's minutes and every other riding day one (research §3, R03).</summary>
    public const int LongRideShares = 2;

    /// <summary>A long ride carrying more of the week's planned load than this is a loaded day as well (research §4.2).</summary>
    public const double LoadedLongRideShare = 0.35;

    /// <summary>Fewer weeks of rides than G1's first rule needs is the gentle base block.</summary>
    public const int BaseBlockWeeks = TrainingGoalSuggestion.EnoughWeeks;

    /// <summary>Back from a break this long, the plan restarts from the real recent load.</summary>
    public const int BreakDays = TrainingGoalSuggestion.BreakDays;

    /// <summary>Three weeks built, then a lighter one; two of them from this age (the year of birth gives the age).</summary>
    public const int OlderRiderAge = 50;

    public const int OlderRiderBuildWeeks = 2;

    public const int BuildWeeks = 3;

    /// <summary>A lighter week carries this much of the last normal week's load.</summary>
    public const double LighterWeekShare = 0.65;

    /// <summary>A week grows by this much, and only after a week where everything planned was done.</summary>
    public const double RampShare = 1.10;

    /// <summary>Three completed days in a row in F2's rest band make this week lighter early.</summary>
    public const int RestDaysInARow = 3;

    /// <summary>The one hard session of a lighter week is short: at most this long.</summary>
    public const int ShortHardSessionMinutes = 60;

    /// <summary>To fit a load cap a day shrinks to this; below it the week keeps fewer days instead.</summary>
    public const int MinimumDayMinutes = 20;

    /// <summary>A day has 1440 minutes, so no session can be longer, whatever the hours per week say.</summary>
    public const int MaxDayMinutes = 24 * 60;

    /// <summary>The gentle base block's recipes: ridden by feel, so they carry no targets and scale to any day.</summary>
    public static readonly string[] BaseRecipes = ["R14", "R15", "R16"];

    /// <summary>
    /// Two hard days at most, one under 4 hours a week and one in a lighter week, and never more than the goal's
    /// recipes offer.
    /// </summary>
    public static int HardDays(int hoursPerWeek, string goal, bool isLighter = false)
    {
        var most = isLighter ? 1 : hoursPerWeek >= 4 ? 2 : 1;
        return Math.Min(most, QualityPreferences(goal).Length);
    }

    /// <summary>
    /// The last four normal weeks, newest first — a week that had a ride and was not made lighter — as the caller holds
    /// them: their planned load, or the hours really ridden. A week the caller has no entry for had no ride; a week it
    /// holds as zero and a lighter week are left out, so a break or an easy week never drags down the week the rider
    /// grows from. It walks the weeks the caller read instead of a fixed window, so a rider back from a long break
    /// restarts from the week they last rode and not from the hours the setup says (W5).
    /// </summary>
    public static double[] NormalWeeks(
        IReadOnlyDictionary<DateOnly, double> ofWeek, DateOnly weekStart, IReadOnlyCollection<DateOnly> lighterWeeks) =>
        [.. ofWeek
            .Where(week => week.Key < weekStart && week.Value > 0 && !lighterWeeks.Contains(week.Key))
            .OrderByDescending(week => week.Key)
            .Take(4)
            .Select(week => week.Value)];

    /// <summary>How many weeks of history the caller reads: enough for four normal weeks and the easier weeks around them.</summary>
    public const int NormalWeeksLookBack = 8;

    /// <summary>
    /// The cap on this week's planned load, or null when no safety rule limits it: the gentle base block has no ramp,
    /// a lighter week carries 65 % of the last normal week, and a building week grows 10 % past the mean of the last
    /// four normal weeks only after a week where everything planned was done.
    /// </summary>
    public static double? LoadCap(PlannerHistory history, bool isBaseBlock, bool isLighter)
    {
        if (isBaseBlock || history.NormalWeekLoads.Length == 0) return null;
        var lastNormal = history.NormalWeekLoads[0];
        if (isLighter) return lastNormal > 0 ? LighterWeekShare * lastNormal : null;
        return (history.LastWeekFullyDone ? RampShare : 1.0) * history.NormalWeekLoads.Average();
    }

    /// <summary>The plan for one week.</summary>
    public static PlannedWeek Plan(PlannerInput input)
    {
        var weekStart = Periods.StartOf(input.Today, Periods.Week, input.FirstDayOfWeek);
        var weekEnd = weekStart.AddDays(6);
        var freeDays = input.FreeDays.Select(d => (DayOfWeek)d).ToHashSet();
        var fixedDates = input.Fixed.Select(s => s.LocalDate).ToHashSet();
        var spentDates = input.Spent.Select(d => d.LocalDate).ToHashSet();

        // The days this run writes: the rider's free days from today to the end of the week, unless the day already
        // carries a session the sweep may not touch or was already ridden with no session planned for it.
        var dates = new List<DateOnly>();
        for (var date = input.Today; date <= weekEnd; date = date.AddDays(1))
            if (freeDays.Contains(date.DayOfWeek) && !fixedDates.Contains(date) && !spentDates.Contains(date))
                dates.Add(date);

        var history = input.History;
        var isBaseBlock = IsBaseBlock(history);
        var isLighter = !isBaseBlock && IsLighterWeek(input);
        var cap = LoadCap(history, isBaseBlock, isLighter);
        var otherLoad = Math.Round(input.Fixed.Sum(s => Session(s.LocalDate, s.Recipe, s.Minutes).Score)
            + input.Spent.Sum(s => s.Load), 1);

        if (dates.Count == 0) return Week(weekStart, [], otherLoad, isLighter, false);

        var budget = Budget(input, weekStart, freeDays, dates.Count);
        // Back from a break the block restarts from the real recent load: the week is no longer than the weeks the rider
        // was really riding before it, whatever hours the setup now says (W5).
        if (isBaseBlock && FromBreak(history) && history.RecentNormalWeekHours is { } recentHours)
            budget = Math.Min(budget, (int)Math.Round(recentHours * 60));
        var longIndex = LongRideIndex(input, dates);
        // The hours cannot hold even the floor of one day: the week carries what it already spent and nothing more,
        // rather than a token minute planned to fill a day.
        if (budget < MinimumDayMinutes) return Week(weekStart, [], otherLoad, isLighter, false);
        // The rider's hours are the ceiling and a day has a floor: hours that cannot give every day one keep fewer
        // days, so the week is shorter rather than longer than the hours (W4).
        while (dates.Count > 1 && budget < MinimumDayMinutes * dates.Count)
            DropDate(dates, ref longIndex);

        // The gentle base block has no hard day at all, and a hard one the rider already rode spends a slot.
        var slots = isBaseBlock
            ? 0
            : HardDays(input.HoursPerWeek, input.Goal, isLighter)
                - input.Fixed.Count(s => Recipes.ByCode(s.Recipe).IsQuality);
        var (recipes, minutes) = Assign(input, dates, budget, longIndex, Math.Max(slots, 0), isLighter, isBaseBlock);

        // A hard day's least length can still push the week over the hours: the easy days go, then the hard days, and
        // one day alone is trimmed to the hours and to the minutes a day has.
        while (dates.Count > 1 && minutes.Sum() > budget)
            if (!DropDay(dates, recipes, minutes, ref longIndex)) break;
        var ceiling = Math.Max(Math.Min(budget, MaxDayMinutes), 1);
        for (var i = 0; i < minutes.Count; i++) minutes[i] = Math.Clamp(minutes[i], 1, ceiling);

        var (sessions, load) = Build(dates, recipes, minutes);

        // The cap is a limit on load, and the days' minutes are the only lever. The longest week that stays under it is
        // found by halving: every step either fits or does not, so twelve of them land within a minute of the answer.
        if (cap is { } limit && otherLoad + load > limit)
        {
            var fits = 0.0;
            var fails = 1.0;
            for (var step = 0; step < 12; step++)
            {
                var middle = (fits + fails) / 2;
                var (_, scaled) = Build(dates, recipes, Scaled(minutes, middle));
                if (otherLoad + scaled <= limit) fits = middle;
                else fails = middle;
            }

            minutes = Scaled(minutes, fits);
            (sessions, load) = Build(dates, recipes, minutes);
        }

        // A cap below even the shortest week of these days keeps fewer days: a shorter week, never a harder one.
        while (cap is { } tight && otherLoad + load > tight && dates.Count > 1)
        {
            if (!DropDay(dates, recipes, minutes, ref longIndex)) break;
            (sessions, load) = Build(dates, recipes, minutes);
        }

        var weekLoad = Math.Round(otherLoad + load, 1);
        var longRide = longIndex >= 0 && longIndex < dates.Count
            ? sessions.FirstOrDefault(s => s.LocalDate == dates[longIndex])
            : null;
        var longRideLoaded = longRide is not null && weekLoad > 0 && longRide.Score / weekLoad > LoadedLongRideShare;
        return Week(weekStart, sessions, weekLoad, isLighter, longRideLoaded);
    }

    private static PlannedWeek Week(
        DateOnly weekStart,
        PlannedSession[] sessions,
        double load,
        bool isLighter,
        bool longRideLoaded) =>
        new(weekStart, sessions, Math.Round(load, 1), isLighter, longRideLoaded);

    /// <summary>
    /// Fewer than four weeks of rides, or back from a break, is the gentle base block: no ramp, no intervals, feel
    /// targets only, and never a feel number above 6 (research §3, *Gentle base block*).
    /// </summary>
    private static bool IsBaseBlock(PlannerHistory history) =>
        history.WeeksOfRides < BaseBlockWeeks || FromBreak(history);

    /// <summary>
    /// Back from a break rather than new to riding: the rider has weeks behind them but has not ridden for 10 days, so
    /// the gentle block restarts from the real recent load and not from the hours they used to ride (W5).
    /// </summary>
    public static bool FromBreak(PlannerHistory history) =>
        history.WeeksOfRides >= BaseBlockWeeks && history.DaysSinceLastRide is null or >= BreakDays;

    /// <summary>
    /// The cycle: three weeks built then a lighter one, two from age 50, and a lighter week early when the last three
    /// completed days were all in F2's rest band. A week once recorded as lighter stays lighter, so a rewrite on
    /// Wednesday cannot turn it back into a build week.
    /// </summary>
    private static bool IsLighterWeek(PlannerInput input)
    {
        var history = input.History;
        if (history.RecordedAsLighter) return true;
        var buildWeeks = input.Age is >= OlderRiderAge ? OlderRiderBuildWeeks : BuildWeeks;
        if (history.WeeksSinceLighter >= buildWeeks) return true;
        return history.RecentReadinessBands.Length >= RestDaysInARow
            && history.RecentReadinessBands.Take(RestDaysInARow).All(band => band == Readiness.Rest);
    }

    /// <summary>
    /// The week's minutes for the days it still has: the rider's hours, less what the week already carries. A week met
    /// mid-way keeps the whole budget behind its remaining days; a week planned for the first time mid-way is scaled to
    /// the days left, because the days gone were never planned.
    /// </summary>
    private static int Budget(PlannerInput input, DateOnly weekStart, HashSet<DayOfWeek> freeDays, int daysLeft)
    {
        var weekDays = Enumerable.Range(0, 7).Count(i => freeDays.Contains(weekStart.AddDays(i).DayOfWeek));
        var planned = input.Fixed.Sum(s => s.Minutes);
        var share = input.Fixed.Any(s => s.LocalDate < input.Today) ? 1.0 : daysLeft / (double)Math.Max(weekDays, 1);
        return Math.Max((int)Math.Round(input.HoursPerWeek * 60 * share) - planned, 0);
    }

    /// <summary>
    /// The rider's own long-ride day, else the last free weekend day (Sunday first), else the last free day. A day next
    /// to a hard day the rider already has is never the long ride's, because two loaded days never sit in a row; when
    /// no day is left that keeps them apart the week has no long ride rather than two loaded days (W1).
    /// </summary>
    private static int LongRideIndex(PlannerInput input, List<DateOnly> dates)
    {
        // The week already has its long ride: a session the sweep may not touch with R03 is that ride.
        if (input.Fixed.Any(s => s.Recipe == "R03")) return -1;
        var loaded = input.Fixed
            .Where(s => Recipes.ByCode(s.Recipe).IsQuality || s.Recipe is "R03" or "R16")
            .Select(s => s.LocalDate)
            .ToArray();
        bool Free(int i) => !NextToHard(dates[i], [.. loaded]);

        if (input.LongRideDay is { } own)
            for (var i = 0; i < dates.Count; i++)
                if ((int)dates[i].DayOfWeek == own && Free(i)) return i;
        for (var i = dates.Count - 1; i >= 0; i--)
            if (dates[i].DayOfWeek == DayOfWeek.Sunday && Free(i)) return i;
        for (var i = dates.Count - 1; i >= 0; i--)
            if (dates[i].DayOfWeek == DayOfWeek.Saturday && Free(i)) return i;
        for (var i = dates.Count - 1; i >= 0; i--)
            if (Free(i)) return i;
        return -1;
    }

    /// <summary>The week's recipes and minutes, day by day.</summary>
    private static (List<string> Recipes, List<int> Minutes) Assign(
        PlannerInput input,
        List<DateOnly> dates,
        int budget,
        int longIndex,
        int slots,
        bool isLighter,
        bool isBaseBlock)
    {
        // The long ride takes two shares and every other day one, so the week's minutes lie on its days as they lie
        // on a week: the long ride is a day and a half of the others.
        var shares = dates.Count + LongRideShares - 1;
        var minutes = dates.Select((_, i) => budget / Math.Max(shares, 1) * (i == longIndex ? LongRideShares : 1)).ToList();
        if (longIndex >= 0) minutes[longIndex] = Math.Max(minutes[longIndex] + budget - minutes.Sum(), MinimumDayMinutes);
        if (longIndex < 0 && minutes.Count > 0) minutes[0] = Math.Max(minutes[0] + budget - minutes.Sum(), MinimumDayMinutes);

        var hard = new Dictionary<int, string>();
        foreach (var index in HardIndexes(input, dates, longIndex, slots))
            if (QualityRecipe(input.Goal, hard.Count, minutes[index], isLighter) is { } code)
                hard[index] = code;

        // A hard day is never shorter than its recipe needs, or the day would be planned as something easier.
        foreach (var (index, code) in hard)
            minutes[index] = isLighter
                ? Math.Clamp(minutes[index], Recipes.ByCode(code).LeastMinutes, ShortHardSessionMinutes)
                : Math.Max(minutes[index], Recipes.ByCode(code).LeastMinutes);
        FitBudget(minutes, budget, longIndex, [.. hard.Keys]);

        var hardDates = dates.Where((_, i) => hard.ContainsKey(i)).ToList();
        hardDates.AddRange(input.Fixed.Where(s => Recipes.ByCode(s.Recipe).IsQuality).Select(s => s.LocalDate));
        if (longIndex >= 0) hardDates.Add(dates[longIndex]);
        hardDates.AddRange(input.Fixed.Where(s => s.Recipe is "R03" or "R16").Select(s => s.LocalDate));

        var recipes = new List<string>(dates.Count);
        for (var i = 0; i < dates.Count; i++)
        {
            if (hard.TryGetValue(i, out var code)) recipes.Add(code);
            else if (i == longIndex && isBaseBlock) recipes.Add("R16");
            else if (i == longIndex) recipes.Add("R03");
            else if (isBaseBlock) recipes.Add(BaseRecipe(minutes[i], i == 1 && input.History.WeeksOfRides >= 2));
            else recipes.Add(NextToHard(dates[i], hardDates) ? "R01" : "R02");
        }

        return (recipes, minutes);
    }

    /// <summary>
    /// The gentle base block's recipe for a day: the steady build only on a day long enough to hold it, and the easy
    /// start otherwise. A base recipe rides by feel and scales to any day (SessionPlan.For), so a short day stays gentle
    /// instead of becoming an endurance session with targets it should not have (W5).
    /// </summary>
    private static string BaseRecipe(int minutes, bool secondDay) =>
        secondDay && minutes >= Recipes.ByCode("R15").LeastMinutes ? "R15" : "R14";

    /// <summary>
    /// The days a hard session can take: never two in a row, never the day before or after the long ride, and never
    /// next to a hard day the rider already has this week. When the days cannot keep that, the second one goes.
    /// </summary>
    private static List<int> HardIndexes(PlannerInput input, List<DateOnly> dates, int longIndex, int slots)
    {
        var hardDates = input.Fixed.Where(s => Recipes.ByCode(s.Recipe).IsQuality).Select(s => s.LocalDate).ToList();
        if (longIndex >= 0) hardDates.Add(dates[longIndex]);
        hardDates.AddRange(input.Fixed.Where(s => s.Recipe is "R03" or "R16").Select(s => s.LocalDate));

        var chosen = new List<int>();
        for (var i = 0; i < dates.Count && chosen.Count < slots; i++)
        {
            if (i == longIndex) continue;
            // Spacing is about days, not about positions in the list: two free days in a row are one day apart.
            if (chosen.Any(c => Math.Abs(dates[c].DayNumber - dates[i].DayNumber) == 1)) continue;
            if (hardDates.Any(d => Math.Abs(d.DayNumber - dates[i].DayNumber) == 1)) continue;
            chosen.Add(i);
        }
        return chosen;
    }

    /// <summary>
    /// Which recipes a goal draws its hard days from, the gentlest that fits first (research §3, *Which goal uses which
    /// recipe*, and `docs/training-models.md` *The planned week*). A goal that builds a habit has no hard day at all.
    /// </summary>
    public static string[] QualityPreferences(string goal) => goal switch
    {
        TrainingGoals.Faster => ["R05", "R06", "R07", "R08"],
        TrainingGoals.Fitter => ["R05", "R08", "R09"],
        TrainingGoals.Event => ["R05", "R06", "R07", "R08"],
        TrainingGoals.Keep => ["R17"],
        _ => [],
    };

    /// <summary>
    /// The recipe of the week's <paramref name="slot"/>-th hard day: the next one down the goal's list that fits the
    /// day's minutes, and in a lighter week one that fits its short length.
    /// </summary>
    private static string? QualityRecipe(string goal, int slot, int minutes, bool isLighter)
    {
        var preferences = QualityPreferences(goal);
        if (preferences.Length == 0) return null;
        var longest = isLighter ? Math.Min(minutes, ShortHardSessionMinutes) : minutes;
        var candidates = preferences.Skip(Math.Min(slot, preferences.Length - 1)).Select(Recipes.ByCode).ToArray();
        if (candidates.FirstOrDefault(recipe => recipe.LeastMinutes <= longest) is { } fits) return fits.Code;
        // Nothing fits the day: it grows into the shortest hard session the goal has, and a lighter week has none.
        return isLighter ? null : candidates.MinBy(recipe => recipe.LeastMinutes)?.Code;
    }

    /// <summary>The rider's hours are the week's ceiling: the easy days give up the minutes a hard day needs to be itself.</summary>
    private static void FitBudget(List<int> minutes, int budget, int longIndex, HashSet<int> keep)
    {
        var excess = minutes.Sum() - budget;
        if (excess <= 0) return;
        foreach (var index in Enumerable.Range(0, minutes.Count))
        {
            if (index == longIndex || keep.Contains(index)) continue;
            var give = Math.Min(excess, Math.Max(minutes[index] - MinimumDayMinutes, 0));
            minutes[index] -= give;
            excess -= give;
            if (excess <= 0) return;
        }
        if (longIndex >= 0)
        {
            var fromLongRide = Math.Min(excess, Math.Max(minutes[longIndex] - Recipes.ByCode("R03").LeastMinutes, 0));
            minutes[longIndex] -= fromLongRide;
            excess -= fromLongRide;
        }
        // Still over: the days shrink together, down to the 20-minute floor. Hours too small to carry one for every
        // day already left fewer days (Plan), and each day is then trimmed to the hours and to the 1440 minutes a day
        // holds, so the week never comes out longer or harder than the rider gave.
        if (excess <= 0) return;
        var total = minutes.Sum();
        for (var i = 0; i < minutes.Count; i++)
            minutes[i] = Math.Max((int)Math.Floor(minutes[i] * (double)budget / Math.Max(total, 1)), MinimumDayMinutes);
    }

    private static PlannedSession[] SessionList(List<DateOnly> dates, List<string> recipes, List<int> minutes) =>
        [.. dates.Select((date, i) => Session(date, recipes[i], minutes[i]))];

    private static (PlannedSession[] Sessions, double Load) Build(
        List<DateOnly> dates, List<string> recipes, List<int> minutes)
    {
        var sessions = SessionList(dates, recipes, minutes);
        return (sessions, Math.Round(sessions.Sum(s => s.Score), 1));
    }

    /// <summary>One session on one day: the recipe scaled to the day's minutes, with the block percentages it stores.</summary>
    private static PlannedSession Session(DateOnly date, string recipe, int minutes)
    {
        var (chosen, blocks) = SessionPlan.For(Recipes.ByCode(recipe), minutes);
        return new PlannedSession(
            date,
            chosen.Code,
            minutes,
            SessionPlan.Percents(blocks),
            SessionPlan.PlannedScore(blocks));
    }

    private static List<int> Scaled(List<int> minutes, double scale) =>
        [.. minutes.Select(m => Math.Max((int)Math.Floor(m * scale), MinimumDayMinutes))];

    /// <summary>Drops the last day that is not the long ride, before the recipes are chosen, so the week keeps its shape.</summary>
    private static void DropDate(List<DateOnly> dates, ref int longIndex)
    {
        var index = longIndex == dates.Count - 1 ? dates.Count - 2 : dates.Count - 1;
        dates.RemoveAt(index);
        if (longIndex > index) longIndex--;
    }

    /// <summary>
    /// Drops one day so a week too long for its hours or its cap keeps its shape: the last easy day first, then the last
    /// hard day. The long ride's day is never dropped — W1 gives the hard days up and keeps the long ride — so a week
    /// whose only day left is the long ride is left alone and the caller stops. False when nothing could go.
    /// </summary>
    private static bool DropDay(List<DateOnly> dates, List<string> recipes, List<int> minutes, ref int longIndex)
    {
        var keep = longIndex;
        var droppable = Enumerable.Range(0, dates.Count).Where(i => i != keep).ToArray();
        var easy = droppable.Where(i => !Recipes.ByCode(recipes[i]).IsQuality).DefaultIfEmpty(-1).Max();
        var index = easy >= 0 ? easy : droppable.DefaultIfEmpty(-1).Max();
        if (index < 0) return false;
        dates.RemoveAt(index);
        recipes.RemoveAt(index);
        minutes.RemoveAt(index);
        if (longIndex > index) longIndex--;
        return true;
    }

    private static bool NextToHard(DateOnly date, List<DateOnly> hardDates) =>
        hardDates.Any(d => Math.Abs(d.DayNumber - date.DayNumber) == 1);
}
