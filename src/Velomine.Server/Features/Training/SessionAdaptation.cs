using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Notifications.Email;
using Velomine.Server.Features.Wellbeing;

namespace Velomine.Server.Features.Training;

/// <summary>One day a session can be moved to, as the session page's sheet reads it: allowed, or why not.</summary>
public sealed record MoveDay(DateOnly LocalDate, bool Allowed, string? Reason);

/// <summary>Why a session cannot go on a day, as the API spells it. The app writes the sentence.</summary>
public static class MoveRefusals
{
    /// <summary>That day already carries a session, and one day holds one.</summary>
    public const string HasSession = "has_session";

    /// <summary>A hard day never sits the day before or after another hard day (W1).</summary>
    public const string NextToHard = "next_to_hard";

    /// <summary>A hard day never sits the day before or after the long ride (W1).</summary>
    public const string NextToLongRide = "next_to_long_ride";

    /// <summary>The week would carry a fourth loaded day (W1).</summary>
    public const string TooManyLoadedDays = "too_many_loaded_days";

    public static readonly string[] All = [HasSession, NextToHard, NextToLongRide, TooManyLoadedDays];
}

/// <summary>
/// The subject of a training notification, which is the fields the app and the email word the sentence from, joined by
/// a bar: today's session carries its name; a session made easy its reason and the day the hard work went to; a moved or
/// skipped one its name and its day. The subject is what an email falls back on when the session has gone, so it always
/// holds something true.
/// </summary>
public static class TrainingNoticeSubject
{
    public static string Today(string name) => name;

    public static string Easy(string reason, DateOnly? movedTo) =>
        movedTo is { } day ? $"{reason}|{day:yyyy-MM-dd}" : reason;

    public static string Moved(string name, DateOnly date) => $"{name}|{date:yyyy-MM-dd}";

    public static string Skipped(string name, DateOnly date) => $"{name}|{date:yyyy-MM-dd}";

    /// <summary>One field of a subject, or null when the subject does not have it.</summary>
    public static string? Field(string subject, int index)
    {
        var parts = subject.Split('|');
        return index < parts.Length && parts[index].Length > 0 ? parts[index] : null;
    }
}

/// <summary>
/// A plan that adapts to the day: a check-in, the readiness it makes, or a form that has been low makes today's hard
/// session an endurance one, moving the hard work to a later free day when the week can hold it, and the rider can
/// make, move or skip a session by hand. The rules are pure functions over the week's sessions; the appliers below
/// read the database, change the sessions and write the notification, all in the caller's one save.
/// See `docs/training-models.md`, *W6 — Making today easy*.
/// </summary>
public static class SessionAdaptation
{
    /// <summary>
    /// The endurance session a hard day becomes: R02, P4's zone 2 at feel 3–4, scaled to the same minutes — the same
    /// length, never longer (`docs/training-models.md`, W6).
    /// </summary>
    public const string EasyRecipe = "R02";

    /// <summary>A week keeps three loaded days at most (W1).</summary>
    public const int LoadedDays = 3;

    /// <summary>L2's form at F2's floor: below this the night makes the next hard day easy.</summary>
    public const double FormFloor = -30;

    /// <summary>The sweeper announces the day at this hour in the rider's own time, on session days only.</summary>
    public static readonly TimeOnly ReminderTime = new(7, 0);

    /// <summary>The long ride the rider's week is built around: R03, or R16 in the gentle base block.</summary>
    public static bool IsLongRide(string recipe) => recipe is "R03" or "R16";

    /// <summary>A hard day: a quality session, or the long ride, which is what "make today easy" replaces (W6).</summary>
    public static bool IsReplacedByEasy(string recipe) => Recipes.ByCode(recipe).IsQuality || IsLongRide(recipe);

    /// <summary>
    /// The worst answer of a check-in, as the reason the rider reads: sleep 1, fatigue 5 or soreness 5 in that order.
    /// Null when the answers say nothing about making today easy. The answers themselves stay the owner's: only this
    /// code leaves, never the numbers.
    /// </summary>
    public static string? CheckInReason(int? sleep, int fatigue, int soreness)
    {
        if (sleep == 1) return TrainingEasyReasons.SleptPoorly;
        if (fatigue == 5) return TrainingEasyReasons.Tired;
        if (soreness == 5) return TrainingEasyReasons.Sore;
        return null;
    }

