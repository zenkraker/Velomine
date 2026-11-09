using Velomine.Server.Features.Rides;

namespace Velomine.Server.Features.Bikes;

/// <summary>
/// Chooses the bike a new ride is given. The ride's dimensions pick a bike kind (an e-bike for an assisted ride,
/// a mountain bike for a mountain ride, a city bike for a commute); the member's single default bike is the
/// fallback when that kind has no active bike.
/// </summary>
public static class DefaultBike
{
    /// <summary>The kind of bike the ride's dimensions prefer, or null when they say nothing useful.</summary>
    public static string? KindFor(string? discipline, string? assist, string? environment, bool? commute)
    {
        if (assist == Assists.EBike) return "ebike";
        if (environment is Velomine.Server.Features.Rides.Environments.Indoor or Velomine.Server.Features.Rides.Environments.Virtual) return null;
        if (discipline is not null)
        {
            return discipline switch
            {
                Disciplines.Road => "road",
                Disciplines.Gravel => "gravel",
                Disciplines.Mountain => "mountain",
                Disciplines.Track => "track",
                _ => null,
            };
        }

        return commute == true ? "city" : null;
    }

    /// <summary>
    /// Picks from the member's active bikes, oldest first. A bike of the preferred kind wins; otherwise the
    /// member's single default bike is used, even when it has another kind.
    /// </summary>
    public static Guid? For(
        IReadOnlyList<Bike> bikes,
        string? discipline,
        string? assist,
        string? environment,
        bool? commute)
    {
        if (KindFor(discipline, assist, environment, commute) is { } kind)
        {
            var match = bikes.FirstOrDefault(b => b.Kind == kind && b.IsDefault)
                        ?? bikes.FirstOrDefault(b => b.Kind == kind);
            if (match is not null) return match.Id;
        }

        return bikes.FirstOrDefault(b => b.IsDefault)?.Id;
    }
}
