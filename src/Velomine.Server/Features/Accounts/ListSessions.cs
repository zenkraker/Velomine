using FastEndpoints;
using Microsoft.AspNetCore.Identity;

namespace Velomine.Server.Features.Accounts;

public sealed record SessionResponse(Guid Id, string Label, DateTimeOffset CreatedAt, DateTimeOffset LastUsedAt, bool Current);

/// <summary>What the member is signed in on now.</summary>
public sealed class ListSessions(UserSessions sessions) : EndpointWithoutRequest<List<SessionResponse>>
{
    public override void Configure()
    {
        Get("accounts/me/sessions");
        Description(d => d.Produces<List<SessionResponse>>(200, "application/json").Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var current = User.SessionId();
        if (current is { } id) await sessions.TouchAsync(id, User.UserId(), ct);
        var rows = await sessions.ListActiveAsync(User.UserId(), ct);
        await Send.OkAsync(rows
            .Select(s => new SessionResponse(s.Id, s.Label, s.CreatedAt, s.LastUsedAt, s.Id == current))
            .ToList(), ct);
    }
}
