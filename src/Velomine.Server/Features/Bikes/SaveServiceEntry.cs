using System.Text.RegularExpressions;
using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

/// <summary>The fields of a service log entry.</summary>
public interface IServiceEntryFields
{
    DateOnly Date { get; }
    string Title { get; }
    string? Notes { get; }
    string? Place { get; }
    decimal? CostAmount { get; }
    string? CostCurrency { get; }
}

public sealed class CreateServiceEntryRequest : IServiceEntryFields
{
    /// <summary>From the address.</summary>
    public Guid BikeId { get; set; }

    /// <summary>The day it was done, today or earlier.</summary>
    public required DateOnly Date { get; set; }

    /// <summary>What was done, such as "Replaced brake pads".</summary>
    public required string Title { get; set; }

    public string? Notes { get; set; }

    /// <summary>A shop's name. Leave out for "at home".</summary>
    public string? Place { get; set; }

    /// <summary>What it cost. Needs a currency.</summary>
    public decimal? CostAmount { get; set; }

    /// <summary>A three-letter currency code such as EUR.</summary>
    public string? CostCurrency { get; set; }

    /// <summary>The part it concerns, when it is about one.</summary>
    public Guid? ComponentId { get; set; }

    /// <summary>The reminder it concerns, when it is about one.</summary>
    public Guid? ReminderId { get; set; }
}

/// <summary>Changing an entry: all fields are sent each time.</summary>
public sealed class UpdateServiceEntryRequest : IServiceEntryFields
{
    /// <summary>From the address.</summary>
    public Guid BikeId { get; set; }

    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    public required DateOnly Date { get; set; }

    public required string Title { get; set; }

    public string? Notes { get; set; }

    public string? Place { get; set; }

    public decimal? CostAmount { get; set; }

    public string? CostCurrency { get; set; }

    public Guid? ComponentId { get; set; }

    public Guid? ReminderId { get; set; }
}

public partial class ServiceEntryFieldsValidator<T> : Validator<T> where T : IServiceEntryFields
{
    public ServiceEntryFieldsValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Notes).MaximumLength(2000);
        RuleFor(x => x.Place).MaximumLength(100);
        RuleFor(x => x.CostAmount).InclusiveBetween(0m, 1_000_000m).When(x => x.CostAmount.HasValue);
        RuleFor(x => x.CostCurrency).Must(c => c is null || CurrencyCode().IsMatch(c)).WithMessage("Use a three-letter currency code such as EUR.");
        RuleFor(x => x).Must(x => x.CostAmount.HasValue == !string.IsNullOrWhiteSpace(x.CostCurrency))
            .WithMessage("A cost needs an amount and a currency together.");
    }

    [GeneratedRegex("^[A-Za-z]{3}$")]
    private static partial Regex CurrencyCode();
}

public sealed class CreateServiceEntryValidator : ServiceEntryFieldsValidator<CreateServiceEntryRequest>;

public sealed class UpdateServiceEntryValidator : ServiceEntryFieldsValidator<UpdateServiceEntryRequest>;

