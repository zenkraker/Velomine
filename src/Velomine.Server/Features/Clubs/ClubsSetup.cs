namespace Velomine.Server.Features.Clubs;

public static class ClubsSetup
{
    public static IServiceCollection AddClubs(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<ClubPlanNotifier>();
        if (configuration.GetValue("Velomine:Background:Enabled", true))
            services.AddHostedService(sp => sp.GetRequiredService<ClubPlanNotifier>());
        return services;
    }
}
