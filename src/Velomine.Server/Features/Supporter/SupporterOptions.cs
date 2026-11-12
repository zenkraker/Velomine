using System.Security.Cryptography;

namespace Velomine.Server.Features.Supporter;

/// <summary>
/// Bound from "Velomine:Supporter" (environment: VELOMINE__SUPPORTER__PUBLICKEY). The optional supporter licence is
/// off until the operator sets the issuer's public key; a server without one works exactly the same.
/// </summary>
public sealed class SupporterOptions
{
    /// <summary>The issuer's ECDSA P-256 public key, base64 of the SPKI DER form. Empty turns the feature off.</summary>
    public string? PublicKey { get; set; }

    /// <summary>False when no key is configured: activation answers 503 and no licence is shown.</summary>
    public bool IsConfigured => !string.IsNullOrWhiteSpace(PublicKey);

    /// <summary>The decoded key, or null when the feature is off. A key that does not parse throws at validation.</summary>
    public byte[]? DecodedPublicKey => IsConfigured ? Convert.FromBase64String(PublicKey!.Trim()) : null;
}

public static class SupporterSetup
{
    public static IServiceCollection AddSupporter(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<SupporterOptions>()
            .BindConfiguration("Velomine:Supporter")
            .Validate(o => !o.IsConfigured || Usable(o.PublicKey!), "Velomine:Supporter:PublicKey must be the base64 of an ECDSA P-256 public key in SPKI DER form.")
            .ValidateOnStart();
        return services;
    }

    private static bool Usable(string publicKey)
    {
        try
        {
            using var ecdsa = ECDsa.Create();
            ecdsa.ImportSubjectPublicKeyInfo(Convert.FromBase64String(publicKey.Trim()), out _);
            return ecdsa.ExportParameters(false).Curve.Oid.Value == ECCurve.NamedCurves.nistP256.Oid.Value;
        }
        catch (Exception e) when (e is FormatException or CryptographicException)
        {
            return false;
        }
    }
}
