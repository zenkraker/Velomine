using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;
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
/// Thursday strong and steady?". It runs only on a ride's first read, from the ingestion service after the ride is
/// saved: a re-read and a duplicate never tick, re-tick or ask again, and the second ride of a day is compared with the
/// ride that ticked the session, so the closest one wins.
/// </summary>
public static class SessionMatch
{
    /// <summary>How close to the plan a ride of another day must be, in duration and in effort, to be asked about.</summary>
    public const double AskTolerance = 0.25;

    /// <summary>What the matching does with one ride: the session it ticks, or the open session it asks about.</summary>
    public readonly record struct Match(TrainingSession Session, bool Asks);

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
        // duration is that session, then the one with the higher effort score.
        var open = onDay.FirstOrDefault(s => IsOpen(s.State) || (s.State == TrainingSessionStates.Done && s.RideId is not null));
        if (open is not null)
        {
            // Already this session's: nothing to do, and a re-read never writes it again.
            if (open.State == TrainingSessionStates.Done && open.RideId == ride.Id) return null;
            // A ride the session holds that is not in the day's list is one the caller could not read: keep it.
            if (open.State == TrainingSessionStates.Done && candidates.All(r => r.Id != open.RideId)) return null;
            return Closest(open, candidates) == ride.Id ? new(open, Asks: false) : null;
        }

        // A day whose session was skipped or made easy is not planned again: no tick, and no question either, because
        // the session asked about would land on a day that already has one.
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
    /// Matches the rides one ingestion has just saved, in one save of their own. A failure here is the caller's to log
    /// and swallow: a session is never worth a ride that did not become ready.
    /// </summary>
    public static async Task AddAsync(
        VelomineDbContext db, TimeProvider time, Guid userId, IReadOnlyList<Guid> rideIds, CancellationToken ct)
    {
        if (rideIds.Count == 0) return;
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var fresh = await db.Rides.AsNoTracking()
            .Where(r => r.UserId == userId && rideIds.Contains(r.Id) && r.Status == RideStatus.Ready && r.StartTime != null)
            .ToListAsync(ct);
        if (fresh.Count == 0) return;

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
        var known = stored.ToDictionary(r => r.Id, r => Shape(clock, r));
        foreach (var ride in fresh) known.TryAdd(ride.Id, Shape(clock, ride));
        var byDay = known.Values.ToLookup(r => r.LocalDate);

        var changed = false;
        foreach (var ride in fresh.OrderBy(r => r.StartTime).ThenBy(r => r.Id).Select(r => known[r.Id]))
        {
            if (Decide(sessions, [.. byDay[ride.LocalDate]], ride) is not { } match) continue;
            changed = true;
            if (match.Asks)
            {
                match.Session.QuestionRideId = ride.Id;
                Notify.Add(db, time, userId, NotificationTypes.TrainingSessionQuestion,
                    Recipes.ByCode(match.Session.Recipe).EnglishName, rideId: ride.Id);
                continue;
            }

            match.Session.RideId = ride.Id;
            match.Session.State = TrainingSessionStates.Done;
        }

        if (changed) await db.SaveChangesAsync(ct);
    }

    /// <summary>
    /// The session set back to open after its ride went away or the rider said it was not this session: missed when
    /// its day has passed. Nothing about the ride is kept, so the ride is never that session again.
    /// </summary>
    public static void Unlink(TrainingSession session, MemberClock clock)
    {
        session.RideId = null;
        session.QuestionRideId = null;
        session.State = session.LocalDate < clock.Today ? TrainingSessionStates.Missed : TrainingSessionStates.Planned;
    }

    /// <summary>A session still waiting for a ride: planned, or missed because its day went by open.</summary>
    public static bool IsOpen(string state) => state is TrainingSessionStates.Planned or TrainingSessionStates.Missed;

    private static MatchRide Shape(MemberClock clock, Ride ride)
    {
        var (effort, _) = TrainingLoad.Effort(ride.Tss, ride.HrTss, null, ride.EstimatedTss);
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
