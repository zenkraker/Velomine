using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

public sealed record CatalogueCountsResponse(int Pending, int Sent, int Rejected, int Failed);

/// <summary>A part the publisher refused or this instance gave up on, with the reason, so an admin can act on it.</summary>
public sealed record CatalogueContributionResponse(
    Guid Id,
    string Type,
    string TypeName,
    string Brand,
    string Model,
    string? Mpn,
    string? Gtin,
    string Status,
    int Attempts,
    string? Reason,
    DateTimeOffset CreatedAt);

/// <summary>
/// The shared catalogue as an admin sees it: whether a publisher is configured, when the list was last fetched, and
/// the contributions that did not make it. The URL and key are reported as on or off, never shown.
/// </summary>
public sealed record CatalogueAdminResponse(
    bool ContributionEndpointConfigured,
    bool ContributionKeyConfigured,
    DateTimeOffset? SyncedAt,
    CatalogueCountsResponse Contributions,
    CatalogueContributionResponse[] Problems);

public sealed class GetCatalogue(VelomineDbContext db, IOptions<CatalogueOptions> options)
    : EndpointWithoutRequest<CatalogueAdminResponse>
{
    public override void Configure()
    {
        Get("admin/catalogue");
        Roles(Accounts.Roles.Admin);
        Description(d => d.Produces<CatalogueAdminResponse>(200).Produces(401).Produces(403), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct) =>
        await Send.OkAsync(await StatusAsync(db, options.Value, ct), ct);

    public static async Task<CatalogueAdminResponse> StatusAsync(
        VelomineDbContext db, CatalogueOptions options, CancellationToken ct)
    {
        var counts = await db.PartContributions.AsNoTracking()
            .GroupBy(c => c.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Status, x => x.Count, ct);

        var meta = await db.CatalogueMeta.AsNoTracking().FirstOrDefaultAsync(ct);
        var problems = (await db.PartContributions.AsNoTracking()
                .Where(c => c.Status == "rejected" || c.Status == "failed")
                .OrderByDescending(c => c.CreatedAt)
                .Take(50)
                .ToListAsync(ct))
            .Select(c => new CatalogueContributionResponse(
                c.Id, c.Type, ComponentTypes.NameOf(c.Type), c.Brand, c.Model, c.Mpn, c.Gtin,
                c.Status, c.Attempts, c.Reason, c.CreatedAt))
            .ToArray();

        return new CatalogueAdminResponse(
            !string.IsNullOrWhiteSpace(options.ContributeUrl),
            !string.IsNullOrWhiteSpace(options.ContributionKey),
            meta?.SyncedAt,
            new CatalogueCountsResponse(
                counts.GetValueOrDefault("pending"),
                counts.GetValueOrDefault("sent"),
                counts.GetValueOrDefault("rejected"),
                counts.GetValueOrDefault("failed")),
            problems);
    }
}
