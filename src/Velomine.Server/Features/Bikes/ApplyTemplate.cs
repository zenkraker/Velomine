using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

/// <summary>
/// Fits a template's parts to a bike. A kind of part the bike already has fitted is left alone, so applying a template
/// to a half-built bike only fills the gaps and never duplicates a chain or a set of pads.
/// </summary>
public sealed class ApplyTemplate(VelomineDbContext db, TimeProvider time)
    : Endpoint<ApplyTemplateRequest, BikeDetailResponse>
{
    public override void Configure()
    {
        Post("bikes/{bikeId}/templates/{id}");
        Description(d => d.Accepts<ApplyTemplateRequest>("application/json")
            .Produces<BikeDetailResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(ApplyTemplateRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var bike = await db.Bikes.Include(b => b.Components)
            .FirstOrDefaultAsync(b => b.Id == req.BikeId && b.UserId == userId, ct);
        var template = await db.BikeTemplates.AsNoTracking().Include(t => t.Parts)
            .FirstOrDefaultAsync(t => t.Id == req.Id && t.UserId == userId, ct);
        if (bike is null || template is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var fittedTypes = bike.Components.Where(c => c.RemovedOn is null).Select(c => c.Type).ToHashSet();
        foreach (var part in template.Parts)
        {
            if (!fittedTypes.Add(part.Type)) continue;

            var component = new BikeComponent
            {
                Id = Guid.CreateVersion7(),
                BikeId = bike.Id,
                Type = part.Type,
                Brand = part.Brand,
                Model = part.Model,
                Mpn = part.Mpn,
                Gtin = part.Gtin,
                IsCustom = part.IsCustom,
                InstalledOn = req.InstalledOn,
                ExpectedDistanceM = part.ExpectedDistanceM,
                ExpectedHours = part.ExpectedHours,
                ExpectedMonths = part.ExpectedMonths,
            };
            var catalogue = part.IsCustom ? null : await PartCatalogue.FindAsync(db, component, ct);
            component.PartId = catalogue?.Id;
            if (catalogue is null && !part.IsCustom) await ContributionOutbox.EnqueueAsync(db, component, time, ct);
            db.BikeComponents.Add(component);
        }

        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await BikeQueries.DetailAsync(db, bike, await MemberClock.ForAsync(db, userId, time, ct), ct), ct);
    }
}
