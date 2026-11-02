using System.Reflection;
using FastEndpoints;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Server;

/// <summary>What a client needs to know about this server before anyone signs in.</summary>
public sealed record ServerInfoResponse(string Name, string Version, string? MapTileUrl, string? MapAttribution);

public sealed class GetServerInfo(IOptions<MapOptions> map) : EndpointWithoutRequest<ServerInfoResponse>
{
    public override void Configure()
    {
        Get("server");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var version = Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "0.0.0";
        var tiles = map.Value.UsableTileUrl;
        await Send.OkAsync(new ServerInfoResponse("Velomine", version, tiles, tiles is null ? null : map.Value.Attribution), ct);
    }
}
