using System.IO.Compression;
using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Bikes;
using Velomine.Server.Features.Rides;
using Velomine.Server.Features.Rides.Ingestion;

namespace Velomine.Server.Features.Accounts;

/// <summary>
/// Everything a member owns, as one ZIP: their details, bikes and parts, goals, notifications and rides as JSON, and every
/// original ride file exactly as it was uploaded (FIT, GPX or TCX), which also holds all the recorded samples.
/// Nothing that is not the member's own data goes in (no password hash, no security stamp, nobody else's data).
/// </summary>
public sealed class AccountExport(VelomineDbContext db, RideFileStore files)
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web) { WriteIndented = true };

    public async Task WriteAsync(Guid userId, Stream output, CancellationToken ct)
    {
        var user = await db.Users.AsNoTracking().FirstAsync(u => u.Id == userId, ct);
        var bikes = await db.Bikes.AsNoTracking().Include(b => b.Components).Where(b => b.UserId == userId).OrderBy(b => b.CreatedAt).ToListAsync(ct);
        var rides = await db.Rides.AsNoTracking().Where(r => r.UserId == userId).OrderBy(r => r.StartTime).ThenBy(r => r.UploadedAt).ToListAsync(ct);
        var goals = await db.Set<Goal>().AsNoTracking().Where(g => g.UserId == userId).OrderBy(g => g.CreatedAt).ToListAsync(ct);
        var notifications = await db.Notifications.AsNoTracking().Where(n => n.UserId == userId).OrderBy(n => n.CreatedAt).ToListAsync(ct);

        using var zip = new ZipArchive(output, ZipArchiveMode.Create, leaveOpen: true);

        // Each original file once, named by what it was: two rides read from one file share it.
        var fileNames = new Dictionary<string, string>();
        foreach (var ride in rides)
        {
            if (fileNames.ContainsKey(ride.FileSha256)) continue;
            await using var source = files.OpenRead(ride.FileSha256);
            if (source is null) continue; // lost from disk: the ride's row says so below
            var entryName = $"files/{ride.FileSha256[..12]}-{SafeName(ride.FileName)}";
            var entry = zip.CreateEntry(entryName, CompressionLevel.Optimal);
            await using var target = entry.Open();
            await source.CopyToAsync(target, ct);
            fileNames[ride.FileSha256] = entryName;
        }

        await AddJsonAsync(zip, "profile.json", new
        {
            user.Email,
            user.DisplayName,
            user.CreatedAt,
            user.FtpW,
            user.WeightKg,
            user.MaxHeartRate,
            user.TimeZone,
            FirstDayOfWeek = WeekDays.Name(user.FirstDayOfWeek),
            user.EmailNotifications,
        }, ct);
        await AddJsonAsync(zip, "bikes.json", bikes.Select(b => new
        {
            b.Id,
            b.Name,
            b.Brand,
            b.Model,
            b.Kind,
            b.WheelCircumferenceMm,
            b.InitialDistanceM,
            b.PurchasedOn,
            b.IsDefault,
            b.IsActive,
            b.CreatedAt,
            Components = b.Components.OrderBy(c => c.InstalledOn).Select(c => new
            {
                c.Id,
                c.Type,
                c.Brand,
                c.Model,
                c.InstalledOn,
                c.RemovedOn,
                c.ExpectedDistanceM,
                c.ExpectedHours,
                c.ExpectedMonths,
            }),
        }), ct);
        await AddJsonAsync(zip, "rides.json", rides.Select(r => new
        {
            Ride = RideResponse.From(r),
            // Where the original file is in this ZIP; null when the file was not on disk.
            File = fileNames.GetValueOrDefault(r.FileSha256),
            r.FileSha256,
        }), ct);
        await AddJsonAsync(zip, "goals.json", goals.Select(g => new { g.Id, g.Period, g.Metric, g.Target, g.CreatedAt }), ct);
        await AddJsonAsync(zip, "notifications.json", notifications.Select(n => new { n.Id, n.Type, n.Subject, n.CreatedAt, n.ReadAt }), ct);
        await AddTextAsync(zip, "README.txt", ReadMe, ct);
    }

    private static async Task AddJsonAsync(ZipArchive zip, string name, object value, CancellationToken ct) =>
        await AddTextAsync(zip, name, JsonSerializer.Serialize(value, Json), ct);

    private static async Task AddTextAsync(ZipArchive zip, string name, string text, CancellationToken ct)
    {
        await using var target = zip.CreateEntry(name, CompressionLevel.Optimal).Open();
        await target.WriteAsync(Encoding.UTF8.GetBytes(text), ct);
    }

    /// <summary>A file name that is safe inside a ZIP and on any system.</summary>
    internal static string SafeName(string name)
    {
        var cleaned = new string([.. Path.GetFileName(name).Select(c => char.IsLetterOrDigit(c) || c is '.' or '-' or '_' ? c : '_')]);
        return cleaned.Length is > 0 and <= 100 ? cleaned : "ride" + Path.GetExtension(cleaned);
    }

    private const string ReadMe = """
        Your Velomine data
        ==================

        profile.json        your account details and training settings
        bikes.json          your bikes and their parts
        rides.json          every ride: its numbers, its status, and where its original file is in this ZIP
        goals.json          your goals
        notifications.json  your notifications
        files/              every ride file exactly as you uploaded it (FIT, GPX or TCX). They hold all the recorded
                            samples (position, speed, power, heart rate, cadence), so any other tool can read them.

        This is all the data Velomine keeps about you, except your password (which is stored only as a one-way hash)
        and the single sign-on link to your provider. Times are UTC. Distances are in metres, durations in seconds,
        speeds in metres per second.
        """;
}
