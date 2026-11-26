using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Analytics;

/// <summary>The FTP a ride suggests. <see cref="EffortWatts"/> is the ride's best for <see cref="Method"/>'s duration.</summary>
public sealed record FtpSuggestionResponse(
    Guid Id,
    Guid RideId,
    int Watts,
    string Method,
    int EffortWatts,
    DateTimeOffset CreatedAt);

/// <summary>The member's one open suggestion, or 204 when there is none. Owner only: a coach never sees it.</summary>
public sealed class GetFtpSuggestion(VelomineDbContext db) : EndpointWithoutRequest<FtpSuggestionResponse>
{
    public override void Configure()
    {
        Get("analytics/ftp-suggestion");
        Description(d => d.Produces<FtpSuggestionResponse>(200).Produces(204).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var suggestion = await db.FtpSuggestions.AsNoTracking()
            .Where(s => s.UserId == userId && s.Status == FtpSuggestionStatuses.Open)
            .OrderByDescending(s => s.CreatedAt).ThenByDescending(s => s.Id)
            .Select(s => new FtpSuggestionResponse(s.Id, s.RideId, s.Watts, s.Method, s.EffortWatts, s.CreatedAt))
            .FirstOrDefaultAsync(ct);
        if (suggestion is null)
        {
            await Send.NoContentAsync(ct);
            return;
        }

        await Send.OkAsync(suggestion, ct);
    }
}

/// <summary>Accepts the suggestion: the FTP becomes this number, with a <c>test</c> row in its history naming the ride.</summary>
public sealed class AcceptFtpSuggestion(VelomineDbContext db, SetFtpValue setValue, TimeProvider time)
    : Endpoint<AcceptFtpSuggestionRequest, ProfileResponse>
{
    public override void Configure()
    {
        Post("analytics/ftp-suggestion/{suggestionId}/accept");
        Description(d => d.Produces<ProfileResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(AcceptFtpSuggestionRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var suggestion = await db.FtpSuggestions
            .FirstOrDefaultAsync(s => s.Id == req.SuggestionId && s.UserId == userId && s.Status == FtpSuggestionStatuses.Open, ct);
        if (suggestion is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var user = await db.Users.FirstAsync(u => u.Id == userId, ct);
        setValue.Set(user, suggestion.Watts, FtpSources.Test, suggestion.RideId);
        suggestion.Status = FtpSuggestionStatuses.Accepted;
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await GetProfile.ProfileOfAsync(db, user, time, ct), ct);
    }
}

/// <summary>Dismisses the suggestion: it leaves the page and is not asked about again.</summary>
public sealed class DismissFtpSuggestion(VelomineDbContext db) : Endpoint<DismissFtpSuggestionRequest>
{
    public override void Configure()
    {
        Post("analytics/ftp-suggestion/{suggestionId}/dismiss");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(DismissFtpSuggestionRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var changed = await db.FtpSuggestions
            .Where(s => s.Id == req.SuggestionId && s.UserId == userId && s.Status == FtpSuggestionStatuses.Open)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.Status, FtpSuggestionStatuses.Dismissed), ct);
        if (changed == 0)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        await Send.NoContentAsync(ct);
    }
}

/// <summary>The suggestion to adopt; its id is named in the route so the path never reads as a ride's.</summary>
public sealed class AcceptFtpSuggestionRequest
{
    public Guid SuggestionId { get; set; }
}

public sealed class DismissFtpSuggestionRequest
{
    public Guid SuggestionId { get; set; }
}
