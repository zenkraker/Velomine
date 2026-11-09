using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Admin;

namespace Velomine.Server.Features.Notifications.Email;

/// <summary>
/// Emails members their notifications when the server has SMTP set up. Every 30 seconds it sends what is due, one
/// email per member: "account and club" notifications as soon as they happen, ride and gear notifications after a
/// short digest window so a burst of uploads becomes one email. The state lives on the notification (EmailedAt), so
/// there is no queue: a failure is tried again at the next run, a refused recipient is recorded and skipped, and a
/// restart loses nothing. Notifications older than a day, already read, or for a member with email off are never
/// emailed, and switching email on never sends the backlog.
/// </summary>
public sealed class NotificationEmailService(
    IServiceProvider services,
    IEmailSender sender,
    IOptions<SmtpOptions> smtp,
    TimeProvider time,
    ILogger<NotificationEmailService> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromSeconds(30);
    private static readonly TimeSpan MaxAge = TimeSpan.FromDays(1);

    /// <summary>A burst of ride and gear notifications is held this long, then sent as one email.</summary>
    private static readonly TimeSpan TrainingDigestWindow = TimeSpan.FromMinutes(10);

    private static readonly TimeSpan MinBackoff = TimeSpan.FromMinutes(2);
    private static readonly TimeSpan MaxBackoff = TimeSpan.FromMinutes(30);
    private const int BatchSize = 50;

    // A run never overlaps another, so one notification is never sent twice.
    private readonly SemaphoreSlim running = new(1, 1);

    /// <summary>Whether the last run stopped on a send failure, so the loop can back off.</summary>
    public bool LastRunFailed { get; private set; }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var interval = Interval;
        try
        {
            while (true)
            {
                try
                {
                    await RunOnceAsync(stoppingToken);
                    interval = LastRunFailed ? BackOff(interval) : Interval;
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    logger.LogError(ex, "Sending notification emails failed unexpectedly.");
                    interval = BackOff(interval);
                }

                await Task.Delay(interval, stoppingToken);
            }
        }
        catch (OperationCanceledException)
        {
            // Stopping.
        }
    }

    /// <summary>One run: returns how many emails went out.</summary>
    public async Task<int> RunOnceAsync(CancellationToken ct)
    {
        if (!smtp.Value.Configured) return 0;

        await running.WaitAsync(ct);
        try
        {
            await using var scope = services.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var now = time.GetUtcNow();

            var settings = await db.Set<ServerSettings>().FirstOrDefaultAsync(ct);
            if (settings is null) db.Add(settings = new ServerSettings());
            if (settings.EmailStartedAt is null)
            {
                settings.EmailStartedAt = now;
                await db.SaveChangesAsync(ct);
            }

            var since = settings.EmailStartedAt.Value > now - MaxAge ? settings.EmailStartedAt.Value : now - MaxAge;
            var trainingCutoff = now - TrainingDigestWindow;
            var accountTypes = NotificationKinds.AccountTypes;
            var trainingTypes = NotificationKinds.TrainingTypes;

            var due = await db.Notifications
                .Where(n => n.EmailedAt == null && n.ReadAt == null && n.CreatedAt >= since)
                .Join(
                    db.Users.Where(u => u.EmailNotifications && u.Email != null),
                    n => n.UserId,
                    u => u.Id,
                    (n, u) => new
                    {
                        Notification = n,
                        u.Email,
                        u.EmailAccountNotifications,
                        u.EmailTrainingNotifications,
                    })
                .Where(x =>
                    (accountTypes.Contains(x.Notification.Type) && x.EmailAccountNotifications)
                    || (trainingTypes.Contains(x.Notification.Type) && x.EmailTrainingNotifications && x.Notification.CreatedAt <= trainingCutoff))
                .OrderBy(x => x.Notification.CreatedAt)
                .Take(BatchSize)
                .ToListAsync(ct);

            var groups = due
                .GroupBy(x => x.Notification.UserId)
                .Select(g => new
                {
                    Email = g.First().Email!,
                    Notifications = g.Select(x => x.Notification).OrderBy(n => n.CreatedAt).ToList(),
                })
                .ToList();

            var outgoing = groups
                .Select(g => new OutgoingEmail(g.Email, NotificationText.Subject(g.Notifications), NotificationText.Body(g.Notifications)))
                .ToList();

            var batch = await sender.SendAsync(outgoing, ct);
            var sentAt = time.GetUtcNow();
            var sent = 0;
            for (var i = 0; i < groups.Count && i < batch.Results.Count; i++)
            {
                var outcome = batch.Results[i].Outcome;
                if (outcome == EmailOutcome.NotSent) continue;
                foreach (var notification in groups[i].Notifications) notification.EmailedAt = sentAt;
                if (outcome == EmailOutcome.Sent) sent++;
            }

            if (db.ChangeTracker.HasChanges()) await db.SaveChangesAsync(ct);

            LastRunFailed = batch.Failure is not null;
            if (batch.Failure is not null)
                logger.LogWarning("Could not send notification emails ({Exception}). Trying again later.", batch.Failure.GetType().Name);
            if (sent > 0)
                logger.LogInformation("Sent {Count} notification email(s).", sent);

            return sent;
        }
        finally
        {
            running.Release();
        }
    }

    /// <summary>2 minutes, doubling, capped at 30: a broken relay is not hammered every 30 seconds.</summary>
    private static TimeSpan BackOff(TimeSpan current) =>
        TimeSpan.FromMinutes(Math.Min(MaxBackoff.TotalMinutes, Math.Max(MinBackoff.TotalMinutes, current.TotalMinutes * 2)));
}
