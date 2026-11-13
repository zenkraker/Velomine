using System.Globalization;
using System.IO.Compression;
using System.Reflection;
using System.Xml;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;
using Velomine.Server.Features.Clubs;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Demo;

public sealed record DemoAccount(string Email, string DisplayName, string ClubRole);

/// <summary>
/// The demo's accounts, club and example data. A reset deletes them with everything their visitors added and makes
/// them again, so the rides are always recent and nobody finds what the last visitor left behind.
/// </summary>
public sealed class DemoData(
    VelomineDbContext db,
    UserManager<User> users,
    AccountDeletion deletion,
    RideFileStore files,
    TimeProvider time)
{
    /// <summary>Public on purpose: the presentation site prints it.</summary>
    public const string Password = "Velomine-demo-1";

    public const string ClubName = "Velo Club Demo";

    public const string SeedResource = "Velomine.Server.Features.Demo.demo-seed.sql";

    public static readonly IReadOnlyList<DemoAccount> Accounts =
    [
        new("demo-admin@velomine.eu", "Giulia Rossi", ClubRoles.Owner),
        new("demo-coach@velomine.eu", "Marco Bianchi", ClubRoles.Coach),
        new("demo-rider@velomine.eu", "Luca Ferri", ClubRoles.Member),
    ];

    /// <summary>
    /// Why this database must not be reset, or null when it may. A reset deletes every account that is not a server
    /// admin, so it runs only where those accounts are the demo's own: never on a server that holds real members.
    /// </summary>
    public async Task<string?> RefusalAsync(CancellationToken ct)
    {
        var demo = Accounts.Select(a => (string?)users.NormalizeEmail(a.Email)).ToList();
        var admins = (await users.GetUsersInRoleAsync(Roles.Admin)).ToList();
        if (admins.Any(a => demo.Contains(a.NormalizedEmail)))
            return "A demo account is a server admin. Use another address for VELOMINE__ADMIN__EMAIL: the demo accounts are public.";

        var adminIds = admins.Select(a => a.Id).ToList();
        if (await db.Users.AnyAsync(u => !adminIds.Contains(u.Id) && (u.NormalizedEmail == null || !demo.Contains(u.NormalizedEmail)), ct))
            return "This server has accounts that are not demo accounts. Demo mode deletes every account but the admins each night, so it only starts on an empty server or on a demo.";

        if (await db.ClubMemberships.AnyAsync(m => adminIds.Contains(m.UserId), ct))
            return "A server admin is a member of a club. Demo mode deletes every club each night, so it only starts on an empty server or on a demo.";

        return null;
    }

    /// <summary>When the demo data was last made: the demo club is made again by every reset.</summary>
    public Task<DateTimeOffset?> LastResetAsync(CancellationToken ct) =>
        db.Clubs.AsNoTracking().OrderBy(c => c.CreatedAt).Select(c => (DateTimeOffset?)c.CreatedAt).FirstOrDefaultAsync(ct);

    /// <summary>Deletes the demo's club, accounts and everything they own, then makes them again with fresh example data.</summary>
    public async Task ResetAsync(CancellationToken ct)
    {
        if (await RefusalAsync(ct) is { } refusal) throw new InvalidOperationException(refusal);

        // The club first: an account that is the only owner of a club cannot be deleted.
        await db.Clubs.ExecuteDeleteAsync(ct);
        var adminIds = (await users.GetUsersInRoleAsync(Roles.Admin)).Select(a => a.Id).ToList();
        foreach (var id in await db.Users.Where(u => !adminIds.Contains(u.Id)).Select(u => u.Id).ToListAsync(ct))
            await deletion.DeleteAsync(id, ct);
        db.ChangeTracker.Clear();

        var now = time.GetUtcNow();
        var club = new Club
        {
            Id = Guid.NewGuid(),
            Name = ClubName,
            JoinCode = await JoinCodes.UniqueAsync(db, ct),
            CreatedAt = now,
        };
        for (var i = 0; i < Accounts.Count; i++)
        {
            var account = Accounts[i];
            var user = new User
            {
                UserName = account.Email,
                Email = account.Email,
                EmailConfirmed = true,
                DisplayName = account.DisplayName,
                IsApproved = true,
                CreatedAt = now,
            };
            var created = await users.CreateAsync(user, Password);
            if (!created.Succeeded)
                throw new InvalidOperationException("Could not create a demo account: " + string.Join("; ", created.Errors.Select(e => e.Description)));
            await users.AddToRoleAsync(user, Roles.Member);
            if (i == 0) club.CreatedBy = user.Id;
            club.Memberships.Add(new ClubMembership
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Role = account.ClubRole,
                JoinedAt = now.AddSeconds(i), // the seed numbers the members in the order they joined
            });
        }

        db.Clubs.Add(club);
        await db.SaveChangesAsync(ct);
        await SeedAsync(ct);
        await WriteOriginalFilesAsync(ct);
    }

    /// <summary>Runs the bundled script, which fills the demo club with bikes, rides and the rest.</summary>
    private async Task SeedAsync(CancellationToken ct)
    {
        await using var resource = Assembly.GetExecutingAssembly().GetManifestResourceStream(SeedResource)
            ?? throw new InvalidOperationException("The demo seed is missing from the build.");
        using var reader = new StreamReader(resource);
        var sql = await reader.ReadToEndAsync(ct);

        var connection = db.Database.GetDbConnection();
        await db.Database.OpenConnectionAsync(ct);
        try
        {
            // One transaction: the script's working tables are dropped at commit, and a failure leaves no half demo.
            await using var transaction = await connection.BeginTransactionAsync(ct);
            await using var command = connection.CreateCommand();
            command.Transaction = transaction;
            command.CommandText = sql;
            command.CommandTimeout = 600;
            await command.ExecuteNonQueryAsync(ct);
            await transaction.CommitAsync(ct);
        }
        finally
        {
            await db.Database.CloseConnectionAsync();
        }
    }

    /// <summary>
    /// The script makes rides without a file. Every ride keeps its original file, and the export hands it back, so
    /// each seeded ride gets one: a gzipped TCX written from its own samples.
    /// </summary>
    private async Task WriteOriginalFilesAsync(CancellationToken ct)
    {
        var rides = await db.Rides.AsNoTracking()
            .Where(r => r.FileSha256 == "" && r.StartTime != null)
            .Select(r => new { r.Id, StartTime = r.StartTime!.Value })
            .ToListAsync(ct);
        foreach (var ride in rides)
        {
            if (await db.RideStreams.AsNoTracking().FirstOrDefaultAsync(s => s.RideId == ride.Id, ct) is not { } streams) continue;

            using var buffer = new MemoryStream();
            await using (var gzip = new GZipStream(buffer, CompressionLevel.Fastest, leaveOpen: true))
                WriteTcx(gzip, ride.StartTime, streams);
            buffer.Position = 0;
            var sha = await files.SaveAsync(buffer, ct);
            await db.Rides.Where(r => r.Id == ride.Id).ExecuteUpdateAsync(
                u => u.SetProperty(r => r.FileSha256, sha).SetProperty(r => r.ParserVersion, RideParserVersion.Current),
                ct);
        }
    }

    private static void WriteTcx(Stream output, DateTimeOffset start, RideStreams s)
    {
        const string tcx = "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2";
        const string tpx = "http://www.garmin.com/xmlschemas/ActivityExtension/v2";
        static string Number(double value) => value.ToString("0.#######", CultureInfo.InvariantCulture);
        static string Instant(DateTimeOffset t) => t.UtcDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture);

        using var xml = XmlWriter.Create(output);
        xml.WriteStartElement("TrainingCenterDatabase", tcx);
        xml.WriteStartElement("Activities", tcx);
        xml.WriteStartElement("Activity", tcx);
        xml.WriteAttributeString("Sport", "Biking");
        xml.WriteElementString("Id", tcx, Instant(start));
        xml.WriteStartElement("Lap", tcx);
        xml.WriteAttributeString("StartTime", Instant(start));
        xml.WriteElementString("TotalTimeSeconds", tcx, Number(s.Time.Length == 0 ? 0 : s.Time[^1]));
        xml.WriteStartElement("Track", tcx);
        for (var i = 0; i < s.Time.Length; i++)
        {
            xml.WriteStartElement("Trackpoint", tcx);
            xml.WriteElementString("Time", tcx, Instant(start.AddSeconds(s.Time[i])));
            if (s.Latitude?[i] is { } latitude && s.Longitude?[i] is { } longitude)
            {
                xml.WriteStartElement("Position", tcx);
                xml.WriteElementString("LatitudeDegrees", tcx, Number(latitude));
                xml.WriteElementString("LongitudeDegrees", tcx, Number(longitude));
                xml.WriteEndElement();
            }

            if (s.Altitude?[i] is { } altitude) xml.WriteElementString("AltitudeMeters", tcx, Number(altitude));
            if (s.Distance?[i] is { } distance) xml.WriteElementString("DistanceMeters", tcx, Number(distance));
            if (s.HeartRate?[i] is { } heartRate)
            {
                xml.WriteStartElement("HeartRateBpm", tcx);
                xml.WriteElementString("Value", tcx, heartRate.ToString(CultureInfo.InvariantCulture));
                xml.WriteEndElement();
            }

            if (s.Cadence?[i] is { } cadence) xml.WriteElementString("Cadence", tcx, cadence.ToString(CultureInfo.InvariantCulture));
            if (s.Speed?[i] is not null || s.Power?[i] is not null)
            {
                xml.WriteStartElement("Extensions", tcx);
                xml.WriteStartElement("TPX", tpx);
                if (s.Speed?[i] is { } speed) xml.WriteElementString("Speed", tpx, Number(speed));
                if (s.Power?[i] is { } power) xml.WriteElementString("Watts", tpx, power.ToString(CultureInfo.InvariantCulture));
                xml.WriteEndElement();
                xml.WriteEndElement();
            }

            xml.WriteEndElement();
        }

        xml.WriteEndElement();
        xml.WriteEndElement();
        xml.WriteEndElement();
        xml.WriteEndElement();
        xml.WriteEndElement();
    }
}
