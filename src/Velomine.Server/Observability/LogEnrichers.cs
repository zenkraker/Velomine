using System.Diagnostics;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Serilog.Core;
using Serilog.Events;

namespace Velomine.Server.Observability;

/// <summary>Adds request context to logs without ever adding the raw path or query string.</summary>
public sealed class RequestContextEnricher(IHttpContextAccessor accessor) : ILogEventEnricher
{
    private static readonly string Version = BuildInfo.Version;

    public void Enrich(LogEvent logEvent, ILogEventPropertyFactory propertyFactory)
    {
        logEvent.AddPropertyIfAbsent(propertyFactory.CreateProperty("Version", Version));

        if (Activity.Current is { } activity)
        {
            logEvent.AddPropertyIfAbsent(propertyFactory.CreateProperty("TraceId", activity.TraceId.ToString()));
            logEvent.AddPropertyIfAbsent(propertyFactory.CreateProperty("SpanId", activity.SpanId.ToString()));
        }

        if (accessor.HttpContext is not { } context) return;

        logEvent.AddPropertyIfAbsent(propertyFactory.CreateProperty("Tenant", context.Request.Host.Host));
        logEvent.AddPropertyIfAbsent(propertyFactory.CreateProperty(
            "Route",
            context.GetEndpoint() is RouteEndpoint { RoutePattern.RawText: { } route } ? route : "unmatched"));
    }
}

/// <summary>Drops properties that are too easy to add by accident and must never be logged.</summary>
public sealed class ForbiddenPropertiesEnricher : ILogEventEnricher
{
    private static readonly HashSet<string> Forbidden = new(StringComparer.OrdinalIgnoreCase)
    {
        "AdminId", "UserId", "Email", "User", "UserName", "DisplayName", "RideId", "BikeId",
        "RequestPath", "QueryString", "Cookie", "Authorization", "Body", "Request", "Response",
        "Password", "Token", "RefreshToken", "AccessToken", "IpAddress",
    };

    public void Enrich(LogEvent logEvent, ILogEventPropertyFactory propertyFactory)
    {
        foreach (var key in logEvent.Properties.Keys.ToList())
            if (Forbidden.Contains(key))
                logEvent.RemovePropertyIfPresent(key);
    }
}
