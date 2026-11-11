using System.Globalization;
using System.Xml.Linq;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Routes;

/// <summary>One point of a route. Elevation is in metres; null when the source has none here.</summary>
public readonly record struct RoutePoint(double Latitude, double Longitude, float? Elevation);

/// <summary>A line read from a file, before the member has named and confirmed it.</summary>
public sealed record RouteDraft(string? Name, IReadOnlyList<RoutePoint> Points);

/// <summary>A route file that cannot be used. The message is meant for the member.</summary>
public sealed class RouteFileException(string message) : Exception(message);

/// <summary>
/// Everything about a line that is not storage: how far and how steep it is, how it is thinned for storage and how it
/// is read from and written to GPX. Distance is the ride code's great-circle distance and climbing is its elevation
/// method, so a route and a ride over the same road agree.
/// </summary>
public static class RouteGeometry
{
    /// <summary>
    /// The most points a stored route keeps. A 150 km road ride keeps well under this at a 2 m tolerance, and 1,500
    /// points is a few dozen kilobytes in the database and draws instantly on a phone (a ride's streams are served at
    /// the same default).
    /// </summary>
    public const int MaxStoredPoints = 1500;

    /// <summary>The most points a request may send to be stored; the server thins them to <see cref="MaxStoredPoints"/>.</summary>
    public const int MaxAcceptedPoints = 5000;

    /// <summary>A line shorter than this is a mistake (a ride that never left the house), not a route.</summary>
    public const double MinDistanceM = 100;

    /// <summary>Thinning starts at this deviation from the original line, in metres.</summary>
    private const double StartToleranceM = 2;

    /// <summary>
    /// A very dense file is thinned by a plain stride before the line is simplified, so the cost stays bounded
    /// whatever a file contains.
    /// </summary>
    private const int PreDecimateAbove = 20_000;

    public static bool IsValid(double latitude, double longitude) =>
        double.IsFinite(latitude) && double.IsFinite(longitude)
        && latitude is >= -90 and <= 90 && longitude is >= -180 and <= 180;

    /// <summary>The spacing the line is sampled at before climbing is counted, about one sample a second at riding speed.</summary>
    private const double ClimbSpacingM = 10;

    /// <summary>
    /// Distance along the line, and climbing counted by the ride method (<see cref="RideMetrics.ElevationChange"/>).
    /// That method is made for samples a second apart, so the line is first sampled every 10 m by interpolating
    /// between its points. A thinned line then climbs what the original did, and a route and a ride over the same road
    /// agree.
    /// </summary>
    public static (double DistanceM, double? ClimbingM) Measure(IReadOnlyList<RoutePoint> points)
    {
        var along = new double[points.Count];
        for (var i = 1; i < points.Count; i++)
            along[i] = along[i - 1] + Geo.Metres(points[i - 1].Latitude, points[i - 1].Longitude, points[i].Latitude, points[i].Longitude);
        var distance = points.Count == 0 ? 0 : along[^1];

        if (FilledElevation(points) is not { } elevation || distance < ClimbSpacingM * 2) return (distance, null);

        var samples = new List<float?>();
        var segment = 0;
        for (var at = 0.0; at <= distance; at += ClimbSpacingM)
        {
            while (segment < points.Count - 2 && along[segment + 1] < at) segment++;
            var length = along[segment + 1] - along[segment];
            var t = length <= 0 ? 0 : Math.Clamp((at - along[segment]) / length, 0, 1);
            samples.Add((float)(elevation[segment] + t * (elevation[segment + 1] - elevation[segment])));
        }

        return (distance, RideMetrics.ElevationChange(samples).Gain);
    }

    /// <summary>
    /// Thins a line to at most <paramref name="maxPoints"/> points with Ramer-Douglas-Peucker: the tolerance starts
    /// small and grows until the line fits. The first and last point always stay.
    /// </summary>
    public static List<RoutePoint> Simplify(IReadOnlyList<RoutePoint> points, int maxPoints = MaxStoredPoints)
    {
        if (points.Count <= 2) return [.. points];
        IReadOnlyList<RoutePoint> source = points.Count > PreDecimateAbove ? Stride(points, PreDecimateAbove) : points;

        // Metres on a flat plane around the middle of the line: exact enough for a tolerance of a few metres.
        var middleLatitude = source.Average(p => p.Latitude);
        var xScale = 111_320 * Math.Cos(middleLatitude * Math.PI / 180);
        const double yScale = 110_574;
        var x = source.Select(p => p.Longitude * xScale).ToArray();
        var y = source.Select(p => p.Latitude * yScale).ToArray();
        // Height counts as a third dimension, so a straight road over a hill keeps the points that shape its profile.
        var z = FilledElevation(source) is { } elevation ? elevation.Select(e => (double)e).ToArray() : new double[source.Count];

        var tolerance = StartToleranceM;
        while (true)
        {
            var keep = Reduce(x, y, z, tolerance);
            var count = keep.Count(k => k);
            if (count <= maxPoints || tolerance > 100_000)
            {
                var result = new List<RoutePoint>(count);
                for (var i = 0; i < keep.Length; i++)
                    if (keep[i]) result.Add(source[i]);
                return result;
            }

            tolerance *= 1.5;
        }
    }

    private static List<RoutePoint> Stride(IReadOnlyList<RoutePoint> points, int target)
    {
        var step = (double)(points.Count - 1) / (target - 1);
        var result = new List<RoutePoint>(target);
        for (var i = 0; i < target; i++) result.Add(points[(int)Math.Round(i * step)]);
        return result;
    }

