using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

/// <summary>The fields of a part.</summary>
public interface IComponentFields
{
    string Type { get; }
    string? Brand { get; }
    string? Model { get; }
    string? Mpn { get; }
    string? Gtin { get; }
    bool Custom { get; }
    DateOnly InstalledOn { get; }
    DateOnly? RemovedOn { get; }
    double? ExpectedDistanceM { get; }
    double? ExpectedHours { get; }
    int? ExpectedMonths { get; }
}

public sealed class CreateComponentRequest : IComponentFields
{
    /// <summary>From the address.</summary>
    public Guid BikeId { get; set; }

    /// <summary>An id from the component types list.</summary>
    public required string Type { get; set; }

    public string? Brand { get; set; }

    public string? Model { get; set; }

    /// <summary>The manufacturer part number, such as "CN-M8100". Optional, but it is what identifies the part.</summary>
    public string? Mpn { get; set; }

    /// <summary>The barcode on the packaging. Optional; a valid GTIN identifies the part on its own.</summary>
    public string? Gtin { get; set; }

    /// <summary>True for a part of the member's own: it is never linked to the shared catalogue and never contributed.</summary>
    public bool Custom { get; set; }

    /// <summary>The day it was fitted. Rides from this day on count towards its wear.</summary>
    public required DateOnly InstalledOn { get; set; }

    /// <summary>The day it was taken off, once it was. Rides after this day no longer count.</summary>
    public DateOnly? RemovedOn { get; set; }

    /// <summary>Worn out after this many metres, riding hours or months, whichever comes first. All three are optional.</summary>
    public double? ExpectedDistanceM { get; set; }

    public double? ExpectedHours { get; set; }

    public int? ExpectedMonths { get; set; }

    /// <summary>
    /// The part this one replaces: it is taken off on the day this one is fitted, and a service log entry is written
    /// in the same step. Leave out for a part that replaces nothing.
    /// </summary>
    public Guid? ReplacesId { get; set; }

    /// <summary>The title of that log entry, in the member's language ("Replaced chain: Shimano CN-HG701"). Optional; the server words one in English when it is left out.</summary>
    public string? LogTitle { get; set; }
}

/// <summary>Changing a part: all fields are sent each time. Set RemovedOn to retire it.</summary>
public sealed class UpdateComponentRequest : IComponentFields
{
    /// <summary>From the address.</summary>
    public Guid BikeId { get; set; }

    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    /// <summary>An id from the component types list.</summary>
    public required string Type { get; set; }

    public string? Brand { get; set; }

    public string? Model { get; set; }

    /// <summary>The manufacturer part number, such as "CN-M8100". Optional, but it is what identifies the part.</summary>
    public string? Mpn { get; set; }

    /// <summary>The barcode on the packaging. Optional; a valid GTIN identifies the part on its own.</summary>
    public string? Gtin { get; set; }

    /// <summary>True for a part of the member's own: it is never linked to the shared catalogue and never contributed.</summary>
    public bool Custom { get; set; }

    /// <summary>The day it was fitted. Rides from this day on count towards its wear.</summary>
    public required DateOnly InstalledOn { get; set; }

    /// <summary>The day it was taken off, once it was. Rides after this day no longer count.</summary>
    public DateOnly? RemovedOn { get; set; }

    /// <summary>Worn out after this many metres, riding hours or months, whichever comes first. All three are optional.</summary>
    public double? ExpectedDistanceM { get; set; }

    public double? ExpectedHours { get; set; }

    public int? ExpectedMonths { get; set; }
}

public class ComponentFieldsValidator<T> : Validator<T> where T : IComponentFields
{
    public ComponentFieldsValidator()
    {
        RuleFor(x => x.Type).Must(ComponentTypes.Ids.Contains).WithMessage("Unknown part type.");
        RuleFor(x => x.Brand).MaximumLength(100);
        RuleFor(x => x.Model).MaximumLength(100);
        RuleFor(x => x.Mpn).MaximumLength(64);
        RuleFor(x => x.Gtin).MaximumLength(20);
        RuleFor(x => x.Gtin).Must(g => string.IsNullOrWhiteSpace(g) || PartIdentity.TryNormaliseGtin(g, out _))
            .WithMessage("That is not a valid GTIN.");
        RuleFor(x => x.RemovedOn).GreaterThanOrEqualTo(x => x.InstalledOn).When(x => x.RemovedOn.HasValue)
            .WithMessage("A part cannot be removed before it was installed.");
        RuleFor(x => x.ExpectedDistanceM).GreaterThan(0).When(x => x.ExpectedDistanceM.HasValue);
        RuleFor(x => x.ExpectedHours).GreaterThan(0).When(x => x.ExpectedHours.HasValue);
        RuleFor(x => x.ExpectedMonths).GreaterThan(0).When(x => x.ExpectedMonths.HasValue);
    }
}

public sealed class CreateComponentValidator : ComponentFieldsValidator<CreateComponentRequest>
{
    public CreateComponentValidator() => RuleFor(x => x.LogTitle).MaximumLength(200);
}

public sealed class UpdateComponentValidator : ComponentFieldsValidator<UpdateComponentRequest>;

