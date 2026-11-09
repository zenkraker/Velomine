namespace Velomine.Server.Features.Bikes;

/// <summary>
/// No longer written: the catalogue is publisher-authoritative, so a local entry can never disagree with the shared
/// one. The table is kept for one release before it is dropped, as the migration rule asks.
/// </summary>
public sealed class CatalogueConflict
{
    public Guid Id { get; set; }

    public string Key { get; set; } = "";

    public string Type { get; set; } = "";

    public string LocalBrand { get; set; } = "";

    public string LocalModel { get; set; } = "";

    public string? LocalMpn { get; set; }

    public string? LocalGtin { get; set; }

    public string SharedBrand { get; set; } = "";

    public string SharedModel { get; set; } = "";

    public string? SharedMpn { get; set; }

    public string? SharedGtin { get; set; }

    public string IncomingHash { get; set; } = "";

    public string Status { get; set; } = "pending";

    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? ResolvedAt { get; set; }
}