    private static bool[] Reduce(double[] x, double[] y, double[] z, double tolerance)
    {
        var keep = new bool[x.Length];
        keep[0] = keep[^1] = true;
        var pending = new Stack<(int From, int To)>();
        pending.Push((0, x.Length - 1));
        while (pending.Count > 0)
        {
            var (from, to) = pending.Pop();
            var farthest = -1;
            var farthestDistance = tolerance;
            for (var i = from + 1; i < to; i++)
            {
                var d = DistanceToSegment(x[i], y[i], z[i], x[from], y[from], z[from], x[to], y[to], z[to]);
                if (d <= farthestDistance) continue;
                farthestDistance = d;
                farthest = i;
            }

            if (farthest < 0) continue;
            keep[farthest] = true;
            pending.Push((from, farthest));
            pending.Push((farthest, to));
        }

        return keep;
    }

    private static double DistanceToSegment(
        double px, double py, double pz, double ax, double ay, double az, double bx, double by, double bz)
    {
        var dx = bx - ax;
        var dy = by - ay;
        var dz = bz - az;
        var lengthSquared = dx * dx + dy * dy + dz * dz;
        var t = lengthSquared == 0 ? 0 : Math.Clamp(((px - ax) * dx + (py - ay) * dy + (pz - az) * dz) / lengthSquared, 0, 1);
        return Math.Sqrt(Math.Pow(px - (ax + t * dx), 2) + Math.Pow(py - (ay + t * dy), 2) + Math.Pow(pz - (az + t * dz), 2));
    }

    /// <summary>
    /// Elevation for every point, or null when no point has one. A gap takes the nearest known value before it (or
    /// after it at the start), so the profile has no holes and the storage rule "all points or none" holds.
    /// </summary>
    public static float[]? FilledElevation(IReadOnlyList<RoutePoint> points)
    {
        if (points.All(p => p.Elevation is null)) return null;
        var result = new float[points.Count];
        var last = points.First(p => p.Elevation is not null).Elevation!.Value;
        for (var i = 0; i < points.Count; i++)
        {
            last = points[i].Elevation ?? last;
            result[i] = last;
        }

        return result;
    }

    /// <summary>Reads the tracks of a GPX file, or its planned route when it has no track.</summary>
    public static RouteDraft ReadGpx(byte[] data)
    {
        XDocument document;
        try
        {
            document = XmlRideFiles.Load(data);
        }
        catch (RideParseException)
        {
            throw new RouteFileException("The file is not a GPX file.");
        }

        var root = document.Root;
        if (root is null || !root.Name.LocalName.Equals("gpx", StringComparison.OrdinalIgnoreCase))
            throw new RouteFileException("The file is not a GPX file.");

        var elements = root.Named("trkpt").ToList();
        if (elements.Count == 0) elements = [.. root.Named("rtept")];

        var points = new List<RoutePoint>(elements.Count);
        foreach (var element in elements)
        {
            if (XmlRideFiles.Number(element.Attribute("lat")?.Value) is not { } latitude
                || XmlRideFiles.Number(element.Attribute("lon")?.Value) is not { } longitude
                || !IsValid(latitude, longitude))
                continue;
            var elevation = XmlRideFiles.Number(element.Elements().FirstOrDefault(e =>
                e.Name.LocalName.Equals("ele", StringComparison.OrdinalIgnoreCase))?.Value);
            points.Add(new RoutePoint(latitude, longitude, elevation is { } e ? (float)e : null));
        }

        if (points.Count < 2) throw new RouteFileException("The file has no route or track with at least two points.");

        string? NameOf(string parent) => root.Elements()
            .Where(e => e.Name.LocalName.Equals(parent, StringComparison.OrdinalIgnoreCase))
            .Select(e => e.Elements().FirstOrDefault(c => c.Name.LocalName.Equals("name", StringComparison.OrdinalIgnoreCase))?.Value)
            .FirstOrDefault(n => !string.IsNullOrWhiteSpace(n))?.Trim();
        var name = NameOf("metadata") ?? NameOf("trk") ?? NameOf("rte");
        return new RouteDraft(name is { Length: > 120 } ? name[..120] : name, points);
    }

    /// <summary>A GPX 1.1 file with one track: what a bike computer loads.</summary>
    public static byte[] ToGpx(string name, string? description, IReadOnlyList<RoutePoint> points)
    {
        XNamespace ns = "http://www.topografix.com/GPX/1/1";
        var segment = new XElement(ns + "trkseg");
        foreach (var point in points)
        {
            var element = new XElement(
                ns + "trkpt",
                new XAttribute("lat", point.Latitude.ToString("0.000000", CultureInfo.InvariantCulture)),
                new XAttribute("lon", point.Longitude.ToString("0.000000", CultureInfo.InvariantCulture)));
            if (point.Elevation is { } elevation)
                element.Add(new XElement(ns + "ele", elevation.ToString("0.#", CultureInfo.InvariantCulture)));
            segment.Add(element);
        }

        var track = new XElement(ns + "trk", new XElement(ns + "name", name));
        if (!string.IsNullOrWhiteSpace(description)) track.Add(new XElement(ns + "desc", description));
        track.Add(segment);

        var document = new XDocument(
            new XDeclaration("1.0", "utf-8", null),
            new XElement(
                ns + "gpx",
                new XAttribute("version", "1.1"),
                new XAttribute("creator", "Velomine"),
                new XElement(ns + "metadata", new XElement(ns + "name", name)),
                track));
        using var stream = new MemoryStream();
        document.Save(stream);
        return stream.ToArray();
    }

    /// <summary>The stored line as points.</summary>
    public static List<RoutePoint> PointsOf(RouteLine line) =>
    [
        .. line.Latitude.Select((latitude, i) => new RoutePoint(latitude, line.Longitude[i], line.Elevation?[i])),
    ];
}
