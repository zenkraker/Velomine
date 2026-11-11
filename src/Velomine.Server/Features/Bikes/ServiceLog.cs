using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Velomine.Server.Data;

namespace Velomine.Server.Features.Bikes;

public static class ServiceOrigins
{
    public const string Manual = "manual";

    /// <summary>Written when a maintenance reminder was marked done.</summary>
    public const string Reminder = "reminder";

    /// <summary>Written when a part was replaced.</summary>
    public const string Part = "part";
}

/// <summary>
/// One thing done to a bike: a date, what was done, and optionally where, what it cost and the part or reminder it
/// concerns. The bike's distance at that date is not kept; it is worked out from the rides when the log is read.
/// </summary>
public sealed class ServiceEntry
{
    public Guid Id { get; set; }

    public Guid BikeId { get; set; }

    public DateOnly Date { get; set; }

    public string Title { get; set; } = "";

    public string? Notes { get; set; }

    /// <summary>"At home" is no value; a shop is its name.</summary>
    public string? Place { get; set; }

    /// <summary>What it cost, with <see cref="CostCurrency"/>; both are set or neither. Kept only; nothing is added up from it.</summary>
    public decimal? CostAmount { get; set; }

    /// <summary>An ISO 4217 code such as EUR.</summary>
    public string? CostCurrency { get; set; }

    /// <summary>The part it concerns. Becomes null when that part is deleted; the entry stays.</summary>
    public Guid? ComponentId { get; set; }

    /// <summary>The reminder it concerns. Becomes null when that reminder is deleted; the entry stays.</summary>
    public Guid? ReminderId { get; set; }

    /// <summary>One of <see cref="ServiceOrigins"/>: how it came to be.</summary>
    public string Origin { get; set; } = ServiceOrigins.Manual;

    public DateTimeOffset CreatedAt { get; set; }

    public uint Version { get; set; }
}

public sealed record ServiceEntryResponse(
    Guid Id,
    DateOnly Date,
    string Title,
    string? Notes,
    string? Place,
    decimal? CostAmount,
    string? CostCurrency,
    Guid? ComponentId,
    Guid? ReminderId,
    string Origin,
    double BikeDistanceM);

public static class ServiceLogQueries
{
    /// <summary>
    /// The bike's distance at the end of a date: what it came with plus every ready ride up to and including that day
    /// (on the member's own calendar, like part wear).
    /// </summary>
    public static double DistanceAt(Bike bike, IReadOnlyList<RideUse> rides, DateOnly date)
    {
        var total = bike.InitialDistanceM;
        foreach (var ride in rides)
            if (ride.LocalDate <= date) total += ride.DistanceM;
        return total;
    }

    public static ServiceEntryResponse Response(ServiceEntry e, Bike bike, IReadOnlyList<RideUse> rides) => new(
        e.Id, e.Date, e.Title, e.Notes, e.Place, e.CostAmount, e.CostCurrency, e.ComponentId, e.ReminderId, e.Origin,
        DistanceAt(bike, rides, e.Date));

    /// <summary>Adds an entry to the context; the caller saves it with the change it is about.</summary>
    public static ServiceEntry Add(VelomineDbContext db, TimeProvider time, Guid bikeId, DateOnly date, string title, string origin,
        Guid? componentId = null, Guid? reminderId = null)
    {
        var trimmed = title.Trim();
        var entry = new ServiceEntry
        {
            Id = Guid.CreateVersion7(),
            BikeId = bikeId,
            Date = date,
            Title = trimmed.Length > 200 ? trimmed[..200] : trimmed,
            Origin = origin,
            ComponentId = componentId,
            ReminderId = reminderId,
            CreatedAt = time.GetUtcNow(),
        };
        db.ServiceEntries.Add(entry);
        return entry;
    }
}

public sealed class ServiceEntryConfiguration : IEntityTypeConfiguration<ServiceEntry>
{
    public void Configure(EntityTypeBuilder<ServiceEntry> entry)
    {
        entry.ToTable("service_entries", "bikes", t =>
        {
            t.HasCheckConstraint("ck_service_entries_cost", "(cost_amount IS NULL AND cost_currency IS NULL) OR (cost_amount >= 0 AND cost_currency IS NOT NULL)");
        });
        entry.HasKey(e => e.Id);
        entry.Property(e => e.Title).HasMaxLength(200);
        entry.Property(e => e.Notes).HasMaxLength(2000);
        entry.Property(e => e.Place).HasMaxLength(100);
        entry.Property(e => e.CostAmount).HasPrecision(12, 2);
        entry.Property(e => e.CostCurrency).HasMaxLength(3);
        entry.Property(e => e.Origin).HasMaxLength(16);
        entry.Property(e => e.Version).IsRowVersion();
        entry.HasOne<Bike>().WithMany().HasForeignKey(e => e.BikeId).OnDelete(DeleteBehavior.Cascade);
        entry.HasOne<BikeComponent>().WithMany().HasForeignKey(e => e.ComponentId).OnDelete(DeleteBehavior.SetNull);
        entry.HasOne<MaintenanceReminder>().WithMany().HasForeignKey(e => e.ReminderId).OnDelete(DeleteBehavior.SetNull);
        entry.HasIndex(e => new { e.BikeId, e.Date, e.Id });
        entry.HasIndex(e => e.ComponentId);
        entry.HasIndex(e => e.ReminderId);
    }
}
