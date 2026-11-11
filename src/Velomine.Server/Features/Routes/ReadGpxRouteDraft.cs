using FastEndpoints;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Routes;

public sealed class GpxRouteDraftRequest
{
    /// <summary>
    /// A GPX file with a track or a planned route. This property only describes the form field in the API document;
    /// the file itself is read from <c>Files</c> in the handler.
    /// </summary>
    public required IFormFile File { get; set; }
}

/// <summary>Reads a GPX file into a line for the member to look at. Nothing is kept: the file is not stored.</summary>
public sealed class ReadGpxRouteDraft(VelomineDbContext db) : Endpoint<GpxRouteDraftRequest, RouteDraftResponse>
{
    private const long MaxFileBytes = 30L * 1024 * 1024;

    public override void Configure()
    {
        Post("routes/gpx-draft");
        Options(b => b.RequireRateLimiting("uploads"));
        AllowFileUploads(dontAutoBindFormData: true);
        Description(d => d.Accepts<GpxRouteDraftRequest>("multipart/form-data").Produces<RouteDraftResponse>(200).ProducesProblem(400).Produces(401).Produces(404).ProducesProblem(413).ProducesProblem(429), clearDefaults: true);
    }

    public override async Task HandleAsync(GpxRouteDraftRequest req, CancellationToken ct)
    {
        if (await RouteQueries.ClubIdAsync(db, User.UserId(), ct) is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        if (Files.Count != 1 || Files[0].Length == 0)
        {
            AddError("Send exactly one file, and it must not be empty.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        if (Files[0].Length > MaxFileBytes)
        {
            AddError("The file is larger than 30 MB.");
            await Send.ErrorsAsync(413, ct);
            return;
        }

        byte[] data;
        await using (var content = Files[0].OpenReadStream())
        {
            using var buffer = new MemoryStream();
            await content.CopyToAsync(buffer, ct);
            data = buffer.ToArray();
        }

        RouteDraft draft;
        try
        {
            draft = RouteGeometry.ReadGpx(data);
        }
        catch (RouteFileException ex)
        {
            AddError(ex.Message);
            await Send.ErrorsAsync(400, ct);
            return;
        }

        if (RouteGeometry.Measure(draft.Points).DistanceM < RouteGeometry.MinDistanceM)
        {
            AddError("This line is shorter than 100 metres.");
            await Send.ErrorsAsync(400, ct);
            return;
        }

        var name = draft.Name ?? Path.GetFileNameWithoutExtension(Files[0].FileName);
        await Send.OkAsync(RouteQueries.Draft(string.IsNullOrWhiteSpace(name) ? null : name, draft.Points, measureStored: true), ct);
    }
}
