using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Rides.Import;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Tests;

/// <summary>
/// What the test host leaves out of a server it starts. The database is a clone of the migrated template and the
/// jobs that only repeat on a timer do nothing a test waits for, so neither is started; a test that needs a job
/// resolves it and calls RunOnceAsync.
/// </summary>
public static class TestHost
{
    /// <summary>
    /// The hosted services a test depends on: the roles and admin every account needs, the reader that finishes an
    /// upload, the import worker that finishes a Strava archive, and the catalogue bootstrap. Every other job of the
    /// server's own repeats on a timer and is left out.
    /// </summary>
    private static readonly Type[] Kept =
    [
        typeof(AccountsStartup),
        typeof(RideIngestionService),
        typeof(ImportService),
        typeof(CatalogueBootstrap),
    ];

    /// <summary>
    /// Drops the migration and every timer loop. A job registered by type shows its type; one registered as
    /// <c>sp =&gt; sp.GetRequiredService&lt;T&gt;()</c> does not, so it is recognised by building the singleton it wraps.
    /// The collection is built once here to identify those few descriptors and once by the host to start the
    /// server. Constructing a job costs nothing; its StartAsync is what does work.
    /// </summary>
    public static void RemoveJobs(IServiceCollection services)
    {
        var ours = typeof(AccountsStartup).Assembly;

        foreach (var descriptor in services.Where(d => d.ServiceType == typeof(IHostedService)).ToList())
        {
            if (descriptor.ImplementationType is { } type && type.Assembly == ours && !Kept.Contains(type))
                services.Remove(descriptor);
        }

        if (!services.Any(d => d.ServiceType == typeof(IHostedService) && d.ImplementationFactory is not null)) return;

        using var probe = services.BuildServiceProvider(new ServiceProviderOptions { ValidateOnBuild = false, ValidateScopes = false });
        foreach (var descriptor in services.Where(d => d.ServiceType == typeof(IHostedService)
                     && d.ImplementationFactory is not null).ToList())
        {
            var job = descriptor.ImplementationFactory!(probe).GetType();
            if (job.Assembly == ours && !Kept.Contains(job)) services.Remove(descriptor);
        }
    }
}
