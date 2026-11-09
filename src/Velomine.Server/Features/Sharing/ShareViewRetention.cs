using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Sharing;

/// <summary>
/// Keeps the member-visible "who looked" log bounded to three months. Deletes in batches so a large backlog never
/// becomes one long transaction, and runs once at startup then daily.
/// </summary>
public sealed class ShareViewRetention(
    IServiceScopeFactory scopes,
    TimeProvider time,
    ILogger<ShareViewRetention> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromDays(1);
    private const int BatchSize = 5000;

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
                    logger.LogError(ex, "Deleting old share views failed.");
                }
            }
            while (await timer.WaitForNextTickAsync(stoppingToken));
        }
        catch (OperationCanceledException)
        {
            // Stopping.
        }
    }

    /// <summary>Deletes share views older than three months; returns how many rows went.</summary>
    public async Task<int> RunOnceAsync(CancellationToken ct)
    {
        var cutoff = time.GetUtcNow().AddMonths(-3);
        var total = 0;
        while (true)
        {
            await using var scope = scopes.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var ids = await db.ShareViews
                .Where(v => v.At < cutoff)
                .OrderBy(v => v.At)
                .Select(v => v.Id)
                .Take(BatchSize)
                .ToListAsync(ct);
            if (ids.Count == 0) break;

            total += await db.ShareViews.Where(v => ids.Contains(v.Id)).ExecuteDeleteAsync(ct);
            if (ids.Count < BatchSize) break;
        }

        if (total > 0) logger.LogInformation("Deleted {Count} share views older than three months.", total);
        return total;
    }
}
