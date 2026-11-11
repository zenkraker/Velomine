namespace Velomine.Server.Features.Bikes;

/// <summary>One ride as the wear calculation sees it, on its local date (see <see cref="Accounts.MemberClock.LocalDateOf"/>).</summary>
public readonly record struct RideUse(DateOnly LocalDate, double DistanceM, double MovingS);

public sealed record ComponentWear(double DistanceM, double Hours, double Months, int? Percent, string Status);

/// <summary>
/// How worn a component is, worked out on request from the rides on its bike; nothing is stored.
/// A part wears from the day it was fitted to the day it was removed (both days included).
/// </summary>
public static class BikeWear
{
    private const double DaysPerMonth = 30.4375;
    private const int SoonPercent = 80;

    public static ComponentWear Compute(BikeComponent component, IEnumerable<RideUse> bikeRides, DateOnly today)
    {
        var wear = Measure(component.InstalledOn, component.RemovedOn, component.ExpectedDistanceM, component.ExpectedHours, component.ExpectedMonths, bikeRides, today);
        return component.RemovedOn is not null ? wear with { Status = "retired" } : wear;
    }

    /// <summary>
    /// How much of the limits the rides from <paramref name="from"/> to <paramref name="to"/> (or today) have used. Parts
    /// and maintenance reminders both count this way, so they always agree. The status is ok, soon or worn.
    /// </summary>
    public static ComponentWear Measure(DateOnly from, DateOnly? to, double? limitDistanceM, double? limitHours, int? limitMonths,
        IEnumerable<RideUse> bikeRides, DateOnly today)
    {
        double distance = 0, seconds = 0;
        foreach (var ride in bikeRides)
        {
            if (ride.LocalDate < from || (to is { } last && ride.LocalDate > last)) continue;
            distance += ride.DistanceM;
            seconds += ride.MovingS;
        }

        var hours = seconds / 3600;
        var end = to ?? today;
        var months = end < from ? 0 : (end.DayNumber - from.DayNumber) / DaysPerMonth;

        var fractions = new List<double>();
        if (limitDistanceM is > 0) fractions.Add(distance / limitDistanceM.Value);
        if (limitHours is > 0) fractions.Add(hours / limitHours.Value);
        if (limitMonths is > 0) fractions.Add(months / limitMonths.Value);

        // Rounded down, so a part at 99.9 % never reads as worn.
        int? percent = fractions.Count == 0 ? null : (int)Math.Floor(fractions.Max() * 100);
        var status = percent switch
        {
            >= 100 => "worn",
            >= SoonPercent => "soon",
            _ => "ok",
        };
        return new ComponentWear(distance, hours, months, percent, status);
    }
}
