using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Features.Bikes;

/// <summary>
/// Tells members when a maintenance reminder becomes nearly due and when it becomes due, once each per cycle. What was
/// already told is kept on the reminder (<see cref="MaintenanceReminder.NotifiedStatus"/>) and cleared when the job is
/// marked done. A bike that is archived says nothing, and a bike nobody rides cannot reach a new distance or hours
/// level, so only months keep moving it, as they should.
/// </summary>
public static class MaintenanceNotifications
{
    /// <summary>After an edit: a reminder that fell back below a level it was told about may tell about it again.</summary>
    public static void Rearm(MaintenanceReminder reminder, string status)
    {
        if (status == "ok") reminder.NotifiedStatus = null;
        else if (status == "soon" && reminder.NotifiedStatus == "due") reminder.NotifiedStatus = "soon";
    }

    /// <summary>
    /// Checks the reminders on these bikes (all of the member's bikes when none are named) and adds the notifications that
    /// are new. Saves them with the change to the reminders that records them.
    /// </summary>
    public static async Task CheckAsync(VelomineDbContext db, TimeProvider time, Guid userId, IReadOnlyCollection<Guid>? bikeIds, CancellationToken ct)
    {
        var bikes = await db.Bikes.AsNoTracking()
            .Where(b => b.UserId == userId && b.IsActive && (bikeIds == null || bikeIds.Contains(b.Id)))
            .Select(b => new { b.Id, b.Name })
            .ToListAsync(ct);
        if (bikes.Count == 0) return;

        var ids = bikes.Select(b => b.Id).ToList();
        var reminders = await db.MaintenanceReminders
            .Where(r => ids.Contains(r.BikeId) && !r.IsPaused && r.NotifiedStatus != "due")
            .ToListAsync(ct);
        if (reminders.Count == 0) return;

        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        foreach (var group in reminders.GroupBy(r => r.BikeId))
        {
            var bike = bikes.First(b => b.Id == group.Key);
            var rides = await BikeQueries.RideUsesAsync(db, bike.Id, clock, ct);
            foreach (var reminder in group)
            {
                var status = MaintenanceProgress.Compute(reminder, rides, clock.Today).Status;
                string? type = status switch
                {
                    "due" => NotificationTypes.ReminderDue,
                    "soon" when reminder.NotifiedStatus is null => NotificationTypes.ReminderSoon,
                    _ => null,
                };
                if (type is null) continue;

                reminder.NotifiedStatus = status;
                Notify.Add(db, time, userId, type, $"{reminder.Name} on {bike.Name}", bikeId: bike.Id);
            }
        }

        await db.SaveChangesAsync(ct);
    }
}

/// <summary>
/// Looks at every member's reminders every hour, so a job that falls due by months alone is noticed without a ride. Rides
/// trigger the same check straight away (see <see cref="Notify.WornPartsAsync"/>). A missed run is caught up at the next.
/// </summary>
public sealed class MaintenanceReminderService(IServiceScopeFactory scopes, ILogger<MaintenanceReminderService> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(1);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);
        do
        {
            try
            {
                await RunOnceAsync(stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                logger.LogError(ex, "Checking maintenance reminders failed unexpectedly.");
            }
        }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }

    /// <summary>One sweep over the members who have a reminder that has not yet said it is due.</summary>
    public async Task RunOnceAsync(CancellationToken ct)
    {
        await using var scope = scopes.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var time = scope.ServiceProvider.GetRequiredService<TimeProvider>();

        var owners = await db.MaintenanceReminders.AsNoTracking()
            .Where(r => !r.IsPaused && r.NotifiedStatus != "due")
            .Join(db.Bikes.Where(b => b.IsActive), r => r.BikeId, b => b.Id, (r, b) => b.UserId)
            .Distinct()
            .ToListAsync(ct);

        foreach (var userId in owners)
            await CheckAsync(db, time, userId, ct);
    }

    private static Task CheckAsync(VelomineDbContext db, TimeProvider time, Guid userId, CancellationToken ct) =>
        MaintenanceNotifications.CheckAsync(db, time, userId, null, ct);
}
