namespace Velomine.Server.Features.Routes;

public static class RoutesSetup
{
    public static IServiceCollection AddRoutes(this IServiceCollection services)
    {
        services.AddSingleton<RouteDownloadTokens>();
        return services;
    }
}
