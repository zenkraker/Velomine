using Velomine.Server.Features.Bikes;

namespace Velomine.Server.Tests.Bikes;

public sealed class BikeWearTests
{
    private static readonly DateOnly Today = new(2026, 6, 1);

    private static BikeComponent Part(string installed, string? removed = null, double? km = null, double? hours = null, int? months = null) => new()
    {
        InstalledOn = DateOnly.Parse(installed),
        RemovedOn = removed is null ? null : DateOnly.Parse(removed),
        ExpectedDistanceM = km * 1000,
        ExpectedHours = hours,
        ExpectedMonths = months,
    };

    private static RideUse Ride(string date, double km, double hours = 1) => new(DateOnly.Parse(date), km * 1000, hours * 3600);

    [Fact]
    public void CountsOnlyRidesBetweenInstalledAndRemoved_BothDaysIncluded()
    {
        var part = Part("2026-03-01", removed: "2026-04-01", km: 1000);
        var w = BikeWear.Compute(part, [Ride("2026-02-28", 100), Ride("2026-03-01", 100), Ride("2026-04-01", 50), Ride("2026-04-02", 100)], Today);

        Assert.Equal(150_000, w.DistanceM);
        Assert.Equal(2, w.Hours);
        Assert.Equal(15, w.Percent);
        Assert.Equal("retired", w.Status);
    }

    [Theory]
    [InlineData(790, "ok")]
    [InlineData(800, "soon")]
    [InlineData(999, "soon")]
    [InlineData(1000, "worn")]
    public void StatusFollowsThePercentUsed(double km, string status) =>
        Assert.Equal(status, BikeWear.Compute(Part("2026-01-01", km: 1000), [Ride("2026-02-01", km)], Today).Status);

    [Fact]
    public void TheMostWornLimitDecides()
    {
        // 100 of 1000 km (10 %), 5 of 10 hours (50 %), about 5 of 6 months (~83 %).
        var part = Part("2026-01-01", km: 1000, hours: 10, months: 6);
        var w = BikeWear.Compute(part, [Ride("2026-01-10", 100, hours: 5)], Today);

        Assert.InRange(w.Months, 4.9, 5.0);
        Assert.Equal(82, w.Percent);
        Assert.Equal("soon", w.Status);
    }

    [Fact]
    public void WithoutLimits_ThereIsNoPercent_AndItStaysOk()
    {
        var w = BikeWear.Compute(Part("2026-01-01"), [Ride("2026-02-01", 100)], Today);

        Assert.Null(w.Percent);
        Assert.Equal("ok", w.Status);
        Assert.Equal(100_000, w.DistanceM);
    }

    [Fact]
    public void LocalDate_UsesTheRidersOffset()
    {
        // 23:30 UTC on the 1st is already the 2nd in Rome (+120 minutes).
        var start = new DateTimeOffset(2026, 3, 1, 23, 30, 0, TimeSpan.Zero);
        Assert.Equal(new DateOnly(2026, 3, 2), RideUse.LocalDateOf(start, 120));
        Assert.Equal(new DateOnly(2026, 3, 1), RideUse.LocalDateOf(start, null));
    }
}
