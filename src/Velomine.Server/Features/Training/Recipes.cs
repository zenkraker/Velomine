namespace Velomine.Server.Features.Training;

/// <summary>The goals the auto-training setup offers, as the API spells them (decisions, *Names the rider sees*).</summary>
public static class TrainingRecipeGoals
{
    public const string Aerobic = "aerobic";
    public const string Fitter = "fitter";
    public const string Faster = "faster";
    public const string Event = "event";
    public const string Keep = "keep";

    public static readonly string[] All = [Aerobic, Fitter, Faster, Event, Keep];
}

/// <summary>A target band: a percentage of a reference, or a feel number on F1's 1–10 scale.</summary>
public sealed record TargetRange(int Low, int High)
{
    public double Middle => (Low + High) / 2.0;
}

/// <summary>
/// The part a block plays in a session. A warm-up and a cool-down keep their length when a recipe scales to the day's
/// minutes; work, recovery and a steady ride scale.
/// </summary>
public static class RecipeRoles
{
    public const string Warmup = "warmup";
    public const string Main = "main";
    public const string Recovery = "recovery";
    public const string Cooldown = "cooldown";

    public static bool Scales(string role) => role is Main or Recovery;
}

/// <summary>
/// One block of a recipe as <c>docs/training-models.md</c> *Session recipes* gives it: its nominal length, its % FTP
/// (P4), its % threshold heart rate (H5) and its feel (F1). <see cref="EffortSeconds"/> is the length of a single effort
/// in a block of intervals and null for a block ridden continuously. A null % FTP or heart rate is a block that has no
/// target in that signal: the gentle base recipes are ride by feel (research §3), and anaerobic efforts have no usable
/// heart rate.
/// </summary>
public sealed record RecipeBlock(
    string Role,
    int Minutes,
    TargetRange? PercentFtp,
    TargetRange? PercentThresholdHeartRate,
    TargetRange Feel,
    int? EffortSeconds = null);

/// <summary>
/// One of the fifteen session recipes (decisions, *Content*). The code is internal; the rider reads
/// <see cref="EnglishName"/> or <see cref="ItalianName"/> and <see cref="EnglishLine"/> or <see cref="ItalianLine"/>.
/// <see cref="TechnicalName"/> is what coaching calls it and appears only in the "Coaches call this …" line and in
/// <c>docs/training-models.md</c>.
/// </summary>
public sealed record Recipe(
    string Code,
    string TechnicalName,
    string EnglishName,
    string ItalianName,
    string EnglishLine,
    string ItalianLine,
    int LeastMinutes,
    string[] Goals,
    RecipeBlock[] Blocks)
{
    /// <summary>
    /// A quality session: its main set reaches 88 % FTP, the sweet-spot floor (P4's Z4 floor is 90 %; the boundary is
    /// Velomine's own). R05–R10 are the quality recipes.
    /// </summary>
    public bool IsQuality => Blocks.Any(b => b.Role == RecipeRoles.Main && b.PercentFtp is { Low: >= 88 });
}

/// <summary>The fifteen recipes from research §3, with the numbers `docs/training-models.md` *Session recipes* keeps.</summary>
public static class Recipes
{
    /// <summary>The recipe a day shorter than the chosen one's least length falls back to.</summary>
    public const string FallbackCode = "R02";

    private static readonly string[] EveryGoal = TrainingRecipeGoals.All;

