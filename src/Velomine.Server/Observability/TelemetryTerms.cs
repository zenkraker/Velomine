using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Observability;

/// <summary>The consent wording version. Bump it when the wording changes so every member is asked again.</summary>
public static class TelemetryTerms
{
    public const int Version = 1;
}

public sealed record TelemetryConsent(bool Required, bool Crash, bool Usage);

/// <summary>Reads a member's contribution choice. Default is off; a version change asks again.</summary>
public static class TelemetryRules
{
    public static async Task<TelemetryConsent> ForAsync(VelomineDbContext db, Guid userId, CancellationToken ct)
    {
        var user = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new { u.TelemetryConsentVersion, u.TelemetryCrash, u.TelemetryUsage })
            .FirstAsync(ct);

        var required = user.TelemetryConsentVersion != TelemetryTerms.Version;
        return new TelemetryConsent(required, !required && user.TelemetryCrash, !required && user.TelemetryUsage);
    }
}
