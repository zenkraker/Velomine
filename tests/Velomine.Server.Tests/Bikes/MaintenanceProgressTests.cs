using Velomine.Server.Features.Bikes;

namespace Velomine.Server.Tests.Bikes;

public sealed class MaintenanceProgressTests
{
    private static readonly DateOnly Today = new(2026, 6, 1);

    private static MaintenanceReminder Reminder(string lastDone, double? km = null, double? hours = null, int? months = null, bool paused = false) => new()
    {
        LastDoneOn = DateOnly.Parse(lastDone),
        IntervalDistanceM = km * 1000,
        IntervalHours = hours,
        IntervalMonths = months,
        IsPaused = paused,
    };

    private static RideUse Ride(string date, double km, double hours = 1) => new(DateOnly.Parse(date), km * 1000, hours * 3600);

    [Fact]
    public void MaintenanceProgress_ShouldCountFromTheDoneDayOn_WhenRidesSurroundIt()
    {
        var progress = MaintenanceProgress.Compute(Reminder("2026-03-01", km: 300),
            [Ride("2026-02-28", 100), Ride("2026-03-01", 40), Ride("2026-03-02", 170)], Today);

        // The ride the day before is the last cycle's; the done day itself counts, as a part's fitting day does.
        Assert.Equal(210_000, progress.DistanceM);
        Assert.Equal(2, progress.Hours);
        Assert.Equal(70, progress.Percent);
        Assert.Equal("ok", progress.Status);
    }

    [Theory]
    [InlineData(239, "ok")]
    [InlineData(240, "soon")]
    [InlineData(299, "soon")]
    [InlineData(300, "due")]
    public void MaintenanceProgress_ShouldUseThePartThresholds_WhenWorkingOutTheStatus(double km, string status) =>
        Assert.Equal(status, MaintenanceProgress.Compute(Reminder("2026-01-01", km: 300), [Ride("2026-02-01", km)], Today).Status);

    [Fact]
    public void MaintenanceProgress_ShouldBeDueAtTheFirstLimitReached_WhenSeveralIntervalsAreSet()
    {
        // 50 of 300 km (16 %), 9.5 of 10 hours (95 %), about 5 of 12 months (41 %).
        var progress = MaintenanceProgress.Compute(Reminder("2026-01-01", km: 300, hours: 10, months: 12), [Ride("2026-01-10", 50, hours: 9.5)], Today);

        Assert.Equal(95, progress.Percent);
        Assert.Equal("soon", progress.Status);
    }

    [Fact]
    public void MaintenanceProgress_ShouldAdvanceWithTheCalendar_WhenOnlyMonthsAreSet()
    {
        var progress = MaintenanceProgress.Compute(Reminder("2026-03-01", months: 3), [], Today);

        Assert.InRange(progress.Months, 2.9, 3.1);
        Assert.Equal("due", progress.Status);
        Assert.Equal(0, progress.DistanceM);
    }

    [Fact]
    public void MaintenanceProgress_ShouldHavePausedStatus_WhenPaused()
    {
        var progress = MaintenanceProgress.Compute(Reminder("2025-01-01", km: 1, paused: true), [Ride("2026-01-01", 100)], Today);

        Assert.Equal("paused", progress.Status);
        Assert.True(progress.Percent >= 100); // still counted, just silent
    }

    [Fact]
    public void MaintenanceProgress_ShouldAgreeWithPartWear_WhenTheSameLimitsAndDatesAreUsed()
    {
        RideUse[] rides = [Ride("2026-02-28", 100), Ride("2026-03-01", 40), Ride("2026-04-10", 90, hours: 3.5), Ride("2026-05-30", 25, hours: 0.5)];
        var part = new BikeComponent { InstalledOn = new DateOnly(2026, 3, 1), ExpectedDistanceM = 200_000, ExpectedHours = 10, ExpectedMonths = 6 };
        var reminder = new MaintenanceReminder { LastDoneOn = new DateOnly(2026, 3, 1), IntervalDistanceM = 200_000, IntervalHours = 10, IntervalMonths = 6 };

        var wear = BikeWear.Compute(part, rides, Today);
        var progress = MaintenanceProgress.Compute(reminder, rides, Today);

        Assert.Equal(wear.DistanceM, progress.DistanceM);
        Assert.Equal(wear.Hours, progress.Hours);
        Assert.Equal(wear.Months, progress.Months);
        Assert.Equal(wear.Percent, progress.Percent);
        Assert.Equal(155_000, progress.DistanceM);
    }

    [Fact]
    public void MaintenanceProgress_ShouldListTheMostUrgentFirst_WhenSorting()
    {
        var rides = new[] { Ride("2026-02-01", 250) };
        var items = new[]
        {
            Reminder("2026-01-01", km: 1000).Named("Fine"),
            Reminder("2026-01-01", km: 300).Named("Soon"),
            Reminder("2026-01-01", km: 100).Named("Due"),
            Reminder("2026-01-01", km: 100, paused: true).Named("Paused"),
        }.Select(r => (r, MaintenanceProgress.Compute(r, rides, Today)));

        Assert.Equal(["Due", "Soon", "Fine", "Paused"], MaintenanceProgress.Sorted(items).Select(r => r.Name));
    }

    [Fact]
    public void ServiceLogQueries_ShouldCountRidesUpToAndIncludingTheDate_WhenWorkingOutTheBikeDistance()
    {
        var bike = new Bike { InitialDistanceM = 4_000_000 };
        RideUse[] rides = [Ride("2026-02-28", 100), Ride("2026-03-01", 40), Ride("2026-03-02", 170)];

        Assert.Equal(4_000_000, ServiceLogQueries.DistanceAt(bike, rides, new DateOnly(2026, 2, 27)));
        Assert.Equal(4_100_000, ServiceLogQueries.DistanceAt(bike, rides, new DateOnly(2026, 2, 28)));
        Assert.Equal(4_140_000, ServiceLogQueries.DistanceAt(bike, rides, new DateOnly(2026, 3, 1)));
        Assert.Equal(4_310_000, ServiceLogQueries.DistanceAt(bike, rides, Today));
    }

    [Theory]
    [InlineData("road", true, false, true)]
    [InlineData("mountain", true, true, true)]
    [InlineData("track", false, false, false)]
    [InlineData("city", false, false, false)]
    public void MaintenanceJobs_ShouldOfferOnlyWhatFitsTheKind_WhenListingJobs(string kind, bool sealant, bool suspension, bool electronicBattery)
    {
        var ids = MaintenanceJobs.For(kind).Select(j => j.Id).ToList();

        Assert.Contains("chain_lube", ids);
        Assert.Contains("bolt_check", ids);
        Assert.Equal(sealant, ids.Contains("sealant_top_up"));
        Assert.Equal(suspension, ids.Contains("fork_service") && ids.Contains("shock_service"));
        Assert.Equal(electronicBattery, ids.Contains("shifting_battery_charge"));
        Assert.Equal(kind != "track", ids.Contains("brake_bleed"));
    }
}

internal static class ReminderTestExtensions
{
    public static MaintenanceReminder Named(this MaintenanceReminder reminder, string name)
    {
        reminder.Name = name;
        return reminder;
    }
}