    /// <summary>A loaded day is a hard day, or the long ride when it carries more than W1's share of the week's load.</summary>
    public static bool IsLoaded(TrainingSession session, bool longRideLoaded) =>
        Recipes.ByCode(session.Recipe).IsQuality || (IsLongRide(session.Recipe) && longRideLoaded);

    /// <summary>Whether the week's long ride carries more than its share of the week's planned load (W1).</summary>
    public static bool LongRideLoaded(IReadOnlyCollection<TrainingSession> week)
    {
        var total = week.Sum(s => SessionPlan.PlannedScore(s.Recipe, s.Minutes));
        var longRide = week.FirstOrDefault(s => IsLongRide(s.Recipe));
        return longRide is not null && total > 0
            && SessionPlan.PlannedScore(longRide.Recipe, longRide.Minutes) / total > WeekPlanner.LoadedLongRideShare;
    }

    /// <summary>
    /// Why <paramref name="moving"/> cannot go on <paramref name="date"/>, or null when it can. The day has to be free,
    /// and a hard day is never next to another hard day or next to the long ride, and never makes a fourth loaded day
    /// (W1). A week's own day is checked against the sessions around it, which may be in the next week.
    /// </summary>
    public static string? Refusal(IReadOnlyList<TrainingSession> week, TrainingSession moving, DateOnly date)
    {
        if (week.Any(s => s.Id != moving.Id && s.LocalDate == date)) return MoveRefusals.HasSession;

        var hard = Recipes.ByCode(moving.Recipe).IsQuality;
        if (hard)
        {
            bool Beside(Func<string, bool> matches) => week.Any(s => s.Id != moving.Id
                && Math.Abs(s.LocalDate.DayNumber - date.DayNumber) == 1 && matches(s.Recipe));
            if (Beside(recipe => Recipes.ByCode(recipe).IsQuality)) return MoveRefusals.NextToHard;
            if (Beside(IsLongRide)) return MoveRefusals.NextToLongRide;
        }

        var longRideLoaded = LongRideLoaded(week);
        var loadedAfter = week.Count(s => s.Id != moving.Id && IsLoaded(s, longRideLoaded))
            + (IsLoaded(moving, longRideLoaded) ? 1 : 0);
        if (loadedAfter > LoadedDays) return MoveRefusals.TooManyLoadedDays;
        return null;
    }

    /// <summary>
    /// The days a session can move to, as the session page's sheet reads them: every day left this week, the ride's
    /// free days or not, with the reason it cannot take the session when it cannot.
    /// </summary>
    public static MoveDay[] Days(
        IReadOnlyList<TrainingSession> week, TrainingSession moving, MemberClock clock)
    {
        var today = clock.Today;
        var end = Periods.StartOf(moving.LocalDate, Periods.Week, clock.FirstDayOfWeek).AddDays(6);
        var days = new List<MoveDay>();
        for (var date = today > moving.LocalDate ? today : moving.LocalDate; date <= end; date = date.AddDays(1))
        {
            if (date == moving.LocalDate) continue;
            var refusal = Refusal(week, moving, date);
            days.Add(new MoveDay(date, refusal is null, refusal));
        }
        return [.. days];
    }

    /// <summary>
    /// The later free day the replaced hard session moves to: the first that keeps the hard days apart and the week at
    /// three loaded days or fewer. Null when the week cannot hold it, and then the hard session is dropped rather than
    /// piled onto another day (W6).
    /// </summary>
    public static DateOnly? FreeDayFor(
        IReadOnlyList<TrainingSession> week, TrainingSession moving, int[] freeDays, MemberClock clock)
    {
        var end = Periods.StartOf(moving.LocalDate, Periods.Week, clock.FirstDayOfWeek).AddDays(6);
        for (var date = moving.LocalDate.AddDays(1); date <= end; date = date.AddDays(1))
        {
            if (!freeDays.Contains((int)date.DayOfWeek)) continue;
            if (Refusal(week, moving, date) is null) return date;
        }
        return null;
    }

