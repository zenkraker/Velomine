using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Tests.Privacy;

/// <summary>
/// The one privacy function every non-owner view goes through, tested on its own: what each switch removes, how the
/// start and end are trimmed, and that a zone in the middle of the ride hides only the middle.
/// A ride heading north from 46.0, 11.0: one degree of latitude is about 111.2 km, so 0.001 is about 111 m.
/// </summary>
public sealed class PrivacyRulesTests
{
    private const double Start = 46.0;
    private const double Lon = 11.0;

    private static PrivacyProfile Hiding(
        bool heartRate = false, bool power = false, bool cadence = false, bool speed = false,
        bool elevation = false, bool temperature = false, int trimStart = 0, int trimEnd = 0,
        params PrivacyZone[] zones) =>
        new(heartRate, power, cadence, speed, elevation, temperature, trimStart, trimEnd, zones);

    /// <summary>A straight line north, 111 m per step, with every signal set.</summary>
    private static RideStreamsResponse Line(int points = 20) => new(
        [.. Enumerable.Range(0, points).Select(i => (double)i)],
        [.. Enumerable.Range(0, points).Select(i => Start + i * 0.001)],
        [.. Enumerable.Range(0, points).Select(_ => Lon)],
        [.. Enumerable.Range(0, points).Select(i => (float?)(100 + i))],
        [.. Enumerable.Range(0, points).Select(_ => (float?)8)],
        [.. Enumerable.Range(0, points).Select(i => (float?)(i * 111))],
        [.. Enumerable.Range(0, points).Select(_ => (short?)150)],
        [.. Enumerable.Range(0, points).Select(_ => (short?)200)],
        [.. Enumerable.Range(0, points).Select(_ => (short?)90)],
        [.. Enumerable.Range(0, points).Select(_ => (short?)20)]);

    private static RideResponse Ride(Guid id) => new(
        id, "ready", null, null, "ride.fit", DateTimeOffset.UnixEpoch, null, null, null, null, null, null, null,
        DistanceM: 2000, ElapsedS: 600, MovingS: 590, ElevationGainM: 120, ElevationLossM: 40,
        AvgSpeedMs: 6.8, MaxSpeedMs: 11.2, SpeedSource: "gps",
        AvgPowerW: 210, MaxPowerW: 480, NormalizedPowerW: 240, IntensityFactor: 1.2, Tss: 95.5, Trimp: 42.5,
        AvgHeartRate: 151, MaxHeartRate: 178, AvgCadence: 88, BikeId: null, Title: "Morning", Description: "Steady",
        Version: 1,
        HeartRateZones: [new ZoneTime(1, 100, 120, 60)],
        PowerZones: [new ZoneTime(1, 110, 150, 300)]);

    [Fact]
    public void ForViewer_ShouldHideTheEndOfTheRide_WhenTheEndIsTrimmed()
    {
        // 20 points 111 m apart: trimming 300 m at the end leaves every point up to 1.9 km.
        var hidden = PrivacyRules.ForViewer(Line(), Hiding(trimEnd: 300), showRoute: true);

        // The line is 19 x 111 m = 2.1 km; the last 300 m start at 1.8 km, so points 0-16 stay and 17-19 go.
        Assert.NotNull(hidden.Latitude![16]);
        Assert.Null(hidden.Latitude[17]);
        Assert.Null(hidden.Latitude[18]);
        Assert.Null(hidden.Latitude[19]);
    }

    [Fact]
    public void ForViewer_ShouldHideOnlyTheMiddle_WhenAPrivacyZoneSitsMidRide()
    {
        // A 250 m zone halfway: points 8-11 (0.9 to 1.2 km north) are inside it, the ends stay.
        var zone = new PrivacyZone { Name = "Work", Latitude = Start + 0.010, Longitude = Lon, RadiusM = 250 };

        var hidden = PrivacyRules.ForViewer(Line(), Hiding(zones: zone), showRoute: true);

        Assert.NotNull(hidden.Latitude![0]);
        Assert.Null(hidden.Latitude[10]);
        Assert.Null(hidden.Longitude![10]);
        Assert.NotNull(hidden.Latitude[^1]);
        Assert.Equal(20, hidden.Latitude.Length); // the sample stays, only its position goes
    }

    [Fact]
    public void ForViewer_ShouldKeepTheStartAndEnd_WhenAZoneCoversTheWholeRoute()
    {
        // Zones only hide what is inside them; a zone over the whole line leaves nothing to draw.
        var zone = new PrivacyZone { Latitude = Start + 0.005, Longitude = Lon, RadiusM = 1609 };

        var hidden = PrivacyRules.ForViewer(Line(), Hiding(zones: zone), showRoute: true);

        Assert.All(hidden.Latitude!, point => Assert.Null(point));
    }

