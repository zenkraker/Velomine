using System.Security.Cryptography;
using System.Text.RegularExpressions;

namespace Velomine.Server.Features.Rides;

/// <summary>
/// Writes a stream to disk under the SHA-256 of its bytes, so the same file uploaded twice takes space once. The ride
/// files and the import archives share this: one implementation of the hashing, the temporary file and the race.
/// </summary>
public static partial class HashedFile
{
    /// <summary>
    /// Saves the content and returns its SHA-256 as 64 lowercase hex characters. <paramref name="maxBytes"/> caps what
    /// the stream may really hold, which is not the same as the size a container claims.
    /// </summary>
    public static async Task<string> SaveAsync(
        string tempFolder,
        Func<string, string> targetFor,
        Stream content,
        long? maxBytes,
        CancellationToken ct)
    {
        Directory.CreateDirectory(tempFolder);
        var temp = Path.Combine(tempFolder, Guid.NewGuid().ToString("N") + ".tmp");
        try
        {
            string sha;
            long total = 0;
            await using (var output = File.Create(temp))
            {
                using var hash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
                var buffer = new byte[81920];
                int read;
                while ((read = await content.ReadAsync(buffer, ct)) > 0)
                {
                    total += read;
                    if (maxBytes is { } max && total > max)
                        throw new InvalidDataException("The file is larger than it is allowed to be.");
                    hash.AppendData(buffer, 0, read);
                    await output.WriteAsync(buffer.AsMemory(0, read), ct);
                }

                sha = Convert.ToHexStringLower(hash.GetHashAndReset());
            }

            var target = targetFor(sha);
            Directory.CreateDirectory(Path.GetDirectoryName(target)!);
            if (File.Exists(target))
            {
                File.Delete(temp);
            }
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
        catch
        {
            // A cancelled or oversized upload must not leave its bytes behind.
            if (File.Exists(temp)) File.Delete(temp);
            throw;
        }
    }

    // Only a hash we made ourselves can name a file, so a stored value can never point outside the folder.
    public static string PathFor(string folder, string sha) => HexSha256().IsMatch(sha)
        ? Path.Combine(folder, sha)
        : throw new ArgumentException("Not a SHA-256.", nameof(sha));

    [GeneratedRegex("^[0-9a-f]{64}$")]
    private static partial Regex HexSha256();
}
