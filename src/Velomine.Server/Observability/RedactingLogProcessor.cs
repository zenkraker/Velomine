using OpenTelemetry;
using OpenTelemetry.Logs;

namespace Velomine.Server.Observability;

/// <summary>
/// The last guard before a log record leaves over OTLP: drops attributes that identify a person or a request, whatever
/// added them. ForbiddenPropertiesEnricher already removes Velomine's own; this catches the standard OpenTelemetry names
/// a library may add.
/// </summary>
public sealed class RedactingLogProcessor : BaseProcessor<LogRecord>
{
    private static readonly HashSet<string> Exact = new(StringComparer.OrdinalIgnoreCase)
    {
        "url.full", "url.query", "url.path", "client.address", "network.peer.address", "user_agent.original",
        "http.client_ip", "db.statement", "db.query.text", "db.connection_string",
    };

    private static readonly string[] Prefixes = ["user.", "enduser.", "http.request.header.", "http.response.header."];

    public override void OnEnd(LogRecord record)
    {
        if (record.Attributes is not { Count: > 0 } attributes) return;
        if (!attributes.Any(a => Forbidden(a.Key))) return;
        record.Attributes = [.. attributes.Where(a => !Forbidden(a.Key))];
    }

    private static bool Forbidden(string key) =>
        Exact.Contains(key) || Prefixes.Any(p => key.StartsWith(p, StringComparison.OrdinalIgnoreCase));
}
