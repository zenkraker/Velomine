using Dynastream.Fit;
using Velomine.Server.Features.Rides.Ingestion;
using static Velomine.Server.Tests.Rides.TestRideFiles;

namespace Velomine.Server.Tests.Rides;

public sealed class RideFileParserTests
{
    private static string Code(Action action) => Assert.Throws<RideParseException>(action).Code;

    // --- FIT

    [Fact]
    public void Fit_ReadsTheSamples_TheDevice_AndTheLocalTimeOffset()
    {
        var rides = RideFileParser.Parse(Fit(new FitSession(Start, 120, NormalizedPower: 215)));

        var ride = Assert.Single(rides);
        Assert.Equal(new DateTimeOffset(Start), ride.StartTime);
        Assert.Equal(120, ride.UtcOffsetMinutes);
        Assert.Equal("Garmin", ride.Device);
        Assert.Equal(215, ride.DeviceNormalizedPowerW);
        Assert.Equal(120, ride.Samples.Count);
        var sample = ride.Samples[10];
        Assert.Equal(10, sample.T);
        Assert.Equal((short?)150, sample.HeartRate);
        Assert.Equal((short?)200, sample.Power);
        Assert.Equal((short?)90, sample.Cadence);
        Assert.Equal(8f, sample.Speed);
        Assert.Equal((short?)18, sample.Temperature);
        Assert.InRange(sample.Latitude!.Value, 46.0007, 46.0009); // 80 m north of 46.0
        Assert.InRange(sample.Longitude!.Value, 10.9999, 11.0001);
        Assert.InRange(sample.Altitude!.Value, 300.9f, 301.1f);
    }

    [Fact]
    public void Fit_ReadsTimerPausesAndTheDevicesMovingTime()
    {
        var ride = Assert.Single(RideFileParser.Parse(Fit(new FitSession(
            Start,
            30,
            TimerSeconds: 20,
            Pauses: [(5, 15)]))));

        Assert.Equal(30d, ride.DeviceElapsedS);
        Assert.Equal(20d, ride.DeviceMovingS);
        var pause = Assert.Single(ride.Pauses);
        Assert.Equal(5d, pause.StartS);
        Assert.Equal(15d, pause.EndS);
    }

    [Fact]
    public void Fit_WithTwoSessions_GivesTwoRides()
    {
        var second = Start.AddHours(2);

        var rides = RideFileParser.Parse(Fit(new FitSession(Start, 90), new FitSession(second, 60, Sport.EBiking)));

        Assert.Equal(2, rides.Count);
        Assert.Equal(new DateTimeOffset(Start), rides[0].StartTime);
        Assert.Equal(90, rides[0].Samples.Count);
        Assert.Equal(new DateTimeOffset(second), rides[1].StartTime);
        Assert.Equal(60, rides[1].Samples.Count);
        Assert.Equal(0, rides[1].Samples[0].T);
    }

    [Fact]
    public void Fit_OfARun_IsRefused() =>
        Assert.Equal("not_cycling", Code(() => RideFileParser.Parse(Fit(new FitSession(Start, 60, Sport.Running)))));

    [Fact]
    public void Fit_ThatIsCutShort_IsReportedAsCorrupt()
    {
        var file = Fit(new FitSession(Start, 120));

        Assert.Equal("corrupt_file", Code(() => RideFileParser.Parse(file[..(file.Length / 2)])));
    }

    // --- GPX

    [Fact]
    public void Gpx_ReadsSensorValuesFromTheCommonExtensions()
    {
        var gpx = Gpx(60, _ => "<gpxtpx:TrackPointExtension><gpxtpx:hr>150</gpxtpx:hr><gpxtpx:cad>88</gpxtpx:cad><gpxtpx:atemp>17</gpxtpx:atemp><gpxtpx:speed>7.5</gpxtpx:speed></gpxtpx:TrackPointExtension>");

        var ride = Assert.Single(RideFileParser.Parse(Bytes(gpx)));

        var sample = ride.Samples[5];
        Assert.Equal((short?)150, sample.HeartRate);
        Assert.Equal((short?)88, sample.Cadence);
        Assert.Equal((short?)17, sample.Temperature);
        Assert.Equal(7.5f, sample.Speed);
    }

