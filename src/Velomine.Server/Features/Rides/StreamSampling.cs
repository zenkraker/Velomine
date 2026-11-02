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

        double[] Mean(double[] values) => [.. Slices().Select(s => values[s.From..s.To].Average())];
        double?[]? Mean2(double?[]? values) => values is null ? null : [.. Slices().Select(s => Average(values[s.From..s.To]))];
        float?[]? MeanF(float?[]? values) => values is null ? null : [.. Slices().Select(s => Average(values[s.From..s.To].Select(v => (double?)v)) is { } m ? (float?)m : null)];
        short?[]? MeanS(short?[]? values) => values is null ? null : [.. Slices().Select(s => Average(values[s.From..s.To].Select(v => (double?)v)) is { } m ? (short?)Math.Round(m) : null)];

        IEnumerable<(int From, int To)> Slices() => Enumerable.Range(0, maxPoints).Select(i => (edges[i], edges[i + 1]));

        return new RideStreams
        {
            RideId = streams.RideId,
            Time = Mean(streams.Time),
            Latitude = Mean2(streams.Latitude),
            Longitude = Mean2(streams.Longitude),
            Altitude = MeanF(streams.Altitude),
            Speed = MeanF(streams.Speed),
            Distance = streams.Distance is null ? null : [.. Slices().Select(s => LastValue(streams.Distance[s.From..s.To]))],
            HeartRate = MeanS(streams.HeartRate),
            Power = MeanS(streams.Power),
            Cadence = MeanS(streams.Cadence),
            Temperature = MeanS(streams.Temperature),
        };
    }

    private static double? Average(IEnumerable<double?> values)
    {
        var present = values.Where(v => v.HasValue).Select(v => v!.Value).ToArray();
        return present.Length == 0 ? null : present.Average();
    }

    private static float? LastValue(float?[] values) => values.LastOrDefault(v => v.HasValue);
}
