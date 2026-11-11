using Velomine.Server.Features.Rides.Import;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Rides;

public static class RidesSetup
{
    public static IServiceCollection AddRides(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<RidesOptions>().BindConfiguration("Velomine");
        services.AddOptions<RideImportOptions>().BindConfiguration("Velomine:Imports")
            .Validate(o => o.MaxArchiveMb > 0, "Velomine:Imports:MaxArchiveMb must be 1 or more.")
            .ValidateOnStart();
        services.AddSingleton<RideFileStore>();
        services.AddSingleton<ImportStore>();
        services.AddSingleton<IngestionQueue>();
        services.AddSingleton<ImportQueue>();
        services.AddSingleton<PowerBestsBackfill>();
        services.AddSingleton<RideReparseService>();
        if (configuration.GetValue("Velomine:Background:Enabled", true))
        {
            services.AddHostedService<RideIngestionService>();
            services.AddHostedService<ImportService>();
            services.AddHostedService(sp => sp.GetRequiredService<PowerBestsBackfill>());
            services.AddHostedService(sp => sp.GetRequiredService<RideReparseService>());
        }
        return services;
    }
}
