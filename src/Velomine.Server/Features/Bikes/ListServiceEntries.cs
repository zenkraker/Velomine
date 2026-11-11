using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

public sealed class ListServiceEntriesRequest
{
    /// <summary>From the address.</summary>
    public Guid BikeId { get; set; }

    /// <summary>Only the entries about this part.</summary>
    [QueryParam]
    public Guid? ComponentId { get; set; }

    /// <summary>1 to 200, default 50.</summary>
    [QueryParam]
    public int? Limit { get; set; }

    /// <summary>To get the next page, the date and id of the last entry of the page before. Both are needed together.</summary>
    [QueryParam]
    public DateOnly? BeforeDate { get; set; }

    [QueryParam]
    public Guid? BeforeId { get; set; }
}

/// <summary>Newest first. HasMore says there is another page after the last entry.</summary>
public sealed record ListServiceEntriesResponse(ServiceEntryResponse[] Entries, bool HasMore);

public sealed class ListServiceEntriesValidator : Validator<ListServiceEntriesRequest>
{
    public ListServiceEntriesValidator()
    {
        RuleFor(x => x.Limit).InclusiveBetween(1, 200).When(x => x.Limit.HasValue);
        RuleFor(x => x).Must(x => x.BeforeDate.HasValue == x.BeforeId.HasValue).WithMessage("Send beforeDate and beforeId together.");
    }
}

/// <summary>A bike's service log, newest first, each entry with the bike's distance on its date.</summary>
public sealed class ListServiceEntries(VelomineDbContext db, TimeProvider time) : Endpoint<ListServiceEntriesRequest, ListServiceEntriesResponse>
{
    public override void Configure()
    {
        Get("bikes/{bikeId}/service");
        Description(d => d.Produces<ListServiceEntriesResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(ListServiceEntriesRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var bike = await db.Bikes.AsNoTracking().FirstOrDefaultAsync(b => b.Id == req.BikeId && b.UserId == userId, ct);
        if (bike is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var limit = req.Limit ?? 50;
        var query = db.ServiceEntries.AsNoTracking().Where(e => e.BikeId == bike.Id);
        if (req.ComponentId is { } componentId) query = query.Where(e => e.ComponentId == componentId);
        if (req is { BeforeDate: { } beforeDate, BeforeId: { } beforeId })
            query = query.Where(e => e.Date < beforeDate || (e.Date == beforeDate && e.Id.CompareTo(beforeId) < 0));

        var page = await query.OrderByDescending(e => e.Date).ThenByDescending(e => e.Id).Take(limit + 1).ToListAsync(ct);
        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        var rides = await BikeQueries.RideUsesAsync(db, bike.Id, clock, ct);
        await Send.OkAsync(new ListServiceEntriesResponse(
            [.. page.Take(limit).Select(e => ServiceLogQueries.Response(e, bike, rides))],
            page.Count > limit), ct);
    }
}
