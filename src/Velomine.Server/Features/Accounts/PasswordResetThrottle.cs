using Microsoft.Extensions.Caching.Memory;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// A small in-memory limit for the two anonymous password endpoints. A restart forgets the counts, which is fine:
/// this only stops someone from hammering the server or a mailbox.
/// </summary>
public sealed class PasswordResetThrottle(IMemoryCache cache, TimeProvider clock)
{
    public const int Limit = 20;
    public static readonly TimeSpan Window = TimeSpan.FromMinutes(15);

    private sealed record Counter(DateTimeOffset Start, int Count);

    public bool Allowed(string action, HttpContext context, string? email = null)
    {
        var key = $"password-reset:{action}:{context.Connection.RemoteIpAddress}:{email?.Trim().ToLowerInvariant()}";
        var now = clock.GetUtcNow();
        var counter = cache.Get<Counter>(key);

        if (counter is null || now - counter.Start >= Window)
        {
            cache.Set(key, new Counter(now, 1), new MemoryCacheEntryOptions { AbsoluteExpiration = now.Add(Window) });
            return true;
        }

        if (counter.Count >= Limit) return false;

        cache.Set(key, counter with { Count = counter.Count + 1 },
            new MemoryCacheEntryOptions { AbsoluteExpiration = counter.Start.Add(Window) });
        return true;
    }
}
