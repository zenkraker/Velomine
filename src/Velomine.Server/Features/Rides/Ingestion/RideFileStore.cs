using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// Keeps every uploaded file exactly as received, named by its SHA-256, so a ride can be read again when a parser
/// improves and the same file uploaded twice takes space once.
/// </summary>
public sealed class RideFileStore(IOptions<RidesOptions> options)
{
    private string Root => Path.GetFullPath(options.Value.FilesPath);

    private string Originals => Path.Combine(Root, "originals");

    /// <summary>Writes the content and returns its SHA-256 as 64 lowercase hex characters.</summary>
    public Task<string> SaveAsync(Stream content, CancellationToken ct, long? maxBytes = null) =>
        HashedFile.SaveAsync(
            Path.Combine(Root, "tmp"),
            sha => Path.Combine(Originals, sha[..2], sha),
            content,
            maxBytes,
            ct);

    public Task<byte[]> ReadAsync(string sha, CancellationToken ct) => File.ReadAllBytesAsync(PathFor(sha), ct);

    /// <summary>Opens a stored file for reading, or null when it is not there.</summary>
    public FileStream? OpenRead(string sha)
    {
        var path = PathFor(sha);
        return File.Exists(path) ? new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read, 81920, useAsync: true) : null;
    }

    public void Delete(string sha)
    {
        var path = PathFor(sha);
        if (File.Exists(path)) File.Delete(path);
    }

    /// <summary>The size of all stored original files, in bytes. Cached: the admin page must not walk the tree each time.</summary>
    public long TotalBytes()
    {
        var now = Environment.TickCount64;
        if (_measuredAt is { } measured && now - measured < TotalBytesCacheMs) return _totalBytes;
        _totalBytes = Directory.Exists(Originals)
            ? new DirectoryInfo(Originals).EnumerateFiles("*", SearchOption.AllDirectories).Sum(f => f.Length)
            : 0;
        _measuredAt = now;
        return _totalBytes;
    }

    private const long TotalBytesCacheMs = 5 * 60 * 1000;
    private long _totalBytes;
    private long? _measuredAt;

    private string PathFor(string sha) => HashedFile.PathFor(Path.Combine(Originals, sha[..2]), sha);
}
