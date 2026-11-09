using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Velomine.Server.Data;

/// <summary>The database is what every request needs; a process that cannot reach it must leave the load balancer.</summary>
public sealed class DatabaseHealthCheck(VelomineDbContext db) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default) =>
        await db.Database.CanConnectAsync(cancellationToken)
            ? HealthCheckResult.Healthy()
            : HealthCheckResult.Unhealthy("The database cannot be reached.");
}
