using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Bikes;

/// <summary>
/// One part waiting to go to the shared catalogue. It carries only the part's identity and name: no member, bike,
/// club or address is stored with it, and the publisher sees no such field. Rows stay after sending as a record of
/// what happened; they are what the admin page reports.
/// </summary>
public sealed class PartContribution
{
    public Guid Id { get; set; }

    public string Key { get; set; } = "";

    public string Type { get; set; } = "";

    public string Brand { get; set; } = "";

    public string Model { get; set; } = "";

    public string? Mpn { get; set; }

    public string? Gtin { get; set; }

    /// <summary>Hash of the fields above, so the same part is never queued twice.</summary>
    public string PayloadHash { get; set; } = "";

    /// <summary>pending, sent, rejected or failed.</summary>
    public string Status { get; set; } = "pending";

    public int Attempts { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset NextAttemptAt { get; set; }

    public DateTimeOffset? SentAt { get; set; }

    /// <summary>The publisher's reason when it rejected the part, or why this instance gave up.</summary>
    public string? Reason { get; set; }
}

/// <summary>What goes over the wire: the part alone.</summary>
public sealed record ContributionEntry(string Key, string Type, string Brand, string Model, string? Mpn, string? Gtin)
{
    public static ContributionEntry From(BikeComponent component) => new(
        PartIdentity.Key(component.Type, component.Brand, component.Model, component.Mpn, component.Gtin)!,
        component.Type,
        PartIdentity.CanonicalBrand(component.Brand) ?? "",
        component.Model?.Trim() ?? "",
        PartIdentity.NormaliseMpn(component.Mpn),
        PartIdentity.TryNormaliseGtin(component.Gtin, out var gtin) ? gtin : null);

    /// <summary>A stable hash of every field, so a repeat of the same part is not sent again.</summary>
    public string Hash()
    {
        var canonical = string.Join('\u001f', Key, Type, Brand, Model, Mpn ?? "", Gtin ?? "");
        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(canonical)));
    }
}

public sealed record ContributionSubmission(ContributionEntry[] Parts);

public sealed record ContributionRejection(string Key, string? Reason);

/// <summary>The publisher's answer: every key it accepted, and every key it refused with a reason.</summary>
public sealed record ContributionReceipt(string[]? Accepted, ContributionRejection[]? Rejected);

/// <summary>Queues a non-custom part that is not in the shared catalogue, so the publisher can list it.</summary>
public static class ContributionOutbox
{
    /// <summary>The catalogue key of the part as it is now, or null when it has none.</summary>
    public static string? KeyOf(BikeComponent component) =>
        PartIdentity.Key(component.Type, component.Brand, component.Model, component.Mpn, component.Gtin);

    /// <summary>
    /// Drops a copy that has not been sent yet. An edit or a switch to "custom" must not let the old values reach the
    /// publisher.
    /// </summary>
    public static async Task DiscardPendingAsync(VelomineDbContext db, BikeComponent component, CancellationToken ct)
    {
        if (KeyOf(component) is not { } key) return;
        var pending = await db.PartContributions
            .Where(c => c.Key == key && c.Status == "pending")
            .ToListAsync(ct);
        if (pending.Count == 0) return;
        // Saved here so the row is really gone before the new values are queued, even when nothing changed.
        db.PartContributions.RemoveRange(pending);
        await db.SaveChangesAsync(ct);
    }

    public static async Task EnqueueAsync(VelomineDbContext db, BikeComponent component, TimeProvider clock, CancellationToken ct)
    {
        if (KeyOf(component) is null) return;

        var entry = ContributionEntry.From(component);
        var hash = entry.Hash();
        // A removed row is still visible here; it must not count as already queued.
        if (db.ChangeTracker.Entries<PartContribution>().Any(e => e.State != EntityState.Deleted
            && e.Entity.Key == entry.Key && e.Entity.PayloadHash == hash)) return;
        if (await db.PartContributions.AnyAsync(c => c.Key == entry.Key && c.PayloadHash == hash, ct)) return;

        var now = clock.GetUtcNow();
        db.PartContributions.Add(new PartContribution
        {
            Id = Guid.CreateVersion7(),
            Key = entry.Key,
            Type = entry.Type,
            Brand = entry.Brand,
            Model = entry.Model,
            Mpn = entry.Mpn,
            Gtin = entry.Gtin,
            PayloadHash = hash,
            CreatedAt = now,
            NextAttemptAt = now,
        });
    }
}

