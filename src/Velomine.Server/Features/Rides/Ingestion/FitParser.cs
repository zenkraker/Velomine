using System.Reflection;
using Dynastream.Fit;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>
/// Reads FIT files with Garmin's own SDK. A FIT file can hold several sessions (a multisport or a split recording);
/// each cycling session becomes its own ride. Sessions that are not cycling are refused.
/// </summary>
public static class FitParser
{
    private const double SemicirclesToDegrees = 180.0 / 2147483648.0;

    private sealed record Raw(System.DateTime Time, Sample Sample);

    public static IReadOnlyList<ParsedRide> Parse(byte[] data)
    {
        var decode = new Decode();
        using var stream = new MemoryStream(data);
        if (!decode.IsFIT(stream)) throw new RideParseException("invalid_file", "Not a FIT file.");
        stream.Position = 0;
        if (!decode.CheckIntegrity(stream)) throw new RideParseException("corrupt_file", "The FIT file is damaged or incomplete.");
        stream.Position = 0;

        var records = new List<Raw>();
        var sessions = new List<(System.DateTime Start, double Elapsed, double? Timer, Sport? Sport, int? NormalizedPower)>();
        var timerEvents = new List<(System.DateTime Time, EventType Type)>();
        string? device = null;
        int? offsetMinutes = null;

        var broadcaster = new MesgBroadcaster();
        decode.MesgEvent += broadcaster.OnMesg;
        decode.MesgDefinitionEvent += broadcaster.OnMesgDefinition;
        broadcaster.RecordMesgEvent += (_, e) =>
        {
            var record = (RecordMesg)e.mesg;
            if (record.GetTimestamp() is not { } stamp) return;
            records.Add(new Raw(stamp.GetDateTime(), new Sample(
                0,
                record.GetPositionLat() is { } lat ? lat * SemicirclesToDegrees : null,
                record.GetPositionLong() is { } lon ? lon * SemicirclesToDegrees : null,
                record.GetEnhancedAltitude() ?? record.GetAltitude(),
                record.GetEnhancedSpeed() ?? record.GetSpeed(),
                record.GetDistance(),
                record.GetHeartRate(),
                record.GetPower() is { } power ? (short?)Math.Min(power, short.MaxValue) : null,
                record.GetCadence(),
                record.GetTemperature())));
        };
        broadcaster.SessionMesgEvent += (_, e) =>
        {
            var session = (SessionMesg)e.mesg;
            if (session.GetStartTime() is not { } start) return;
            sessions.Add((
                start.GetDateTime(),
                session.GetTotalElapsedTime() ?? 0,
                session.GetTotalTimerTime(),
                session.GetSport(),
                session.GetNormalizedPower()));
        };
        broadcaster.EventMesgEvent += (_, e) =>
        {
            var timer = (EventMesg)e.mesg;
            if (timer.GetEvent() != Event.Timer) return;
            if (timer.GetTimestamp() is not { } stamp || timer.GetEventType() is not { } type) return;
            timerEvents.Add((stamp.GetDateTime(), type));
        };
        broadcaster.FileIdMesgEvent += (_, e) => device ??= ManufacturerName(((FileIdMesg)e.mesg).GetManufacturer());
        broadcaster.ActivityMesgEvent += (_, e) =>
        {
            var activity = (ActivityMesg)e.mesg;
            if (activity.GetTimestamp() is { } utc && activity.GetLocalTimestamp() is { } local)
                offsetMinutes ??= (int)Math.Round(((long)local - utc.GetTimeStamp()) / 60.0);
        };

        try
        {
            decode.Read(stream);
        }
        catch (FitException)
        {
            throw new RideParseException("corrupt_file", "The FIT file could not be read.");
        }

        if (records.Count == 0) throw new RideParseException("no_records", "The FIT file has no recorded data.");

        var rides = new List<ParsedRide>();
        if (sessions.Count == 0)
        {
            rides.Add(Build(records, device, offsetMinutes, normalizedPower: null, timerEvents));
        }
        else
        {
            foreach (var session in sessions.OrderBy(s => s.Start))
            {
                if (session.Sport is { } sport && sport is not (Sport.Cycling or Sport.EBiking or Sport.Generic))
                    throw new RideParseException("not_cycling", $"The session is \"{sport}\", not cycling.");

                var end = session.Start.AddSeconds(session.Elapsed + 1);
                var inSession = records.Where(r => r.Time >= session.Start && r.Time <= end).ToList();
                if (inSession.Count >= 2)
                {
                    rides.Add(Build(
                        inSession,
                        device,
                        offsetMinutes,
                        session.NormalizedPower,
                        timerEvents.Where(e => e.Time >= session.Start && e.Time <= end),
                        session.Elapsed,
                        session.Timer));
                }
            }
        }

        if (rides.Count == 0) throw new RideParseException("no_records", "The FIT file has no cycling data.");
        return rides;
    }

    // The SDK lists manufacturers as numeric constants; look the name up so the ride shows "Garmin", not "1".
    private static string? ManufacturerName(ushort? id) => id is null
        ? null
        : typeof(Manufacturer).GetFields(BindingFlags.Public | BindingFlags.Static)
            .FirstOrDefault(f => f.IsLiteral && f.GetRawConstantValue() is ushort value && value == id)?.Name
            ?? id.ToString();

    private static ParsedRide Build(
        List<Raw> records,
        string? device,
        int? offsetMinutes,
        int? normalizedPower,
        IEnumerable<(System.DateTime Time, EventType Type)> timerEvents,
        double? deviceElapsedS = null,
        double? deviceMovingS = null)
    {
        var first = records.Min(r => r.Time);
        var last = records.Max(r => r.Time);
        var eventList = timerEvents.ToList();
        var pauseEnd = eventList.Select(e => e.Time).DefaultIfEmpty(last).Max();
        var samples = records.OrderBy(r => r.Time).Select(r => r.Sample with { T = (r.Time - first).TotalSeconds }).ToList();
        return new ParsedRide
        {
            StartTime = new DateTimeOffset(System.DateTime.SpecifyKind(first, DateTimeKind.Utc)),
            UtcOffsetMinutes = offsetMinutes,
            Device = device,
            DeviceNormalizedPowerW = normalizedPower is > 0 ? normalizedPower : null,
            DeviceElapsedS = deviceElapsedS is > 0 ? deviceElapsedS : null,
            DeviceMovingS = deviceMovingS is > 0 ? deviceMovingS : null,
            Pauses = BuildPauses(eventList, first, pauseEnd),
            Samples = samples,
        };
    }

    /// <summary>Turns timer stop/start events into paused intervals relative to the first sample.</summary>
    private static IReadOnlyList<PauseInterval> BuildPauses(
        IEnumerable<(System.DateTime Time, EventType Type)> events,
        System.DateTime first,
        System.DateTime last)
    {
        var pauses = new List<PauseInterval>();
        double? pausedAt = null;
        foreach (var item in events.OrderBy(e => e.Time))
        {
            if (item.Time < first) continue;
            if (item.Time > last) break;
            var seconds = (item.Time - first).TotalSeconds;

            if (item.Type is EventType.Stop or EventType.StopAll)
            {
                pausedAt ??= seconds;
            }
            else if (item.Type is EventType.Start && pausedAt is { } start)
            {
                if (seconds > start) pauses.Add(new PauseInterval(start, seconds));
                pausedAt = null;
            }
        }

        if (pausedAt is { } open)
        {
            var end = (last - first).TotalSeconds;
            if (end > open) pauses.Add(new PauseInterval(open, end));
        }
        return pauses;
    }
}
