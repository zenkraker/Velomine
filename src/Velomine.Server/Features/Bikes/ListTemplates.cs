using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

/// <summary>The member's own build templates, with their parts. Nobody else sees them.</summary>
public sealed class ListTemplates(VelomineDbContext db) : EndpointWithoutRequest<ListTemplatesResponse>
{
    public override void Configure()
    {
        Get("bikes/templates");
        Description(d => d.Produces<ListTemplatesResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var templates = await db.BikeTemplates.AsNoTracking()
            .Include(t => t.Parts)
            .Where(t => t.UserId == User.UserId())
            .OrderBy(t => t.Name)
            .ToListAsync(ct);

        await Send.OkAsync(new ListTemplatesResponse([.. templates.Select(BikeTemplateQueries.Response)]), ct);
    }
}
