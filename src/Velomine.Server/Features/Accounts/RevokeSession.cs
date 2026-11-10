using FastEndpoints;

namespace Velomine.Server.Features.Accounts;

public sealed class SessionIdRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }
}

/// <summary>Signs one other device out. An id that is not the member's is a 404, never a hint that it exists.</summary>
public sealed class RevokeSession(UserSessions sessions) : Endpoint<SessionIdRequest>
{
    public override void Configure()
    {
        Delete("accounts/me/sessions/{id}");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(SessionIdRequest req, CancellationToken ct)
    {
        if (!await sessions.RevokeAsync(req.Id, User.UserId(), ct))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        await Send.NoContentAsync(ct);
    }
}

/// <summary>The "log out other devices" action; the caller's own session stays signed in.</summary>
public sealed class RevokeOtherSessions(UserSessions sessions) : EndpointWithoutRequest
{
    public override void Configure()
    {
        Post("accounts/me/sessions/logout-others");
        Description(d => d.Produces(204).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        if (User.SessionId() is not { } current)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        await sessions.RevokeOthersAsync(User.UserId(), current, ct);
        await Send.NoContentAsync(ct);
    }
}
