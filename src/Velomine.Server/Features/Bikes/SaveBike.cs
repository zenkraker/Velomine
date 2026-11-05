using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Velomine.Server.Data;
using Velomine.Server.Features.Accounts;

namespace Velomine.Server.Features.Bikes;

/// <summary>The fields of a bike a member can set.</summary>
public interface IBikeFields
{
    string Name { get; }
    string? Brand { get; }
    string? Model { get; }
    string Kind { get; }
    int WheelCircumferenceMm { get; }
    double InitialDistanceM { get; }
    DateOnly? PurchasedOn { get; }
}

public sealed class CreateBikeRequest : IBikeFields
{
    public required string Name { get; set; }

    public string? Brand { get; set; }

    public string? Model { get; set; }

    /// <summary>road, gravel, mountain, ebike, timetrial, track, city or other.</summary>
    public required string Kind { get; set; }

    /// <summary>1000 to 2600 millimetres.</summary>
    public required int WheelCircumferenceMm { get; set; }

    /// <summary>Metres the bike had done before it was added here.</summary>
    public required double InitialDistanceM { get; set; }

    public DateOnly? PurchasedOn { get; set; }
}

/// <summary>Changing a bike: all fields are sent each time.</summary>
public sealed class UpdateBikeRequest : IBikeFields
{
    /// <summary>From the address.</summary>
    public Guid Id { get; set; }

    public required string Name { get; set; }

    public string? Brand { get; set; }

    public string? Model { get; set; }

    /// <summary>road, gravel, mountain, ebike, timetrial, track, city or other.</summary>
    public required string Kind { get; set; }

    /// <summary>1000 to 2600 millimetres.</summary>
    public required int WheelCircumferenceMm { get; set; }

    /// <summary>Metres the bike had done before it was added here.</summary>
    public required double InitialDistanceM { get; set; }

    public DateOnly? PurchasedOn { get; set; }

    /// <summary>An archived bike (false) is not offered for new rides. Leave out to keep it as it is.</summary>
    public bool? IsActive { get; set; }
}

public class BikeFieldsValidator<T> : Validator<T> where T : IBikeFields
{
    public BikeFieldsValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Brand).MaximumLength(100);
        RuleFor(x => x.Model).MaximumLength(100);
        RuleFor(x => x.Kind).Must(k => BikeKinds.All.Contains(k)).WithMessage("Choose one of: " + string.Join(", ", BikeKinds.All) + ".");
        RuleFor(x => x.WheelCircumferenceMm).InclusiveBetween(1000, 2600);
        RuleFor(x => x.InitialDistanceM).InclusiveBetween(0, 10_000_000);
    }
}

public sealed class CreateBikeValidator : BikeFieldsValidator<CreateBikeRequest>;

public sealed class UpdateBikeValidator : BikeFieldsValidator<UpdateBikeRequest>;

public sealed class CreateBike(VelomineDbContext db, TimeProvider time) : Endpoint<CreateBikeRequest, BikeDetailResponse>
{
    public override void Configure()
    {
        Post("bikes");
        Description(d => d.Accepts<CreateBikeRequest>("application/json").Produces<BikeDetailResponse>(201).ProducesProblem(400).Produces(401), clearDefaults: true);
    }

    public override async Task HandleAsync(CreateBikeRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var bike = new Bike
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            Name = req.Name.Trim(),
            Brand = req.Brand?.Trim(),
            Model = req.Model?.Trim(),
            Kind = req.Kind,
            WheelCircumferenceMm = req.WheelCircumferenceMm,
            InitialDistanceM = req.InitialDistanceM,
            PurchasedOn = req.PurchasedOn,
            CreatedAt = time.GetUtcNow(),
            // The first bike is the one rides are given until the member picks another.
            IsDefault = !await db.Bikes.AnyAsync(b => b.UserId == userId && b.IsDefault, ct),
        };
        db.Bikes.Add(bike);
        await db.SaveChangesAsync(ct);
        await Send.CreatedAtAsync<GetBike>(new { id = bike.Id }, await BikeQueries.DetailAsync(db, bike, await MemberClock.ForAsync(db, User.UserId(), time, ct), ct), cancellation: ct);
    }
}

public sealed class UpdateBike(VelomineDbContext db, TimeProvider time) : Endpoint<UpdateBikeRequest, BikeDetailResponse>
{
    public override void Configure()
    {
        Put("bikes/{id}");
        Description(d => d.Accepts<UpdateBikeRequest>("application/json").Produces<BikeDetailResponse>(200).ProducesProblem(400).Produces(401).Produces(404), clearDefaults: true);
    }

    public override async Task HandleAsync(UpdateBikeRequest req, CancellationToken ct)
    {
        var userId = User.UserId();
        var bike = await db.Bikes.Include(b => b.Components).FirstOrDefaultAsync(b => b.Id == req.Id && b.UserId == userId, ct);
        if (bike is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        bike.Name = req.Name.Trim();
        bike.Brand = req.Brand?.Trim();
        bike.Model = req.Model?.Trim();
        bike.Kind = req.Kind;
        bike.WheelCircumferenceMm = req.WheelCircumferenceMm;
        bike.InitialDistanceM = req.InitialDistanceM;
        bike.PurchasedOn = req.PurchasedOn;
        if (req.IsActive is { } active)
        {
            bike.IsActive = active;
            if (!active) bike.IsDefault = false; // an archived bike cannot be the default
        }

        await db.SaveChangesAsync(ct);
        await Send.OkAsync(await BikeQueries.DetailAsync(db, bike, await MemberClock.ForAsync(db, User.UserId(), time, ct), ct), ct);
    }
}
