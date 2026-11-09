using Microsoft.EntityFrameworkCore;

namespace Velomine.Server.Features.Rides;

/// <summary>
/// The cursor both ride lists use: the last ride's time and id, so new uploads never shift a page.
/// One parser and one pager keep the member list and the coach list on the same rules.
/// </summary>
internal static class RideCursor
{
    public const string InvalidMessage = "The cursor is not valid.";

    public static bool TryParse(string value, out DateTimeOffset lastTime, out Guid lastId)
    {
        lastTime = default;
        lastId = default;
        var parts = value.Split(':');
        if (parts.Length != 2
            || !long.TryParse(parts[0], out var ticks)
            || ticks < 0
            || ticks > DateTimeOffset.MaxValue.UtcTicks
            || !Guid.TryParse(parts[1], out lastId))
        {
            return false;
        }

        lastTime = new DateTimeOffset(ticks, TimeSpan.Zero);
        return true;
    }

    public static IQueryable<Ride> Apply(IQueryable<Ride> query, DateTimeOffset lastTime, Guid lastId) =>
        query.Where(r => (r.StartTime ?? r.UploadedAt) < lastTime
            || ((r.StartTime ?? r.UploadedAt) == lastTime && r.Id.CompareTo(lastId) < 0));

    /// <summary>One page and the Next value, or null on the last page.</summary>
    public static async Task<(List<Ride> Page, string? Next)> PageAsync(
        IQueryable<Ride> query, int limit, CancellationToken ct)
    {
        var page = await query
            .OrderByDescending(r => r.StartTime ?? r.UploadedAt)
            .ThenByDescending(r => r.Id)
            .Take(limit + 1)
            .ToListAsync(ct);

        var hasMore = page.Count > limit;
        if (hasMore) page.RemoveAt(page.Count - 1);
        var last = page.LastOrDefault();
        var next = hasMore && last is not null ? $"{(last.StartTime ?? last.UploadedAt).UtcTicks}:{last.Id}" : null;
        return (page, next);
    }
}
