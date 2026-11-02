using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Bikes;

/// <summary>A bike with what it has done so far: the distance it came with plus every ready ride on it.</summary>
public sealed record BikeResponse(
    Guid Id,
    string Name,
    string? Brand,
    string? Model,
    string Kind,
    int WheelCircumferenceMm,
    double InitialDistanceM,
    DateOnly? PurchasedOn,
    bool IsDefault,
    bool IsActive,
    int RideCount,
    double DistanceM,
    double MovingS);

/// <summary>A part with its limits and how much of them it has used. Percent is null when it has no limit.</summary>
public sealed record ComponentResponse(
    Guid Id,
    string Type,
    string TypeName,
    string? Brand,
    string? Model,
    DateOnly InstalledOn,
    DateOnly? RemovedOn,
    double? ExpectedDistanceM,
    double? ExpectedHours,
    int? ExpectedMonths,
    double UsedDistanceM,
    double UsedHours,
    double UsedMonths,
    int? WearPercent,
    string Status);

public sealed record BikeDetailResponse(BikeResponse Bike, ComponentResponse[] Components);

public static class BikeQueries
{
    public static async Task<BikeResponse[]> SummariesAsync(VelomineDbContext db, IReadOnlyList<Bike> bikes, CancellationToken ct)
    {
        var ids = bikes.Select(b => b.Id).ToList();
        var totals = await db.Rides.AsNoTracking()
            .Where(r => r.BikeId != null && ids.Contains(r.BikeId.Value) && r.Status == RideStatus.Ready)
            .GroupBy(r => r.BikeId!.Value)
            .Select(g => new { Id = g.Key, Count = g.Count(), Distance = g.Sum(r => r.DistanceM ?? 0), Moving = g.Sum(r => r.MovingS ?? 0) })
            .ToDictionaryAsync(t => t.Id, ct);

        return [.. bikes.Select(b =>
        {
            totals.TryGetValue(b.Id, out var t);
            return new BikeResponse(b.Id, b.Name, b.Brand, b.Model, b.Kind, b.WheelCircumferenceMm, b.InitialDistanceM, b.PurchasedOn,
                b.IsDefault, b.IsActive, t?.Count ?? 0, b.InitialDistanceM + (t?.Distance ?? 0), t?.Moving ?? 0);
        })];
    }

    public static async Task<BikeDetailResponse> DetailAsync(VelomineDbContext db, Bike bike, DateOnly today, CancellationToken ct)
    {
        var rides = (await db.Rides.AsNoTracking()
                .Where(r => r.BikeId == bike.Id && r.Status == RideStatus.Ready && r.StartTime != null)
                .Select(r => new { r.StartTime, r.UtcOffsetMinutes, r.DistanceM, r.MovingS })
                .ToListAsync(ct))
            .Select(r => new RideUse(RideUse.LocalDateOf(r.StartTime!.Value, r.UtcOffsetMinutes), r.DistanceM ?? 0, r.MovingS ?? 0))
            .ToList();

        var components = bike.Components
            .OrderBy(c => c.RemovedOn != null)
            .ThenBy(c => ComponentTypes.NameOf(c.Type))
            .ThenByDescending(c => c.InstalledOn)
            .Select(c => Component(c, BikeWear.Compute(c, rides, today)))
            .ToArray();

        return new BikeDetailResponse((await SummariesAsync(db, [bike], ct))[0], components);
    }

    public static ComponentResponse Component(BikeComponent c, ComponentWear w) => new(
        c.Id, c.Type, ComponentTypes.NameOf(c.Type), c.Brand, c.Model, c.InstalledOn, c.RemovedOn,
        c.ExpectedDistanceM, c.ExpectedHours, c.ExpectedMonths, w.DistanceM, w.Hours, w.Months, w.Percent, w.Status);
}
