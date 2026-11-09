using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

public static class BikeKinds
{
    public static readonly string[] All = ["road", "gravel", "mountain", "ebike", "timetrial", "track", "city", "other"];
}

public sealed class Bike
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string Name { get; set; } = "";

    public string? Brand { get; set; }

    public string? Model { get; set; }

    /// <summary>The model year the make and model belong to.</summary>
    public int? ModelYear { get; set; }

    /// <summary>The build or specification level within the model, such as "SL 7" or "Comp".</summary>
    public string? BuildSpec { get; set; }

    /// <summary>The frame size, in whatever form the brand uses: 56, M, S3, 17.5".</summary>
    public string? FrameSize { get; set; }

    /// <summary>One of <see cref="BikeKinds.All"/>.</summary>
    public string Kind { get; set; } = "road";

    /// <summary>How far the wheel rolls in one turn. The phone recorder turns wheel sensor revolutions into distance with it.</summary>
    public int WheelCircumferenceMm { get; set; }

    /// <summary>Distance the bike had done before it was added here (a bike bought used). Counted in the bike's total.</summary>
    public double InitialDistanceM { get; set; }

    public DateOnly? PurchasedOn { get; set; }

    /// <summary>The bike new rides are given when they are imported. A member has at most one.</summary>
    public bool IsDefault { get; set; }

    /// <summary>An inactive (archived) bike is not offered for new rides but keeps the rides it has.</summary>
    public bool IsActive { get; set; } = true;

    public DateTimeOffset CreatedAt { get; set; }

    public uint Version { get; set; }

    public User? Owner { get; set; }

    public List<BikeComponent> Components { get; set; } = [];
}

/// <summary>A part on a bike (chain, tyres, brake pads...) with an optional limit for how long it should last.</summary>
public sealed class BikeComponent
{
    public Guid Id { get; set; }

    public Guid BikeId { get; set; }

    /// <summary>An id from <see cref="ComponentTypes"/>.</summary>
    public string Type { get; set; } = "";

    public string? Brand { get; set; }

    public string? Model { get; set; }

    /// <summary>The manufacturer part number, the code a mechanic looks up: "CN-M8100".</summary>
    public string? Mpn { get; set; }

    /// <summary>The barcode on the packaging, normalised to GTIN-14. Only parts bought boxed have one.</summary>
    public string? Gtin { get; set; }

    /// <summary>The shared catalogue entry this part is, when it is one. Null for a custom part and for a part the publisher has not listed yet.</summary>
    public Guid? PartId { get; set; }

    /// <summary>True for a part the member added themselves: it is never linked to the shared catalogue and never contributed.</summary>
    public bool IsCustom { get; set; }

    public DateOnly InstalledOn { get; set; }

    /// <summary>Set when the part was taken off. Rides after this date no longer count towards its wear.</summary>
    public DateOnly? RemovedOn { get; set; }

    /// <summary>The part is worn out after this distance, this many riding hours, or this many months: whichever comes first.</summary>
    public double? ExpectedDistanceM { get; set; }

    public double? ExpectedHours { get; set; }

    public int? ExpectedMonths { get; set; }

    public uint Version { get; set; }
}
