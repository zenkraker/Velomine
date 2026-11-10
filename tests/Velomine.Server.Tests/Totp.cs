using System.Security.Cryptography;
using System.Text;

namespace Velomine.Server.Tests;

/// <summary>An authenticator app, in one method: RFC 6238 TOTP over the base32 key Identity hands out.</summary>
internal static class Totp
{
    public static string Code(string base32Key, DateTimeOffset when)
    {
        var counter = when.ToUnixTimeSeconds() / 30;
        var message = BitConverter.GetBytes(counter);
        if (BitConverter.IsLittleEndian) Array.Reverse(message);

        using var hmac = new HMACSHA1(Base32Decode(base32Key));
        var hash = hmac.ComputeHash(message);
        var offset = hash[^1] & 0x0f;
        var value = ((hash[offset] & 0x7f) << 24)
            | (hash[offset + 1] << 16)
            | (hash[offset + 2] << 8)
            | hash[offset + 3];
        return (value % 1_000_000).ToString("D6");
    }

    private static byte[] Base32Decode(string input)
    {
        const string alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
        var bits = new StringBuilder();
        foreach (var c in input.TrimEnd('=').ToUpperInvariant())
            bits.Append(Convert.ToString(alphabet.IndexOf(c), 2).PadLeft(5, '0'));

        var bytes = new byte[bits.Length / 8];
        for (var i = 0; i < bytes.Length; i++)
            bytes[i] = Convert.ToByte(bits.ToString(i * 8, 8), 2);
        return bytes;
    }
}
