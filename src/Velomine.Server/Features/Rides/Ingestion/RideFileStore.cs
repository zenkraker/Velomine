using System.Security.Cryptography;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Options;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// Keeps every uploaded file exactly as received, named by its SHA-256, so a ride can be read again when a parser
/// improves and the same file uploaded twice takes space once.
/// </summary>
public sealed partial class RideFileStore(IOptions<RidesOptions> options)
{
    private string Root => Path.GetFullPath(options.Value.FilesPath);

    /// <summary>Writes the content and returns its SHA-256 as 64 lowercase hex characters.</summary>
    public async Task<string> SaveAsync(Stream content, CancellationToken ct)
    {
        Directory.CreateDirectory(Path.Combine(Root, "tmp"));
        var temp = Path.Combine(Root, "tmp", Guid.NewGuid().ToString("N"));
        string sha;
        await using (var output = File.Create(temp))
        {
            using var hash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
            var buffer = new byte[81920];
            int read;
            while ((read = await content.ReadAsync(buffer, ct)) > 0)
            {
                hash.AppendData(buffer, 0, read);
                await output.WriteAsync(buffer.AsMemory(0, read), ct);
            }

            sha = Convert.ToHexStringLower(hash.GetHashAndReset());
        }

        var target = PathFor(sha);
        Directory.CreateDirectory(Path.GetDirectoryName(target)!);
        if (File.Exists(target)) File.Delete(temp);
        else
        {
            try
            {
                File.Move(temp, target);
            }
            catch (IOException) when (File.Exists(target))
            {
                // Another upload of the same file won the race; the bytes are identical, so keep one copy.
                File.Delete(temp);
            }
        }
        return sha;
    }

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

    /// <summary>The size of all stored original files, in bytes.</summary>
    public long TotalBytes()
    {
        var originals = Path.Combine(Root, "originals");
        return Directory.Exists(originals)
            ? new DirectoryInfo(originals).EnumerateFiles("*", SearchOption.AllDirectories).Sum(f => f.Length)
            : 0;
    }

    // Only a hash we made ourselves can name a file, so a stored value can never point outside the folder.
    private string PathFor(string sha) => HexSha256().IsMatch(sha)
        ? Path.Combine(Root, "originals", sha[..2], sha)
        : throw new ArgumentException("Not a SHA-256.", nameof(sha));

    [GeneratedRegex("^[0-9a-f]{64}$")]
    private static partial Regex HexSha256();
}
