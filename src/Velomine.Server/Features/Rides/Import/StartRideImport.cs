using System.IO.Compression;
using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides.Import;

namespace Velomine.Server.Features.Rides;

public sealed class StartRideImportRequest
{
    /// <summary>
    /// A Strava bulk export (the ZIP Strava hands out). Only activities.csv and activities/ are read; photos and the
    /// other files in the archive are ignored.
    /// </summary>
    public required IFormFile File { get; set; }
}

public sealed record StartRideImportResponse(Guid ImportId, string Status);

/// <summary>
/// Saves the archive exactly as received and answers 202 right away. The activities are read in the background:
/// poll GET rides/imports/{id} until its status is no longer "processing".
/// </summary>
public sealed class StartRideImport(VelomineDbContext db, ImportStore store, ImportQueue queue, TimeProvider clock, IOptions<RideImportOptions> options)
    : Endpoint<StartRideImportRequest, StartRideImportResponse>
{
    public override void Configure()
    {
        Post("rides/imports");
        Options(b => b.RequireRateLimiting("imports"));
        AllowFileUploads(dontAutoBindFormData: true);
        Description(d => d.Accepts<StartRideImportRequest>("multipart/form-data")
            .Produces<StartRideImportResponse>(202)
            .ProducesProblem(400)
            .Produces(401)
            .ProducesProblem(413)
            .ProducesProblem(429), clearDefaults: true);
    }

    public override async Task HandleAsync(StartRideImportRequest req, CancellationToken ct)
    {
        if (Files.Count != 1 || Files[0].Length == 0)
        {
            AddError("Send exactly one Strava export archive.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        var file = Files[0];
        if (file.Length > options.Value.MaxArchiveBytes)
        {
            AddError($"The archive is larger than {options.Value.MaxArchiveMb} MB.");
            await Send.ErrorsAsync(413, ct);
            return;
        }

        var userId = User.UserId();
        string sha;
        await using (var content = file.OpenReadStream()) sha = await store.SaveAsync(userId, content, ct);

        if (!await IsStravaExportAsync(userId, sha, ct))
        {
            store.Delete(userId, sha);
            AddError("This is not a Strava export: it has no activities.csv.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        // The same archive uploaded again (a retry, or a second browser tab) is the same import.
        var earlier = await FindAsync(userId, sha, ct);
        if (earlier is not null)
        {
            if (earlier.Status != RideImportStatus.Processing) store.Delete(userId, sha);
            await Send.ResponseAsync(new StartRideImportResponse(earlier.Id, Status(earlier)), 202, ct);
            return;
        }

        var import = new RideImport
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            Source = StravaExport.Source,
            ArchiveSha256 = sha,
            FileName = StravaExport.FileName(file.FileName, "strava-export.zip"),
            Status = RideImportStatus.Processing,
            CreatedAt = clock.GetUtcNow(),
        };
        db.RideImports.Add(import);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // Two requests with the same archive at the same moment: the other one won.
            db.Entry(import).State = EntityState.Detached;
            var winner = await FindAsync(userId, sha, ct);
            if (winner is null) throw;
            if (winner.Status != RideImportStatus.Processing) store.Delete(userId, sha);
            await Send.ResponseAsync(new StartRideImportResponse(winner.Id, Status(winner)), 202, ct);
            return;
        }

        queue.Enqueue(import.Id);
        await Send.ResponseAsync(new StartRideImportResponse(import.Id, "processing"), 202, ct);
    }

    private Task<RideImport?> FindAsync(Guid userId, string sha, CancellationToken ct) =>
        db.RideImports.AsNoTracking().FirstOrDefaultAsync(i => i.UserId == userId && i.ArchiveSha256 == sha, ct);

    private async Task<bool> IsStravaExportAsync(Guid userId, string sha, CancellationToken ct)
    {
        await using var archive = store.OpenRead(userId, sha);
        if (archive is null) return false;
        try
        {
            using var zip = new ZipArchive(archive, ZipArchiveMode.Read);
            return zip.Entries.Any(e => string.Equals(e.FullName, StravaExport.CsvEntry, StringComparison.OrdinalIgnoreCase));
        }
        catch (InvalidDataException)
        {
            return false;
        }
    }

    private static string Status(RideImport import) => import.Status.ToString().ToLowerInvariant();

}
