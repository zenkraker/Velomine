using FastEndpoints;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

/// <summary>The rider's pending request to a club, if there is one.</summary>
public sealed class GetMyJoinRequest(VelomineDbContext db) : EndpointWithoutRequest<MyJoinRequestResponse>
{
    public override void Configure()
    {
        Get("club/join-request");
        Description(d => d.Produces<MyJoinRequestResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var request = await JoinRequestQueries.MineAsync(db, User.UserId(), ct);
        await Send.OkAsync(new MyJoinRequestResponse(request), ct);
    }
}
