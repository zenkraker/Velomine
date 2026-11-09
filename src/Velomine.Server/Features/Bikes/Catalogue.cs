using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Bikes;

/// <summary>Where the shared parts catalogue comes from. Empty <see cref="Url"/> means the bundled seed only.</summary>
public sealed class CatalogueOptions
{
    public string? Url { get; set; }

    /// <summary>How often to look for a newer snapshot, in minutes. At least 5.</summary>
    public int SyncMinutes { get; set; } = 60;

    /// <summary>Whether an empty club gets the bundled seed. On by default; tests turn it off.</summary>
    public bool Seed { get; set; } = true;

    /// <summary>Where an opted-in club sends the parts it adds. Empty means contributions are never sent.</summary>
    public string? ContributeUrl { get; set; }

    /// <summary>The per-deployment key the publisher issued. A secret: configuration only, never the database.</summary>
    public string? ContributionKey { get; set; }

    /// <summary>How often to try the contribution outbox, in minutes.</summary>
    public int ContributeMinutes { get; set; } = 15;
}

/// <summary>The version of the shared catalogue this club has. One row per club database.</summary>
public sealed class CatalogueMeta
{
    public int Id { get; set; } = 1;

    public int Version { get; set; }

    public DateTimeOffset? SyncedAt { get; set; }

    public string? SourceUrl { get; set; }
}

/// <summary>One part in the shared feed. The key is computed locally from these fields, never trusted from the feed.</summary>
public sealed record CatalogueEntry(string? Type, string? Brand, string? Model, string? Mpn, string? Gtin);

/// <summary>The publisher's full list of parts. It is complete every time, so there are no versions or deltas.</summary>
public sealed record CatalogueFeed(CatalogueEntry[] Parts);

public interface ICatalogueSource
{
    /// <summary>The publisher's current full list, or null when the publisher is not configured.</summary>
    Task<CatalogueFeed?> FetchAsync(CancellationToken ct);
}

/// <summary>Mirrors the publisher's full list into this instance. Members never write to it.</summary>
public static class CatalogueSync
{
    public const string SharedSource = "shared";

    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    /// <summary>Fetches and applies the current list. Returns false when there was nothing to apply.</summary>
    public static async Task<bool> RunAsync(VelomineDbContext db, ICatalogueSource source, TimeProvider clock, string? sourceUrl, CancellationToken ct)
    {
        var feed = await source.FetchAsync(ct);
        if (feed is null || !await ApplyAsync(db, feed, ct)) return false;

        var meta = await db.CatalogueMeta.FirstOrDefaultAsync(ct);
        if (meta is null) db.CatalogueMeta.Add(meta = new CatalogueMeta { Id = 1 });
        meta.SyncedAt = clock.GetUtcNow();
        meta.SourceUrl = sourceUrl;
        await db.SaveChangesAsync(ct);
        return true;
    }

    /// <summary>
    /// Upserts the feed's parts, reactivates ones that come back, and retires everything the list leaves out. Returns
    /// false for an empty list, which would retire the whole catalogue and is a publisher mistake.
    /// </summary>
    public static async Task<bool> ApplyAsync(VelomineDbContext db, CatalogueFeed feed, CancellationToken ct)
    {
        var entries = feed.Parts
            .Select(e => (Key: KeyOf(e), Entry: e))
            .Where(x => x.Key is not null)
            .GroupBy(x => x.Key!)
            .Select(g => (Key: g.Key, Entry: g.First().Entry))
            .ToList();

        if (entries.Count == 0) return false;

        var parts = await db.Parts.ToListAsync(ct);
        var byKey = parts.ToDictionary(p => p.Key);

        foreach (var (key, entry) in entries)
        {
            if (!byKey.TryGetValue(key, out var part))
            {
                part = new Part { Id = Guid.CreateVersion7(), Key = key, Source = SharedSource, Confirmations = 0 };
                db.Parts.Add(part);
                byKey[key] = part;
            }
            Apply(part, entry);
            part.Source = SharedSource;
            part.Status = "active";
        }

        var keep = entries.Select(e => e.Key).ToHashSet();
        foreach (var part in parts)
            if (!keep.Contains(part.Key)) part.Status = "retired";

        return true;
    }

    private static string? KeyOf(CatalogueEntry entry)
    {
        var type = entry.Type?.Trim();
        var brand = PartIdentity.CanonicalBrand(entry.Brand);
        var model = Trim(entry.Model, 100);
        if (string.IsNullOrEmpty(type) || !ComponentTypes.Ids.Contains(type) || brand is null || model is null) return null;

        var mpn = PartIdentity.NormaliseMpn(entry.Mpn);
        var gtin = PartIdentity.TryNormaliseGtin(entry.Gtin, out var normalised) ? normalised : null;
        return PartIdentity.Key(type, brand, model, mpn, gtin);
    }

    private static void Apply(Part part, CatalogueEntry entry)
    {
        part.Type = entry.Type!.Trim();
        part.Brand = Trim(PartIdentity.CanonicalBrand(entry.Brand), 100)!;
        part.Model = Trim(entry.Model, 100)!;
        part.Mpn = Trim(PartIdentity.NormaliseMpn(entry.Mpn), 64);
        part.Gtin = PartIdentity.TryNormaliseGtin(entry.Gtin, out var gtin) ? gtin : null;
    }

    private static string? Trim(string? value, int max)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        var trimmed = value.Trim();
        return trimmed.Length <= max ? trimmed : trimmed[..max];
    }

    internal static JsonSerializerOptions JsonOptions => Json;
}

/// <summary>The bundled seed: the same parts every club starts with, shipped with the release.</summary>
public static class CatalogueSeed
{
    public const string ResourceName = "Velomine.Server.Features.Bikes.parts-seed.json";

    /// <summary>Loads the seed once per database. Returns false when the club already has a catalogue.</summary>
    public static async Task<bool> EnsureSeededAsync(VelomineDbContext db, TimeProvider clock, CancellationToken ct)
    {
        if (await db.CatalogueMeta.AnyAsync(ct)) return false;
        var feed = await ReadAsync(ct);
        if (feed is null || !await CatalogueSync.ApplyAsync(db, feed, ct)) return false;

        db.CatalogueMeta.Add(new CatalogueMeta
        {
            Id = 1,
            SyncedAt = clock.GetUtcNow(),
        });
        await db.SaveChangesAsync(ct);
        return true;
    }

    private static async Task<CatalogueFeed?> ReadAsync(CancellationToken ct)
    {
        await using var stream = typeof(CatalogueSeed).Assembly.GetManifestResourceStream(ResourceName);
        return stream is null
            ? null
            : await JsonSerializer.DeserializeAsync<CatalogueFeed>(stream, CatalogueSync.JsonOptions, ct);
    }
}
