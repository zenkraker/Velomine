using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Rides;

public sealed class ListRidesRequest
{
    /// <summary>The Next value from the previous page. Omit for the newest rides.</summary>
    [QueryParam]
    public string? Cursor { get; set; }

    /// <summary>How many rides to return, 1 to 200. Default 50.</summary>
    [QueryParam]
    public int? Limit { get; set; }

    /// <summary>road, gravel, mountain or track.</summary>
    [QueryParam]
    public string? Discipline { get; set; }

    /// <summary>none or ebike.</summary>
    [QueryParam]
    public string? Assist { get; set; }

    /// <summary>outdoor, indoor or virtual.</summary>
    [QueryParam]
    public string? Environment { get; set; }

    /// <summary>True or false for a commute, omitted for every ride.</summary>
    [QueryParam]
    public bool? Commute { get; set; }

    /// <summary>Words to find in the title or description, ignoring case. Up to 100 characters.</summary>
    [QueryParam]
    public string? Q { get; set; }

    /// <summary>First day, inclusive, as a calendar date such as 2026-11-01 in the member's own calendar.</summary>
    [QueryParam]
    public string? From { get; set; }

    /// <summary>Last day, inclusive, as a calendar date such as 2026-11-30 in the member's own calendar.</summary>
    [QueryParam]
    public string? To { get; set; }
}

public sealed record ListRidesResponse(RideResponse[] Rides, string? Next);

public sealed class ListRidesValidator : Validator<ListRidesRequest>
{
    public ListRidesValidator()
    {
        RuleFor(x => x.Limit).InclusiveBetween(1, 200).When(x => x.Limit.HasValue);
        RuleFor(x => x.Discipline).Must(v => v is null || Disciplines.All.Contains(v))
            .WithMessage("Choose road, gravel, mountain or track.");
        RuleFor(x => x.Assist).Must(v => v is null || Assists.All.Contains(v))
            .WithMessage("Choose none or ebike.");
        RuleFor(x => x.Environment).Must(v => v is null || Environments.All.Contains(v))
            .WithMessage("Choose outdoor, indoor or virtual.");
        RuleFor(x => x.Q).MaximumLength(100).WithMessage("Search for up to 100 characters.");
        RuleFor(x => x.From).Must(v => v is null || ListRides.TryParseDate(v, out _))
            .WithMessage("Use a date such as 2026-11-01.");
        RuleFor(x => x.To).Must(v => v is null || ListRides.TryParseDate(v, out _))
            .WithMessage("Use a date such as 2026-11-30.");
    }
}

/// <summary>
/// The member's rides, newest first (a ride still being read counts from its upload time). Duplicates are left out.
/// Paged with a cursor of the last ride's time and id, so new uploads never shift a page. A search matches the title
/// and description; a date range is read in the member's own calendar, like totals (a ride without a start time has
/// no date and is left out of a range).
/// </summary>
public sealed class ListRides(VelomineDbContext db, TimeProvider time) : Endpoint<ListRidesRequest, ListRidesResponse>
{
    public static bool TryParseDate(string value, out DateOnly date) =>
        DateOnly.TryParseExact(value, "yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture,
            System.Globalization.DateTimeStyles.None, out date);

    public override void Configure()
    {
        Get("rides");
        Description(d => d.Produces<ListRidesResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(ListRidesRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var limit = req.Limit ?? 50;
        // Duplicates stay out; a file an import could not read is reported by the import, not as a failed ride card.
        var query = db.Rides.AsNoTracking().Where(r => r.UserId == userId && r.Status != RideStatus.Duplicate
            && (r.ImportId == null || r.Status != RideStatus.Failed));

        DateTimeOffset? lastTime = null;
        Guid lastId = default;
        if (req.Cursor is not null)
        {
            if (!RideCursor.TryParse(req.Cursor, out var parsedTime, out lastId))
            {
                AddError(r => r.Cursor!, RideCursor.InvalidMessage);
                await Send.ErrorsAsync(400, ct);
                return;
            }

            lastTime = parsedTime;
        }

        if (req.Discipline is not null) query = query.Where(r => r.Discipline == req.Discipline);
        if (req.Assist is not null) query = query.Where(r => r.Assist == req.Assist);
        if (req.Environment is not null) query = query.Where(r => r.Environment == req.Environment);
        if (req.Commute is { } commute) query = query.Where(r => r.Commute == commute);

        if (RideText.Clean(req.Q) is { } term)
        {
            var pattern = RideText.ContainsPattern(term);
            query = query.Where(r => EF.Functions.ILike(r.Title!, pattern, RideText.LikeEscape)
                || EF.Functions.ILike(r.Description!, pattern, RideText.LikeEscape));
        }

        DateOnly? from = req.From is not null && TryParseDate(req.From, out var f) ? f : null;
        DateOnly? to = req.To is not null && TryParseDate(req.To, out var t) ? t : null;
        MemberClock? clock = null;
        if (from is not null || to is not null)
        {
            clock = await MemberClock.ForAsync(db, userId, time, ct);
            // A local date is at most 14 hours from UTC, so a day either side catches every ride in the range; the exact
            // cut is made on the rows below, the same way totals decide which day a ride counts on.
            if (from is { } first)
            {
                var earliest = new DateTimeOffset(first.AddDays(-1).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
                query = query.Where(r => r.StartTime >= earliest);
            }
            if (to is { } last)
            {
                var latest = new DateTimeOffset(last.AddDays(2).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
                query = query.Where(r => r.StartTime < latest);
            }
        }

        // Without a range every row passes, so this is one page. With one, the rows in the day on either side of it may
        // be cut, so pages are read on until the limit is filled or the rides run out.
        var kept = new List<Ride>();
        string? next = null;
        while (true)
        {
            var paged = lastTime is { } after ? RideCursor.Apply(query, after, lastId) : query;
            var (page, pageNext) = await RideCursor.PageAsync(paged, limit, ct);
            foreach (var ride in page)
            {
                if (clock is not null && !InRange(ride, clock, from, to)) continue;
                kept.Add(ride);
                if (kept.Count > limit) break;
            }

            if (kept.Count > limit)
            {
                kept.RemoveAt(kept.Count - 1);
                next = RideCursor.Format(kept[^1]);
                break;
            }

            if (pageNext is null) break;
            RideCursor.TryParse(pageNext, out var nextTime, out lastId);
            lastTime = nextTime;
        }

        await Send.OkAsync(new ListRidesResponse([.. kept.Select(RideResponse.From)], next), ct);
    }

    private static bool InRange(Ride ride, MemberClock clock, DateOnly? from, DateOnly? to)
    {
        if (ride.StartTime is not { } start) return false;
        var day = clock.LocalDateOf(start, ride.UtcOffsetMinutes);
        return (from is null || day >= from) && (to is null || day <= to);
    }
}
