namespace Velomine.Server.Features.Training;

/// <summary>
/// The member's zone, from what their device could say: the zone's own name when the browser sends it, otherwise the
/// zone matching the offset the device reports. The offset alone cannot say whether the rider's zone keeps daylight
/// saving, so this is a fallback and the closest zone with that offset is taken, preferring one that does (a rider in
/// Rome at +60 is in Europe/Amsterdam's kind of zone, not Lagos's). Null when neither is usable: the account keeps UTC.
/// </summary>
public static class DeviceZone
{
    public static string? Of(string? name, int? utcOffsetMinutes, TimeProvider time)
    {
        if (!string.IsNullOrWhiteSpace(name) && TimeZoneInfo.TryFindSystemTimeZoneById(name.Trim(), out _))
            return name.Trim();
        if (utcOffsetMinutes is not { } minutes) return null;

        var now = time.GetUtcNow();
        return TimeZoneInfo.GetSystemTimeZones()
            .Where(z => z.GetUtcOffset(now).TotalMinutes == minutes)
            .OrderByDescending(z => z.SupportsDaylightSavingTime)
            .ThenBy(z => z.Id, StringComparer.Ordinal)
            .Select(z => z.Id)
            .FirstOrDefault();
    }
}
