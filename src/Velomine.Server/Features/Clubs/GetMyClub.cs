using FastEndpoints;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Admin;

namespace Velomine.Server.Features.Clubs;

/// <summary>The signed-in account's club and its roster; `club` is null before joining one.</summary>
public sealed class GetMyClub(VelomineDbContext db, SettingsReader settings, TimeProvider time) : EndpointWithoutRequest<MyClubResponse>
{
    public override void Configure()
    {
        Get("club");
        Description(d => d.Produces<MyClubResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var club = await ClubQueries.MyClubAsync(db, time, User.UserId(), ct);
        var canStart = club is null && (await settings.GetAsync(ct)).ClubCreationEnabled;
        await Send.OkAsync(new MyClubResponse(club, canStart), ct);
    }
}
