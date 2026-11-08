using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Privacy;

/// <summary>
/// The one seam every non-owner view goes through. Today it hides the route when the member has not shared routes;
/// privacy zones and start/end trimming slot in here without touching callers.
/// </summary>
public static class PrivacyRules
{
    public static RideStreamsResponse ForViewer(RideStreamsResponse streams, bool showRoute) =>
        showRoute ? streams : streams with { Latitude = null, Longitude = null };
}
