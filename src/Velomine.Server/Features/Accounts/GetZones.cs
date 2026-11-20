using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// One set of zones as the profile shows it: the bounds in use (fractions of the reference), whether the rider set
/// them, the watts or bpm they give today with where that reference came from, and the ranges.
/// </summary>
public sealed record ZoneSetResponse(
    string Set,
    double[] Bounds,
    bool Custom,
    int? Reference,
    string? ReferenceSource,
    ZoneTime[] Zones);

/// <summary>The three sets of zones, and the heart-rate model they are read against (null when the rider has no number).</summary>
public sealed record ZonesResponse(ZoneSetResponse[] Sets, string? HeartRateModel);

public sealed class GetZones(VelomineDbContext db, TimeProvider time) : EndpointWithoutRequest<ZonesResponse>
{
    public override void Configure()
    {
        Get("accounts/me/zones");
        Description(d => d.Produces<ZonesResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var user = await db.Users.AsNoTracking().FirstAsync(u => u.Id == User.UserId(), ct);
        await Send.OkAsync(ZoneSets.Of(user, time), ct);
    }
}
