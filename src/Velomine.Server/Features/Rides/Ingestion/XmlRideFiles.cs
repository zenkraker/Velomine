using System.Globalization;
using System.Xml;
using System.Xml.Linq;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>Shared by the GPX and TCX readers. Both are XML, and both are read without regard to XML namespaces.</summary>
internal static class XmlRideFiles
{
    public static XDocument Load(byte[] data)
    {
        // DTDs are refused so a hostile file cannot read other files or blow up memory (XXE, "billion laughs").
        var settings = new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null };
        try
        {
            using var reader = XmlReader.Create(new MemoryStream(data), settings);
            return XDocument.Load(reader);
        }
        catch (XmlException)
        {
            throw new RideParseException("invalid_file", "The file is not valid XML.");
        }
    }

    public static IEnumerable<XElement> Named(this XElement parent, string localName) =>
        parent.Descendants().Where(e => e.Name.LocalName.Equals(localName, StringComparison.OrdinalIgnoreCase));

    /// <summary>The text of a direct child, so a track's own name is not mistaken for a point's or a segment's.</summary>
    public static string? ChildText(this XElement parent, string localName) =>
        parent.Elements().FirstOrDefault(e => e.Name.LocalName.Equals(localName, StringComparison.OrdinalIgnoreCase))?.Value;

    public static XElement? First(this XElement parent, string localName) => parent.Named(localName).FirstOrDefault();

    public static double? Number(string? text) =>
        double.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out var value) && double.IsFinite(value) ? value : null;

    public static DateTimeOffset? Time(string? text) =>
        DateTimeOffset.TryParse(text, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal, out var value)
            ? value
            : null;

    /// <summary>A whole-number signal, kept only when it fits the column (power, heart rate, cadence, temperature).</summary>
    public static short? Short(double? value) => value is { } v && Math.Abs(v) < short.MaxValue ? (short)Math.Round(v) : null;

    /// <summary>Samples are in time order, one per second at most is not required, but time must not go backwards.</summary>
    public static ParsedRide Build(
        DateTimeOffset start,
        List<(DateTimeOffset Time, Sample Sample)> points,
        string? device = null,
        RideDimensions? dimensions = null,
        IReadOnlyList<ParsedLap>? laps = null,
        string? title = null)
    {
        var ordered = points.OrderBy(p => p.Time).ToList();
        var first = ordered[0].Time;
        var samples = ordered.Select(p => p.Sample with { T = (p.Time - first).TotalSeconds }).ToList();
        var d = dimensions ?? RideDimensions.Unset;
        return new ParsedRide
        {
            StartTime = first,
            Samples = samples,
            Device = device,
            Discipline = d.Discipline,
            Assist = d.Assist,
            Environment = d.Environment,
            Commute = d.Commute,
            Laps = laps ?? [],
            Title = RideText.Imported(title, RideText.MaxTitle),
        };
    }
}