    /// <summary>
    /// A session made easy now: the endurance replacement in its place, the reason kept for the line the rider reads,
    /// and — when the week can hold it — the hard session moved to a later free day, or dropped when it cannot. The
    /// change and its notification land in the caller's save.
    /// </summary>
    public static async Task<bool> MakeEasyAsync(
        VelomineDbContext db,
        User user,
        TrainingPlan plan,
        MemberClock clock,
        TimeProvider time,
        TrainingSession session,
        string reason,
        bool moveTheHardSession,
        CancellationToken ct)
    {
        if (!IsReplacedByEasy(session.Recipe)) return false;
        if (session.State != TrainingSessionStates.Planned) return false;

        var week = await WeekAsync(db, user.Id, session.LocalDate, clock, ct);
        DateOnly? movedTo = null;
        if (moveTheHardSession && FreeDayFor(week, session, plan.Days, clock) is { } date)
        {
            movedTo = date;
            db.TrainingSessions.Add(new TrainingSession
            {
                Id = Guid.CreateVersion7(),
                UserId = user.Id,
                LocalDate = date,
                Recipe = session.Recipe,
                Minutes = session.Minutes,
                BlockPercents = session.BlockPercents,
                State = TrainingSessionStates.Planned,
                CreatedAt = time.GetUtcNow(),
            });
        }

        session.OriginalRecipe = session.Recipe;
        session.EasyReason = reason;
        session.EasyMovedTo = movedTo;
        session.Recipe = EasyRecipe;
        session.BlockPercents = SessionPlan.Percents(SessionPlan.For(Recipes.ByCode(EasyRecipe), session.Minutes).Blocks);
        session.State = TrainingSessionStates.Easy;
        Notify.Add(db, time, user.Id, NotificationTypes.TrainingEasy,
            TrainingNoticeSubject.Easy(reason, movedTo), trainingSessionId: session.Id);
        return true;
    }

    /// <summary>
    /// "Back to the plan": the hard session comes back on today's day, and the copy the change moved to another day
    /// goes with it, as long as nobody has ridden it. False when there is nothing to undo.
    /// </summary>
    public static async Task<bool> BackToPlanAsync(
        VelomineDbContext db, MemberClock clock, TrainingSession session, CancellationToken ct)
    {
        if (session.State != TrainingSessionStates.Easy || session.EasyReason is null || session.OriginalRecipe is null)
            return false;

        if (session.EasyMovedTo is { } movedTo)
        {
            var copy = await db.TrainingSessions.FirstOrDefaultAsync(s => s.UserId == session.UserId
                && s.LocalDate == movedTo && s.Recipe == session.OriginalRecipe, ct);
            // The moved hard day is already ridden or answered: undoing today would put two hard days in the week.
            if (copy is not null && (copy.RideId is not null || copy.QuestionRideId is not null
                || copy.State != TrainingSessionStates.Planned)) return false;
            if (copy is not null) db.TrainingSessions.Remove(copy);
        }

        session.Recipe = session.OriginalRecipe;
        session.BlockPercents = SessionPlan.Percents(SessionPlan.For(Recipes.ByCode(session.Recipe), session.Minutes).Blocks);
        session.State = TrainingSessionStates.Planned;
        session.OriginalRecipe = null;
        session.EasyReason = null;
        session.EasyMovedTo = null;
        return true;
    }

    /// <summary>
    /// A moved session keeps its recipe and takes the new day; the reason it left is the notification's subject, and
    /// the rider reads it in the week. It is never written again at night: the sweep leaves a session the rider moved.
    /// </summary>
    public static void Move(User user, TimeProvider time, VelomineDbContext db, TrainingSession session, DateOnly date)
    {
        session.LocalDate = date;
        session.State = TrainingSessionStates.Moved;
        Notify.Add(db, time, user.Id, NotificationTypes.TrainingMoved,
            TrainingNoticeSubject.Moved(SessionName(user, session.Recipe), date), trainingSessionId: session.Id);
    }

    /// <summary>
    /// The check-in that was just saved changes today at once: its worst answer, or a readiness in F2's rest band,
    /// makes today's hard session an endurance one and moves the hard work to a later free day when it fits.
    /// </summary>
    public static async Task AfterCheckInAsync(
        VelomineDbContext db, User user, TrainingPlan plan, MemberClock clock, TimeProvider time,
        int? sleep, int fatigue, int soreness, CancellationToken ct)
    {
        var reason = CheckInReason(sleep, fatigue, soreness);
        if (reason is null)
        {
            var readiness = await Readiness.ForAsync(db, user.Id, clock, time, clock.Today, ct);
            if (readiness.Band != Readiness.Rest) return;
            reason = TrainingEasyReasons.FormLow;
        }

        var session = await TodayAsync(db, user.Id, clock, ct);
        if (session is null) return;
        if (await MakeEasyAsync(db, user, plan, clock, time, session, reason, moveTheHardSession: true, ct))
            await db.SaveChangesAsync(ct);
    }

