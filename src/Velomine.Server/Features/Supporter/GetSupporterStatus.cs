using FastEndpoints;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Supporter;

/// <summary>The caller's supporter status: their own licence and their club's, so the app can draw the badge.</summary>
public sealed class GetSupporterStatus(VelomineDbContext db, IOptions<SupporterOptions> options)
    : EndpointWithoutRequest<SupporterStatusResponse>
{
    public override void Configure()
    {
        Get("supporter");
        Description(d => d.Produces<SupporterStatusResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct) =>
        await Send.OkAsync(await SupporterQueries.StatusAsync(db, options.Value.IsConfigured, User.UserId(), ct), ct);
}
