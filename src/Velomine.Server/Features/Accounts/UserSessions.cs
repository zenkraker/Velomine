using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

/// <summary>The one place that writes <see cref="UserSession"/> rows.</summary>
public sealed class UserSessions(
    VelomineDbContext db,
    IOptionsMonitor<BearerTokenOptions> bearer,
    TimeProvider clock)
{
    /// <summary>A label the member can recognise, short enough to fit one line.</summary>
    public static string NormalizeLabel(string? label)
    {
        var trimmed = label?.Trim();
        if (string.IsNullOrEmpty(trimmed)) return "Unknown device";
        return trimmed.Length <= 60 ? trimmed : trimmed[..60];
    }

    private TimeSpan Lifetime() => bearer.Get(IdentityConstants.BearerScheme).RefreshTokenExpiration;

    public async Task<UserSession> CreateAsync(Guid userId, string? label, CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        var session = new UserSession
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Label = NormalizeLabel(label),
            CreatedAt = now,
            LastUsedAt = now,
            ExpiresAt = now.Add(Lifetime()),
        };
        db.UserSessions.Add(session);
        await db.SaveChangesAsync(ct);
        return session;
    }

    public Task<UserSession?> FindAsync(Guid id, CancellationToken ct) =>
        db.UserSessions.AsNoTracking().FirstOrDefaultAsync(s => s.Id == id, ct);

    /// <summary>Marks the session as seen, when it still belongs to that member and is usable.</summary>
    public async Task<bool> TouchAsync(Guid id, Guid userId, CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        return await db.UserSessions
            .Where(s => s.Id == id && s.UserId == userId && s.RevokedAt == null && s.ExpiresAt > now)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.LastUsedAt, now), ct) > 0;
    }

    /// <summary>
    /// Spends the presented refresh token: only the current generation may rotate. A stale generation means the token
    /// was used twice, so null is returned and the caller revokes the session.
    /// </summary>
    public async Task<int?> RotateAsync(Guid id, Guid userId, int expectedGeneration, CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        var updated = await db.UserSessions
            .Where(s => s.Id == id && s.UserId == userId
                && s.Generation == expectedGeneration && s.RevokedAt == null && s.ExpiresAt > now)
            .ExecuteUpdateAsync(s => s
                .SetProperty(x => x.Generation, expectedGeneration + 1)
                .SetProperty(x => x.LastUsedAt, now)
                .SetProperty(x => x.ExpiresAt, now.Add(Lifetime())), ct);
        return updated == 1 ? expectedGeneration + 1 : null;
    }

    /// <summary>False when the session is not the member's (or no longer exists), which the endpoint answers as 404.</summary>
    public async Task<bool> RevokeAsync(Guid id, Guid userId, CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        return await db.UserSessions
            .Where(s => s.Id == id && s.UserId == userId)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.RevokedAt, now), ct) > 0;
    }

    public Task RevokeOthersAsync(Guid userId, Guid keepId, CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        return db.UserSessions
            .Where(s => s.UserId == userId && s.Id != keepId && s.RevokedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.RevokedAt, now), ct);
    }

    public Task RevokeAllAsync(Guid userId, CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        return db.UserSessions
            .Where(s => s.UserId == userId && s.RevokedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.RevokedAt, now), ct);
    }

    public Task<List<UserSession>> ListActiveAsync(Guid userId, CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        return db.UserSessions.AsNoTracking()
            .Where(s => s.UserId == userId && s.RevokedAt == null && s.ExpiresAt > now)
            .OrderByDescending(s => s.LastUsedAt)
            .ToListAsync(ct);
    }

    /// <summary>Rows only exist while they mean something; a week is enough to notice a device that vanished.</summary>
    public Task<int> DeleteStaleAsync(DateTimeOffset now, CancellationToken ct)
    {
        var cutoff = now.AddDays(-7);
        return db.UserSessions
            .Where(s => s.ExpiresAt < cutoff || (s.RevokedAt != null && s.RevokedAt < cutoff))
            .ExecuteDeleteAsync(ct);
    }
}
