using Dynastream.Fit;

namespace Velomine.Server.Features.Rides;

/// <summary>
/// Writes a ride the server holds as a FIT file, so a ride read from GPX or TCX can leave as FIT. The message order is
/// the one the phone's own recorder writes: file id, a timer start, one record per sample, a timer stop, one lap, one
/// session and the activity. Only the recorded power goes in: estimated watts are a guess about the ride, not a
/// measurement of it, so they stay out of the file.
/// </summary>
public static class RideFitWriter
{
    /// <summary>Degrees to semicircles, the unit FIT stores a position in.</summary>
    private const double SemicirclesPerDegree = 2147483648.0 / 180.0;

    public static byte[] Write(Ride ride, RideStreams streams)
    {
        var start = ride.StartTime ?? throw new ArgumentException("A ride without a start time has no FIT file.", nameof(ride));
        var samples = streams.Time.Length;
        var end = samples == 0 ? start : start.AddSeconds(streams.Time[^1]);
        var elapsed = ride.ElapsedS ?? (samples == 0 ? 0 : streams.Time[^1]);
        var timer = ride.MovingS ?? elapsed;
        // A GPX or TCX file need not carry a distance at all: the ride's total was then measured from the positions, so
        // the records say the same step by step.
        var distance = streams.Distance ?? FromPositions(streams);
        var total = ride.DistanceM ?? Last(distance) ?? 0;

        using var output = new MemoryStream();
        var encode = new Encode(ProtocolVersion.V20);
        encode.Open(output);

        var fileId = new FileIdMesg();
        fileId.SetType(Dynastream.Fit.File.Activity);
        fileId.SetManufacturer(Manufacturer.Development);
        encode.Write(fileId);

        WriteTimer(encode, start, EventType.Start);

        for (var i = 0; i < samples; i++)
        {
            var record = new RecordMesg();
            record.SetTimestamp(new Dynastream.Fit.DateTime(start.AddSeconds(streams.Time[i]).UtcDateTime));
            if (At(streams.Latitude, i) is { } latitude) record.SetPositionLat((int)(latitude * SemicirclesPerDegree));
            if (At(streams.Longitude, i) is { } longitude) record.SetPositionLong((int)(longitude * SemicirclesPerDegree));
            if (At(streams.Altitude, i) is { } altitude) record.SetAltitude(altitude);
            if (At(streams.Speed, i) is { } speed) record.SetSpeed(speed);
            if (At(distance, i) is { } metres) record.SetDistance(metres);
            if (At(streams.HeartRate, i) is { } heartRate) record.SetHeartRate((byte)heartRate);
            if (At(streams.Power, i) is { } power) record.SetPower((ushort)power);
            if (At(streams.Cadence, i) is { } cadence) record.SetCadence((byte)cadence);
            if (At(streams.Temperature, i) is { } temperature) record.SetTemperature((sbyte)temperature);
            encode.Write(record);
        }

        WriteTimer(encode, end, EventType.StopAll);

        var lap = new LapMesg();
        lap.SetTimestamp(new Dynastream.Fit.DateTime(end.UtcDateTime));
        lap.SetStartTime(new Dynastream.Fit.DateTime(start.UtcDateTime));
        lap.SetTotalElapsedTime((float)elapsed);
        lap.SetTotalTimerTime((float)timer);
        lap.SetTotalDistance((float)total);
        lap.SetSport(Sport.Cycling);
        encode.Write(lap);

        var session = new SessionMesg();
        session.SetTimestamp(new Dynastream.Fit.DateTime(end.UtcDateTime));
        session.SetStartTime(new Dynastream.Fit.DateTime(start.UtcDateTime));
        session.SetTotalElapsedTime((float)elapsed);
        session.SetTotalTimerTime((float)timer);
        session.SetTotalDistance((float)total);
        session.SetSport(Sport.Cycling);
        encode.Write(session);

        var activity = new ActivityMesg();
        activity.SetTimestamp(new Dynastream.Fit.DateTime(end.UtcDateTime));
        activity.SetLocalTimestamp(new Dynastream.Fit.DateTime(end.UtcDateTime.AddMinutes(ride.UtcOffsetMinutes ?? 0)).GetTimeStamp());
        activity.SetNumSessions(1);
        encode.Write(activity);

        encode.Close();
        return output.ToArray();
    }

    private static void WriteTimer(Encode encode, DateTimeOffset time, EventType type)
    {
        var timer = new EventMesg();
        timer.SetTimestamp(new Dynastream.Fit.DateTime(time.UtcDateTime));
        timer.SetEvent(Dynastream.Fit.Event.Timer);
        timer.SetEventType(type);
        timer.SetTimerTrigger((byte)TimerTrigger.Manual);
        encode.Write(timer);
    }

    /// <summary>The distance so far at each sample, added up from the positions, for a file that has none of its own.</summary>
    private static float?[]? FromPositions(RideStreams streams)
    {
        if (streams.Latitude is not { } latitudes || streams.Longitude is not { } longitudes) return null;

        var distances = new float?[streams.Time.Length];
        var metres = 0.0;
        for (var i = 0; i < distances.Length; i++)
        {
            if (i > 0
                && latitudes[i - 1] is { } fromLat && longitudes[i - 1] is { } fromLon
                && latitudes[i] is { } toLat && longitudes[i] is { } toLon)
                metres += Ingestion.RideMetrics.Haversine(fromLat, fromLon, toLat, toLon);
            distances[i] = (float)metres;
        }

        return distances;
    }

    /// <summary>One signal's value at one sample, or null when the ride has no value there.</summary>
    private static T? At<T>(T?[]? values, int index) where T : struct =>
        values is not null && index < values.Length ? values[index] : null;

    private static double? Last(float?[]? values) =>
        values is { Length: > 0 } ? values[^1] : null;
}
