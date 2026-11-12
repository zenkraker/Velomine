// Issues a Velomine supporter licence key. Run from the repository root without touching the stack:
//
//   dotnet run tools/supporter-key.cs -- gen                 # new key pair: keeps the private key, prints the public one
//   dotnet run tools/supporter-key.cs -- rider "Ada Rossi" 7 # rider licence for serial 7
//   dotnet run tools/supporter-key.cs -- club  "Friday Riders" 8
//
// It reads the private key from the file named by VELOMINE__SUPPORTER__PRIVATEKEYFILE (default .dev/supporter.pem; the
// base64 of the PKCS#8 DER form, not a PEM block) and writes the public key to VELOMINE__SUPPORTER__PUBLICKEYFILE
// (default .dev/supporter.pub; the base64 of the SPKI DER form). The public one goes on the server as
// VELOMINE__SUPPORTER__PUBLICKEY. Both stay in .dev/, which git ignores: the private key is the signer.
using System.Security.Cryptography;
using System.Text.Json;
using System.Text.Json.Serialization;

var privatePath = Environment.GetEnvironmentVariable("VELOMINE__SUPPORTER__PRIVATEKEYFILE") ?? ".dev/supporter.pem";
var publicPath = Environment.GetEnvironmentVariable("VELOMINE__SUPPORTER__PUBLICKEYFILE") ?? ".dev/supporter.pub";

if (args.Length == 1 && args[0] == "gen")
{
    Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(privatePath))!);
    if (File.Exists(privatePath))
    {
        Console.Error.WriteLine($"{privatePath} already exists: refusing to overwrite the signer.");
        return 1;
    }

    using var fresh = ECDsa.Create(ECCurve.NamedCurves.nistP256);
    await File.WriteAllTextAsync(privatePath, Convert.ToBase64String(fresh.ExportPkcs8PrivateKey()));
    var publicText = Convert.ToBase64String(fresh.ExportSubjectPublicKeyInfo());
    await File.WriteAllTextAsync(publicPath, publicText);
    if (!OperatingSystem.IsWindows())
        File.SetUnixFileMode(privatePath, UnixFileMode.UserRead | UnixFileMode.UserWrite);
    Console.WriteLine($"Private key: {privatePath} (keep it secret)");
    Console.WriteLine($"Set on the server: VELOMINE__SUPPORTER__PUBLICKEY={publicText}");
    return 0;
}

if (args.Length != 3 || args[0] is not ("rider" or "club") || !int.TryParse(args[2], out var serial) || serial <= 0)
{
    Console.Error.WriteLine("usage: supporter-key gen | supporter-key (rider|club) \"Holder Name\" <serial>");
    return 2;
}

var (type, holder) = (args[0], args[1]);

// The server refuses a holder over 100 characters, so a key it would reject is never handed out.
if (holder.Trim().Length is 0 or > 100)
{
    Console.Error.WriteLine("the holder's name must be 1 to 100 characters");
    return 2;
}

using var key = ECDsa.Create();
key.ImportPkcs8PrivateKey(Convert.FromBase64String(await File.ReadAllTextAsync(privatePath)), out _);

// The payload is the exact JSON the server checks, written the same way so the bytes match.
var payload = JsonSerializer.SerializeToUtf8Bytes(new Payload(type, holder, serial), PayloadJson.Default.Payload);
var signature = key.SignData(payload, HashAlgorithmName.SHA256, DSASignatureFormat.IeeeP1363FixedFieldConcatenation);
Console.WriteLine($"{Base64Url.Encode(payload)}.{Base64Url.Encode(signature)}");
return 0;

internal static class Base64Url
{
    public static string Encode(byte[] bytes) =>
        Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
}

internal sealed record Payload(string t, string n, int s);

[JsonSourceGenerationOptions(JsonSerializerDefaults.Web)]
[JsonSerializable(typeof(Payload))]
internal sealed partial class PayloadJson : JsonSerializerContext;
