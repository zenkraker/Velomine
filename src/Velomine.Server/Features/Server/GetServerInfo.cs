using System.Reflection;
using FastEndpoints;
using Microsoft.Extensions.Options;
using Velomine.Server.Features.Admin;

namespace Velomine.Server.Features.Server;

/// <summary>What a client needs to know about this server before anyone signs in.</summary>
public sealed record ServerInfoResponse(string Name, string Version, string MapTileUrl, string MapAttribution, bool EmailAvailable);

public sealed class GetServerInfo(IOptions<MapOptions> map, IOptions<SmtpOptions> smtp) : EndpointWithoutRequest<ServerInfoResponse>
{
    public override void Configure()
    {
        Get("server");
        AllowAnonymous();
    }

    public override Task HandleAsync(CancellationToken ct)
    {
        var version = Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "0.0.0";
        return Send.OkAsync(new ServerInfoResponse(
            "Velomine",
            version,
            map.Value.EffectiveTileUrl,
            map.Value.EffectiveAttribution,
            smtp.Value.Configured), ct);
    }
}
