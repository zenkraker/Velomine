namespace Velomine.Server.Features.Rides.Import;

/// <summary>Bound from "Velomine:Imports" (environment: VELOMINE__IMPORTS__MAXARCHIVEMB).</summary>
public sealed class RideImportOptions
{
    /// <summary>The largest archive accepted, in megabytes. The web image allows the server to enforce this.</summary>
    public int MaxArchiveMb { get; set; } = 1024;

    public long MaxArchiveBytes => MaxArchiveMb * 1024L * 1024L;
}
