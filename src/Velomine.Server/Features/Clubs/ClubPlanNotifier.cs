using System.Globalization;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Notifications;

namespace Velomine.Server.Features.Clubs;

/// <summary>
/// Tells a club's owners when its plan is about to end (14 days before the last paid day) and when it has ended, once
/// each. Nothing is stored for this: the notifications already sent are the record, keyed by owner, type and the paid-until
/// day, so a missed run is caught up at the next one and extending the date earns a fresh pair of notices. Runs at startup,
/// then every hour. The email that accompanies a notification is sent by the notification email service as usual.
/// </summary>
public sealed class ClubPlanNotifier(
    IServiceScopeFactory scopes,
    TimeProvider time,
    ILogger<ClubPlanNotifier> logger) : BackgroundService
{
    public const int WarningDays = 14;

    private static readonly TimeSpan Interval = TimeSpan.FromHours(1);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);
        try
        {
            do
            {
                try
                {
                    await RunOnceAsync(stoppingToken);
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    logger.LogError(ex, "Checking club plans failed.");
                }
            }
            while (await timer.WaitForNextTickAsync(stoppingToken));
        }
        catch (OperationCanceledException)
        {
            // Stopping.
        }
    }

    /// <summary>One check: returns how many notifications were created.</summary>
    public async Task<int> RunOnceAsync(CancellationToken ct)
    {
        await using var scope = scopes.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
        var today = ClubPlan.Today(time);
        var horizon = today.AddDays(WarningDays);

        var due = await db.Clubs.AsNoTracking()
            .Where(c => c.PaidUntil != null && c.PaidUntil <= horizon)
            .Select(c => new { c.Id, PaidUntil = c.PaidUntil!.Value })
            .ToListAsync(ct);
        if (due.Count == 0) return 0;

        var clubIds = due.Select(c => c.Id).ToList();
        var owners = await db.ClubMemberships.AsNoTracking()
            .Where(m => clubIds.Contains(m.ClubId) && m.Role == ClubRoles.Owner)
            .Select(m => new { m.ClubId, m.UserId })
            .ToListAsync(ct);
        var ownerIds = owners.Select(o => o.UserId).Distinct().ToList();
        string[] types = [NotificationTypes.ClubPlanEnding, NotificationTypes.ClubPlanEnded];
        var sent = (await db.Notifications.AsNoTracking()
                .Where(n => ownerIds.Contains(n.UserId) && types.Contains(n.Type))
                .Select(n => new { n.UserId, n.Type, n.Subject })
                .ToListAsync(ct))
            .Select(n => (n.UserId, n.Type, n.Subject))
            .ToHashSet();

        var created = 0;
        foreach (var club in due)
        {
            var type = today > club.PaidUntil ? NotificationTypes.ClubPlanEnded : NotificationTypes.ClubPlanEnding;
            var subject = club.PaidUntil.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            foreach (var owner in owners.Where(o => o.ClubId == club.Id))
            {
                if (!sent.Add((owner.UserId, type, subject))) continue;
                Notify.Add(db, time, owner.UserId, type, subject);
                created++;
            }
        }

        if (created > 0)
        {
            await db.SaveChangesAsync(ct);
            logger.LogInformation("Created {Count} club plan notification(s).", created);
        }

        return created;
    }
}
