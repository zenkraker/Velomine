using FastEndpoints;
using Velomine.Server.Data;
using Velomine.Server.Observability;

namespace Velomine.Server.Features.Accounts;

public sealed record TelemetryResponse(bool ConsentRequired, bool Crash, bool Usage, int Version);

/// <summary>The member's telemetry contribution choice. Off until they opt in.</summary>
public sealed class GetTelemetry(VelomineDbContext db) : EndpointWithoutRequest<TelemetryResponse>
{
    public override void Configure()
    {
        Get("accounts/me/telemetry");
        Description(d => d.Produces<TelemetryResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var consent = await TelemetryRules.ForAsync(db, User.UserId(), ct);
        await Send.OkAsync(new TelemetryResponse(consent.Required, consent.Crash, consent.Usage, TelemetryTerms.Version), ct);
    }
}