    [Fact]
    public void ForViewer_ShouldHideEverySwitch_WhenTheMemberTurnedThemAllOff()
    {
        var hidden = PrivacyRules.ForViewer(
            Line(), Hiding(heartRate: true, power: true, cadence: true, speed: true, elevation: true, temperature: true), showRoute: true);

        Assert.Null(hidden.HeartRate);
        Assert.Null(hidden.Power);
        Assert.Null(hidden.Cadence);
        Assert.Null(hidden.Speed);
        Assert.Null(hidden.Altitude);
        Assert.Null(hidden.Temperature);
        Assert.NotNull(hidden.Latitude); // the route is its own grant, not one of the stream switches
    }

    [Fact]
    public void ForViewer_ShouldHideThePositions_WhenTheViewerLacksTheRoutesGrant()
    {
        var hidden = PrivacyRules.ForViewer(Line(), Hiding(), showRoute: false);

        Assert.Null(hidden.Latitude);
        Assert.Null(hidden.Longitude);
        Assert.NotNull(hidden.HeartRate); // every other signal stays
        Assert.NotNull(hidden.Power);
    }

    [Fact]
    public void ForViewer_ShouldNullThePowerNumbers_WhenPowerIsHidden()
    {
        var hidden = PrivacyRules.ForViewer(Ride(Guid.NewGuid()), Hiding(power: true));

        Assert.Null(hidden.AvgPowerW);
        Assert.Null(hidden.MaxPowerW);
        Assert.Null(hidden.NormalizedPowerW);
        Assert.Null(hidden.IntensityFactor); // IF and TSS are computed from power, so they are power
        Assert.Null(hidden.Tss);
        Assert.Null(hidden.PowerZones);
        Assert.Equal(151, hidden.AvgHeartRate); // heart rate is a separate switch
    }

    [Fact]
    public void ForViewer_ShouldNullTheHeartRateNumbers_WhenHeartRateIsHidden()
    {
        var hidden = PrivacyRules.ForViewer(Ride(Guid.NewGuid()), Hiding(heartRate: true));

        Assert.Null(hidden.AvgHeartRate);
        Assert.Null(hidden.MaxHeartRate);
        Assert.Null(hidden.Trimp); // load is the heart-rate weighted minutes
        Assert.Null(hidden.HeartRateZones);
        Assert.Equal(210, hidden.AvgPowerW);
        Assert.Equal(95.5, hidden.Tss);
    }

    [Fact]
    public void ForViewer_ShouldNullTheSpeedTheCadenceAndTheClimb_WhenEachIsHidden()
    {
        var id = Guid.NewGuid();

        var noSpeed = PrivacyRules.ForViewer(Ride(id), Hiding(speed: true));
        var noCadence = PrivacyRules.ForViewer(Ride(id), Hiding(cadence: true));
        var noClimb = PrivacyRules.ForViewer(Ride(id), Hiding(elevation: true));

        Assert.Null(noSpeed.AvgSpeedMs);
        Assert.Null(noSpeed.MaxSpeedMs);
        Assert.Null(noCadence.AvgCadence);
        Assert.Null(noClimb.ElevationGainM);
        Assert.Null(noClimb.ElevationLossM);
        // Everything else is untouched.
        Assert.Equal(2000, noSpeed.DistanceM);
        Assert.Equal(2000, noCadence.DistanceM);
        Assert.Equal(2000, noClimb.DistanceM);
    }

    [Fact]
    public void ForViewer_ShouldKeepTheTitleAndDescription_WhenTheRideIsShared()
    {
        // The member's own words about the ride are meant to pass; the per-ride wellbeing note is a different field
        // that never reaches a viewer at all.
        var hidden = PrivacyRules.ForViewer(Ride(Guid.NewGuid()), Hiding(heartRate: true, power: true));

        Assert.Equal("Morning", hidden.Title);
        Assert.Equal("Steady", hidden.Description);
        Assert.Equal("ride.fit", hidden.FileName);
    }

    [Fact]
    public void ForViewer_ShouldRedactALapLikeTheSummary_WhenTheLapIsShared()
    {
        var lap = new LapResponse(1, 0, 300, 300, 295, 2000, 6.8, 11.2, 210, 480, 151, 178, 88, 120);

        var hidden = PrivacyRules.ForViewer(lap, Hiding(heartRate: true, power: true, speed: true, cadence: true, elevation: true));

        Assert.Null(hidden.AvgHeartRate);
        Assert.Null(hidden.MaxHeartRate);
        Assert.Null(hidden.AvgPowerW);
        Assert.Null(hidden.MaxPowerW);
        Assert.Null(hidden.AvgSpeedMs);
        Assert.Null(hidden.MaxSpeedMs);
        Assert.Null(hidden.AvgCadence);
        Assert.Null(hidden.ElevationGainM);
        Assert.Equal(2000, hidden.DistanceM); // distance and time are not a signal the switches control
        Assert.Equal(300, hidden.DurationS);
    }

    [Fact]
    public void ForViewer_ShouldChangeNothing_WhenTheMemberSharesEverything()
    {
        var ride = Ride(Guid.NewGuid());
        var streams = Line();

        Assert.Equal(ride, PrivacyRules.ForViewer(ride, PrivacyProfile.None));
        Assert.Equal(streams.Latitude, PrivacyRules.ForViewer(streams, PrivacyProfile.None, showRoute: true).Latitude);
    }
}
