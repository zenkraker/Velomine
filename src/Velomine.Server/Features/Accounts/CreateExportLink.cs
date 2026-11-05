using FastEndpoints;

namespace Velomine.Server.Features.Accounts;

/// <summary>An address, on this server, that downloads the member's data as a ZIP. It works for two minutes.</summary>
public sealed record ExportLinkResponse(string Path, DateTimeOffset ExpiresAt);

public sealed class CreateExportLink(ExportTokens tokens, TimeProvider time) : EndpointWithoutRequest<ExportLinkResponse>
{
    public override void Configure()
    {
        Post("accounts/me/export-link");
        Description(d => d.Produces<ExportLinkResponse>(200).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CancellationToken ct) =>
        await Send.OkAsync(new ExportLinkResponse("/api/v1/accounts/export/" + Uri.EscapeDataString(tokens.Issue(User.UserId())), time.GetUtcNow().Add(ExportTokens.Lifetime)), ct);
}
