using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Demo;

/// <summary>
/// What a demo refuses. Its visitors share three accounts, so one of them must not be able to lock the others out:
/// no new or reset password, no two-factor sign-in, no deleted account, no signing the others out, no changed club roles, and
/// no new accounts.
/// </summary>
public static class DemoLock
{
    public const string Code = "demo_locked";

    /// <summary>Method and route template, as the endpoints declare them.</summary>
    public static readonly IReadOnlyList<(string Method, string Route)> Refused =
    [
        ("POST", "accounts/register"),
        ("PUT", "accounts/me/password"),
        // A reset link would set a new password on a shared account, if the demo ever had email.
        ("POST", "accounts/password/forgot"),
        ("POST", "accounts/password/reset"),
        ("POST", "accounts/me/delete"),
        ("POST", "accounts/me/two-factor/start"),
        ("POST", "accounts/me/two-factor/enable"),
        ("POST", "accounts/me/two-factor/disable"),
        ("POST", "accounts/me/two-factor/recovery-codes"),
        ("DELETE", "accounts/me/sessions/{id}"),
        ("POST", "accounts/me/sessions/logout-others"),
        ("POST", "club/leave"),
        ("POST", "club/join-code"),
        ("PUT", "club/members/{userId}/role"),
    ];

    public static bool Refuses(string method, string? routeTemplate)
    {
        if (routeTemplate is null) return false;
        var route = routeTemplate.Trim('/');
        if (route.StartsWith("api/v1/", StringComparison.OrdinalIgnoreCase)) route = route["api/v1/".Length..];
        foreach (var (refusedMethod, refusedRoute) in Refused)
            if (string.Equals(method, refusedMethod, StringComparison.OrdinalIgnoreCase)
                && string.Equals(route, refusedRoute, StringComparison.OrdinalIgnoreCase))
                return true;
        return false;
    }

    /// <summary>Answers 403 for a refused action when this server is a demo. Runs after routing has chosen the endpoint.</summary>
    public static IApplicationBuilder UseDemoLock(this IApplicationBuilder app) => app.Use(async (context, next) =>
    {
        if (context.RequestServices.GetRequiredService<IOptions<DemoOptions>>().Value.Enabled
            && context.GetEndpoint() is RouteEndpoint endpoint
            && Refuses(context.Request.Method, endpoint.RoutePattern.RawText))
        {
            await Results.Problem(new ProblemDetails
            {
                Status = StatusCodes.Status403Forbidden,
                Title = "Not available in the demo.",
                Detail = "This is switched off in the demo, because everyone shares these accounts.",
                Extensions = { ["code"] = Code },
            }).ExecuteAsync(context);
            return;
        }

        await next(context);
    });
}
