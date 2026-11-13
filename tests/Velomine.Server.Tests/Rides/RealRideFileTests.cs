using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Tests.Rides;

/// <summary>
/// Files as devices write them, committed under <c>Rides/Samples</c>, with the values they must give. The synthetic
/// files the other tests build describe the shape they want; these describe what a Garmin, a Wahoo and a FIT device
/// actually put on disk, so a parser that only works on the test's own output fails here.
/// </summary>
public sealed class RealRideFileTests
{
    private static byte[] Sample(string name) =>
        File.ReadAllBytes(Path.Combine(AppContext.BaseDirectory, "Rides", "Samples", name));

    [Fact]
    public void GpxParser_ShouldReadADeviceTrack_WhenItIsAGarminEdgeExport()
    {
        var ride = Assert.Single(RideFileParser.Parse(Sample("garmin-edge.gpx")));

        Assert.Equal("Morning commute", ride.Title);
        Assert.Equal(new DateTimeOffset(2026, 10, 3, 8, 0, 0, TimeSpan.Zero), ride.StartTime);
        Assert.Equal(5, ride.Samples.Count);
        var first = ride.Samples[0];
        Assert.Equal((short?)132, first.HeartRate);
        Assert.Equal((short?)78, first.Cadence);
        Assert.Equal(300f, first.Altitude);
        // 0.0005 of latitude is about 55.6 m, in ten seconds: 5.56 m/s from the positions, not from a speed field.
        Assert.InRange(ride.Samples[1].Latitude!.Value, 46.0004, 46.0006);
    }

    [Fact]
    public void TcxParser_ShouldReadAPowerMeterTrack_WhenItIsAWahooExport()
    {
        var ride = Assert.Single(RideFileParser.Parse(Sample("wahoo-elemnt.tcx")));

        Assert.Equal(new DateTimeOffset(2026, 10, 3, 8, 0, 0, TimeSpan.Zero), ride.StartTime);
        Assert.Equal(5, ride.Samples.Count);
        // A steady, ordered power ramp, which the file states in watts on the extension.
        Assert.Equal([180, 200, 240, 260], ride.Samples.Skip(1).Select(s => (int)s.Power!.Value));
        Assert.Equal((short?)120, ride.Samples[0].HeartRate);
        Assert.Equal(302f, ride.Samples[1].Altitude);
        Assert.Single(ride.Laps);
    }

    [Fact]
    public void FitParser_ShouldReadADeviceFile_WhenItIsATenMinuteRide()
    {
        var ride = Assert.Single(RideFileParser.Parse(Sample("garmin-edge-600s.fit")));

        Assert.Equal("Garmin", ride.Device);
        Assert.Equal(600, ride.Samples.Count);
        Assert.All(ride.Samples, s =>
        {
            Assert.Equal((short?)150, s.HeartRate);
            Assert.Equal((short?)200, s.Power);
        });
    }

    [Fact]
    public void RideMetrics_ShouldUseTheChangedPowerAndHeartRate_WhenTheRideIsNotSteady()
    {
        // A synthetic ride that changes: 10 s at 100 W / 120 bpm, then 10 s at 300 W / 170 bpm, one sample a second.
        var samples = new List<Sample>();
        for (var t = 0; t < 20; t++)
        {
            samples.Add(new Sample(t,
                Latitude: 46.0 + t * 5.0 / 111_195.0, Longitude: 11.0, Altitude: 300, Speed: 5f,
                HeartRate: (short)(t < 10 ? 120 : 170), Power: (short)(t < 10 ? 100 : 300)));
        }

        var metrics = RideMetrics.Compute(samples, ftpW: 250, maxHeartRate: 200);

        // Each sample is held until the next, so the 20 samples are 19 counted seconds: 9 at 100 W then 10 at 300 W
        // (194.7 W), and 9 at 120 bpm then 10 at 170 bpm (143.7 bpm). A constant-value ride could never show this.
        Assert.Equal(195, metrics.AvgPowerW);
        Assert.Equal(144, metrics.AvgHeartRate);
        Assert.Equal(300, metrics.MaxPowerW);
        Assert.Equal(170, metrics.MaxHeartRate);
    }
}
