using System.Security.Cryptography;
using System.Text;
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

/// <summary>
/// The secret in a calendar address. It is 256 random bits, and only its SHA-256 is stored, so the database never
/// holds an address that works. The address is shown once, when it is made; replacing it stops the old one.
/// </summary>
public static class CalendarFeedTokens
{
    public static string NewSecret() => Convert.ToBase64String(RandomNumberGenerator.GetBytes(32))
        .TrimEnd('=').Replace('+', '-').Replace('/', '_');

    public static byte[] Hash(string secret) => SHA256.HashData(Encoding.UTF8.GetBytes(secret));
}

/// <summary>Whether the signed-in member has a calendar address; the address itself is not readable again.</summary>
public sealed class GetCalendarFeed(VelomineDbContext db) : EndpointWithoutRequest<CalendarFeedStatusResponse>
{
    public override void Configure()
    {
        Get("club/calendar-feed");
        Description(d => d.Produces<CalendarFeedStatusResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        if (await db.ClubMemberships.AsNoTracking().AnyAsync(m => m.UserId == userId, ct) is false)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var feed = await db.CalendarFeeds.AsNoTracking().FirstOrDefaultAsync(f => f.UserId == userId, ct);
        await Send.OkAsync(new CalendarFeedStatusResponse(feed is not null, feed?.CreatedAt), ct);
    }
}

/// <summary>
/// Makes the member a private calendar address, or replaces the one they had, which stops it. Only the hash is kept,
/// so this answer is the one time the address is shown.
/// </summary>
public sealed class CreateCalendarFeed(
    VelomineDbContext db,
    TimeProvider time,
    IOptions<PublicUrlOptions> publicUrl) : EndpointWithoutRequest<CalendarFeedAddressResponse>
{
    public override void Configure()
    {
        Post("club/calendar-feed");
        Description(d => d.Produces<CalendarFeedAddressResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var membership = await db.ClubMemberships.AsNoTracking().FirstOrDefaultAsync(m => m.UserId == userId, ct);
        if (membership is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var secret = CalendarFeedTokens.NewSecret();
        var feed = await db.CalendarFeeds.FirstOrDefaultAsync(f => f.UserId == userId, ct);
        if (feed is null)
        {
            feed = new CalendarFeed { UserId = userId };
            db.CalendarFeeds.Add(feed);
        }

        feed.ClubId = membership.ClubId;
        feed.TokenHash = CalendarFeedTokens.Hash(secret);
        feed.CreatedAt = time.GetUtcNow();
        await db.SaveChangesAsync(ct);

        var url = publicUrl.Value.PublicUrl.TrimEnd('/') + "/api/v1/calendar/" + secret + ".ics";
        await Send.OkAsync(new CalendarFeedAddressResponse(url, feed.CreatedAt), ct);
    }
}

/// <summary>Stops the member's calendar address. A feed that is already gone is not an error.</summary>
public sealed class DeleteCalendarFeed(VelomineDbContext db) : EndpointWithoutRequest
{
    public override void Configure()
    {
        Delete("club/calendar-feed");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        if (await db.ClubMemberships.AsNoTracking().AnyAsync(m => m.UserId == userId, ct) is false)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (await db.CalendarFeeds.FirstOrDefaultAsync(f => f.UserId == userId, ct) is { } feed)
        {
            db.CalendarFeeds.Remove(feed);
            await db.SaveChangesAsync(ct);
        }

        await Send.NoContentAsync(ct);
    }
}
