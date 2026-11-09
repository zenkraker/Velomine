using System.Reflection;
using FastEndpoints;
using Microsoft.Extensions.Options;
using Velomine.Server.Features.Admin;
using Velomine.Server.Observability;

namespace Velomine.Server.Features.Server;

/// <summary>What a client needs to know about this server before anyone signs in.</summary>
public sealed record ServerInfoResponse(
    string Name,
    string Version,
    string MapTileUrl,
    string MapAttribution,
    bool EmailAvailable,
    bool TelemetryEnabled,
    string? SentryDsn,
    int TelemetryTermsVersion);

public sealed class GetServerInfo(
    IOptions<MapOptions> map,
    IOptions<SmtpOptions> smtp,
    IOptions<TelemetryOptions> telemetry) : EndpointWithoutRequest<ServerInfoResponse>
{
    public override void Configure()
    {
        Get("server");
        AllowAnonymous();
    }

    public override Task HandleAsync(CancellationToken ct)
    {
        var version = Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "0.0.0";
        var options = telemetry.Value;
        return Send.OkAsync(new ServerInfoResponse(
            "Velomine",
            version,
            map.Value.EffectiveTileUrl,
            map.Value.EffectiveAttribution,
            smtp.Value.Configured,
            options.IsAppActive,
            options.IsAppActive ? options.EffectiveAppDsn : null,
            TelemetryTerms.Version), ct);
    }
}
