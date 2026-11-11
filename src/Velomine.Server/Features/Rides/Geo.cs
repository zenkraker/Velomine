namespace Velomine.Server.Features.Rides;

/// <summary>
/// The one great-circle distance on the WGS-84 sphere: rides, privacy zones and nearby-club search all use it, so a
/// distance computed in one place matches the distance computed in another.
/// </summary>
public static class Geo
{
    private const double EarthRadiusM = 6_371_000;

    /// <summary>Metres between two points on the sphere, by the haversine formula.</summary>
    public static double Metres(double latitude1, double longitude1, double latitude2, double longitude2)
    {
        static double Radians(double degrees) => degrees * Math.PI / 180;

        var dLatitude = Radians(latitude2 - latitude1);
        var dLongitude = Radians(longitude2 - longitude1);
        var a = Math.Sin(dLatitude / 2) * Math.Sin(dLatitude / 2)
            + Math.Cos(Radians(latitude1)) * Math.Cos(Radians(latitude2))
            * Math.Sin(dLongitude / 2) * Math.Sin(dLongitude / 2);
        return EarthRadiusM * 2 * Math.Asin(Math.Sqrt(a));
    }

    public static double Kilometres(double latitude1, double longitude1, double latitude2, double longitude2) =>
        Metres(latitude1, longitude1, latitude2, longitude2) / 1000;
}
