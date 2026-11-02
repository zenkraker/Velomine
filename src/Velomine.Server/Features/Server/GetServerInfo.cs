using System.Reflection;
using FastEndpoints;

namespace Velomine.Server.Features.Server;

public sealed record ServerInfoResponse(string Name, string Version);

public sealed class GetServerInfo : EndpointWithoutRequest<ServerInfoResponse>
{
    public override void Configure()
    {
        Get("server");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var version = Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "0.0.0";
        await Send.OkAsync(new ServerInfoResponse("Velomine", version), ct);
    }
}
