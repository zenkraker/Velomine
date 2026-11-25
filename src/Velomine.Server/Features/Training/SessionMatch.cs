using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Notifications.Email;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Training;

/// <summary>A ride as the session matching reads it: the day it counts on, its moving time and its effort score (L1).</summary>
public readonly record struct MatchRide(Guid Id, DateOnly LocalDate, double MovingS, double? Effort);

/// <summary>
/// A ride's link to a planned session, as the ride page shows it: the open session it is being asked about ("Was this
/// your Thursday strong and steady?") or the one it ticked. The rider's own: no other viewer of the ride gets it.
/// </summary>
public sealed record TrainingRideMatch(
    Guid SessionId,
    DateOnly LocalDate,
    string Recipe,
    string EnglishName,
    string ItalianName,
    string State)
{
    public static TrainingRideMatch Of(TrainingSession session)
    {
        var recipe = Recipes.ByCode(session.Recipe);
        return new(session.Id, session.LocalDate, recipe.Code, recipe.EnglishName, recipe.ItalianName, session.State);
    }
}

/// <summary>
/// A ride ticks the session of its own day, or asks about an open session the day before or after: "Was this your
/// Thursday strong and steady?". It runs only on a ride's first read, inside the ingestion's own save: a re-read and a
/// duplicate never tick, re-tick or ask again, and the second ride of a day is compared with the ride that ticked the
/// session, so the closest one wins. The session and the ride land together, so a ride is never ready without the tick
/// it earned.
/// </summary>
public static class SessionMatch
{
    /// <summary>How close to the plan a ride of another day must be, in duration and in effort, to be asked about.</summary>
    public const double AskTolerance = 0.25;

    /// <summary>What the matching does with one ride: the session it ticks, or the open session it asks about.</summary>
    public readonly record struct Match(TrainingSession Session, bool Asks);

    /// <summary>
    /// What one matching changed, as it was before, so a caller whose save loses a session — the nightly planning
    /// deletes and re-adds the sessions of today and later — can put it back and still save its ride.
    /// </summary>
    public sealed record Edits(
        IReadOnlyList<(TrainingSession Session, string State, Guid? RideId, Guid? QuestionRideId)> Before,
        IReadOnlyList<Notification> Added)
    {
        public void Restore(VelomineDbContext db)
        {
            foreach (var (session, state, rideId, question) in Before)
            {
                session.State = state;
                session.RideId = rideId;
                session.QuestionRideId = question;
            }
            db.Notifications.RemoveRange(Added);
        }
    }

    /// <summary>
    /// The session a first-read ride ticks or asks about, out of the sessions of the days around it and the member's
    /// ready rides of its own day: the closest by duration, then the higher effort score, then the earliest id. Null
    /// when the ride is not a session and is not close enough to one.
    /// </summary>
    public static Match? Decide(
        IReadOnlyList<TrainingSession> sessions,
        IReadOnlyList<MatchRide> dayRides,
        MatchRide ride)
    {
        var onDay = sessions.Where(s => s.LocalDate == ride.LocalDate).ToList();
        // The ride itself is always one of the day's candidates, whichever way the caller built the list.
        var candidates = dayRides.Where(r => r.Id != ride.Id).Append(ride).ToArray();
        // An open session of the day, or one this day's ride already ticked: with several rides the closest by
        // duration is that session, then the one with the higher effort score. A session made easy is still a session
        // the rider rides, so a ride of its day ticks it and it stays easy.
        var open = onDay.FirstOrDefault(s => IsTickable(s.State) || s.RideId is not null);
        if (open is not null)
        {
            // Already this session's: nothing to do, and a re-read never writes it again.
            if (open.RideId == ride.Id) return null;
            // A ride the session holds that is not in the day's list is one the caller could not read: keep it.
            if (open.RideId is not null && candidates.All(r => r.Id != open.RideId)) return null;
            return Closest(open, candidates) == ride.Id ? new(open, Asks: false) : null;
        }

        // A day whose session was skipped is not planned again: no tick, and no question either, because the session
        // asked about would land on a day that already has one.
        if (onDay.Count > 0) return null;

        var beside = sessions
            .Where(s => Math.Abs(s.LocalDate.DayNumber - ride.LocalDate.DayNumber) == 1
                && IsOpen(s.State) && s.QuestionRideId is null && Near(s, ride))
            .OrderBy(s => Math.Abs(PlannedSeconds(s) - ride.MovingS))
            .ThenBy(s => s.LocalDate)
            .FirstOrDefault();
        return beside is null ? null : new(beside, Asks: true);
    }

