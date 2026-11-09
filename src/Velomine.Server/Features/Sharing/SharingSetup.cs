namespace Velomine.Server.Features.Sharing;

public static class SharingSetup
{
    public static IServiceCollection AddSharing(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<ShareViewRetention>();
        if (configuration.GetValue("Velomine:Background:Enabled", true))
            services.AddHostedService(sp => sp.GetRequiredService<ShareViewRetention>());
        return services;
    }
}
