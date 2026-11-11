using System.Text;

namespace Velomine.Server.Features.Rides.Import;

/// <summary>One row of a Strava export's activities.csv: which original file belongs to which activity.</summary>
public sealed record StravaActivity(string? SourceId, string File, bool? Commute);

/// <summary>
/// Reads the activities.csv of a Strava bulk export. The export is written in the member's Strava language, so the
/// column names are not relied on: the file column is the one whose values name a file under activities/, and the
/// activity id is the first column.
/// </summary>
public static class StravaExport
{
    public const string Source = "strava";

    public const string CsvEntry = "activities.csv";

    /// <summary>A safe, bounded name for a file the archive names.</summary>
    public static string FileName(string? name, string fallback)
    {
        var clean = Path.GetFileName(name ?? "") is { Length: > 0 } n ? n : fallback;
        return clean.Length > 256 ? clean[..256] : clean;
    }

    /// <summary>The archive's activity rows, including the ones without a file (their File is empty).</summary>
    public static IReadOnlyList<StravaActivity> Parse(Stream csv)
    {
        using var reader = new StreamReader(csv, Encoding.UTF8, detectEncodingFromByteOrderMarks: true, leaveOpen: true);
        var rows = Records(reader).ToList();
        if (rows.Count == 0) return [];

        var header = rows[0];
        var file = FileColumn(header, rows);
        var commute = Column(header, "commut") ?? Column(header, "pendolar");
        var activities = new List<StravaActivity>(rows.Count - 1);
        foreach (var row in rows.Skip(1))
        {
            if (row.Length == 0) continue;
            var name = file >= 0 && file < row.Length ? row[file].Trim() : "";
            if (name.Length == 0 || !name.StartsWith("activities/", StringComparison.Ordinal)) name = "";
            var id = row[0].Trim();
            activities.Add(new StravaActivity(
                id.Length > 0 && id.All(char.IsAsciiDigit) ? id : IdFromFile(name),
                name,
                commute is { } c && c < row.Length ? row[c].Trim().ToLowerInvariant() switch
                {
                    "true" => true,
                    "false" => false,
                    _ => null,
                } : null));
        }
        return activities;
    }

    /// <summary>The column whose data values look like activities/123.gpx: the same in every language.</summary>
    private static int FileColumn(string[] header, List<string[]> rows)
    {
        foreach (var row in rows.Skip(1).Take(20))
            for (var i = 0; i < row.Length; i++)
                if (row[i].TrimStart().StartsWith("activities/", StringComparison.Ordinal)) return i;

        return Column(header, "file") ?? Column(header, "nome del file") ?? -1;
    }

    private static int? Column(string[] header, string name)
    {
        for (var i = 0; i < header.Length; i++)
            if (header[i].Contains(name, StringComparison.OrdinalIgnoreCase)) return i;
        return null;
    }

    /// <summary>The id an export names its file after, when the first column is not the id.</summary>
    private static string? IdFromFile(string file)
    {
        var name = Path.GetFileName(file);
        if (name.EndsWith(".gz", StringComparison.OrdinalIgnoreCase)) name = Path.GetFileNameWithoutExtension(name);
        return Path.GetFileNameWithoutExtension(name) is { Length: > 0 } id && id.All(char.IsAsciiDigit) ? id : null;
    }

    /// <summary>RFC 4180 records: quoted fields may hold commas, quotes ("") and line breaks.</summary>
    private static IEnumerable<string[]> Records(TextReader reader)
    {
        var fields = new List<string>();
        var field = new StringBuilder();
        var quoted = false;
        var any = false;
        int c;
        while ((c = reader.Read()) >= 0)
        {
            any = true;
            if (quoted)
            {
                if (c == '"')
                {
                    if (reader.Peek() == '"')
                    {
                        reader.Read();
                        field.Append('"');
                    }
                    else quoted = false;
                }
                else field.Append((char)c);
                continue;
            }

            switch (c)
            {
                case '"':
                    quoted = true;
                    break;
                case ',':
                    fields.Add(field.ToString());
                    field.Clear();
                    break;
                case '\r':
                    if (reader.Peek() == '\n') reader.Read();
                    goto case '\n';
                case '\n':
                    fields.Add(field.ToString());
                    field.Clear();
                    yield return fields.ToArray();
                    fields.Clear();
                    any = false;
                    break;
                default:
                    field.Append((char)c);
                    break;
            }
        }

        if (!any && field.Length == 0 && fields.Count == 0) yield break;
        fields.Add(field.ToString());
        yield return fields.ToArray();
    }
}
