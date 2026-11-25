using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Features.Training;

/// <summary>
/// Turning auto training off: today's and later sessions go, the ones already ridden stay as history and in the export,
/// and the setup stays so turning it on again is pre-filled.
/// </summary>
public sealed class TurnOffTrainingPlan(VelomineDbContext db, TimeProvider time)
    : EndpointWithoutRequest<TrainingPlanResponse>
{
    public override void Configure()
    {
        Delete("training/plan");
        Description(d => d.Produces<TrainingPlanResponse>(200).Produces(404).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var plan = await db.TrainingPlans.FirstOrDefaultAsync(p => p.UserId == userId, ct);
        if (plan is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var user = await db.Users.AsNoTracking().FirstAsync(u => u.Id == userId, ct);
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var today = await db.TrainingSessions
            .Where(s => s.UserId == userId && s.LocalDate >= clock.Today)
            .ToListAsync(ct);
        db.TrainingSessions.RemoveRange(today);
        // A question about a session that is going cannot be answered any more, so it goes too. So does one on a past
        // session, which stays: with the week gone there is nothing to answer it against, and no week to read.
        await db.TrainingSessions
            .Where(s => s.UserId == userId && s.QuestionRideId != null)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.QuestionRideId, (Guid?)null), ct);
        db.Notifications.RemoveRange(db.Notifications.Where(n =>
            n.UserId == userId && n.Type == NotificationTypes.TrainingSessionQuestion));
        plan.IsOn = false;
        // Turned on again, the sweep plans the week afresh rather than leaving today as it was left.
        plan.LastPlannedFor = null;
        plan.UpdatedAt = time.GetUtcNow();
        await db.SaveChangesAsync(ct);

        await Send.OkAsync(await TrainingPlanView.OfAsync(db, user, clock, time, ct), ct);
    }
}
