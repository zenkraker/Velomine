using System.Text;
using Velomine.Server.Features.Rides.Import;

namespace Velomine.Server.Tests.Rides;

public sealed class StravaExportTests
{
    private static IReadOnlyList<StravaActivity> Parse(string csv) =>
        StravaExport.Parse(new MemoryStream(Encoding.UTF8.GetBytes(csv)));

    [Fact]
    public void StravaExport_ShouldFindTheFileAndCommute_WhenTheHeadersAreItalian()
    {
        var activities = Parse(
            "ID attività,Data dell’attività,Nome attività,Tipo attività,Tragitto pendolare,Nome del file\n" +
            "20907461447,\"8 nov 2026, 10:33:07\",\"Giro, con virgola\",Ciclismo,true,activities/20907461447.gpx\n");

        var activity = Assert.Single(activities);
        Assert.Equal("20907461447", activity.SourceId);
        Assert.Equal("activities/20907461447.gpx", activity.File);
        Assert.True(activity.Commute);
    }

    [Fact]
    public void StravaExport_ShouldFindTheFileColumnByItsValues_WhenTheHeadersAreInAnotherLanguage()
    {
        var activities = Parse(
            "Kennung,Datum,Name,Typ,Pendeln,Datei\n" +
            "111,\"8 Nov 2026, 10:33:07\",Giro,Ciclismo,false,activities/111.gpx\n" +
            "112,\"9 Nov 2026, 10:33:07\",Giro,Ciclismo,false,activities/112.gpx.gz\n");

        Assert.Equal(2, activities.Count);
        Assert.Equal(["activities/111.gpx", "activities/112.gpx.gz"], activities.Select(a => a.File));
        Assert.All(activities, a => Assert.Null(a.Commute));
    }

    [Fact]
    public void StravaExport_ShouldKeepRowsWithoutAFile_WhenAnActivityHasNone()
    {
        var activities = Parse(
            "ID attività,Nome del file\n111,activities/111.gpx\n112,\n");

        Assert.Equal(2, activities.Count);
        Assert.Equal("", activities[1].File);
        Assert.Equal("112", activities[1].SourceId);
    }

    [Fact]
    public void StravaExport_ShouldReadCommasAndLineBreaksInsideQuotedFields_WhenTheNameHasThem()
    {
        var activities = Parse(
            "ID attività,Nome attività,Nome del file\n" +
            "111,\"Giro, con\nuna virgola\",activities/111.gpx\n");

        Assert.Equal("activities/111.gpx", Assert.Single(activities).File);
    }

    [Fact]
    public void StravaExport_ShouldUseTheFileNameAsId_WhenTheFirstColumnIsNotTheId()
    {
        var activities = Parse(
            "ID attività,Nome del file\nnot-an-id,activities/123456.gpx\n");

        Assert.Equal("123456", Assert.Single(activities).SourceId);
    }
}
