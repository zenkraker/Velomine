using System.Globalization;
using System.IO.Compression;
using System.Text;
using Dynastream.Fit;
using DateTime = System.DateTime;

namespace Velomine.Server.Tests.Rides;

/// <summary>Builds small ride files for tests, so no binary fixtures are kept in the repository.</summary>
public static class TestRideFiles
{
    public static readonly DateTime Start = new(2026, 10, 3, 8, 0, 0, DateTimeKind.Utc);

    public sealed record FitSession(
        DateTime Start,
        int Seconds,
        Sport Sport = Sport.Cycling,
        ushort? NormalizedPower = null,
        int? TimerSeconds = null,
        IReadOnlyList<(int Start, int Stop)>? Pauses = null);

    /// <summary>A FIT file with 1 Hz records: 150 bpm, 200 W, 90 rpm, 8 m/s north, climbing 0.1 m/s.</summary>
    public static byte[] Fit(params FitSession[] sessions)
    {
        using var stream = new MemoryStream();
        var encode = new Encode(ProtocolVersion.V20);
        encode.Open(stream);

        var fileId = new FileIdMesg();
        fileId.SetType(Dynastream.Fit.File.Activity);
        fileId.SetManufacturer(Manufacturer.Garmin);
        fileId.SetProduct(1);
        fileId.SetSerialNumber(1234);
        encode.Write(fileId);

        foreach (var session in sessions)
        {
            WriteTimer(encode, session.Start, EventType.Start);
            foreach (var pause in session.Pauses ?? [])
            {
                WriteTimer(encode, session.Start.AddSeconds(pause.Start), EventType.Stop);
                WriteTimer(encode, session.Start.AddSeconds(pause.Stop), EventType.Start);
            }

            for (var s = 0; s < session.Seconds; s++)
            {
                var record = new RecordMesg();
                record.SetTimestamp(new Dynastream.Fit.DateTime(session.Start.AddSeconds(s)));
                record.SetPositionLat((int)((46.0 + s * 8 / 111_195.0) * (2147483648.0 / 180.0)));
                record.SetPositionLong((int)(11.0 * (2147483648.0 / 180.0)));
                record.SetAltitude(300 + s * 0.1f);
                record.SetSpeed(8);
                record.SetDistance(s * 8f);
                record.SetHeartRate(150);
                record.SetPower(200);
                record.SetCadence(90);
                record.SetTemperature(18);
                encode.Write(record);
            }

            var end = session.Start.AddSeconds(session.Seconds);
            WriteTimer(encode, end, EventType.StopAll);

            var summary = new SessionMesg();
            summary.SetTimestamp(new Dynastream.Fit.DateTime(end));
            summary.SetStartTime(new Dynastream.Fit.DateTime(session.Start));
            summary.SetTotalElapsedTime(session.Seconds);
            summary.SetTotalTimerTime(session.TimerSeconds ?? session.Seconds);
            summary.SetSport(session.Sport);
            if (session.NormalizedPower is { } np) summary.SetNormalizedPower(np);
            encode.Write(summary);
        }

        var last = sessions[^1].Start.AddSeconds(sessions[^1].Seconds);
        var activity = new ActivityMesg();
        activity.SetTimestamp(new Dynastream.Fit.DateTime(last));
        activity.SetLocalTimestamp(new Dynastream.Fit.DateTime(last.AddHours(2)).GetTimeStamp()); // UTC+2
        activity.SetNumSessions((ushort)sessions.Length);
        encode.Write(activity);

        encode.Close();
        return stream.ToArray();
    }

    private static void WriteTimer(Encode encode, DateTime time, EventType type)
    {
        var timer = new EventMesg();
        timer.SetTimestamp(new Dynastream.Fit.DateTime(time));
        timer.SetEvent(Dynastream.Fit.Event.Timer);
        timer.SetEventType(type);
        timer.SetTimerTrigger((byte)TimerTrigger.Manual);
        encode.Write(timer);
    }

    /// <summary>A GPX track of <paramref name="count"/> points, one second apart, riding north at 8 m/s.</summary>
    public static string Gpx(int count, Func<int, string>? extensions = null, string trackName = "Test ride", DateTime? start = null, bool withTime = true)
    {
        var t0 = start ?? Start;
        var points = new StringBuilder();
        for (var i = 0; i < count; i++)
        {
            var lat = (46.0 + i * 8 / 111_195.0).ToString("F6", CultureInfo.InvariantCulture);
            var time = withTime ? $"<time>{t0.AddSeconds(i):yyyy-MM-ddTHH:mm:ssZ}</time>" : "";
            points.Append(CultureInfo.InvariantCulture, $"<trkpt lat=\"{lat}\" lon=\"11.000000\"><ele>{300 + i * 0.1:F1}</ele>{time}{(extensions is null ? "" : "<extensions>" + extensions(i) + "</extensions>")}</trkpt>");
        }

        return $"""
            <?xml version="1.0" encoding="UTF-8"?>
            <gpx version="1.1" creator="test" xmlns="http://www.topografix.com/GPX/1/1"
                 xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1"
                 xmlns:gpxpx="http://www.garmin.com/xmlschemas/PowerExtension/v1">
              <trk><name>{trackName}</name><trkseg>{points}</trkseg></trk>
            </gpx>
            """;
    }

    public static string Tcx(string sport, int count) => $"""
        <?xml version="1.0" encoding="UTF-8"?>
        <TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
                                xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
          <Activities><Activity Sport="{sport}"><Id>{Start:yyyy-MM-ddTHH:mm:ssZ}</Id>
            <Lap StartTime="{Start:yyyy-MM-ddTHH:mm:ssZ}"><Track>
        {string.Concat(Enumerable.Range(0, count).Select(i => $"""
              <Trackpoint><Time>{Start.AddSeconds(i):yyyy-MM-ddTHH:mm:ssZ}</Time>
                <Position><LatitudeDegrees>{(46.0 + i * 8 / 111_195.0).ToString("F6", CultureInfo.InvariantCulture)}</LatitudeDegrees><LongitudeDegrees>11.0</LongitudeDegrees></Position>
                <AltitudeMeters>{(300 + i * 0.1).ToString("F1", CultureInfo.InvariantCulture)}</AltitudeMeters><DistanceMeters>{i * 8}</DistanceMeters>
                <HeartRateBpm><Value>150</Value></HeartRateBpm><Cadence>90</Cadence>
                <Extensions><ns3:TPX><ns3:Speed>8</ns3:Speed><ns3:Watts>200</ns3:Watts></ns3:TPX></Extensions></Trackpoint>
        """))}
            </Track></Lap></Activity></Activities>
        </TrainingCenterDatabase>
        """;

    public static byte[] Gzip(byte[] data)
    {
        using var output = new MemoryStream();
        using (var gzip = new GZipStream(output, CompressionLevel.Fastest, leaveOpen: true)) gzip.Write(data);
        return output.ToArray();
    }

    public static byte[] Bytes(string text) => Encoding.UTF8.GetBytes(text);
}
