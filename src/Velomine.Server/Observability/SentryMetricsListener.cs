using System.Diagnostics.Metrics;
using Sentry;

namespace Velomine.Server.Observability;

/// <summary>
/// Bridges the Microsoft <see cref="Meter"/> API to Sentry Application Metrics. This is the only
/// place that knows the metrics backend; switching to OTel metrics later replaces this class.
/// </summary>
public sealed class SentryMetricsListener : IHostedService, IDisposable
{
    private MeterListener? _listener;

    public Task StartAsync(CancellationToken cancellationToken)
    {
        if (!SentrySdk.IsEnabled) return Task.CompletedTask;

        _listener = new MeterListener
        {
            InstrumentPublished = (instrument, listener) =>
            {
                if (instrument.Meter.Name == VelomineMetrics.Meter.Name)
                    listener.EnableMeasurementEvents(instrument);
            },
        };
        _listener.SetMeasurementEventCallback<long>(OnCounter);
        _listener.SetMeasurementEventCallback<int>(OnCounter);
        _listener.SetMeasurementEventCallback<double>(OnHistogram);
        _listener.SetMeasurementEventCallback<float>(OnHistogram);
        _listener.Start();
        return Task.CompletedTask;
    }

    private static void OnCounter(Instrument instrument, long value, ReadOnlySpan<KeyValuePair<string, object?>> tags, object? state) =>
        SentrySdk.Metrics.EmitCounter(instrument.Name, value, attributes: Attributes(tags));

    private static void OnCounter(Instrument instrument, int value, ReadOnlySpan<KeyValuePair<string, object?>> tags, object? state) =>
        SentrySdk.Metrics.EmitCounter(instrument.Name, value, attributes: Attributes(tags));

    private static void OnHistogram(Instrument instrument, double value, ReadOnlySpan<KeyValuePair<string, object?>> tags, object? state) =>
        SentrySdk.Metrics.EmitDistribution(instrument.Name, value, MeasurementUnit.None, Attributes(tags));

    private static void OnHistogram(Instrument instrument, float value, ReadOnlySpan<KeyValuePair<string, object?>> tags, object? state) =>
        SentrySdk.Metrics.EmitDistribution(instrument.Name, value, MeasurementUnit.None, Attributes(tags));

    private static KeyValuePair<string, object>[] Attributes(ReadOnlySpan<KeyValuePair<string, object?>> tags)
    {
        var attributes = new List<KeyValuePair<string, object>>(tags.Length);
        foreach (var tag in tags)
            if (tag.Value is { } value)
                attributes.Add(new KeyValuePair<string, object>(tag.Key, value));
        return [.. attributes];
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        _listener?.Dispose();
        _listener = null;
        return Task.CompletedTask;
    }

    public void Dispose()
    {
        _listener?.Dispose();
        _listener = null;
    }
}
