using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Rides;

public sealed class UploadRideRequest
{
    /// <summary>
    /// A FIT, GPX or TCX file (optionally gzipped). This property only describes the form field in the API document;
    /// the file itself is read from <c>Files</c> in the handler, so stray text fields cannot break the upload.
    /// </summary>
    public required IFormFile File { get; set; }

    /// <summary>
    /// Makes retries safe: the same key from the same member with the same file returns the ride from the first try.
    /// The phone sends its own ride id.
    /// </summary>
    [FromHeader("Idempotency-Key", IsRequired = false)]
    public string? IdempotencyKey { get; set; }
}

public sealed record UploadRideResponse(Guid RideId, string Status);

public sealed class UploadRideValidator : Validator<UploadRideRequest>
{
    public UploadRideValidator()
    {
        RuleFor(x => x.IdempotencyKey).MaximumLength(128);
    }
}

/// <summary>
/// Saves the file exactly as received and answers 202 right away. The ride is read in the background:
/// poll GET rides/{id} until its status is no longer "processing".
/// </summary>
public sealed class UploadRide(VelomineDbContext db, RideFileStore files, IngestionQueue queue, TimeProvider clock)
    : Endpoint<UploadRideRequest, UploadRideResponse>
{
    public override void Configure()
    {
        Post("rides/uploads");
        Options(b => b.RequireRateLimiting("uploads"));
        // The generated Dart client sends a text field named "file" next to the file part. Automatic form binding
        // would refuse that, so the file is read from Files instead.
        AllowFileUploads(dontAutoBindFormData: true);
        Description(d => d.Accepts<UploadRideRequest>("multipart/form-data").Produces<UploadRideResponse>(202).ProducesProblem(400).Produces(401).ProducesProblem(409).ProducesProblem(413).ProducesProblem(429), clearDefaults: true);
    }

    /// <summary>One ride file, not an archive: anything bigger than this is refused.</summary>
    private const long MaxFileBytes = 30L * 1024 * 1024;

    public override async Task HandleAsync(UploadRideRequest req, CancellationToken ct)
    {
        if (Files.Count != 1 || Files[0].Length == 0)
        {
            AddError("Send exactly one file, and it must not be empty.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        var file = Files[0];
        if (file.Length > MaxFileBytes)
        {
            AddError("The file is larger than 30 MB.");
            await Send.ErrorsAsync(413, ct);
            return;
        }
        var userId = User.UserId();

        string sha;
        await using (var content = file.OpenReadStream()) sha = await files.SaveAsync(content, ct);

        if (!string.IsNullOrEmpty(req.IdempotencyKey))
        {
            var earlier = await FindByKeyAsync(userId, req.IdempotencyKey, ct);
            if (earlier is not null)
            {
                await ReplayAsync(earlier, sha, ct);
                return;
            }
        }

        var ride = new Ride
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            Status = RideStatus.Processing,
            IdempotencyKey = string.IsNullOrEmpty(req.IdempotencyKey) ? null : req.IdempotencyKey,
            FileSha256 = sha,
            FileName = SafeName(file.FileName),
            UploadedAt = clock.GetUtcNow(),
        };
        db.Rides.Add(ride);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException) when (ride.IdempotencyKey is not null)
        {
            // Two requests with the same key at the same moment: the other one won.
            db.Entry(ride).State = EntityState.Detached;
            var winner = await FindByKeyAsync(userId, ride.IdempotencyKey, ct);
            if (winner is null) throw;
            await ReplayAsync(winner, sha, ct);
            return;
        }

        queue.Enqueue(ride.Id);
        await Send.ResponseAsync(new UploadRideResponse(ride.Id, "processing"), 202, ct);
    }

    private Task<Ride?> FindByKeyAsync(Guid userId, string key, CancellationToken ct) =>
        db.Rides.AsNoTracking().FirstOrDefaultAsync(r => r.UserId == userId && r.IdempotencyKey == key, ct);

    private async Task ReplayAsync(Ride earlier, string sha, CancellationToken ct)
    {
        if (earlier.FileSha256 != sha)
        {
            // The file just saved belongs to no ride: do not leave it on disk. A file another member also uploaded stays.
            if (!await db.Rides.AnyAsync(r => r.FileSha256 == sha, ct)) files.Delete(sha);
            AddError("This Idempotency-Key was already used with a different file.");
            await Send.ErrorsAsync(409, ct);
            return;
        }

        await Send.ResponseAsync(new UploadRideResponse(earlier.Id, earlier.Status.ToString().ToLowerInvariant()), 202, ct);
    }

    private static string SafeName(string? name)
    {
        var clean = Path.GetFileName(name ?? "") is { Length: > 0 } n ? n : "ride";
        return clean.Length > 256 ? clean[..256] : clean;
    }
}