    public static readonly Recipe[] All =
    [
        new("R01", "Easy spin (recovery)", "Easy spin", "Giro defaticante",
            "Legs moving, nothing more. You should be able to chat.",
            "Gambe in movimento, niente di più. Devi riuscire a chiacchierare.",
            30, EveryGoal,
            [
                new(RecipeRoles.Main, 30, new(40, 55), new(60, 80), new(1, 2)),
            ]),

        new("R02", "Endurance", "Easy ride", "Giro tranquillo",
            "Steady and comfortable: the ride that builds everything else.",
            "Costante e comodo: il giro su cui si costruisce tutto il resto.",
            45, EveryGoal,
            [
                new(RecipeRoles.Warmup, 10, new(45, 60), new(70, 80), new(2, 3)),
                new(RecipeRoles.Main, 50, new(56, 75), new(81, 89), new(3, 4)),
            ]),

        new("R03", "Long ride", "Long ride", "Uscita lunga",
            "Your longest ride of the week, at an easy pace.",
            "Il tuo giro più lungo della settimana, a ritmo facile.",
            60, [TrainingRecipeGoals.Fitter, TrainingRecipeGoals.Faster, TrainingRecipeGoals.Event, TrainingRecipeGoals.Keep],
            [
                new(RecipeRoles.Warmup, 10, new(45, 60), new(70, 80), new(2, 3)),
                new(RecipeRoles.Main, 90, new(56, 75), new(81, 89), new(3, 4)),
                new(RecipeRoles.Main, 20, new(70, 80), new(88, 93), new(4, 4)),
            ]),

        new("R04", "Tempo", "Steady pace", "Ritmo costante",
            "A bit faster than easy: talking in short sentences.",
            "Un po' più veloce del facile: parli a frasi brevi.",
            60, [TrainingRecipeGoals.Fitter, TrainingRecipeGoals.Event],
            [
                new(RecipeRoles.Warmup, 15, new(45, 65), new(75, 85), new(2, 3)),
                new(RecipeRoles.Main, 40, new(76, 90), new(90, 93), new(4, 5)),
                new(RecipeRoles.Recovery, 5, new(40, 55), new(70, 80), new(2, 2)),
                new(RecipeRoles.Cooldown, 10, new(40, 55), new(70, 80), new(2, 2)),
            ]),

        new("R05", "Sweet spot", "Strong and steady", "Forte e costante",
            "Long efforts just below your limit.",
            "Sforzi lunghi appena sotto il limite.",
            60, [TrainingRecipeGoals.Fitter, TrainingRecipeGoals.Faster, TrainingRecipeGoals.Event],
            [
                new(RecipeRoles.Warmup, 15, new(55, 70), new(80, 88), new(3, 3)),
                new(RecipeRoles.Main, 40, new(88, 94), new(91, 97), new(5, 6)),
                new(RecipeRoles.Recovery, 5, new(40, 55), new(70, 80), new(2, 2)),
                new(RecipeRoles.Cooldown, 10, new(40, 55), new(70, 80), new(2, 2)),
            ]),

        new("R06", "Threshold", "At your limit", "Al limite",
            "Efforts at the pace you could hold for about an hour.",
            "Sforzi al ritmo che riesci a tenere per circa un'ora.",
            50, [TrainingRecipeGoals.Faster, TrainingRecipeGoals.Event],
            [
                new(RecipeRoles.Warmup, 15, new(65, 80), new(85, 92), new(4, 4)),
                new(RecipeRoles.Main, 30, new(95, 105), new(94, 102), new(6, 7)),
                new(RecipeRoles.Recovery, 10, new(40, 55), new(70, 80), new(2, 2)),
                new(RecipeRoles.Cooldown, 10, new(40, 55), new(70, 80), new(2, 2)),
            ]),

        new("R07", "Climbing repeats", "Hill repeats", "Ripetute in salita",
            "The same climb, several times, strong.",
            "La stessa salita, più volte, deciso.",
            70, [TrainingRecipeGoals.Faster],
            [
                new(RecipeRoles.Warmup, 15, new(65, 80), new(85, 92), new(4, 4)),
                new(RecipeRoles.Main, 25, new(95, 105), new(94, 102), new(6, 7)),
                new(RecipeRoles.Recovery, 20, new(40, 55), new(70, 80), new(2, 2)),
                new(RecipeRoles.Cooldown, 10, new(40, 55), new(70, 80), new(2, 2)),
            ]),

        new("R08", "VO2max 4–5 min", "Hard efforts", "Sforzi duri",
            "4–5 minutes very hard, with full recovery.",
            "4–5 minuti molto duri, con recupero completo.",
            55, [TrainingRecipeGoals.Fitter, TrainingRecipeGoals.Faster],
            [
                new(RecipeRoles.Warmup, 20, new(60, 80), new(80, 90), new(3, 4)),
                new(RecipeRoles.Main, 20, new(106, 120), new(103, 115), new(8, 9), EffortSeconds: 300),
                new(RecipeRoles.Recovery, 20, new(40, 55), new(70, 80), new(2, 2), EffortSeconds: 300),
                new(RecipeRoles.Cooldown, 10, new(40, 55), new(70, 80), new(2, 2)),
            ]),

        new("R09", "30/15", "On and off", "Acceso e spento",
            "30 seconds hard, 15 easy, over and over.",
            "30 secondi duri, 15 facili, di nuovo e di nuovo.",
            50, [TrainingRecipeGoals.Fitter, TrainingRecipeGoals.Faster],
            [
                new(RecipeRoles.Warmup, 20, new(60, 80), new(80, 90), new(3, 4)),
                new(RecipeRoles.Main, 10, new(115, 125), new(103, 115), new(8, 9), EffortSeconds: 30),
                new(RecipeRoles.Recovery, 10, new(40, 55), new(70, 80), new(2, 2), EffortSeconds: 15),
                new(RecipeRoles.Cooldown, 10, new(40, 55), new(70, 80), new(2, 2)),
            ]),

        new("R10", "Anaerobic capacity", "All-out bursts", "Scatti al massimo",
            "Short, everything you have, long rest.",
            "Corti, tutto quello che hai, riposo lungo.",
            45, [TrainingRecipeGoals.Faster, TrainingRecipeGoals.Event],
            [
                new(RecipeRoles.Warmup, 20, new(60, 80), new(80, 90), new(3, 4)),
                new(RecipeRoles.Main, 4, new(120, 130), null, new(9, 9), EffortSeconds: 60),
                new(RecipeRoles.Recovery, 12, new(40, 55), new(70, 80), new(2, 2)),
                new(RecipeRoles.Cooldown, 10, new(40, 55), new(70, 80), new(2, 2)),
            ]),

        new("R12", "Cadence", "Quick legs", "Gambe agili",
            "Easy pace, fast pedalling.",
            "Ritmo facile, pedalata veloce.",
            45, EveryGoal,
            [
                new(RecipeRoles.Main, 60, new(56, 75), new(81, 89), new(3, 4)),
            ]),

        new("R14", "Easy start", "First rides", "Primi giri",
            "Short and easy, to build the habit.",
            "Corto e facile, per prendere l'abitudine.",
            30, [TrainingRecipeGoals.Aerobic, TrainingRecipeGoals.Fitter],
            [
                new(RecipeRoles.Main, 30, null, null, new(3, 4)),
            ]),

        new("R15", "Steady build", "A little faster", "Un po' più veloce",
            "Mostly easy, with two short steady stretches.",
            "Per lo più facile, con due brevi tratti costanti.",
            45, [TrainingRecipeGoals.Aerobic, TrainingRecipeGoals.Fitter],
            [
                new(RecipeRoles.Warmup, 10, null, null, new(2, 3)),
                new(RecipeRoles.Main, 20, null, null, new(4, 5)),
                new(RecipeRoles.Recovery, 5, null, null, new(2, 2)),
                new(RecipeRoles.Cooldown, 10, null, null, new(2, 3)),
            ]),

        new("R16", "Long and easy (base)", "Longer, still easy", "Più lungo, sempre facile",
            "A bit longer each week, never hard.",
            "Un po' più lungo ogni settimana, mai duro.",
            60, [TrainingRecipeGoals.Aerobic],
            [
                new(RecipeRoles.Main, 75, null, null, new(3, 4)),
            ]),

        new("R17", "Keep-it", "Keep it going", "Mantieni il ritmo",
            "One short strong ride to keep what you've built.",
            "Un giro corto e forte per tenere quello che hai costruito.",
            45, [TrainingRecipeGoals.Keep],
            [
                // Below the 88 % sweet-spot floor on purpose: decisions confine the quality sessions to R05–R10, so the
                // short strong ride of a "keep fitness" week is tempo at the top of P4's Z3.
                new(RecipeRoles.Warmup, 10, new(60, 75), new(80, 88), new(3, 3)),
                new(RecipeRoles.Main, 25, new(84, 88), new(90, 94), new(5, 5)),
                new(RecipeRoles.Cooldown, 10, new(40, 55), new(70, 80), new(2, 2)),
            ]),
    ];

    /// <summary>The recipe with that code. The codes are fixed by decisions and every one of them exists.</summary>
    public static Recipe ByCode(string code) =>
        All.FirstOrDefault(r => r.Code == code)
        ?? throw new ArgumentOutOfRangeException(nameof(code), code, "Not a session recipe.");

    /// <summary>The recipes a goal draws on.</summary>
    public static Recipe[] ForGoal(string goal) => [.. All.Where(r => r.Goals.Contains(goal))];

    /// <summary>The quality recipes: the ones whose main set reaches the sweet-spot floor.</summary>
    public static Recipe[] Quality => [.. All.Where(r => r.IsQuality)];
}
