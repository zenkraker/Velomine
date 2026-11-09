using FastEndpoints;
using FluentValidation;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

/// <summary>A member's build: the parts they fit to a bike, ready to apply to the next one of the same kind.</summary>
public sealed class BikeTemplate
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string Name { get; set; } = "";

    public DateTimeOffset CreatedAt { get; set; }

    public uint Version { get; set; }

    public User? Owner { get; set; }

    public List<BikeTemplatePart> Parts { get; set; } = [];
}

/// <summary>One part in a build template. It keeps the part's identity just as a component does.</summary>
public sealed class BikeTemplatePart
{
    public Guid Id { get; set; }

    public Guid TemplateId { get; set; }

    public string Type { get; set; } = "";

    public string? Brand { get; set; }

    public string? Model { get; set; }

    public string? Mpn { get; set; }

    public string? Gtin { get; set; }

    /// <summary>True when the part was custom on the bike, so applying the template keeps it out of the shared catalogue.</summary>
    public bool IsCustom { get; set; }

    public double? ExpectedDistanceM { get; set; }

    public double? ExpectedHours { get; set; }

    public int? ExpectedMonths { get; set; }
}

public sealed record TemplatePartResponse(
    Guid Id,
    string Type,
    string TypeName,
    string? Brand,
    string? Model,
    string? Mpn,
    string? Gtin,
    bool IsCustom,
    double? ExpectedDistanceM,
    double? ExpectedHours,
    int? ExpectedMonths);

public sealed record BikeTemplateResponse(Guid Id, string Name, DateTimeOffset CreatedAt, TemplatePartResponse[] Parts);

public sealed record ListTemplatesResponse(BikeTemplateResponse[] Templates);

public sealed class TemplatePartRequest
{
    /// <summary>An id from the component types list.</summary>
    public required string Type { get; set; }

    public string? Brand { get; set; }

    public string? Model { get; set; }

    /// <summary>The manufacturer part number, such as "CN-M8100". Optional, but it is what identifies the part.</summary>
    public string? Mpn { get; set; }

    /// <summary>The barcode on the packaging. Optional; a valid GTIN identifies the part on its own.</summary>
    public string? Gtin { get; set; }

    /// <summary>True to keep this part out of the shared catalogue.</summary>
    public bool IsCustom { get; set; }

    /// <summary>Worn out after this many metres, riding hours or months, whichever comes first.</summary>
    public double? ExpectedDistanceM { get; set; }

    public double? ExpectedHours { get; set; }

    public int? ExpectedMonths { get; set; }

    public BikeTemplatePart ToEntity(Guid templateId) => new()
    {
        Id = Guid.CreateVersion7(),
        TemplateId = templateId,
        Type = Type,
        Brand = PartIdentity.CanonicalBrand(Brand),
        Model = Model?.Trim(),
        Mpn = PartIdentity.NormaliseMpn(Mpn),
        Gtin = PartIdentity.TryNormaliseGtin(Gtin, out var gtin) ? gtin : null,
        IsCustom = IsCustom,
        ExpectedDistanceM = ExpectedDistanceM,
        ExpectedHours = ExpectedHours,
        ExpectedMonths = ExpectedMonths,
    };
}

public sealed class TemplatePartValidator : Validator<TemplatePartRequest>
{
    public TemplatePartValidator()
    {
        RuleFor(x => x.Type).Must(ComponentTypes.Ids.Contains).WithMessage("Unknown part type.");
        RuleFor(x => x.Brand).MaximumLength(100);
        RuleFor(x => x.Model).MaximumLength(100);
        RuleFor(x => x.Mpn).MaximumLength(64);
        RuleFor(x => x.Gtin).MaximumLength(20);
        RuleFor(x => x.Gtin).Must(g => string.IsNullOrWhiteSpace(g) || PartIdentity.TryNormaliseGtin(g, out _))
            .WithMessage("That is not a valid GTIN.");
        RuleFor(x => x.ExpectedDistanceM).GreaterThan(0).When(x => x.ExpectedDistanceM.HasValue);
        RuleFor(x => x.ExpectedHours).GreaterThan(0).When(x => x.ExpectedHours.HasValue);
        RuleFor(x => x.ExpectedMonths).GreaterThan(0).When(x => x.ExpectedMonths.HasValue);
    }
}

public sealed class CreateTemplateRequest
{
    public required string Name { get; set; }

    public required TemplatePartRequest[] Parts { get; set; }
}

public sealed class UpdateTemplateRequest
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    public required string Name { get; set; }

    public required TemplatePartRequest[] Parts { get; set; }
}

public sealed class SaveBikeAsTemplateRequest
{
    /// <summary>From the address.</summary>
    public Guid BikeId { get; set; }

    public required string Name { get; set; }
}

public sealed class ApplyTemplateRequest
{
    /// <summary>From the address.</summary>
    public Guid BikeId { get; set; }

    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    /// <summary>The day the parts are fitted. Rides from this day on count towards their wear.</summary>
    public required DateOnly InstalledOn { get; set; }
}

public sealed class CreateTemplateValidator : Validator<CreateTemplateRequest>
{
    public CreateTemplateValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Parts).NotEmpty().Must(p => p.Length <= 100).WithMessage("A template holds at most 100 parts.");
        RuleForEach(x => x.Parts).SetValidator(new TemplatePartValidator());
    }
}

public sealed class UpdateTemplateValidator : Validator<UpdateTemplateRequest>
{
    public UpdateTemplateValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Parts).NotEmpty().Must(p => p.Length <= 100).WithMessage("A template holds at most 100 parts.");
        RuleForEach(x => x.Parts).SetValidator(new TemplatePartValidator());
    }
}

public sealed class SaveBikeAsTemplateValidator : Validator<SaveBikeAsTemplateRequest>
{
    public SaveBikeAsTemplateValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
    }
}

public static class BikeTemplateQueries
{
    private static readonly Dictionary<string, int> TypeOrder =
        ComponentTypes.All.Select((t, index) => (t.Id, index)).ToDictionary(x => x.Id, x => x.index);

    public static BikeTemplateResponse Response(BikeTemplate template) => new(
        template.Id,
        template.Name,
        template.CreatedAt,
        [.. template.Parts
            .OrderBy(p => TypeOrder.TryGetValue(p.Type, out var order) ? order : int.MaxValue)
            .ThenBy(p => p.Type)
            .Select(p => new TemplatePartResponse(
                p.Id, p.Type, ComponentTypes.NameOf(p.Type), p.Brand, p.Model, p.Mpn, p.Gtin, p.IsCustom,
                p.ExpectedDistanceM, p.ExpectedHours, p.ExpectedMonths))]);
}
