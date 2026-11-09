using System.Xml.Linq;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// Reads TCX activities, one ride per activity. Running activities are refused: Velomine is for cycling.
/// Laps are kept as boundaries; their numbers are recomputed from the samples during ingestion.
/// </summary>
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

            var points = new List<(DateTimeOffset Time, Sample Sample)>();
            var lapRanges = new List<(DateTimeOffset Start, DateTimeOffset End)>();

            var laps = activity.Named("Lap").ToList();
            if (laps.Count == 0)
            {
                // Some writers put the trackpoints straight under the activity, without laps.
                ReadPoints(activity, points);
            }
            else
            {
                foreach (var lap in laps)
                {
                    var lapPoints = new List<(DateTimeOffset Time, Sample Sample)>();
                    ReadPoints(lap, lapPoints);
                    if (lapPoints.Count == 0) continue;

                    var start = XmlRideFiles.Time(lap.Attribute("StartTime")?.Value) ?? lapPoints.Min(p => p.Time);
                    var seconds = XmlRideFiles.Number(lap.First("TotalTimeSeconds")?.Value);
                    var end = seconds is { } s ? start.AddSeconds(s) : lapPoints.Max(p => p.Time);
                    if (end > start) lapRanges.Add((start, end));
                    points.AddRange(lapPoints);
                }
            }

            if (points.Count < 2) continue;

            // TCX has no discipline: an activity is only "Biking". GPS points do say the ride was outdoors.
            var hasPositions = points.Any(p => p.Item2.Latitude is not null && p.Item2.Longitude is not null);
            var first = points.Min(p => p.Time);
            var parsedLaps = lapRanges
                .Select(l => new ParsedLap((l.Start - first).TotalSeconds, (l.End - first).TotalSeconds))
                .Where(l => l.EndS > l.StartS)
                .ToList();
            rides.Add(XmlRideFiles.Build(
                points[0].Item1,
                points,
                dimensions: hasPositions ? new RideDimensions(null, null, Environments.Outdoor, null) : RideDimensions.Unset,
                laps: parsedLaps));
        }

        if (rides.Count == 0)
            throw new RideParseException("no_timestamps", "The TCX file has no activity with timestamped trackpoints.");
        return rides;
    }

    private static void ReadPoints(XElement parent, List<(DateTimeOffset Time, Sample Sample)> points)
    {
        foreach (var trackpoint in parent.Named("Trackpoint"))
        {
            if (XmlRideFiles.Time(trackpoint.First("Time")?.Value) is not { } time) continue;
            points.Add((time, ReadTrackpoint(trackpoint)));
        }
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
