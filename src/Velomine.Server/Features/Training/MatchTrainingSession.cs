using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Training;

public sealed class MatchTrainingSessionRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    /// <summary>The ride the question is about.</summary>
    public required Guid RideId { get; set; }

    /// <summary>"yes": this ride was that session. "no": it was not, and it never will be.</summary>
    public required string Answer { get; set; }
}

/// <summary>The two answers to "Was this your Thursday strong and steady?".</summary>
public static class SessionMatchAnswers
{
    public const string Yes = "yes";
    public const string No = "no";

    public static readonly string[] All = [Yes, No];
}

/// <summary>
/// Answers the question a ride asked, and takes back a ride the rider says was not the session:
/// <list type="bullet">
/// <item>"yes" ticks the open session with that ride and moves it to the ride's own day.</item>
/// <item>"no" sets the session back to open — missed when its day has passed — and the ride is never matched again,
/// because matching only ever runs on a ride's first read, which has happened.</item>
/// </list>
/// The question's notification goes in the same save, so the inbox never keeps a question that was answered.
/// </summary>
public sealed class MatchTrainingSession(VelomineDbContext db, TimeProvider time) : Endpoint<MatchTrainingSessionRequest>
{
    public override void Configure()
    {
        Post("training/sessions/{id}/match");
        Description(d => d.Accepts<MatchTrainingSessionRequest>("application/json")
            .Produces(204).ProducesProblem(400).ProducesProblem(401).ProducesProblem(404).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(MatchTrainingSessionRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var session = await db.TrainingSessions.FirstOrDefaultAsync(s => s.Id == req.Id && s.UserId == userId, ct);
        var ride = await db.Rides.AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == req.RideId && r.UserId == userId && r.Status == RideStatus.Ready, ct);
        if (session is null || ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (req.Answer == SessionMatchAnswers.Yes)
        {
            var clock = await MemberClock.ForAsync(db, userId, time, ct);
            var date = ride.StartTime is { } start ? clock.LocalDateOf(start, ride.UtcOffsetMinutes) : session.LocalDate;
            if (!SessionMatch.IsOpen(session.State) || (session.QuestionRideId != ride.Id && session.RideId != ride.Id))
            {
                AddError(r => r.Answer, "That session is not waiting for this ride.");
                await Send.ErrorsAsync(409, ct);
                return;
            }

            // Moving it takes the ride's day, which is free because a day with a session is ticked, never asked about.
            if (await db.TrainingSessions.AnyAsync(s => s.UserId == userId && s.LocalDate == date && s.Id != session.Id, ct))
            {
                AddError(r => r.Answer, "That day already has a session.");
                await Send.ErrorsAsync(409, ct);
                return;
            }

            session.LocalDate = date;
            session.RideId = ride.Id;
            session.State = TrainingSessionStates.Done;
            session.QuestionRideId = null;
        }
        else if (session.RideId == ride.Id || session.QuestionRideId == ride.Id)
        {
            SessionMatch.Unlink(session, await MemberClock.ForAsync(db, userId, time, ct));
        }
        else
        {
            AddError(r => r.Answer, "That session is not this ride.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        db.Notifications.RemoveRange(db.Notifications.Where(n =>
            n.UserId == userId && n.RideId == ride.Id && n.Type == NotificationTypes.TrainingSessionQuestion));
        await db.SaveChangesAsync(ct);
        await Send.NoContentAsync(ct);
    }
}

public sealed class MatchTrainingSessionValidator : Validator<MatchTrainingSessionRequest>
{
    public MatchTrainingSessionValidator()
    {
        RuleFor(x => x.Answer).Must(answer => SessionMatchAnswers.All.Contains(answer))
            .WithMessage("Answer yes or no.");
    }
}
