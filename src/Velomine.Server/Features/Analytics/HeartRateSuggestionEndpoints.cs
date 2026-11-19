using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Analytics;

/// <summary>A heart-rate number a ride suggests. <see cref="Kind"/> is <c>max</c> or <c>threshold</c>.</summary>
public sealed record HeartRateSuggestionResponse(
    Guid Id,
    Guid RideId,
    string Kind,
    int Bpm,
    DateTimeOffset CreatedAt);

/// <summary>The member's open suggestions, one per number at most, possibly none. Owner only: a coach never sees them.</summary>
public sealed class ListHeartRateSuggestions(VelomineDbContext db)
    : EndpointWithoutRequest<ListHeartRateSuggestionsResponse>
{
    public override void Configure()
    {
        Get("analytics/heart-rate-suggestions");
        Description(d => d.Produces<ListHeartRateSuggestionsResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.UserId();
        var suggestions = await db.HeartRateSuggestions.AsNoTracking()
            .Where(s => s.UserId == userId && s.Status == HeartRateSuggestionStatuses.Open)
            .OrderBy(s => s.Kind).ThenByDescending(s => s.CreatedAt)
            .Select(s => new HeartRateSuggestionResponse(s.Id, s.RideId, s.Kind, s.Bpm, s.CreatedAt))
            .ToArrayAsync(ct);
        await Send.OkAsync(new ListHeartRateSuggestionsResponse([.. suggestions]), ct);
    }
}

public sealed record ListHeartRateSuggestionsResponse(HeartRateSuggestionResponse[] Suggestions);

/// <summary>Accepts the suggestion: the number becomes this value, measured from the ride.</summary>
public sealed class AcceptHeartRateSuggestion(VelomineDbContext db, SetHeartRateValue setValue, TimeProvider time)
    : Endpoint<AcceptHeartRateSuggestionRequest, ProfileResponse>
{
    public override void Configure()
    {
        Post("analytics/heart-rate-suggestions/{suggestionId}/accept");
        Description(d => d.Produces<ProfileResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(AcceptHeartRateSuggestionRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var suggestion = await db.HeartRateSuggestions
            .FirstOrDefaultAsync(s => s.Id == req.SuggestionId && s.UserId == userId && s.Status == HeartRateSuggestionStatuses.Open, ct);
        if (suggestion is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var user = await db.Users.FirstAsync(u => u.Id == suggestion.UserId, ct);
        // A suggestion is only made below the maximum in use; a maximum lowered since then keeps the rule.
        if (suggestion.Kind == HeartRateKinds.Threshold
            && HeartRates.For(user, time).Max?.Bpm is { } max && suggestion.Bpm >= max)
        {
            await Send.ResultAsync(TypedResults.Problem(
                $"The threshold must be below the maximum in use ({max} bpm).",
                statusCode: StatusCodes.Status400BadRequest));
            return;
        }

        await setValue.SetAsync(user, suggestion.Kind, suggestion.Bpm, HeartRateSources.Measured, suggestion.RideId, ct);
        suggestion.Status = HeartRateSuggestionStatuses.Accepted;
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await GetProfile.ProfileOfAsync(db, user, time, ct), ct);
    }
}

/// <summary>Dismisses the suggestion: it leaves the page and is not asked about again.</summary>
public sealed class DismissHeartRateSuggestion(VelomineDbContext db) : Endpoint<DismissHeartRateSuggestionRequest>
{
    public override void Configure()
    {
        Post("analytics/heart-rate-suggestions/{suggestionId}/dismiss");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(DismissHeartRateSuggestionRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var changed = await db.HeartRateSuggestions
            .Where(s => s.Id == req.SuggestionId && s.UserId == userId && s.Status == HeartRateSuggestionStatuses.Open)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.Status, HeartRateSuggestionStatuses.Dismissed), ct);
        if (changed == 0)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        await Send.NoContentAsync(ct);
    }
}

/// <summary>The suggestion to answer; its id is named in the route so the path never reads as a ride's.</summary>
public sealed class AcceptHeartRateSuggestionRequest
{
    public Guid SuggestionId { get; set; }
}

public sealed class DismissHeartRateSuggestionRequest
{
    public Guid SuggestionId { get; set; }
}
