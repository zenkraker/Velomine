using System.Diagnostics;
using OpenTelemetry;

namespace Velomine.Server.Observability;

/// <summary>
/// Removes values that must never leave the process, before the OTLP exporter sees the span.
/// It is the only guard for traces, whichever backend receives them.
/// </summary>
public sealed class RedactingActivityProcessor : BaseProcessor<Activity>
{
    private static readonly string[] Exact =
    [
        "url.full",
        "url.query",
        "url.path",
        "http.url",
        "http.target",
        "http.user_agent",
        "http.request.header.authorization",
        "http.request.header.cookie",
        "http.request.body",
        "http.response.body",
        "http.client_ip",
        "user_agent.original",
        "db.statement",
        "db.query.text",
        "db.connection_string",
        "client.address",
        "network.peer.address",
        "enduser.id",
        "user.id",
        "user.name",
        "user.email",
    ];

    public override void OnEnd(Activity activity)
    {
        foreach (var key in Exact)
            activity.SetTag(key, null);

        foreach (var tag in activity.TagObjects.ToList())
        {
            if (tag.Key.StartsWith("http.request.header.", StringComparison.OrdinalIgnoreCase) ||
                tag.Key.StartsWith("http.response.header.", StringComparison.OrdinalIgnoreCase) ||
                tag.Key.StartsWith("db.query.parameter.", StringComparison.OrdinalIgnoreCase) ||
                tag.Key.StartsWith("enduser.", StringComparison.OrdinalIgnoreCase) ||
                tag.Key.StartsWith("user.", StringComparison.OrdinalIgnoreCase))
                activity.SetTag(tag.Key, null);
        }

        // The ASP.NET Core server span name is "GET /raw/path". Use the route template when there is one,
        // so a share token in the path never becomes a trace name. Leave client/db span names alone.
        if (activity.Kind == ActivityKind.Server)
        {
            var route = activity.GetTagItem("http.route") as string;
            var method = activity.GetTagItem("http.method") as string;
            activity.DisplayName = route is null ? "HTTP" : $"{method ?? "HTTP"} {route}";
        }
    }
}