public sealed class CreateServiceEntry(VelomineDbContext db, TimeProvider time) : Endpoint<CreateServiceEntryRequest, ServiceEntryResponse>
{
    public override void Configure()
    {
        Post("bikes/{bikeId}/service");
        Description(d => d.Accepts<CreateServiceEntryRequest>("application/json").Produces<ServiceEntryResponse>(201).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(CreateServiceEntryRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var bike = await db.Bikes.AsNoTracking().FirstOrDefaultAsync(b => b.Id == req.BikeId && b.UserId == userId, ct);
        if (bike is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        foreach (var problem in await ProblemsAsync(db, bike.Id, req.ComponentId, req.ReminderId, clock.Today, req.Date, ct)) AddError(problem);
        ThrowIfAnyErrors();

        var entry = ServiceLogQueries.Add(db, time, bike.Id, req.Date, req.Title, ServiceOrigins.Manual, req.ComponentId, req.ReminderId);
        Apply(entry, req);
        await db.SaveChangesAsync(ct);
        await Send.ResponseAsync(ServiceLogQueries.Response(entry, bike, await BikeQueries.RideUsesAsync(db, bike.Id, clock, ct)), 201, ct);
    }

    internal static void Apply(ServiceEntry entry, IServiceEntryFields req)
    {
        entry.Date = req.Date;
        entry.Title = req.Title.Trim();
        entry.Notes = string.IsNullOrWhiteSpace(req.Notes) ? null : req.Notes.Trim();
        entry.Place = string.IsNullOrWhiteSpace(req.Place) ? null : req.Place.Trim();
        entry.CostAmount = req.CostAmount;
        entry.CostCurrency = req.CostAmount.HasValue ? req.CostCurrency!.Trim().ToUpperInvariant() : null;
    }

    /// <summary>What is wrong with the date and links: it is in the future, or the part or reminder is not on this bike.</summary>
    internal static async Task<List<string>> ProblemsAsync(VelomineDbContext db, Guid bikeId, Guid? componentId, Guid? reminderId,
        DateOnly today, DateOnly date, CancellationToken ct)
    {
        var problems = new List<string>();
        if (date > today) problems.Add("The day it was done cannot be in the future.");
        if (componentId is { } c && !await db.BikeComponents.AnyAsync(x => x.Id == c && x.BikeId == bikeId, ct))
            problems.Add("That part is not on this bike.");
        if (reminderId is { } r && !await db.MaintenanceReminders.AnyAsync(x => x.Id == r && x.BikeId == bikeId, ct))
            problems.Add("That reminder is not on this bike.");
        return problems;
    }
}

public sealed class UpdateServiceEntry(VelomineDbContext db, TimeProvider time) : Endpoint<UpdateServiceEntryRequest, ServiceEntryResponse>
{
    public override void Configure()
    {
        Put("bikes/{bikeId}/service/{id}");
        Description(d => d.Accepts<UpdateServiceEntryRequest>("application/json").Produces<ServiceEntryResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateServiceEntryRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var bike = await db.Bikes.AsNoTracking().FirstOrDefaultAsync(b => b.Id == req.BikeId && b.UserId == userId, ct);
        var entry = bike is null ? null : await db.ServiceEntries.FirstOrDefaultAsync(e => e.Id == req.Id && e.BikeId == bike.Id, ct);
        if (bike is null || entry is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var clock = await MemberClock.ForAsync(db, userId, time, ct);
        foreach (var problem in await CreateServiceEntry.ProblemsAsync(db, bike.Id, req.ComponentId, req.ReminderId, clock.Today, req.Date, ct)) AddError(problem);
        ThrowIfAnyErrors();

        CreateServiceEntry.Apply(entry, req);
        entry.ComponentId = req.ComponentId;
        entry.ReminderId = req.ReminderId;
        await db.SaveChangesAsync(ct);
        await Send.OkAsync(ServiceLogQueries.Response(entry, bike, await BikeQueries.RideUsesAsync(db, bike.Id, clock, ct)), ct);
    }
}

public sealed class ServiceEntryIdRequest
{
    public Guid BikeId { get; set; }

    public Guid Id { get; set; }
}

public sealed class DeleteServiceEntry(VelomineDbContext db) : Endpoint<ServiceEntryIdRequest>
{
    public override void Configure()
    {
        Delete("bikes/{bikeId}/service/{id}");
        Description(d => d.Produces(204).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(ServiceEntryIdRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var deleted = await db.ServiceEntries
            .Where(e => e.Id == req.Id && e.BikeId == req.BikeId && db.Bikes.Any(b => b.Id == e.BikeId && b.UserId == userId))
            .ExecuteDeleteAsync(ct);
        if (deleted == 0) await Send.NotFoundAsync(ct);
        else await Send.NoContentAsync(ct);
    }
}
