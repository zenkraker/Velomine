using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Rides.Import;

/// <summary>
/// Holds an import archive while it is being read, under the member's id and named by its SHA-256 so the same archive
/// uploaded twice takes space once. Unlike a ride file, an archive is deleted as soon as the import finishes.
/// </summary>
public sealed class ImportStore(IOptions<RidesOptions> options)
{
    private string Root => Path.GetFullPath(Path.Combine(options.Value.FilesPath, "imports"));

    private string Folder(Guid userId) => Path.Combine(Root, userId.ToString("N"));

    /// <summary>Writes the content and returns its SHA-256 as 64 lowercase hex characters.</summary>
    public Task<string> SaveAsync(Guid userId, Stream content, CancellationToken ct)
    {
        var folder = Folder(userId);
        return HashedFile.SaveAsync(folder, sha => Path.Combine(folder, sha), content, maxBytes: null, ct);
    }

    /// <summary>Opens a stored archive for reading, or null when it is not there.</summary>
    public FileStream? OpenRead(Guid userId, string sha)
    {
        var path = PathFor(userId, sha);
        return File.Exists(path) ? new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read, 81920, useAsync: true) : null;
    }

    public void Delete(Guid userId, string sha)
    {
        var path = PathFor(userId, sha);
        if (File.Exists(path)) File.Delete(path);
    }

    /// <summary>Deletes every stored archive no import still needs: crashed uploads, and imports that finished or failed.</summary>
    public void KeepOnly(IReadOnlySet<(Guid UserId, string Sha)> keep)
    {
        if (!Directory.Exists(Root)) return;
        foreach (var file in Directory.EnumerateFiles(Root, "*", SearchOption.AllDirectories))
        {
            var user = Guid.TryParseExact(Path.GetFileName(Path.GetDirectoryName(file)), "N", out var id) ? id : Guid.Empty;
            if (keep.Contains((user, Path.GetFileName(file)))) continue;
            if (DateTime.UtcNow - File.GetLastWriteTimeUtc(file) < RecentUpload) continue; // an upload may still be in flight
            try
            {
                File.Delete(file); // best effort: a leftover archive is not worth failing the start over
            }
            catch (IOException)
            {
            }
        }
    }

    /// <summary>How new an archive may be before the sweep leaves it alone, in case its import row is not written yet.</summary>
    private static readonly TimeSpan RecentUpload = TimeSpan.FromMinutes(10);

    private string PathFor(Guid userId, string sha) => HashedFile.PathFor(Folder(userId), sha);
}
