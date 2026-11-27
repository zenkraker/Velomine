using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Demo;

/// <summary>
/// What a demo refuses. Its visitors share the demo accounts, so one of them must not be able to lock the others out:
/// no new or reset password, no two-factor sign-in, no deleted account, no signing the others out, no changed club roles,
/// no new accounts, no turning auto training off and no skipping the rest of the week, either of which would take the
/// week away from everyone until 03:00 UTC.
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
        // The demo's only email is the feedback form: its accounts are shared and their addresses are not mailboxes.
        ("POST", "accounts/email/resend"),
        ("POST", "admin/settings/test-email"),
        ("POST", "accounts/me/delete"),
        ("POST", "accounts/me/two-factor/start"),
        ("POST", "accounts/me/two-factor/enable"),
        ("POST", "accounts/me/two-factor/disable"),
        ("POST", "accounts/me/two-factor/recovery-codes"),
        ("POST", "club/leave"),
        ("POST", "club/join-code"),
        ("PUT", "club/members/{userId}/role"),
        // A visitor must not turn the demo rider's auto training off for the next visitor.
        ("DELETE", "training/plan"),
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

    /// <summary>The refusal a demo answers with, as the middleware and an endpoint that reads a request body both send it.</summary>
    public static ProblemDetails Problem() => new()
    {
        Status = StatusCodes.Status403Forbidden,
        Title = "Not available in the demo.",
        Detail = "This is switched off in the demo, because everyone shares these accounts.",
        Extensions = { ["code"] = Code },
    };

    /// <summary>Answers 403 for a refused action when this server is a demo. Runs after routing has chosen the endpoint.</summary>
    public static IApplicationBuilder UseDemoLock(this IApplicationBuilder app) => app.Use(async (context, next) =>
    {
        if (context.RequestServices.GetRequiredService<IOptions<DemoOptions>>().Value.Enabled
            && context.GetEndpoint() is RouteEndpoint endpoint
            && Refuses(context.Request.Method, endpoint.RoutePattern.RawText))
        {
            await Results.Problem(Problem()).ExecuteAsync(context);
            return;
        }

        await next(context);
    });
}
