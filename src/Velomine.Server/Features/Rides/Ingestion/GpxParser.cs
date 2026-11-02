using System.Xml.Linq;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// Reads GPX tracks, one ride per track. Sensor values come from extensions, and extension names vary between
/// apps and are matched ignoring case: hr/heartrate, cad/cadence, atemp/temp, speed, power/PowerInWatts/watts.
/// </summary>
public static class GpxParser
{
    public static IReadOnlyList<ParsedRide> Parse(XDocument document)
    {
        var rides = new List<ParsedRide>();
        foreach (var track in document.Root!.Named("trk"))
        {
            var points = new List<(DateTimeOffset, Sample)>();
            foreach (var point in track.Named("trkpt"))
            {
                if (XmlRideFiles.Time(point.First("time")?.Value) is not { } time) continue;
                points.Add((time, ReadPoint(point)));
            }

            if (points.Count >= 2) rides.Add(XmlRideFiles.Build(points[0].Item1, points));
        }

        if (rides.Count == 0)
            throw new RideParseException("no_timestamps", "The GPX file has no track with timestamped points.");
        return rides;
    }

    private static Sample ReadPoint(XElement point)
    {
        var sample = new Sample(0)
        {
            Latitude = XmlRideFiles.Number(point.Attribute("lat")?.Value),
            Longitude = XmlRideFiles.Number(point.Attribute("lon")?.Value),
            Altitude = XmlRideFiles.Number(point.First("ele")?.Value) is { } e ? (float)e : null,
        };

        // Extensions can be nested (gpxtpx:TrackPointExtension, gpxpx:PowerExtension), so every descendant is checked.
        foreach (var extension in point.Named("extensions").SelectMany(x => x.DescendantsAndSelf()))
        {
            var value = XmlRideFiles.Number(extension.Value);
            if (value is null || extension.HasElements) continue;
            sample = extension.Name.LocalName.ToLowerInvariant() switch
            {
                "hr" or "heartrate" => sample with { HeartRate = XmlRideFiles.Short(value) },
                "cad" or "cadence" => sample with { Cadence = XmlRideFiles.Short(value) },
                "atemp" or "temp" or "temperature" => sample with { Temperature = XmlRideFiles.Short(value) },
                "speed" => sample with { Speed = (float)value.Value },
                "power" or "powerinwatts" or "watts" => sample with { Power = XmlRideFiles.Short(value) },
                _ => sample,
            };
        }

        return sample;
    }
}
