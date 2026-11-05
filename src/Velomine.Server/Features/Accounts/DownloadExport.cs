using FastEndpoints;

namespace Velomine.Server.Features.Accounts;

public sealed class DownloadExportRequest
{
    public string Token { get; set; } = "";
}

/// <summary>Streams the member's data as a ZIP. The address is the sign-in: it comes from <see cref="CreateExportLink"/>.</summary>
public sealed class DownloadExport(ExportTokens tokens, AccountExport export, TimeProvider time) : Endpoint<DownloadExportRequest>
{
    public override void Configure()
    {
        Get("accounts/export/{token}");
        AllowAnonymous();
        Description(d => d.Produces(200, contentType: "application/zip").Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(DownloadExportRequest req, CancellationToken ct)
    {
        if (tokens.Read(req.Token) is not { } userId)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        // Built in a temporary file (deleted when closed), so a large library never sits in memory and the ZIP is
        // complete before the first byte goes out.
        var path = Path.Combine(Path.GetTempPath(), "velomine-export-" + Guid.NewGuid().ToString("N"));
        await using var temp = new FileStream(path, FileMode.CreateNew, FileAccess.ReadWrite, FileShare.None, 81920, FileOptions.DeleteOnClose | FileOptions.Asynchronous);
        await export.WriteAsync(userId, temp, ct);
        temp.Position = 0;
        await Send.StreamAsync(temp, $"velomine-data-{time.GetUtcNow():yyyy-MM-dd}.zip", temp.Length, "application/zip", cancellation: ct);
    }
}
