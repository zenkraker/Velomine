namespace Velomine.Server.Features.Bikes;

/// <summary>A kind of part, with how long it typically lasts, so adding one can start from a sensible limit.</summary>
public sealed record ComponentType(string Id, string Name, string Group, double? TypicalDistanceKm = null, double? TypicalHours = null, int? TypicalMonths = null);

/// <summary>
/// The parts a bike has. The typical lifetimes are rough rules of thumb for road and gravel riding and are only a starting
/// point: they depend on the part, the weather, the riding and the rider. Members change them to what suits their bike.
/// </summary>
public static class ComponentTypes
{
    public static readonly ComponentType[] All =
    [
        new("chain", "Chain", "Drivetrain", TypicalDistanceKm: 4000),
        new("cassette", "Cassette", "Drivetrain", TypicalDistanceKm: 12000),
        new("chainring", "Chainring", "Drivetrain", TypicalDistanceKm: 15000),
        new("crankset", "Crankset", "Drivetrain"),
        new("bottom_bracket", "Bottom bracket", "Drivetrain", TypicalDistanceKm: 15000),
        new("front_derailleur", "Front derailleur", "Drivetrain"),
        new("rear_derailleur", "Rear derailleur", "Drivetrain"),
        new("derailleur_hanger", "Derailleur hanger", "Drivetrain", TypicalMonths: 24),
        new("shifters", "Shifters", "Drivetrain"),
        new("shift_cables", "Shift cables", "Drivetrain", TypicalMonths: 12),
        new("pedals", "Pedals", "Drivetrain", TypicalDistanceKm: 20000),
        new("front_tire", "Front tire", "Wheels", TypicalDistanceKm: 5000),
        new("rear_tire", "Rear tire", "Wheels", TypicalDistanceKm: 4000),
        new("tubeless_sealant", "Tubeless sealant", "Wheels", TypicalMonths: 3),
        new("inner_tubes", "Inner tubes", "Wheels", TypicalMonths: 24),
        new("wheelset", "Wheelset", "Wheels"),
        new("hub_service", "Hub service", "Wheels", TypicalDistanceKm: 10000, TypicalMonths: 12),
        new("front_brake_pads", "Front brake pads", "Brakes", TypicalDistanceKm: 2500),
        new("rear_brake_pads", "Rear brake pads", "Brakes", TypicalDistanceKm: 2000),
        new("front_rotor", "Front rotor", "Brakes", TypicalDistanceKm: 10000),
        new("rear_rotor", "Rear rotor", "Brakes", TypicalDistanceKm: 8000),
        new("brake_fluid", "Brake fluid", "Brakes", TypicalMonths: 24),
        new("brake_cables", "Brake cables", "Brakes", TypicalMonths: 12),
        new("handlebar_tape", "Handlebar tape or grips", "Cockpit", TypicalMonths: 12),
        new("handlebar", "Handlebar", "Cockpit"),
        new("stem", "Stem", "Cockpit"),
        new("headset", "Headset", "Cockpit", TypicalDistanceKm: 20000),
        new("saddle", "Saddle", "Cockpit"),
        new("seatpost", "Seatpost", "Cockpit"),
        new("fork_service", "Fork service", "Suspension", TypicalHours: 50, TypicalMonths: 12),
        new("shock_service", "Rear shock service", "Suspension", TypicalHours: 50, TypicalMonths: 12),
        new("dropper_post_service", "Dropper post service", "Suspension", TypicalHours: 100, TypicalMonths: 12),
        new("e_battery", "E-bike battery", "Electric"),
        new("e_motor", "E-bike motor", "Electric"),
        new("other", "Other part", "Other"),
    ];

    public static readonly IReadOnlySet<string> Ids = All.Select(t => t.Id).ToHashSet();

    public static string NameOf(string id) => All.FirstOrDefault(t => t.Id == id)?.Name ?? id;
}
