using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Clubs;

/// <summary>Short codes that people read out loud or put in a link, without 0/o or 1/i confusion.</summary>
public static class JoinCodes
{
    private const string Alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private const int Length = 8;

    public static string New() => string.Create(
        Length,
        Alphabet,
        static (span, alphabet) =>
        {
            for (var i = 0; i < span.Length; i++) span[i] = alphabet[RandomNumberGenerator.GetInt32(alphabet.Length)];
        });

    /// <summary>A code no other club uses. The unique index is the real guard; this keeps a clash vanishingly rare.</summary>
    public static async Task<string> UniqueAsync(VelomineDbContext db, CancellationToken ct)
    {
        for (var attempt = 0; attempt < 10; attempt++)
        {
            var code = New();
            if (!await db.Clubs.AnyAsync(c => c.JoinCode == code, ct)) return code;
        }

        throw new InvalidOperationException("Could not find an unused club join code.");
    }
}
