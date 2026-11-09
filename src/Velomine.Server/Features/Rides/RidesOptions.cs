namespace Velomine.Server.Features.Rides;

/// <summary>Bound from "Velomine" (environment: VELOMINE__FILESPATH).</summary>
public sealed class RidesOptions
{
    /// <summary>The folder for uploaded ride files (docker-compose mounts a volume here).</summary>
    public string FilesPath { get; set; } = "data/files";
}