/// <summary>Pushes the outbox to the publisher and records exactly what it said. Never logs a part or the key.</summary>
public static class ContributionPush
{
    public const int BatchSize = 50;
    public const int MaxAttempts = 10;

    public static async Task<int> RunAsync(
        VelomineDbContext db,
        HttpClient client,
        CatalogueOptions options,
        TimeProvider clock,
        ILogger? logger,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(options.ContributeUrl) || string.IsNullOrWhiteSpace(options.ContributionKey)) return 0;

        var now = clock.GetUtcNow();
        var batch = await db.PartContributions
            .Where(c => c.Status == "pending" && c.NextAttemptAt <= now)
            .OrderBy(c => c.CreatedAt)
            .Take(BatchSize)
            .ToListAsync(ct);
        if (batch.Count == 0) return 0;

        try
        {
            var submission = new ContributionSubmission([.. batch.Select(c =>
                new ContributionEntry(c.Key, c.Type, c.Brand, c.Model, c.Mpn, c.Gtin))]);

            using var request = new HttpRequestMessage(HttpMethod.Post, options.ContributeUrl)
            {
                Content = JsonContent.Create(submission, options: CatalogueSync.JsonOptions),
            };
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", options.ContributionKey);

            using var response = await client.SendAsync(request, ct);
            response.EnsureSuccessStatusCode();

            var receipt = await response.Content.ReadFromJsonAsync<ContributionReceipt>(CatalogueSync.JsonOptions, ct)
                ?? throw new InvalidOperationException("The catalogue publisher sent no answer.");
            var accepted = (receipt.Accepted ?? []).ToHashSet(StringComparer.Ordinal);
            var rejected = (receipt.Rejected ?? []).ToDictionary(r => r.Key, r => r.Reason, StringComparer.Ordinal);
            var sentAt = clock.GetUtcNow();

            foreach (var item in batch)
            {
                if (accepted.Contains(item.Key))
                {
                    item.Status = "sent";
                    item.SentAt = sentAt;
                    item.Reason = null;
                }
                else if (rejected.TryGetValue(item.Key, out var reason))
                {
                    item.Status = "rejected";
                    item.SentAt = sentAt;
                    item.Reason = Short(reason) ?? "The publisher rejected this part.";
                }
                else
                {
                    Retry(item, sentAt);
                }
            }

            await db.SaveChangesAsync(ct);
            return batch.Count;
        }
        catch (Exception) when (!ct.IsCancellationRequested)
        {
            Retry(batch, clock.GetUtcNow());
            await db.SaveChangesAsync(ct);
            logger?.LogWarning("The shared parts catalogue could not be reached for {Count} contribution(s).", batch.Count);
            return 0;
        }
    }

    private static void Retry(IEnumerable<PartContribution> items, DateTimeOffset now)
    {
        foreach (var item in items) Retry(item, now);
    }

    private static void Retry(PartContribution item, DateTimeOffset now)
    {
        item.Attempts++;
        if (item.Attempts >= MaxAttempts)
        {
            item.Status = "failed";
            item.Reason = "The shared catalogue did not accept this part after several tries.";
            return;
        }

        // Five minutes, doubling, capped at a day: an outage is not a reason to hammer the publisher.
        var minutes = Math.Min(24 * 60, 5 * Math.Pow(2, Math.Min(item.Attempts, 8)));
        item.NextAttemptAt = now.AddMinutes(minutes);
    }

    private static string? Short(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Length <= 500 ? value : value[..500];
}
