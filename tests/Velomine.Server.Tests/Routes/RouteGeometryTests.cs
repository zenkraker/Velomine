using Velomine.Server.Features.Routes;

namespace Velomine.Server.Tests.Routes;

public sealed class RouteGeometryTests
{
    [Fact]
    public void Measure_ShouldSumGreatCircleDistance_WhenPointsFollowAMeridian()
    {
        // One degree of latitude on the 6,371 km sphere is 111,194.9 m.
        var (distance, climbing) = RouteGeometry.Measure([new(46.0, 11.0, null), new(47.0, 11.0, null)]);

        Assert.Equal(111_194.9, distance, 1);
        Assert.Null(climbing);
    }

    [Fact]
    public void Measure_ShouldUseTheRideElevationMethod_WhenTheLineHasElevation()
    {
        // 100 m of steady climbing over 40 points: far above the noise threshold, so it all counts.
        var points = Enumerable.Range(0, 40)
            .Select(i => new RoutePoint(46.0 + i * 0.001, 11.0, 300 + i * 100f / 39))
            .ToList();

        var (_, climbing) = RouteGeometry.Measure(points);

        Assert.InRange(climbing!.Value, 90, 100);
    }

    [Fact]
    public void Simplify_ShouldKeepEndsAndStayUnderTheLimit_WhenTheLineIsDense()
    {
        var points = Enumerable.Range(0, 20_000)
            .Select(i => new RoutePoint(46.0 + i * 0.00001, 11.0 + Math.Sin(i / 300.0) * 0.01, null))
            .ToList();

        var thinned = RouteGeometry.Simplify(points, 500);

        Assert.InRange(thinned.Count, 50, 500);
        Assert.Equal(points[0], thinned[0]);
        Assert.Equal(points[^1], thinned[^1]);
    }

    [Fact]
    public void Simplify_ShouldKeepTheShapeOfAHill_WhenTheRoadIsStraight()
    {
        // A straight road over a 60 m hill: height counts as a dimension, so the top of the hill is kept.
        var points = Enumerable.Range(0, 200)
            .Select(i => new RoutePoint(46.0 + i * 0.0001, 11.0, (float)(300 + 60 * Math.Sin(i * Math.PI / 199))))
            .ToList();

        var thinned = RouteGeometry.Simplify(points);
        var (_, original) = RouteGeometry.Measure(points);
        var (_, kept) = RouteGeometry.Measure(thinned);

        Assert.Contains(thinned, p => p.Elevation > 350);
        Assert.InRange(kept!.Value, original!.Value * 0.8, original.Value * 1.2);
    }

    [Fact]
    public void FilledElevation_ShouldCarryTheLastValueForward_WhenSomePointsHaveNone()
    {
        var filled = RouteGeometry.FilledElevation([new(0, 0, null), new(0, 1, 10), new(0, 2, null), new(0, 3, 14)]);

        Assert.Equal([10f, 10f, 10f, 14f], filled!);
        Assert.Null(RouteGeometry.FilledElevation([new(0, 0, null), new(0, 1, null)]));
    }

    [Fact]
    public void ReadGpx_ShouldReadTrackPointsAndTheName_WhenTheFileHasATrack()
    {
        var draft = RouteGeometry.ReadGpx(System.Text.Encoding.UTF8.GetBytes(RoutesTestKit.Gpx("Lake loop")));

        Assert.Equal("Lake loop", draft.Name);
        Assert.Equal(6, draft.Points.Count);
        Assert.Equal(300, draft.Points[0].Elevation);
        Assert.Equal(46.005, draft.Points[5].Latitude, 6);
    }

    [Fact]
    public void ReadGpx_ShouldReadPlannedRoutePoints_WhenTheFileHasNoTrack()
    {
        var gpx = """
            <gpx version="1.1"><rte><name>Planned</name>
            <rtept lat="46.0" lon="11.0"/><rtept lat="46.01" lon="11.0"/></rte></gpx>
            """;

        var draft = RouteGeometry.ReadGpx(System.Text.Encoding.UTF8.GetBytes(gpx));

        Assert.Equal("Planned", draft.Name);
        Assert.Equal(2, draft.Points.Count);
        Assert.Null(draft.Points[0].Elevation);
    }

    [Theory]
    [InlineData("this is not xml")]
    [InlineData("<kml/>")]
    [InlineData("<gpx><trk><trkseg><trkpt lat=\"46\" lon=\"11\"/></trkseg></trk></gpx>")]
    [InlineData("<gpx><trk><trkseg><trkpt lat=\"146\" lon=\"11\"/><trkpt lat=\"47\" lon=\"11\"/></trkseg></trk></gpx>")]
    public void ReadGpx_ShouldRefuse_WhenTheFileHasNoUsableLine(string text)
    {
        Assert.Throws<RouteFileException>(() => RouteGeometry.ReadGpx(System.Text.Encoding.UTF8.GetBytes(text)));
    }

    [Fact]
    public void ReadGpx_ShouldRefuseADocumentType_WhenTheFileDeclaresOne()
    {
        var hostile = "<!DOCTYPE gpx [<!ENTITY x SYSTEM \"file:///etc/passwd\">]><gpx><trk><trkseg>"
            + "<trkpt lat=\"46\" lon=\"11\"/><trkpt lat=\"47\" lon=\"11\"/></trkseg></trk></gpx>";

        Assert.Throws<RouteFileException>(() => RouteGeometry.ReadGpx(System.Text.Encoding.UTF8.GetBytes(hostile)));
    }

    [Fact]
    public void ToGpx_ShouldWriteAFileThatReadsBack_WhenTheRouteHasElevation()
    {
        var points = new List<RoutePoint> { new(46.0, 11.0, 300), new(46.01, 11.002, 312.5f) };

        var gpx = RouteGeometry.ToGpx("Lake & loop", "Steady <ride>", points);
        var back = RouteGeometry.ReadGpx(gpx);

        Assert.Equal("Lake & loop", back.Name);
        Assert.Equal(points, back.Points);
        Assert.Contains("Steady &lt;ride&gt;", System.Text.Encoding.UTF8.GetString(gpx));
    }
}
