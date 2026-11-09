using Microsoft.Extensions.Options;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Bikes;

/// <summary>
/// Loads the bundled seed into an empty club before the server starts taking requests. Clubs with a catalogue URL
/// get the newer shared feed from <see cref="CatalogueSyncService"/> afterwards.
/// </summary>
public sealed class CatalogueBootstrap(
    IServiceScopeFactory scopes,
    IOptions<CatalogueOptions> options,
    ILogger<CatalogueBootstrap> logger) : IHostedService
{
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        if (!options.Value.Seed) return;
        try
        {
            await using var scope = scopes.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var clock = scope.ServiceProvider.GetRequiredService<TimeProvider>();
            if (await CatalogueSeed.EnsureSeededAsync(db, clock, cancellationToken))
                logger.LogInformation("Loaded the bundled parts catalogue.");
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            // A missing seed must not stop the club from starting; members can still add parts by hand.
            logger.LogError(exception, "The bundled parts catalogue could not be loaded.");
        }
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}

/// <summary>
/// Looks for a newer shared catalogue every few minutes. When the source is unreachable the club keeps its current
/// catalogue: the shared catalogue is an enhancement, never a dependency of the bikes section.
/// </summary>
public sealed class CatalogueSyncService(
    IServiceScopeFactory scopes,
    IOptions<CatalogueOptions> options,
    ILogger<CatalogueSyncService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var settings = options.Value;
        if (string.IsNullOrWhiteSpace(settings.Url)) return;

        await SyncAsync(stoppingToken);

        var minutes = Math.Clamp(settings.SyncMinutes, 5, 24 * 60);
        using var timer = new PeriodicTimer(TimeSpan.FromMinutes(minutes));
        while (await timer.WaitForNextTickAsync(stoppingToken))
            await SyncAsync(stoppingToken);
    }

    private async Task SyncAsync(CancellationToken cancellationToken)
    {
        try
        {
            await using var scope = scopes.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<VelomineDbContext>();
            var source = scope.ServiceProvider.GetRequiredService<ICatalogueSource>();
            var clock = scope.ServiceProvider.GetRequiredService<TimeProvider>();
            if (await CatalogueSync.RunAsync(db, source, clock, options.Value.Url, cancellationToken))
                logger.LogInformation("Applied a newer shared parts catalogue.");
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            logger.LogWarning(exception, "The shared parts catalogue could not be read; keeping the current one.");
        }
    }
}
