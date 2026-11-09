using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Rides;

public static class RidesSetup
{
    public static IServiceCollection AddRides(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<RidesOptions>().BindConfiguration("Velomine");
        services.AddSingleton<RideFileStore>();
        services.AddSingleton<IngestionQueue>();
        if (configuration.GetValue("Velomine:Background:Enabled", true))
        {
            services.AddHostedService<RideIngestionService>();
            services.AddHostedService<PowerBestsBackfill>();
        }
        return services;
    }
}
