using System.IO.Compression;

namespace Velomine.Server.Features.Rides.Ingestion;

/// <summary>Turns an uploaded file into rides. The format is recognised from the content, not from the file name.</summary>
public static class RideFileParser
{
    /// <summary>Largest file after unzipping, so a small .gz cannot expand without limit.</summary>
    private const int MaxBytes = 200 * 1024 * 1024;

    public static IReadOnlyList<ParsedRide> Parse(byte[] file)
    {
        var data = IsGzip(file) ? Unzip(file) : file;

        if (data.Length >= 12 && data[8] == '.' && data[9] == 'F' && data[10] == 'I' && data[11] == 'T')
            return FitParser.Parse(data);

        var document = XmlRideFiles.Load(data);
        return document.Root?.Name.LocalName switch
        {
            "gpx" => GpxParser.Parse(document),
            "TrainingCenterDatabase" => TcxParser.Parse(document),
            _ => throw new RideParseException("unsupported_format", "Only FIT, GPX and TCX files are supported."),
        };
    }

    private static bool IsGzip(byte[] data) => data.Length > 2 && data[0] == 0x1f && data[1] == 0x8b;

    private static byte[] Unzip(byte[] compressed)
    {
        try
        {
            using var gzip = new GZipStream(new MemoryStream(compressed), CompressionMode.Decompress);
            using var output = new MemoryStream();
            var buffer = new byte[81920];
            int read;
            while ((read = gzip.Read(buffer)) > 0)
            {
                output.Write(buffer, 0, read);
                if (output.Length > MaxBytes) throw new RideParseException("file_too_large", "The file is too large once unzipped.");
            }

            return output.ToArray();
        }
        catch (InvalidDataException)
        {
            throw new RideParseException("corrupt_file", "The gzip file is damaged.");
        }
    }
}
