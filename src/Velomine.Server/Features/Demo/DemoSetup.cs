namespace Velomine.Server.Features.Demo;

public static class DemoSetup
{
    public static IServiceCollection AddDemo(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<DemoOptions>().BindConfiguration("Velomine:Demo");
        services.AddScoped<DemoData>();
        services.AddSingleton<DemoResetService>();
        // After the accounts startup, which makes the roles and the admin the reset relies on.
        if (configuration.GetValue("Velomine:Background:Enabled", true))
            services.AddHostedService(sp => sp.GetRequiredService<DemoResetService>());
        return services;
    }
}
