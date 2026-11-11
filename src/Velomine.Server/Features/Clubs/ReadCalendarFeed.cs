using System.Globalization;
using System.Text;
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

public sealed class CalendarFeedRequest
{
    /// <summary>The secret from the address. Never logged: the server logs the route template.</summary>
    public string Token { get; set; } = "";
}

/// <summary>
/// The member's private calendar: the club's rides from the last month and the next year, in RFC 5545 by hand. It
/// carries no names and no sign-up list, only what a calendar needs. A cancelled ride says so; a route withdrawn from
/// the library is simply missing. The secret is looked up by its hash, and the member's membership is checked now, so
/// leaving the club stops the address.
/// </summary>
public sealed class ReadCalendarFeed(
    VelomineDbContext db,
    TimeProvider time,
    IOptions<PublicUrlOptions> publicUrl) : Endpoint<CalendarFeedRequest>
{
    public override void Configure()
    {
        Get("calendar/{token}.ics");
        AllowAnonymous();
        Description(d => d.Produces(200, contentType: "text/calendar").Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CalendarFeedRequest req, CancellationToken ct)
    {
        var hash = CalendarFeedTokens.Hash(req.Token);
        var feed = await db.CalendarFeeds.AsNoTracking().FirstOrDefaultAsync(f => f.TokenHash == hash, ct);
        if (feed is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var inClub = await db.ClubMemberships.AsNoTracking()
            .AnyAsync(m => m.UserId == feed.UserId && m.ClubId == feed.ClubId, ct);
        if (!inClub)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var now = time.GetUtcNow();
        var rides = await db.PlannedRides.AsNoTracking()
            .Where(r => r.ClubId == feed.ClubId
                && r.StartsAt >= now.AddDays(-ListClubRides.PastDays)
                && r.StartsAt <= now.AddYears(1))
            .OrderBy(r => r.StartsAt).ThenBy(r => r.Id)
            .Take(500)
            .ToListAsync(ct);
        var routes = await CalendarQueries.SharedRoutesAsync(db, feed.ClubId, rides.Select(r => r.RouteId), ct);
        var clubName = await db.Clubs.AsNoTracking().Where(c => c.Id == feed.ClubId).Select(c => c.Name)
            .FirstOrDefaultAsync(ct) ?? "Velomine";

        var calendar = CalendarFeedFile.Write(clubName, rides, routes, publicUrl.Value.PublicUrl, now);
        await Send.StringAsync(calendar, 200, "text/calendar; charset=utf-8", cancellation: ct);
    }
}

/// <summary>The iCalendar file itself. Small enough to write by hand, and every line folded and escaped as RFC 5545 asks.</summary>
public static class CalendarFeedFile
{
    public static string Write(
        string clubName,
        IReadOnlyList<PlannedRide> rides,
        IReadOnlyDictionary<Guid, RideRouteRef> routes,
        string publicUrl,
        DateTimeOffset now)
    {
        var site = publicUrl.TrimEnd('/');
        var lines = new List<string>
        {
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//Velomine//Club rides//EN",
            "CALSCALE:GREGORIAN",
            "METHOD:PUBLISH",
            $"X-WR-CALNAME:{Text(clubName)}",
        };

        // Times are UTC: every calendar shows them in its own zone, and a ride planned for 8:00 local stays 8:00.
        foreach (var ride in rides)
        {
            var route = ride.RouteId is { } routeId && routes.TryGetValue(routeId, out var found) ? found : null;
            var end = CalendarQueries.EndsAt(ride.StartsAt, ride.Pace, route?.DistanceM);
            var description = string.Join('\n', new[]
            {
                ride.Notes,
                route is null ? null : $"Route: {route.Name} ({Math.Round(route.DistanceM / 1000)} km)",
            }.Where(part => !string.IsNullOrWhiteSpace(part)));

            lines.Add("BEGIN:VEVENT");
            lines.Add($"UID:ride-{ride.Id:N}@velomine");
            lines.Add($"DTSTAMP:{Stamp(now)}");
            lines.Add($"DTSTART:{Stamp(ride.StartsAt)}");
            lines.Add($"DTEND:{Stamp(end)}");
            lines.Add($"SUMMARY:{Text(ride.Title)}");
            lines.Add($"LOCATION:{Text(ride.MeetingName)}");
            lines.Add($"GEO:{ride.MeetingLatitude.ToString("0.######", CultureInfo.InvariantCulture)};{ride.MeetingLongitude.ToString("0.######", CultureInfo.InvariantCulture)}");
            if (description.Length > 0) lines.Add($"DESCRIPTION:{Text(description)}");
            lines.Add($"URL:{site}/club/rides/{ride.Id}");
            if (ride.CancelledAt is not null) lines.Add("STATUS:CANCELLED");
            lines.Add("END:VEVENT");
        }

        lines.Add("END:VCALENDAR");
        return string.Concat(lines.SelectMany(Fold).Select(line => line + "\r\n"));
    }

    private static string Stamp(DateTimeOffset instant) =>
        instant.UtcDateTime.ToString("yyyyMMdd'T'HHmmss'Z'", CultureInfo.InvariantCulture);

    /// <summary>RFC 5545 text: backslash, semicolon and comma escaped, a line break becomes \n.</summary>
    private static string Text(string value) => value
        .Replace("\\", "\\\\")
        .Replace(";", "\\;")
        .Replace(",", "\\,")
        .Replace("\r\n", "\\n")
        .Replace("\n", "\\n")
        .Replace("\r", "\\n");

    /// <summary>No content line is longer than 75 octets; the rest continues on a line that starts with a space.</summary>
    private static IEnumerable<string> Fold(string line)
    {
        const int limit = 75;
        var part = new StringBuilder();
        var bytes = 0;
        foreach (var rune in line.EnumerateRunes())
        {
            var length = rune.Utf8SequenceLength;
            if (bytes + length > limit)
            {
                yield return part.ToString();
                part.Clear();
                part.Append(' ');
                bytes = 1;
            }

            part.Append(rune.ToString());
            bytes += length;
        }

        yield return part.ToString();
    }
}
