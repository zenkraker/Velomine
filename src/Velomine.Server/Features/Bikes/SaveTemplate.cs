using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

public sealed class CreateTemplate(VelomineDbContext db, TimeProvider time) : Endpoint<CreateTemplateRequest, BikeTemplateResponse>
{
    public override void Configure()
    {
        Post("bikes/templates");
        Description(d => d.Accepts<CreateTemplateRequest>("application/json").Produces<BikeTemplateResponse>(201).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CreateTemplateRequest req, CancellationToken ct)
    {
        var template = new BikeTemplate
        {
            Id = Guid.CreateVersion7(),
            UserId = User.UserId(),
            Name = req.Name.Trim(),
            CreatedAt = time.GetUtcNow(),
        };
        foreach (var part in req.Parts) template.Parts.Add(part.ToEntity(template.Id));

        db.BikeTemplates.Add(template);
        await db.SaveChangesAsync(ct);
        await Send.ResponseAsync(BikeTemplateQueries.Response(template), 201, ct);
    }
}

public sealed class UpdateTemplate(VelomineDbContext db) : Endpoint<UpdateTemplateRequest, BikeTemplateResponse>
{
    public override void Configure()
    {
        Put("bikes/templates/{id}");
        Description(d => d.Accepts<UpdateTemplateRequest>("application/json").Produces<BikeTemplateResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateTemplateRequest req, CancellationToken ct)
    {
        var template = await db.BikeTemplates.Include(t => t.Parts)
            .FirstOrDefaultAsync(t => t.Id == req.Id && t.UserId == User.UserId(), ct);
        if (template is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        template.Name = req.Name.Trim();
        db.BikeTemplateParts.RemoveRange(template.Parts);
        template.Parts.Clear();
        foreach (var part in req.Parts) template.Parts.Add(part.ToEntity(template.Id));

        await db.SaveChangesAsync(ct);
        await Send.OkAsync(BikeTemplateQueries.Response(template), ct);
    }
}

public sealed class DeleteTemplate(VelomineDbContext db) : Endpoint<TemplateIdRequest>
{
    public override void Configure()
    {
        Delete("bikes/templates/{id}");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(TemplateIdRequest req, CancellationToken ct)
    {
        var deleted = await db.BikeTemplates
            .Where(t => t.Id == req.Id && t.UserId == User.UserId())
            .ExecuteDeleteAsync(ct);

        if (deleted == 0) await Send.NotFoundAsync(ct);
        else await Send.NoContentAsync(ct);
    }
}

public sealed class TemplateIdRequest
{
    public Guid Id { get; set; }
}
