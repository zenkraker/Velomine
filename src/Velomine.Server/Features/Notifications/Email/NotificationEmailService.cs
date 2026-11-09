using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Admin;

namespace Velomine.Server.Features.Notifications.Email;

/// <summary>
/// Emails members their notifications when the server has SMTP set up. Every 30 seconds it sends the notifications that
/// are not emailed yet. The state lives on the notification (EmailedAt), so there is no queue: a failed send is simply
/// tried again at the next run, and a restart loses nothing.
/// What is emailed: notifications created after email was first switched on (so switching it on never sends a backlog),
/// and no older than a day, that the member has not already read, for members who have email notifications on.
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
    private const int BatchSize = 50;

    // A run never overlaps another, so one notification is never sent twice.
    private readonly SemaphoreSlim running = new(1, 1);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);
        try
        {
            // Once at the start, so the moment email was switched on is the start of the server, not 30 seconds later.
            do
            {
                try
                {
                    await RunOnceAsync(stoppingToken);
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    logger.LogError(ex, "Sending notification emails failed unexpectedly.");
                }
            }
            while (await timer.WaitForNextTickAsync(stoppingToken));
        }
        catch (OperationCanceledException)
        {
            // stopping
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
            var due = await db.Notifications
                .Where(n => n.EmailedAt == null && n.ReadAt == null && n.CreatedAt >= since)
                .Join(db.Users.Where(u => u.EmailNotifications && u.Email != null), n => n.UserId, u => u.Id, (n, u) => new { Notification = n, Email = u.Email! })
                .OrderBy(x => x.Notification.CreatedAt)
                .Take(BatchSize)
                .ToListAsync(ct);

            var sent = 0;
            foreach (var item in due)
            {
                try
                {
                    await sender.SendAsync(item.Email, NotificationText.Subject(item.Notification), NotificationText.Body(item.Notification), ct);
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    // The exception type says what failed; the message can name the recipient, which must not be logged.
                    logger.LogWarning("Could not send a notification email ({Exception}). Trying again later.", ex.GetType().Name);
                    break;
                }

                item.Notification.EmailedAt = time.GetUtcNow();
                await db.SaveChangesAsync(ct);
                sent++;
            }

            return sent;
        }
        finally
        {
            running.Release();
        }
    }
}
