using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Bikes;

/// <summary>A part the club already knows, as offered while a member types.</summary>
public sealed record PartResponse(Guid Id, string Type, string Brand, string Model, string? Mpn, string? Gtin, int Confirmations);

public sealed record SearchPartsResponse(PartResponse[] Parts);

public sealed class SearchPartsRequest
{
    /// <summary>Part of the brand, the model or the manufacturer part number.</summary>
    public string? Q { get; set; }

    /// <summary>An id from the component types list, to keep the suggestions to the part being added.</summary>
    public string? Type { get; set; }

    /// <summary>The exact brand, when the member has already typed one.</summary>
    public string? Brand { get; set; }

    /// <summary>At most 25; 10 when left out.</summary>
    public int? Limit { get; set; }
}

/// <summary>Parts this club has used before, most used first. A suggestion, never a claim about what fits.</summary>
public sealed class SearchParts(VelomineDbContext db) : Endpoint<SearchPartsRequest, SearchPartsResponse>
{
    public override void Configure()
    {
        Get("bikes/parts");
        Description(d => d.Produces<SearchPartsResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(SearchPartsRequest req, CancellationToken ct)
    {
        var query = db.Parts.AsNoTracking().Where(p => p.Status == "active");

        if (!string.IsNullOrWhiteSpace(req.Type)) query = query.Where(p => p.Type == req.Type);

        var brandKey = PartIdentity.CanonicalBrand(req.Brand)?.ToLowerInvariant();
        if (brandKey is not null) query = query.Where(p => p.Brand.ToLower() == brandKey);

        if (!string.IsNullOrWhiteSpace(req.Q))
        {
            var pattern = "%" + EscapeLike(req.Q.Trim()) + "%";
            query = query.Where(p =>
                EF.Functions.ILike(p.Brand + " " + p.Model, pattern, "\\") ||
                (p.Mpn != null && EF.Functions.ILike(p.Mpn, pattern, "\\")));
        }

        var parts = await query
            .OrderByDescending(p => p.Confirmations).ThenBy(p => p.Brand).ThenBy(p => p.Model)
            .Take(Math.Clamp(req.Limit ?? 10, 1, 25))
            .Select(p => new PartResponse(p.Id, p.Type, p.Brand, p.Model, p.Mpn, p.Gtin, p.Confirmations))
            .ToListAsync(ct);

        await Send.OkAsync(new SearchPartsResponse([.. parts]), ct);
    }

    /// <summary>"%" and "_" are wildcards in LIKE; a member typing them means the characters.</summary>
    private static string EscapeLike(string value) =>
        value.Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_");
}
