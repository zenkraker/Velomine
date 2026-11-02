using System.Xml.Linq;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>Reads TCX activities, one ride per activity. Running activities are refused: Velomine is for cycling.</summary>
public static class TcxParser
{
    public static IReadOnlyList<ParsedRide> Parse(XDocument document)
    {
        var rides = new List<ParsedRide>();
        foreach (var activity in document.Root!.Named("Activity"))
        {
            var sport = activity.Attribute("Sport")?.Value;
            if (sport is not null && !sport.Equals("Biking", StringComparison.OrdinalIgnoreCase) && !sport.Equals("Other", StringComparison.OrdinalIgnoreCase))
                throw new RideParseException("not_cycling", $"The activity is \"{sport}\", not cycling.");

            var points = new List<(DateTimeOffset, Sample)>();
            foreach (var trackpoint in activity.Named("Trackpoint"))
            {
                if (XmlRideFiles.Time(trackpoint.First("Time")?.Value) is not { } time) continue;
                points.Add((time, ReadTrackpoint(trackpoint)));
            }

            if (points.Count >= 2) rides.Add(XmlRideFiles.Build(points[0].Item1, points));
        }

        if (rides.Count == 0)
            throw new RideParseException("no_timestamps", "The TCX file has no activity with timestamped trackpoints.");
        return rides;
    }

    private static Sample ReadTrackpoint(XElement point)
    {
        var position = point.First("Position");
        return new Sample(0)
        {
            Latitude = XmlRideFiles.Number(position?.First("LatitudeDegrees")?.Value),
            Longitude = XmlRideFiles.Number(position?.First("LongitudeDegrees")?.Value),
            Altitude = XmlRideFiles.Number(point.First("AltitudeMeters")?.Value) is { } a ? (float)a : null,
            Distance = XmlRideFiles.Number(point.First("DistanceMeters")?.Value) is { } d ? (float)d : null,
            HeartRate = XmlRideFiles.Short(XmlRideFiles.Number(point.First("HeartRateBpm")?.First("Value")?.Value)),
            // Cadence is a direct child for cycling; Watts and Speed live in the TPX extension.
            Cadence = XmlRideFiles.Short(XmlRideFiles.Number(point.Elements().FirstOrDefault(e => e.Name.LocalName == "Cadence")?.Value)),
            Power = XmlRideFiles.Short(XmlRideFiles.Number(point.First("Watts")?.Value)),
            Speed = XmlRideFiles.Number(point.First("Speed")?.Value) is { } s ? (float)s : null,
        };
    }
}
