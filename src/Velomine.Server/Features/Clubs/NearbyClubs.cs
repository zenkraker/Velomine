using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

public sealed class NearbyClubsRequest
{
    /// <summary>Where the rider is now. Sent in the body so it stays out of access logs.</summary>
    public double Latitude { get; set; }

    public double Longitude { get; set; }

    /// <summary>How far to look, 1 to 200 km.</summary>
    public int RadiusKm { get; set; } = 50;
}

public sealed class NearbyClubsValidator : Validator<NearbyClubsRequest>
{
    public NearbyClubsValidator()
    {
        RuleFor(x => x.Latitude).InclusiveBetween(-90, 90);
        RuleFor(x => x.Longitude).InclusiveBetween(-180, 180);
        RuleFor(x => x.RadiusKm).InclusiveBetween(1, 200);
    }
}

/// <summary>A discoverable club, with a rounded distance and no exact position.</summary>
public sealed record NearbyClubResponse(Guid Id, string Name, int MemberCount, double DistanceKm);

public sealed record NearbyClubsResponse(NearbyClubResponse[] Clubs);

/// <summary>Active, discoverable clubs within the radius, nearest first. Only the owner opens a club to discovery.</summary>
public sealed class NearbyClubs(VelomineDbContext db) : Endpoint<NearbyClubsRequest, NearbyClubsResponse>
{
    private const int MaxResults = 50;

    public override void Configure()
    {
        Post("club/nearby");
        Description(d => d.Accepts<NearbyClubsRequest>("application/json").Produces<NearbyClubsResponse>(200).ProducesProblem(400).Produces(401).ProducesProblem(409), clearDefaults: true);
    }

    public override async Task HandleAsync(NearbyClubsRequest req, CancellationToken ct)
    {
        // Discovery is for riders looking for a club; someone who already has one is not shown the others.
        if (await db.ClubMemberships.AnyAsync(m => m.UserId == User.UserId(), ct))
        {
            AddError("You are already in a club.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        var clubs = await db.Clubs.AsNoTracking()
            .Where(c => c.IsActive && c.IsDiscoverable && c.Latitude != null && c.Longitude != null)
            .Select(c => new
            {
                c.Id,
                c.Name,
                c.Latitude,
                c.Longitude,
                MemberCount = c.Memberships.Count,
            })
            .ToListAsync(ct);

        var nearby = clubs
            .Select(c => new NearbyClubResponse(
                c.Id,
                c.Name,
                c.MemberCount,
                // Whole kilometres: enough to choose, too coarse to pin the club down by triangulating.
                Math.Round(DistanceKm(req.Latitude, req.Longitude, c.Latitude!.Value, c.Longitude!.Value))))
            .Where(c => c.DistanceKm <= req.RadiusKm)
            .OrderBy(c => c.DistanceKm)
            .ThenBy(c => c.Name, StringComparer.OrdinalIgnoreCase)
            .Take(MaxResults)
            .ToArray();

        await Send.OkAsync(new NearbyClubsResponse(nearby), ct);
    }

    /// <summary>The great-circle distance in kilometres. A handful of clubs fit well in memory.</summary>
    private static double DistanceKm(double latitude, double longitude, double otherLatitude, double otherLongitude)
    {
        const double earthKm = 6371.0;
        static double Radians(double degrees) => degrees * Math.PI / 180;

        var dLat = Radians(otherLatitude - latitude);
        var dLon = Radians(otherLongitude - longitude);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(Radians(latitude)) * Math.Cos(Radians(otherLatitude)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        return earthKm * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    }
}
