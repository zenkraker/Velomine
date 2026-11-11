using System.Xml.Linq;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// Reads GPX tracks, one ride per track. Sensor values come from extensions, and extension names vary between
/// apps and are matched ignoring case: hr/heartrate, cad/cadence, atemp/temp, speed, power/PowerInWatts/watts.
/// </summary>
public static class GpxParser
{
    /// <summary>
    /// Track types that are clearly not a bike ride, so a Strava export's runs and hikes do not become rides. A file
    /// that says nothing is still read as a ride: many writers leave the type empty.
    /// </summary>
    private static readonly string[] OtherSports =
        ["run", "walk", "hike", "swim", "row", "ski", "snowboard", "skate", "paddle", "surf", "kayak", "canoe",
            "yoga", "workout", "weight", "stair", "sail", "horse", "golf", "climb"];

    public static IReadOnlyList<ParsedRide> Parse(XDocument document)
    {
        var rides = new List<ParsedRide>();
        var otherSport = 0;
        var fileName = document.Root!.Elements()
            .FirstOrDefault(e => e.Name.LocalName.Equals("metadata", StringComparison.OrdinalIgnoreCase))?.ChildText("name");
        foreach (var track in document.Root!.Named("trk"))
        {
            var type = track.First("type")?.Value;
            if (type is not null && OtherSports.Any(s => type.Contains(s, StringComparison.OrdinalIgnoreCase)))
            {
                otherSport++;
                continue;
            }

            var points = new List<(DateTimeOffset, Sample)>();
            foreach (var point in track.Named("trkpt"))
            {
                if (XmlRideFiles.Time(point.First("time")?.Value) is not { } time) continue;
                points.Add((time, ReadPoint(point)));
            }

            if (points.Count >= 2)
            {
                var dimensions = RideDimensions.FromText(type);
                var hasPositions = points.Any(p => p.Item2.Latitude is not null && p.Item2.Longitude is not null);
                if (dimensions.Environment is null && hasPositions)
                    dimensions = dimensions with { Environment = Environments.Outdoor };
                // The track's own name wins over the file's; either is only used when it says something.
                var title = RideText.Clean(track.ChildText("name")) is { } trackName ? trackName : fileName;
                rides.Add(XmlRideFiles.Build(points[0].Item1, points, dimensions: dimensions, title: title));
            }
        }

        if (rides.Count == 0)
        {
            throw otherSport > 0
                ? new RideParseException("not_cycling", "The activity is not cycling.")
                : new RideParseException("no_timestamps", "The GPX file has no track with timestamped points.");
        }
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
