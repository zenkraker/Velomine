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
        double distance = 0, seconds = 0;
        foreach (var ride in bikeRides)
        {
            if (ride.LocalDate < component.InstalledOn || (component.RemovedOn is { } removed && ride.LocalDate > removed)) continue;
            distance += ride.DistanceM;
            seconds += ride.MovingS;
        }

        var hours = seconds / 3600;
        var end = component.RemovedOn ?? today;
        var months = end < component.InstalledOn ? 0 : (end.DayNumber - component.InstalledOn.DayNumber) / DaysPerMonth;

        var fractions = new List<double>();
        if (component.ExpectedDistanceM is > 0) fractions.Add(distance / component.ExpectedDistanceM.Value);
        if (component.ExpectedHours is > 0) fractions.Add(hours / component.ExpectedHours.Value);
        if (component.ExpectedMonths is > 0) fractions.Add(months / component.ExpectedMonths.Value);

        // Rounded down, so a part at 99.9 % never reads as worn.
        int? percent = fractions.Count == 0 ? null : (int)Math.Floor(fractions.Max() * 100);
        var status = component.RemovedOn is not null ? "retired" : percent switch
        {
            >= 100 => "worn",
            >= SoonPercent => "soon",
            _ => "ok",
        };
        return new ComponentWear(distance, hours, months, percent, status);
    }
}
