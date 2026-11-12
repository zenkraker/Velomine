using System.Security.Cryptography;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Velomine.Server.Features.Supporter;

/// <summary>
/// A supporter licence paid once: a rider's, held by one account, or a club's. It never expires and unlocks nothing;
/// it only shows a badge the holder can hide. The signed key names the holder and this table records who activated it.
/// </summary>
public sealed class Licence
{
    public Guid Id { get; set; }

    /// <summary>Set for a rider licence: the account that activated it.</summary>
    public Guid? UserId { get; set; }

    /// <summary>Set for a club licence: the club it belongs to.</summary>
    public Guid? ClubId { get; set; }

    /// <summary>The name written into the signed key.</summary>
    public string Holder { get; set; } = "";

    /// <summary>The serial in the signed key. Unique, so the same key cannot be activated twice.</summary>
    public int Serial { get; set; }

    public DateTimeOffset ActivatedAt { get; set; }

    /// <summary>Whether the badge is hidden. A licence still counts; only the badge is hidden.</summary>
    public bool Hidden { get; set; }
}

public static class LicenceKinds
{
    public const string Rider = "rider";
    public const string Club = "club";

    public static bool IsKnown(string kind) => kind is Rider or Club;
}

/// <summary>What a signed key says: the type, the holder's name and the serial.</summary>
public sealed record LicencePayload(
    [property: JsonPropertyName("t")] string Type,
    [property: JsonPropertyName("n")] string Holder,
    [property: JsonPropertyName("s")] int Serial)
{
    public static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
}

/// <summary>
/// Verifies a licence key: <c>&lt;payload&gt;.&lt;sig&gt;</c>, both base64url. The payload is the UTF-8 JSON of
/// <see cref="LicencePayload"/>; the signature is ECDSA P-256 over the SHA-256 of the exact payload bytes. Only the
/// public key is on the server, so a key can be checked but never made here.
/// </summary>
public static class LicenceKeys
{
    /// <summary>The payload and signature, or null when the key is not even shaped like one.</summary>
    public static (byte[] Payload, byte[] Signature)? Split(string key)
    {
        var parts = key.Trim().Split('.');
        if (parts.Length != 2 || parts[0].Length == 0 || parts[1].Length == 0) return null;
        try
        {
            return (Base64Url.Decode(parts[0]), Base64Url.Decode(parts[1]));
        }
        catch (FormatException)
        {
            return null;
        }
    }

    /// <summary>The payload, or null when the signature does not match or the payload is not a licence.</summary>
    public static LicencePayload? Verify(string key, byte[] publicKey)
    {
        if (Split(key) is not var (payload, signature)) return null;

        using var ecdsa = ECDsa.Create();
        try
        {
            ecdsa.ImportSubjectPublicKeyInfo(publicKey, out _);
        }
        catch (CryptographicException)
        {
            return null;
        }

        if (!ecdsa.VerifyData(payload, signature, HashAlgorithmName.SHA256, DSASignatureFormat.IeeeP1363FixedFieldConcatenation))
            return null;

        LicencePayload? licence;
        try
        {
            licence = JsonSerializer.Deserialize<LicencePayload>(payload, LicencePayload.Json);
        }
        catch (JsonException)
        {
            return null;
        }

        return licence is not null && LicenceKinds.IsKnown(licence.Type) && licence.Serial > 0
            && licence.Holder is { Length: > 0 and <= MaxHolderLength } && !string.IsNullOrWhiteSpace(licence.Holder)
            ? licence
            : null;
    }

    /// <summary>The holder's name, the same limit the database column has.</summary>
    public const int MaxHolderLength = 100;
}

/// <summary>base64url without padding, the shape used in URLs and licence keys.</summary>
public static class Base64Url
{
    public static string Encode(byte[] bytes) =>
        Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');

    public static byte[] Decode(string text)
    {
        var base64 = text.Replace('-', '+').Replace('_', '/');
        return Convert.FromBase64String(base64.PadRight(base64.Length + (4 - base64.Length % 4) % 4, '='));
    }
}