    [Theory]
    [InlineData("<gpxpx:PowerExtension><gpxpx:PowerInWatts>240</gpxpx:PowerInWatts></gpxpx:PowerExtension>")] // Garmin: the case Endurain misses
    [InlineData("<power>240</power>")]
    [InlineData("<gpxtpx:TrackPointExtension><gpxtpx:power>240</gpxtpx:power></gpxtpx:TrackPointExtension>")]
    [InlineData("<watts>240</watts>")]
    public void Gpx_ReadsPower_InEveryCommonSpelling(string extension)
    {
        var ride = Assert.Single(RideFileParser.Parse(Bytes(Gpx(30, _ => extension))));

        Assert.Equal((short?)240, ride.Samples[3].Power);
    }

    [Fact]
    public void Gpx_WithTwoTracks_GivesTwoRides()
    {
        var one = Gpx(30);
        var two = Gpx(30, start: Start.AddHours(3));
        var combined = one.Replace("</gpx>", two[two.IndexOf("<trk>", StringComparison.Ordinal)..]);

        Assert.Equal(2, RideFileParser.Parse(Bytes(combined)).Count);
    }

    [Fact]
    public void Gpx_WithoutTimestamps_IsRefused() =>
        Assert.Equal("no_timestamps", Code(() => RideFileParser.Parse(Bytes(Gpx(30, withTime: false)))));

    // --- TCX

    [Fact]
    public void Tcx_ReadsABikeActivity()
    {
        var ride = Assert.Single(RideFileParser.Parse(Bytes(Tcx("Biking", 60))));

        var sample = ride.Samples[10];
        Assert.Equal((short?)150, sample.HeartRate);
        Assert.Equal((short?)90, sample.Cadence);
        Assert.Equal((short?)200, sample.Power);
        Assert.Equal(8f, sample.Speed);
        Assert.Equal(80f, sample.Distance);
        Assert.Equal(60, ride.Samples.Count);
    }

    [Fact]
    public void Tcx_OfARun_IsRefused() =>
        Assert.Equal("not_cycling", Code(() => RideFileParser.Parse(Bytes(Tcx("Running", 60)))));

    // --- Recognising the format

    [Fact]
    public void Gzip_IsUnzippedFirst() =>
        Assert.Single(RideFileParser.Parse(Gzip(Bytes(Gpx(30)))));

    [Fact]
    public void Gzip_ThatIsDamaged_IsReported()
    {
        var zipped = Gzip(Bytes(Gpx(300)));

        // A cut-off gzip decompresses to cut-off text, which is then not a valid file.
        Assert.Contains(Code(() => RideFileParser.Parse(zipped[..(zipped.Length / 2)])), new[] { "corrupt_file", "invalid_file" });
    }

    [Fact]
    public void Text_ThatIsNotARideFile_IsRefused() =>
        Assert.Equal("invalid_file", Code(() => RideFileParser.Parse(Bytes("this is just a note"))));

    [Fact]
    public void Xml_OfAnotherKind_IsRefused() =>
        Assert.Equal("unsupported_format", Code(() => RideFileParser.Parse(Bytes("<recipe><step>stir</step></recipe>"))));

    [Fact]
    public void Xml_WithADocumentTypeDefinition_IsRefused()
    {
        const string hostile = """<?xml version="1.0"?><!DOCTYPE gpx [<!ENTITY x SYSTEM "file:///etc/passwd">]><gpx>&x;</gpx>""";

        Assert.Equal("invalid_file", Code(() => RideFileParser.Parse(Bytes(hostile))));
    }
}
