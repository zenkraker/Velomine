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
    }
}

/// <summary>
/// The member's rides, newest first (a ride still being read counts from its upload time). Duplicates are left out.
/// Paged with a cursor of the last ride's time and id, so new uploads never shift a page.
/// </summary>
public sealed class ListRides(VelomineDbContext db) : Endpoint<ListRidesRequest, ListRidesResponse>
{
    public override void Configure()
    {
        Get("rides");
        Description(d => d.Produces<ListRidesResponse>(200).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(ListRidesRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var limit = req.Limit ?? 50;
        var query = db.Rides.AsNoTracking().Where(r => r.UserId == userId && r.Status != RideStatus.Duplicate);

        if (req.Cursor is not null)
        {
            var parts = req.Cursor.Split(':');
            if (parts.Length != 2 || !long.TryParse(parts[0], out var ticks) || !Guid.TryParse(parts[1], out var lastId))
            {
                AddError(r => r.Cursor!, "The cursor is not valid.");
                await Send.ErrorsAsync(400, ct);
                return;
            }

            var lastTime = new DateTimeOffset(ticks, TimeSpan.Zero);
            query = query.Where(r => (r.StartTime ?? r.UploadedAt) < lastTime || ((r.StartTime ?? r.UploadedAt) == lastTime && r.Id.CompareTo(lastId) < 0));
        }

        if (req.Discipline is not null) query = query.Where(r => r.Discipline == req.Discipline);
        if (req.Assist is not null) query = query.Where(r => r.Assist == req.Assist);
        if (req.Environment is not null) query = query.Where(r => r.Environment == req.Environment);
        if (req.Commute is { } commute) query = query.Where(r => r.Commute == commute);

        var page = await query
            .OrderByDescending(r => r.StartTime ?? r.UploadedAt)
            .ThenByDescending(r => r.Id)
            .Take(limit + 1)
            .ToListAsync(ct);

        var hasMore = page.Count > limit;
        if (hasMore) page.RemoveAt(page.Count - 1);
        var last = page.LastOrDefault();
        var next = hasMore && last is not null ? $"{(last.StartTime ?? last.UploadedAt).UtcTicks}:{last.Id}" : null;

        await Send.OkAsync(new ListRidesResponse([.. page.Select(RideResponse.From)], next), ct);
    }
}
