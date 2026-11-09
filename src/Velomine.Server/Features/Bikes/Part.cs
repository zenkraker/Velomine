using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Bikes;

/// <summary>
/// A part the club knows: a name to pick from, and, where possible, the official code that identifies it. The key is
/// what matching uses; the name is only for people. A part is per club (the tenant's database), never shared between
/// clubs through the database; the shared catalogue is a separate dataset that fills the same table.
/// </summary>
public sealed class Part
{
    public Guid Id { get; set; }

    /// <summary>What identifies this part: a GTIN, else brand and manufacturer part number, else type, brand and model.</summary>
    public string Key { get; set; } = "";

    /// <summary>An id from <see cref="ComponentTypes"/>.</summary>
    public string Type { get; set; } = "";

    public string Brand { get; set; } = "";

    public string Model { get; set; } = "";

    public string? Mpn { get; set; }

    /// <summary>The barcode, normalised to GTIN-14.</summary>
    public string? Gtin { get; set; }

    /// <summary>local (entered in this club) or shared (from the shared catalogue dataset).</summary>
    public string Source { get; set; } = "local";

    /// <summary>active, conflicted or retired. Only active parts are offered.</summary>
    public string Status { get; set; } = "active";

    /// <summary>How many times the club has confirmed this part. Only a hint for ordering suggestions.</summary>
    public int Confirmations { get; set; } = 1;

    public DateTimeOffset CreatedAt { get; set; }

    public uint Version { get; set; }
}

/// <summary>
/// How a part is recognised. A display name is never part of the key: two people write "Shimano CN-M8100" and
/// "shimano CN M8100", and the key still has to match. The rules here are the whole of the deterministic matching.
/// </summary>
public static class PartIdentity
{
    /// <summary>Brands that the industry and shops write in more than one way; the key is lowercase anyway, this fixes the name.</summary>
    private static readonly Dictionary<string, string> BrandNames = new(StringComparer.Ordinal)
    {
        ["shimano"] = "Shimano",
        ["shimano inc"] = "Shimano",
        ["shimano inc."] = "Shimano",
        ["sram"] = "SRAM",
        ["sram corporation"] = "SRAM",
        ["campagnolo"] = "Campagnolo",
        ["campagnolo s.r.l."] = "Campagnolo",
        ["campagnolo srl"] = "Campagnolo",
        ["fox racing shox"] = "FOX",
        ["dt swiss"] = "DT Swiss",
        ["e*thirteen"] = "e*thirteen",
        ["rockshox"] = "RockShox",
        ["rock shox"] = "RockShox",
        ["bontrager"] = "Bontrager",
        ["specialized"] = "Specialized",
        ["trek"] = "Trek",
        ["giant"] = "Giant",
        ["canyon"] = "Canyon",
        ["cube"] = "Cube",
        ["merida"] = "Merida",
        ["scott"] = "Scott",
        ["orbea"] = "Orbea",
        ["bianchi"] = "Bianchi",
        ["cervelo"] = "Cervelo",
        ["cervélo"] = "Cervélo",
        ["pinarello"] = "Pinarello",
        ["bmc"] = "BMC",
        ["cannondale"] = "Cannondale",
        ["santa cruz"] = "Santa Cruz",
        ["yet"] = "Yeti",
        ["yeti"] = "Yeti",
        ["pivot"] = "Pivot",
        ["commencal"] = "Commencal",
        ["norco"] = "Norco",
        ["marin"] = "Marin",
        ["fuji"] = "Fuji",
        ["ridley"] = "Ridley",
        ["look"] = "Look",
        ["colnago"] = "Colnago",
        ["wilier"] = "Wilier",
        ["lapierre"] = "Lapierre",
        ["ghost"] = "Ghost",
        ["haibike"] = "Haibike",
        ["radon"] = "Radon",
        ["rose"] = "Rose",
        ["stevens"] = "Stevens",
        ["ktm"] = "KTM",
        ["bulls"] = "Bulls",
    };

    /// <summary>The brand as people should see it; unknown brands keep the spelling the member used.</summary>
    public static string? CanonicalBrand(string? brand)
    {
        var trimmed = Collapse(brand);
        if (trimmed is null) return null;
        return BrandNames.TryGetValue(trimmed.ToLowerInvariant(), out var known) ? known : trimmed;
    }

    /// <summary>The part number as typed, minus stray whitespace. Case is kept for display; the key upper-cases it.</summary>
    public static string? NormaliseMpn(string? mpn) => Collapse(mpn);

    /// <summary>The key a part is matched on, or null when there is nothing to match it by.</summary>
    public static string? Key(string type, string? brand, string? model, string? mpn, string? gtin)
    {
        // The type is part of every key: the front and the rear brake pad are the same product but two parts on the
        // bike, and a suggestion for one must not turn up while the member is adding the other.
        if (TryNormaliseGtin(gtin, out var gtin14)) return "gtin:" + type + ":" + gtin14;

        var brandKey = CanonicalBrand(brand)?.ToLowerInvariant();
        var mpnKey = NormaliseMpn(mpn)?.ToUpperInvariant();
        if (brandKey is not null && mpnKey is not null) return "mpn:" + type + ":" + brandKey + "|" + mpnKey;

        var modelKey = Collapse(model)?.ToLowerInvariant();
        if (!string.IsNullOrWhiteSpace(type) && brandKey is not null && modelKey is not null)
            return "name:" + type + "|" + brandKey + "|" + modelKey;

        return null;
    }

    /// <summary>
    /// A barcode as GTIN-14, or false when it is not a well-formed GTIN-8, UPC-A, EAN-13 or GTIN-14 with a valid
    /// check digit. This is the only validation there is: no lookup, no guessing.
    /// </summary>
    public static bool TryNormaliseGtin(string? value, out string gtin14)
    {
        gtin14 = "";
        var digits = value?.Trim();
        if (string.IsNullOrEmpty(digits)) return false;
        if (digits.Any(c => c is < '0' or > '9')) return false;
        if (digits.Length is not (8 or 12 or 13 or 14)) return false;

        var sum = 0;
        for (int i = digits.Length - 2, weight = 3; i >= 0; i--, weight = 4 - weight)
            sum += (digits[i] - '0') * weight;
        if ((10 - sum % 10) % 10 != digits[^1] - '0') return false;

        gtin14 = digits.PadLeft(14, '0');
        return true;
    }

    /// <summary>Trimmed with runs of whitespace collapsed to one space; null when there is nothing left.</summary>
    private static string? Collapse(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        return string.Join(' ', value.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
    }
}

/// <summary>
/// Looks a component up in the shared catalogue. A member never adds to that catalogue: a part that is not in it is
/// offered to the publisher instead, and appears for everyone after the publisher lists it.
/// </summary>
public static class PartCatalogue
{
    /// <summary>The shared part this component is, or null when the catalogue does not list it (yet).</summary>
    public static async Task<Part?> FindAsync(VelomineDbContext db, BikeComponent component, CancellationToken ct)
    {
        var key = PartIdentity.Key(component.Type, component.Brand, component.Model, component.Mpn, component.Gtin);
        if (key is null) return null;

        return await db.Parts.AsNoTracking()
            .FirstOrDefaultAsync(p => p.Key == key && p.Status == "active", ct);
    }
}