    /// <summary>
    /// The night's own rule: without a check-in (or without the wellbeing terms accepted) a form below F2's floor makes
    /// the next hard day easy, moving it when the week can hold it (W6).
    /// </summary>
    public static async Task NightAsync(
        VelomineDbContext db, User user, TrainingPlan plan, MemberClock clock, TimeProvider time, CancellationToken ct)
    {
        var consented = await WellbeingRules.HasConsentAsync(db, user.Id, ct);
        if (consented && await db.DailyCheckIns.AsNoTracking()
                .AnyAsync(c => c.UserId == user.Id && c.LocalDate == clock.Today, ct)) return;

        var training = await TrainingRange.LoadAsync(db, user.Id, clock, time, 1, ct);
        if (training.Days[^1].Form >= FormFloor) return;

        var next = await db.TrainingSessions
            .Where(s => s.UserId == user.Id && s.LocalDate >= clock.Today
                && s.LocalDate <= clock.Today.AddDays(7) && s.State == TrainingSessionStates.Planned)
            .OrderBy(s => s.LocalDate).ThenBy(s => s.Id)
            .ToListAsync(ct);
        if (next.FirstOrDefault(s => Recipes.ByCode(s.Recipe).IsQuality) is not { } hard) return;
        if (await MakeEasyAsync(db, user, plan, clock, time, hard, TrainingEasyReasons.FormLow, true, ct))
            await db.SaveChangesAsync(ct);
    }

    /// <summary>
    /// The 07:00 reminder on a session day, once a day in the rider's own time: the day's session as an in-app
    /// notification, which the email service sends too when the rider's training emails are on.
    /// </summary>
    public static async Task RemindAsync(
        VelomineDbContext db, User user, TrainingPlan plan, MemberClock clock, TimeProvider time, CancellationToken ct)
    {
        if (plan.RemindedFor == clock.Today || clock.TimeOf(time) < ReminderTime) return;
        var session = await TodayAsync(db, user.Id, clock, ct);
        // A day already ridden, skipped or missed has nothing to announce; a day made easy is still ridden.
        if (session is null || !(SessionMatch.IsTickable(session.State) || session.State == TrainingSessionStates.Easy))
            return;

        Notify.Add(db, time, user.Id, NotificationTypes.TrainingToday, TrainingNoticeSubject.Today(SessionName(user, session.Recipe)),
            trainingSessionId: session.Id);
        plan.RemindedFor = clock.Today;
        await db.SaveChangesAsync(ct);
    }

    /// <summary>Today's session, tracked, or null on a rest day.</summary>
    private static Task<TrainingSession?> TodayAsync(
        VelomineDbContext db, Guid userId, MemberClock clock, CancellationToken ct) =>
        db.TrainingSessions.FirstOrDefaultAsync(s => s.UserId == userId && s.LocalDate == clock.Today, ct);

    /// <summary>
    /// The sessions a move or a replacement is judged against: the session's week, and the days either side of it,
    /// because the long ride of the week before or the hard day of the next one sit next to this week's first and last.
    /// </summary>
    private static async Task<List<TrainingSession>> WeekAsync(
        VelomineDbContext db, Guid userId, DateOnly date, MemberClock clock, CancellationToken ct)
    {
        var start = Periods.StartOf(date, Periods.Week, clock.FirstDayOfWeek);
        var from = start.AddDays(-1);
        var to = start.AddDays(7);
        return await db.TrainingSessions
            .Where(s => s.UserId == userId && s.LocalDate >= from && s.LocalDate <= to)
            .OrderBy(s => s.LocalDate).ThenBy(s => s.Id)
            .ToListAsync(ct);
    }

    /// <summary>A session's plain name in the rider's own language, as a notification's subject keeps it.</summary>
    private static string SessionName(User user, string recipe)
    {
        var chosen = Recipes.ByCode(recipe);
        return EmailLanguage.Resolve(user.Language) == "it" ? chosen.ItalianName : chosen.EnglishName;
    }
}
