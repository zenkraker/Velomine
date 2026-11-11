namespace Velomine.Server.Features.Bikes;

public static class BikesSetup
{
    public static IServiceCollection AddBikes(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<CatalogueOptions>(configuration.GetSection("Velomine:Catalogue"));

        // The feed is small and read rarely: a plain HttpClient with a short timeout is all the cache it needs.
        services.AddHttpClient<ICatalogueSource, HttpCatalogueSource>(client => client.Timeout = TimeSpan.FromSeconds(15));
        services.AddHttpClient("catalogue-contribution", client => client.Timeout = TimeSpan.FromSeconds(20));

        if (configuration.GetValue("Velomine:Background:Enabled", true))
        {
            services.AddHostedService<CatalogueBootstrap>();
            services.AddHostedService<CatalogueSyncService>();
            services.AddHostedService<ContributionService>();
            services.AddHostedService<MaintenanceReminderService>();
        }
        return services;
    }
}
