using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Caching.Memory;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// A small in-memory limit for the two anonymous password endpoints. A restart forgets the counts, which is fine:
/// this only stops someone from hammering the server or a mailbox.
/// <para>
/// "forgot" asks about one address: the limit is per account, so a member can ask a few times, nobody can flood a
/// mailbox, and a whole office behind one address does not spend a shared budget. "reset" redeems a token: it is
/// limited per calling address, because a guess is aimed at an account the caller chooses.
/// </para>
/// <para>
/// Both windows start there and are not extended by refusals, so a caller is served again once the window has passed
/// instead of being locked out by its own attempts.
/// </para>
/// </summary>
public sealed class PasswordResetThrottle(IMemoryCache cache, TimeProvider clock)
{
    /// <summary>Asks about one account within <see cref="Window"/>: enough for a member who did not get the first email.</summary>
    public const int ForgotLimit = 5;

    /// <summary>Token attempts from one address within <see cref="Window"/>.</summary>
    public const int ResetLimit = 20;

    public static readonly TimeSpan Window = TimeSpan.FromMinutes(15);

    private sealed record Counter(DateTimeOffset Start, int Count);

    /// <summary>Whether this ask about <paramref name="email"/> may go ahead.</summary>
    public bool AllowedForEmail(string email) => Counted($"forgot:{Hash(email)}", ForgotLimit);

    /// <summary>Whether a reset attempt from this context's address may go ahead.</summary>
    public bool AllowedFromAddress(HttpContext context) =>
        Counted($"reset:{context.Connection.RemoteIpAddress?.ToString() ?? "unknown"}", ResetLimit);

    /// <summary>
    /// The address is only ever held as a hash, so a cache dump does not list who asked. It is not logged, answered or
    /// used for anything else.
    /// </summary>
    private static string Hash(string email) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(email.Trim().ToLowerInvariant())));

    private bool Counted(string key, int limit)
    {
        var now = clock.GetUtcNow();
        var counter = cache.Get<Counter>(key);

        if (counter is null || now - counter.Start >= Window)
        {
            cache.Set(key, new Counter(now, 1), now + Window);
            return true;
        }

        if (counter.Count >= limit) return false;

        cache.Set(key, counter with { Count = counter.Count + 1 }, counter.Start + Window);
        return true;
    }
}
