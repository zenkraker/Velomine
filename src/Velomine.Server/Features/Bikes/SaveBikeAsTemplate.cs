using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

/// <summary>
/// Turns the parts currently on a bike into a template, so the same build can be filled in on another bike without
/// typing any of it again. Only parts still fitted are copied.
/// </summary>
public sealed class SaveBikeAsTemplate(VelomineDbContext db, TimeProvider time)
    : Endpoint<SaveBikeAsTemplateRequest, BikeTemplateResponse>
{
    public override void Configure()
    {
        Post("bikes/{bikeId}/templates");
        Description(d => d.Accepts<SaveBikeAsTemplateRequest>("application/json")
            .Produces<BikeTemplateResponse>(201).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(SaveBikeAsTemplateRequest req, CancellationToken ct)
    {
        var bike = await db.Bikes.AsNoTracking().Include(b => b.Components)
            .FirstOrDefaultAsync(b => b.Id == req.BikeId && b.UserId == User.UserId(), ct);
        if (bike is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var fitted = bike.Components.Where(c => c.RemovedOn is null).ToList();
        if (fitted.Count == 0)
        {
            AddError("Add at least one part to the bike before saving it as a template.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        var template = new BikeTemplate
        {
            Id = Guid.CreateVersion7(),
            UserId = User.UserId(),
            Name = req.Name.Trim(),
            CreatedAt = time.GetUtcNow(),
        };
        foreach (var component in fitted)
        {
            template.Parts.Add(new BikeTemplatePart
            {
                Id = Guid.CreateVersion7(),
                TemplateId = template.Id,
                Type = component.Type,
                Brand = component.Brand,
                Model = component.Model,
                Mpn = component.Mpn,
                Gtin = component.Gtin,
                IsCustom = component.IsCustom,
                ExpectedDistanceM = component.ExpectedDistanceM,
                ExpectedHours = component.ExpectedHours,
                ExpectedMonths = component.ExpectedMonths,
            });
        }

        db.BikeTemplates.Add(template);
        await db.SaveChangesAsync(ct);
        await Send.ResponseAsync(BikeTemplateQueries.Response(template), 201, ct);
    }
}
