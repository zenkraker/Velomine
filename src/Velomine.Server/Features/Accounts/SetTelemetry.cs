using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Observability;

namespace Velomine.Server.Features.Accounts;

public sealed record SetTelemetryRequest(bool Crash, bool Usage);

/// <summary>Records the member's opt-in or opt-out. Both switches default to off.</summary>
public sealed class SetTelemetry(VelomineDbContext db, TimeProvider time)
    : Endpoint<SetTelemetryRequest, TelemetryResponse>
{
    public override void Configure()
    {
        Put("accounts/me/telemetry");
        Description(d => d.Accepts<SetTelemetryRequest>("application/json")
            .Produces<TelemetryResponse>(200)
            .ProducesProblem(400)
            .Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(SetTelemetryRequest req, CancellationToken ct)
    {
        var user = await db.Users.FirstAsync(u => u.Id == User.UserId(), ct);
        user.TelemetryConsentAt = time.GetUtcNow();
        user.TelemetryConsentVersion = TelemetryTerms.Version;
        user.TelemetryCrash = req.Crash;
        user.TelemetryUsage = req.Usage;
        await db.SaveChangesAsync(ct);

        await Send.OkAsync(new TelemetryResponse(false, req.Crash, req.Usage, TelemetryTerms.Version), ct);
    }
}
