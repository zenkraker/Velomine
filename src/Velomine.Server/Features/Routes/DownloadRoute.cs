using FastEndpoints;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Routes;

/// <summary>
/// Short-lived download links for one route's GPX, so the phone can hand the address to the system browser, which
/// saves the file. The token names the member and the route and is signed by Data Protection; nothing secret is in it
/// and it works for two minutes. It is checked again when it is used, so a member who has left the club gets nothing.
/// </summary>
public sealed class RouteDownloadTokens(IDataProtectionProvider provider, TimeProvider time)
{
    public TimeSpan Lifetime { get; } = TimeSpan.FromMinutes(2);

    private ITimeLimitedDataProtector Protector => provider.CreateProtector("velomine.route-download").ToTimeLimitedDataProtector();

    public string Issue(Guid userId, Guid routeId) =>
        Protector.Protect($"{userId:N}.{routeId:N}", time.GetUtcNow().Add(Lifetime));

    public (Guid UserId, Guid RouteId)? Read(string token)
    {
        try
        {
            var parts = Protector.Unprotect(token, out var expires).Split('.');
            return expires > time.GetUtcNow() && parts.Length == 2
                && Guid.TryParseExact(parts[0], "N", out var userId)
                && Guid.TryParseExact(parts[1], "N", out var routeId)
                ? (userId, routeId)
                : null;
        }
        catch (System.Security.Cryptography.CryptographicException)
        {
            return null;
        }
    }
}

/// <summary>An address that downloads the route as a GPX file, for anyone who may open the route.</summary>
public sealed class CreateRouteDownloadLink(VelomineDbContext db, RouteDownloadTokens tokens, TimeProvider time)
    : Endpoint<RouteIdRequest, RouteDownloadLinkResponse>
{
    public override void Configure()
    {
        Post("routes/{id}/gpx-link");
        Description(d => d.Produces<RouteDownloadLinkResponse>(200).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(RouteIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var clubId = await RouteQueries.ClubIdAsync(db, userId, ct);
        if (!await RouteQueries.Visible(db, userId, clubId).AnyAsync(r => r.Id == req.Id, ct))
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        await Send.OkAsync(
            new RouteDownloadLinkResponse(
                "/api/v1/routes/downloads/" + Uri.EscapeDataString(tokens.Issue(userId, req.Id)),
                time.GetUtcNow().Add(tokens.Lifetime)),
            ct);
    }
}

public sealed class DownloadRouteRequest
{
    public string Token { get; set; } = "";
}

/// <summary>Streams the route as GPX. The address is the sign-in: it comes from <see cref="CreateRouteDownloadLink"/>.</summary>
public sealed class DownloadRoute(VelomineDbContext db, RouteDownloadTokens tokens) : Endpoint<DownloadRouteRequest>
{
    public override void Configure()
    {
        Get("routes/downloads/{token}");
        AllowAnonymous();
        Description(d => d.Produces(200, contentType: "application/gpx+xml").Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(DownloadRouteRequest req, CancellationToken ct)
    {
        if (tokens.Read(req.Token) is not { } who)
        {
            await Send.UnauthorizedAsync(ct);
            return;
        }

        // Access is decided now, not when the link was made.
        var clubId = await RouteQueries.ClubIdAsync(db, who.UserId, ct);
        var route = await RouteQueries.Visible(db, who.UserId, clubId).AsNoTracking()
            .Include(r => r.Line)
            .FirstOrDefaultAsync(r => r.Id == who.RouteId, ct);
        if (route?.Line is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var gpx = RouteGeometry.ToGpx(route.Name, route.Description, RouteGeometry.PointsOf(route.Line));
        await Send.BytesAsync(gpx, GpxFileName(route.Name), "application/gpx+xml", cancellation: ct);
    }

    /// <summary>The route's name as a file name that is safe on any system.</summary>
    internal static string GpxFileName(string name)
    {
        var cleaned = new string([.. name.Select(c => char.IsLetterOrDigit(c) || c is '-' or '_' ? c : '-')]).Trim('-');
        return (cleaned.Length == 0 ? "route" : cleaned.Length > 80 ? cleaned[..80] : cleaned) + ".gpx";
    }
}
