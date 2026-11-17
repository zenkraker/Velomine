using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Accounts;

public sealed record FtpHistoryEntry(int Watts, DateTimeOffset SetAt, string Source, Guid? RideId);

/// <summary>Newest first, at most 100: the rider's own FTP history, and nobody else's.</summary>
public sealed record FtpHistoryResponse(IReadOnlyList<FtpHistoryEntry> Entries);

/// <summary>Every FTP the member has had, so the number their zones and TSS use can be trusted.</summary>
public sealed class GetFtpHistory(VelomineDbContext db) : EndpointWithoutRequest<FtpHistoryResponse>
{
    private const int MaxEntries = 100;

    public override void Configure()
    {
        Get("accounts/me/ftp-history");
        Description(d => d.Produces<FtpHistoryResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var entries = await db.FtpHistory.AsNoTracking()
            .Where(h => h.UserId == userId)
            // Two rows can share an instant (a clock that does not tick in a test); the later id is the later write.
            .OrderByDescending(h => h.SetAt).ThenByDescending(h => h.Id)
            .Take(MaxEntries)
            .Select(h => new FtpHistoryEntry(h.Watts, h.SetAt, h.Source, h.RideId))
            .ToListAsync(ct);
        await Send.OkAsync(new FtpHistoryResponse(entries), ct);
    }
}
