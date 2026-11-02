using Microsoft.EntityFrameworkCore;

namespace Velomine.Server.Data;

/// <summary>
/// Applies the EF Core migrations when the server starts, before any other startup work or background service runs
/// (hosted services start in the order they are registered). EF Core locks the migration table, so starting several
/// servers at once is safe.
/// </summary>
public sealed class DatabaseMigrator(IServiceProvider services) : IHostedService
{
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        await using var scope = services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<VelomineDbContext>().Database.MigrateAsync(cancellationToken);
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}
