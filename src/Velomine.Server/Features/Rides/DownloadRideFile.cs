using System.IO.Compression;
using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Rides;

/// <summary>The two shapes a ride's file is downloaded in.</summary>
public static class RideFileFormats
{
    /// <summary>The file exactly as the member uploaded it.</summary>
    public const string Original = "original";

    /// <summary>The same ride as a FIT file: the original when it is one already, otherwise one the server writes.</summary>
    public const string Fit = "fit";

    public static bool IsKnown(string format) => format is Original or Fit;
}

public sealed class DownloadRideFileRequest
{
    public Guid Id { get; set; }

    public string Token { get; set; } = "";

    /// <summary><c>original</c> or <c>fit</c>.</summary>
    public string Format { get; set; } = RideFileFormats.Original;
}

public sealed class DownloadRideFileValidator : Validator<DownloadRideFileRequest>
{
    public DownloadRideFileValidator() => RuleFor(x => x.Format).Must(RideFileFormats.IsKnown)
        .WithMessage("Use \"original\" or \"fit\".");
}

/// <summary>Downloads one ride's file. The address is the sign-in: it comes from <see cref="CreateRideFileLink"/>.</summary>
public sealed class DownloadRideFile(VelomineDbContext db, RideFileTokens tokens, RideFileStore files)
    : Endpoint<DownloadRideFileRequest>
{
    public override void Configure()
    {
        Get("rides/{id}/file/{token}");
        AllowAnonymous();
        Description(d => d
            .Produces(200, contentType: "application/octet-stream")
            .Produces(400)
            .Produces(401)
            .Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(DownloadRideFileRequest req, CancellationToken ct)
    {
        if (tokens.Read(req.Token) is not { } userId)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        var ride = await db.Rides.AsNoTracking()
            .Include(r => r.Streams)
            .FirstOrDefaultAsync(r => r.Id == req.Id && r.UserId == userId && r.DuplicateOf == null, ct);
        if (ride is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (req.Format == RideFileFormats.Original)
        {
            using var original = files.OpenRead(ride.FileSha256);
            if (original is null)
            {
                await Send.NotFoundAsync(ct);
                return;
            }

            // As received: a multi-activity FIT is one file for several rides, and it goes out whole.
            await Send.StreamAsync(original, ride.FileName, original.Length, "application/octet-stream", cancellation: ct);
            return;
        }

        if (IsFitName(ride.FileName))
        {
            var stored = await files.ReadAsync(ride.FileSha256, ct);
            var data = ride.FileName.EndsWith(".gz", StringComparison.OrdinalIgnoreCase) ? Unzip(stored) : stored;
            await Send.BytesAsync(data, FileNameWithoutGzip(ride.FileName), "application/octet-stream", cancellation: ct);
            return;
        }

        if (ride.Streams is null)
        {
            AddError("A FIT file is written from the ride's samples, and this ride has none.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        await Send.BytesAsync(
            RideFitWriter.Write(ride, ride.Streams),
            Path.GetFileNameWithoutExtension(ride.FileName) + ".fit",
            "application/octet-stream",
            cancellation: ct);
    }

    private static bool IsFitName(string fileName) =>
        fileName.EndsWith(".fit", StringComparison.OrdinalIgnoreCase)
        || fileName.EndsWith(".fit.gz", StringComparison.OrdinalIgnoreCase);

    private static string FileNameWithoutGzip(string fileName) =>
        fileName.EndsWith(".gz", StringComparison.OrdinalIgnoreCase) ? Path.GetFileNameWithoutExtension(fileName) : fileName;

    private static byte[] Unzip(byte[] compressed)
    {
        using var gzip = new GZipStream(new MemoryStream(compressed), CompressionMode.Decompress);
        using var output = new MemoryStream();
        gzip.CopyTo(output);
        return output.ToArray();
    }
}