    /// <summary>
    /// Matches the rides one ingestion has just read. It changes the sessions in the caller's context and saves
    /// nothing: the ride and the session land in the caller's one save. Every read happens before the first change, so
    /// a failure here leaves the ride's save exactly as it would have been — the caller logs it and swallows it.
    /// </summary>
    public static async Task<Edits?> AddAsync(
        VelomineDbContext db, TimeProvider time, Guid userId, IReadOnlyList<Ride> rides, CancellationToken ct)
    {
        if (rides.Count == 0) return null;
        // Nothing ticks or asks while auto training is off. Turning it off keeps the past sessions, so an import of old
        // rides would otherwise write their history, and the ride page would offer a question the week cannot answer.
        var plan = await db.TrainingPlans.AsNoTracking().FirstOrDefaultAsync(p => p.UserId == userId && p.IsOn, ct);
        if (plan is null) return null;
        var user = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new { u.TimeZone, u.FirstDayOfWeek, u.Language })
            .FirstOrDefaultAsync(ct);
        var clock = MemberClock.For(user?.TimeZone, user?.FirstDayOfWeek ?? DayOfWeek.Monday, time);
        // A file the rider already said was not this session is never asked about again, whichever ride carries it:
        // deleting a ride brings its hidden duplicate back to be read as a new one.
        var declined = plan.DeclinedFileHashes.ToHashSet();
        var fresh = rides.Where(r => r.StartTime is not null && !declined.Contains(r.FileSha256)).ToList();
        if (fresh.Count == 0) return null;

        var days = fresh.Select(r => clock.LocalDateOf(r.StartTime!.Value, r.UtcOffsetMinutes)).ToHashSet();
        var from = days.Min().AddDays(-1);
        var to = days.Max().AddDays(1);

        var sessions = await db.TrainingSessions
            .Where(s => s.UserId == userId && s.LocalDate >= from && s.LocalDate <= to)
            .ToListAsync(ct);
        // The day's other rides are candidates too: a ride read a minute ago can be closer to the plan than this one.
        var stored = await db.Rides.AsNoTracking()
            .Where(r => r.UserId == userId && r.Status == RideStatus.Ready && r.StartTime != null
                && r.StartTime >= new DateTimeOffset(from.AddDays(-1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero)
                && r.StartTime < new DateTimeOffset(to.AddDays(2).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero))
            .ToListAsync(ct);
        stored.RemoveAll(r => declined.Contains(r.FileSha256));
        // The rider's own rating is part of the effort score (L1), and it can be given the moment the ride is read.
        var ids = stored.Select(r => r.Id).Concat(fresh.Select(r => r.Id)).ToList();
        var feels = (await db.RideFeels.AsNoTracking()
                .Where(f => ids.Contains(f.RideId))
                .Select(f => new { f.RideId, f.Rpe })
                .ToListAsync(ct))
            .ToDictionary(f => f.RideId, f => f.Rpe);
        var known = stored.ToDictionary(r => r.Id, r => Shape(clock, r, feels.GetValueOrDefault(r.Id)));
        foreach (var ride in fresh) known.TryAdd(ride.Id, Shape(clock, ride, feels.GetValueOrDefault(ride.Id)));
        var byDay = known.Values.ToLookup(r => r.LocalDate);

        List<(TrainingSession, string, Guid?, Guid?)> before = [];
        List<Notification> added = [];
        foreach (var ride in fresh.OrderBy(r => r.StartTime).ThenBy(r => r.Id).Select(r => known[r.Id]))
        {
            if (Decide(sessions, [.. byDay[ride.LocalDate]], ride) is not { } match) continue;
            // Snapshotted once per session, however many of this read's rides touch it.
            if (before.All(b => b.Item1 != match.Session))
                before.Add((match.Session, match.Session.State, match.Session.RideId, match.Session.QuestionRideId));

            if (match.Asks)
            {
                match.Session.QuestionRideId = ride.Id;
                // The subject is what the email says, so it is the name in the rider's own language.
                var recipe = Recipes.ByCode(match.Session.Recipe);
                var name = EmailLanguage.Resolve(user?.Language) == "it" ? recipe.ItalianName : recipe.EnglishName;
                var notification = Notify.Add(db, time, userId, NotificationTypes.TrainingSessionQuestion, name, rideId: ride.Id);
                if (notification is not null) added.Add(notification);
                continue;
            }

            match.Session.RideId = ride.Id;
            if (match.Session.State != TrainingSessionStates.Easy) match.Session.State = TrainingSessionStates.Done;
        }

        return before.Count == 0 ? null : new Edits(before, added);
    }

