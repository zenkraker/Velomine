using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Demo;

/// <summary>
/// In demo mode, makes the demo data again every night at 03:00 UTC. Whether a reset is due is read from the data
/// (when the demo club was last made), so a night the server was off is caught up when it starts.
/// </summary>
public sealed class DemoResetService(
    IServiceScopeFactory scopes,
    IOptions<DemoOptions> options,
    TimeProvider time,
    ILogger<DemoResetService> logger) : BackgroundService
{
    public const int ResetHourUtc = 3;

    private DateTimeOffset? failedFor;

    /// <summary>Refuses to start a demo on a server that holds anything but a demo, before any request is served.</summary>
    public override async Task StartAsync(CancellationToken cancellationToken)
    {
        if (options.Value.Enabled)
        {
            await using var scope = scopes.CreateAsyncScope();
            if (await scope.ServiceProvider.GetRequiredService<DemoData>().RefusalAsync(cancellationToken) is { } refusal)
                throw new InvalidOperationException("VELOMINE__DEMO__ENABLED is on, but: " + refusal);
            logger.LogWarning("Demo mode is on: every account but the admins is deleted and made again each night at 03:00 UTC.");
        }

        await base.StartAsync(cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!options.Value.Enabled) return;

        using var timer = new PeriodicTimer(TimeSpan.FromMinutes(1));
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
                    // Once per night is enough to know; the next night tries again.
                    failedFor = LastBoundary(time.GetUtcNow());
                    logger.LogError(ex, "The demo could not be reset.");
                }
            }
            while (await timer.WaitForNextTickAsync(stoppingToken));
        }
        catch (OperationCanceledException)
        {
            // Stopping.
        }
    }

    /// <summary>Resets the demo when the last 03:00 UTC has passed since it was made; returns whether it did.</summary>
    public async Task<bool> RunOnceAsync(CancellationToken ct)
    {
        var boundary = LastBoundary(time.GetUtcNow());
        if (failedFor == boundary) return false;

        await using var scope = scopes.CreateAsyncScope();
        var demo = scope.ServiceProvider.GetRequiredService<DemoData>();
        if (await demo.LastResetAsync(ct) is { } last && last >= boundary) return false;

        await demo.ResetAsync(ct);
        logger.LogInformation("The demo was reset.");
        return true;
    }

    /// <summary>The most recent 03:00 UTC at or before <paramref name="now"/>.</summary>
    public static DateTimeOffset LastBoundary(DateTimeOffset now)
    {
        var utc = now.ToUniversalTime();
        var today = new DateTimeOffset(utc.Year, utc.Month, utc.Day, ResetHourUtc, 0, 0, TimeSpan.Zero);
        return today <= utc ? today : today.AddDays(-1);
    }
}
