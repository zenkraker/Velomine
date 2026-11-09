using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Rides;

public static class RidesSetup
{
    public static IServiceCollection AddRides(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<RidesOptions>().BindConfiguration("Velomine");
        services.AddSingleton<RideFileStore>();
        services.AddSingleton<IngestionQueue>();
        services.AddSingleton<PowerBestsBackfill>();
        if (configuration.GetValue("Velomine:Background:Enabled", true))
        {
            services.AddHostedService<RideIngestionService>();
            services.AddHostedService(sp => sp.GetRequiredService<PowerBestsBackfill>());
        }
        return services;
    }
}