    /// <summary>
    /// The session set back to open after its ride went away or the rider said it was not this session: missed when
    /// its day has passed. Nothing about the ride is kept, so the ride is never that session again.
    /// </summary>
    public static void Unlink(TrainingSession session, MemberClock clock)
    {
        session.RideId = null;
        session.QuestionRideId = null;
        // A session made easy stays made easy; one still waiting goes back to open, missed once its day has passed.
        if (session.State != TrainingSessionStates.Easy)
            session.State = session.LocalDate < clock.Today ? TrainingSessionStates.Missed : TrainingSessionStates.Planned;
    }

    /// <summary>A session still waiting for a ride: planned, or missed because its day went by open.</summary>
    public static bool IsOpen(string state) => state is TrainingSessionStates.Planned or TrainingSessionStates.Missed;

    /// <summary>
    /// A session a ride of its own day ticks: one still waiting, or one made easy that day, which is the session the
    /// rider did — undone unless a ride is ticked against it (story 5), and counted as done by the week either way.
    /// </summary>
    public static bool IsTickable(string state) => IsOpen(state) || state == TrainingSessionStates.Easy;

    private static MatchRide Shape(MemberClock clock, Ride ride, int? rpe)
    {
        var (effort, _) = TrainingLoad.Effort(ride.Tss, ride.HrTss, TrainingLoad.FeelScore(ride.MovingS, rpe), ride.EstimatedTss);
        return new MatchRide(ride.Id, clock.LocalDateOf(ride.StartTime!.Value, ride.UtcOffsetMinutes), ride.MovingS ?? 0, effort);
    }

    private static Guid? Closest(TrainingSession session, IReadOnlyList<MatchRide> dayRides)
    {
        var planned = PlannedSeconds(session);
        return dayRides
            .OrderBy(r => Math.Abs(r.MovingS - planned))
            .ThenByDescending(r => r.Effort ?? double.MinValue)
            .ThenBy(r => r.Id)
            .Select(r => (Guid?)r.Id)
            .FirstOrDefault();
    }

    /// <summary>
    /// The ride of the day before or after is this session when it is within a quarter of the planned minutes and of
    /// the planned effort score. Both must exist: a ride with no effort score of its own cannot be compared.
    /// </summary>
    private static bool Near(TrainingSession session, MatchRide ride)
    {
        if (ride.Effort is not { } effort) return false;
        var plannedEffort = SessionPlan.PlannedScore(session.Recipe, session.Minutes);
        if (plannedEffort <= 0) return false;
        var plannedS = PlannedSeconds(session);
        return Math.Abs(ride.MovingS - plannedS) <= AskTolerance * plannedS
            && Math.Abs(effort - plannedEffort) <= AskTolerance * plannedEffort;
    }

    private static double PlannedSeconds(TrainingSession session) =>
        SessionPlan.PlannedMinutes(session.Recipe, session.Minutes) * 60;
}
