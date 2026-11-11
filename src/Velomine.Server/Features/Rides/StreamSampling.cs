namespace Velomine.Server.Features.Rides;

/// <summary>Thins a ride's samples to a number a chart or map can draw, by averaging within equal slices of the ride.</summary>
public static class StreamSampling
{
    /// <summary>
    /// Returns the streams unchanged when they are small enough, otherwise <paramref name="maxPoints"/> points.
    /// Each point is the average of its slice (distance is the slice's last value, since it only grows). A signal with no
    /// value in a slice is null there. Positions are averaged too, which is fine for a slice of a few seconds.
    /// shortcut: averaging longitudes breaks across the 180 degree line, handle it when someone rides there.
    /// </summary>
    public static RideStreams Reduce(RideStreams streams, int maxPoints)
    {
        var n = streams.Time.Length;
        if (n <= maxPoints) return streams;

        var edges = Enumerable.Range(0, maxPoints + 1).Select(i => (int)((long)i * n / maxPoints)).ToArray();

        IEnumerable<(int From, int To)> Slices() => Enumerable.Range(0, maxPoints).Select(i => (edges[i], edges[i + 1]));

        // One slice's mean, converted back to the signal's own type; null when the slice has no value.
        T?[]? Mean<T>(T?[]? values, Func<double, T> convert) where T : struct =>
            values is null
                ? null
                : [.. Slices().Select(s => Average(values[s.From..s.To].Select(v => v is { } value ? (double?)Convert.ToDouble(value) : null)) is { } m ? (T?)convert(m) : null)];

        return new RideStreams
        {
            RideId = streams.RideId,
            Time = [.. Slices().Select(s => streams.Time[s.From..s.To].Average())],
            Latitude = Mean(streams.Latitude, d => d),
            Longitude = Mean(streams.Longitude, d => d),
            Altitude = Mean(streams.Altitude, d => (float)d),
            Speed = Mean(streams.Speed, d => (float)d),
            Distance = streams.Distance is null ? null : [.. Slices().Select(s => LastValue(streams.Distance[s.From..s.To]))],
            HeartRate = Mean(streams.HeartRate, d => (short)Math.Round(d)),
            Power = Mean(streams.Power, d => (short)Math.Round(d)),
            Cadence = Mean(streams.Cadence, d => (short)Math.Round(d)),
            Temperature = Mean(streams.Temperature, d => (short)Math.Round(d)),
        };
    }

    private static double? Average(IEnumerable<double?> values)
    {
        var present = values.Where(v => v.HasValue).Select(v => v!.Value).ToArray();
        return present.Length == 0 ? null : present.Average();
    }

    private static float? LastValue(float?[] values) => values.LastOrDefault(v => v.HasValue);
}