public sealed class CreateComponent(VelomineDbContext db, TimeProvider time) : Endpoint<CreateComponentRequest, BikeDetailResponse>
{
    public override void Configure()
    {
        Post("bikes/{bikeId}/components");
        Description(d => d.Accepts<CreateComponentRequest>("application/json").Produces<BikeDetailResponse>(201).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CreateComponentRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var bike = await db.Bikes.Include(b => b.Components).FirstOrDefaultAsync(b => b.Id == req.BikeId && b.UserId == userId, ct);
        if (bike is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var component = new BikeComponent { Id = Guid.CreateVersion7(), BikeId = bike.Id };
        Apply(component, req);

        // Replacing is one step: the old part comes off the day the new one goes on, and the log says so.
        if (req.ReplacesId is { } replacesId)
        {
            var old = bike.Components.FirstOrDefault(c => c.Id == replacesId && c.RemovedOn == null);
            if (old is null)
            {
                await Send.NotFoundAsync(ct);
                return;
            }
            if (req.InstalledOn < old.InstalledOn)
            {
                ThrowError("The new part cannot be fitted before the old one was.");
                return;
            }

            old.RemovedOn = req.InstalledOn;
            var make = string.Join(' ', new[] { component.Brand, component.Model }.Where(x => !string.IsNullOrWhiteSpace(x)));
            var title = string.IsNullOrWhiteSpace(req.LogTitle)
                ? $"Replaced {ComponentTypes.NameOf(old.Type).ToLowerInvariant()}" + (make.Length > 0 ? ": " + make : "")
                : req.LogTitle;
            ServiceLogQueries.Add(db, time, bike.Id, req.InstalledOn, title, ServiceOrigins.Part, componentId: component.Id);
        }

        var part = req.Custom ? null : await PartCatalogue.FindAsync(db, component, ct);
        component.PartId = part?.Id;
        // Publisher-authoritative: a non-custom part that is not in the shared list is offered to the publisher, never
        // added to the list on this instance. A custom part is never offered.
        if (part is null && !req.Custom) await ContributionOutbox.EnqueueAsync(db, component, time, ct);
        db.BikeComponents.Add(component); // Add explicitly: EF would treat a new child with a preset key as existing
        await db.SaveChangesAsync(ct);
        await Send.CreatedAtAsync<GetBike>(new { id = bike.Id }, await BikeQueries.DetailAsync(db, bike, await MemberClock.ForAsync(db, User.UserId(), time, ct), ct), cancellation: ct);
    }

    internal static void Apply(BikeComponent c, IComponentFields req)
    {
        c.Type = req.Type;
        c.Brand = req.Brand?.Trim();
        c.Model = req.Model?.Trim();
        c.Mpn = PartIdentity.NormaliseMpn(req.Mpn);
        c.Gtin = PartIdentity.TryNormaliseGtin(req.Gtin, out var gtin) ? gtin : null;
        c.IsCustom = req.Custom;
        c.InstalledOn = req.InstalledOn;
        c.RemovedOn = req.RemovedOn;
        c.ExpectedDistanceM = req.ExpectedDistanceM;
        c.ExpectedHours = req.ExpectedHours;
        c.ExpectedMonths = req.ExpectedMonths;
    }
}

public sealed class UpdateComponent(VelomineDbContext db, TimeProvider time) : Endpoint<UpdateComponentRequest, BikeDetailResponse>
{
    public override void Configure()
    {
        Put("bikes/{bikeId}/components/{id}");
        Description(d => d.Accepts<UpdateComponentRequest>("application/json").Produces<BikeDetailResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateComponentRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var bike = await db.Bikes.Include(b => b.Components).FirstOrDefaultAsync(b => b.Id == req.BikeId && b.UserId == userId, ct);
        var component = bike?.Components.FirstOrDefault(c => c.Id == req.Id);
        if (bike is null || component is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        CreateComponent.Apply(component, req);
        var part = req.Custom ? null : await PartCatalogue.FindAsync(db, component, ct);
        component.PartId = part?.Id;
        if (part is null && !req.Custom) await ContributionOutbox.EnqueueAsync(db, component, time, ct);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateConcurrencyException)
        {
            AddError("This part changed on another device. Reload it and try again.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        await Send.OkAsync(await BikeQueries.DetailAsync(db, bike, await MemberClock.ForAsync(db, User.UserId(), time, ct), ct), ct);
    }
}

public sealed class ComponentIdRequest
{
    public Guid BikeId { get; set; }

    public Guid Id { get; set; }
}

public sealed class DeleteComponent(VelomineDbContext db) : Endpoint<ComponentIdRequest>
{
    public override void Configure()
    {
        Delete("bikes/{bikeId}/components/{id}");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(ComponentIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var deleted = await db.BikeComponents
            .Where(c => c.Id == req.Id && c.BikeId == req.BikeId && db.Bikes.Any(b => b.Id == c.BikeId && b.UserId == userId))
            .ExecuteDeleteAsync(ct);
        if (deleted == 0) await Send.NotFoundAsync(ct);
        else await Send.NoContentAsync(ct);
    }
}
