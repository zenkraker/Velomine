using Microsoft.Extensions.Options;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Bikes;

/// <summary>
/// Sends the parts an opted-in club added to the publisher, a batch at a time. Runs even while the club has not opted
/// in, so turning contributions on later takes effect without a restart; nothing is queued until then.
/// </summary>
public sealed class ContributionService(
    IServiceScopeFactory scopes,
    IHttpClientFactory clients,
    IOptions<CatalogueOptions> options,
    ILogger<ContributionService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var settings = options.Value;
        if (string.IsNullOrWhiteSpace(settings.ContributeUrl) || string.IsNullOrWhiteSpace(settings.ContributionKey)) return;

        await PushAsync(stoppingToken);

        var minutes = Math.Clamp(settings.ContributeMinutes, 1, 24 * 60);
        using var timer = new PeriodicTimer(TimeSpan.FromMinutes(minutes));
        while (await timer.WaitForNextTickAsync(stoppingToken))
            await PushAsync(stoppingToken);
    }

    private async Task PushAsync(CancellationToken cancellationToken)
    {
        try
        {
            await using var scope = scopes.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var clock = scope.ServiceProvider.GetRequiredService<TimeProvider>();
            await ContributionPush.RunAsync(
                db, clients.CreateClient("catalogue-contribution"), options.Value, clock, logger, cancellationToken);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            // Shutting down.
        }
        catch (Exception exception)
        {
            // Nothing about a part is in this message: only that the attempt failed.
            logger.LogWarning(exception, "The contribution outbox could not be sent.");
        }
    }
}
