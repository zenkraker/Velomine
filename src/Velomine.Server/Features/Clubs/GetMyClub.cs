using FastEndpoints;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Clubs;

/// <summary>The signed-in account's club and its roster; `club` is null before joining one.</summary>
public sealed class GetMyClub(VelomineDbContext db) : EndpointWithoutRequest<MyClubResponse>
{
    public override void Configure()
    {
        Get("club");
        Description(d => d.Produces<MyClubResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct) =>
        await Send.OkAsync(new MyClubResponse(await ClubQueries.MyClubAsync(db, User.UserId(), ct)), ct);
}
