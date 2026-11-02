using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Rides;

public sealed class UploadRideRequest
{
    /// <summary>A FIT, GPX or TCX file (optionally gzipped).</summary>
    public IFormFile File { get; set; } = null!;

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
        RuleFor(x => x.File).NotNull().Must(f => f.Length > 0).WithMessage("The file is empty.");
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
        AllowFileUploads();
    }

    public override async Task HandleAsync(UploadRideRequest req, CancellationToken ct)
    {
        var userId = User.UserId();

        string sha;
        await using (var content = req.File.OpenReadStream()) sha = await files.SaveAsync(content, ct);

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
            FileName = SafeName(req.File.FileName),
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
