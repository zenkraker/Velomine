using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Rides;

public sealed class CreateRideFileLinkRequest
{
    public Guid Id { get; set; }

    /// <summary><c>original</c> for the file as received, <c>fit</c> for a FIT file written from the ride.</summary>
    public string Format { get; set; } = RideFileFormats.Original;
}

public sealed class CreateRideFileLinkValidator : Validator<CreateRideFileLinkRequest>
{
    public CreateRideFileLinkValidator() => RuleFor(x => x.Format).Must(RideFileFormats.IsKnown)
        .WithMessage("Use \"original\" or \"fit\".");
}

/// <summary>An address, on this server, that downloads one ride's file. It works for two minutes.</summary>
public sealed record RideFileLinkResponse(string Path, DateTimeOffset ExpiresAt);

/// <summary>
/// The two-minute link a browser can download without a sign-in of its own, like the data export's. Only the ride's
/// own member gets one: someone else's ride, a hidden duplicate and a ride whose file is gone all look the same.
/// </summary>
public sealed class CreateRideFileLink(VelomineDbContext db, RideFileTokens tokens, RideFileStore files, TimeProvider time)
    : Endpoint<CreateRideFileLinkRequest, RideFileLinkResponse>
{
    public override void Configure()
    {
        Post("rides/{id}/file-link");
        Description(d => d
            .Accepts<CreateRideFileLinkRequest>("application/json")
            .Produces<RideFileLinkResponse>(200)
            .ProducesProblem(400)
            .Produces(401)
            .Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CreateRideFileLinkRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var ride = await db.Rides.AsNoTracking()
            .Where(r => r.Id == req.Id && r.UserId == userId && r.DuplicateOf == null)
            .Select(r => new { r.Id, r.FileSha256 })
            .FirstOrDefaultAsync(ct);
        using var file = ride is null ? null : files.OpenRead(ride.FileSha256);
        if (ride is null || file is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (req.Format == RideFileFormats.Fit && !await db.RideStreams.AnyAsync(s => s.RideId == ride.Id, ct))
        {
            AddError("A FIT file is written from the ride's samples, and this ride has none.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        var token = Uri.EscapeDataString(tokens.Issue(userId));
        await Send.OkAsync(
            new RideFileLinkResponse(
                $"/api/v1/rides/{ride.Id}/file/{token}?format={req.Format}",
                time.GetUtcNow().Add(tokens.Lifetime)),
            ct);
    }
}
