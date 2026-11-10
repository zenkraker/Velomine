using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

/// <summary>Drops revoked and expired session rows after a week, so the list never keeps stale device labels.</summary>
public sealed class SessionCleanup(IServiceScopeFactory scopes, ILogger<SessionCleanup> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromDays(1));
        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                await using var scope = scopes.CreateAsyncScope();
                var sessions = scope.ServiceProvider.GetRequiredService<UserSessions>();
                await sessions.DeleteStaleAsync(DateTimeOffset.UtcNow, stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                logger.LogWarning("Session cleanup failed: {Exception}.", ex.GetType().Name);
            }
        }
    }
}
