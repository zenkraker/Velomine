using Velomine.Server.Features.Analytics;
using Velomine.Server.Features.Privacy;
using Velomine.Server.Features.Rides;

namespace Velomine.Server.Tests.Privacy;

/// <summary>
/// The one privacy function every non-owner view goes through, tested on its own: it redacts the route only, so how
/// the start and end are trimmed, that a zone in the middle hides only the middle, and that every number of the ride
/// reaches a viewer as it is.
/// A ride heading north from 46.0, 11.0: one degree of latitude is about 111.2 km, so 0.001 is about 111 m.
/// </summary>
public sealed class PrivacyRulesTests
{
    private const double Start = 46.0;
    private const double Lon = 11.0;

    private static PrivacyProfile Trimmed(int trimStart = 0, int trimEnd = 0, params PrivacyZone[] zones) =>
        new(new PrivacyDefaults(trimStart, trimEnd), zones);

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
        PowerZones: [new ZoneTime(1, 110, 150, 300)],
        HeartRateZoneModel: HeartRateZoneModels.Threshold,
        HeartRateZoneReferenceBpm: 160,
        HeartRateZoneReferenceSource: "measured");

    [Fact]
    public void ForViewer_ShouldHideTheEndOfTheRide_WhenTheEndIsTrimmed()
    {
        // 20 points 111 m apart: trimming 300 m at the end leaves every point up to 1.9 km.
        var hidden = PrivacyRules.ForViewer(Line(), Trimmed(trimEnd: 300), showRoute: true);

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

        var hidden = PrivacyRules.ForViewer(Line(), Trimmed(zones: zone), showRoute: true);

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

        var hidden = PrivacyRules.ForViewer(Line(), Trimmed(zones: zone), showRoute: true);

        Assert.All(hidden.Latitude!, point => Assert.Null(point));
    }

    [Fact]
    public void ForViewer_ShouldPassEverySignal_WhenTheRideIsShared()
    {
        var shared = PrivacyRules.ForViewer(Line(), Trimmed(), showRoute: true);

        Assert.Equal(Line().HeartRate, shared.HeartRate);
        Assert.Equal(Line().Power, shared.Power);
        Assert.Equal(Line().Cadence, shared.Cadence);
        Assert.Equal(Line().Speed, shared.Speed);
        Assert.Equal(Line().Altitude, shared.Altitude);
        Assert.Equal(Line().Temperature, shared.Temperature);
        Assert.NotNull(shared.Latitude);
    }

    [Fact]
    public void ForViewer_ShouldHideThePositions_WhenTheViewerLacksTheRoutesGrant()
    {
        var hidden = PrivacyRules.ForViewer(Line(), Trimmed(), showRoute: false);

        Assert.Null(hidden.Latitude);
        Assert.Null(hidden.Longitude);
        Assert.NotNull(hidden.HeartRate); // every other signal stays
        Assert.NotNull(hidden.Power);
    }

    [Fact]
    public void ForViewer_ShouldPassEveryNumber_WhenTheRideIsShared()
    {
        var ride = Ride(Guid.NewGuid()) with
        {
            HrTss = 64.0,
            EstimatedAvgPowerW = 180,
            EfficiencyFactor = 2.1,
            DecouplingPct = 4.2,
            Steady = true,
            WPrimeJ = 22_000,
            MinWPrimeBalanceJ = 8000,
        };

        var shared = PrivacyRules.ForViewer(ride);

        Assert.Equal(210, shared.AvgPowerW);
        Assert.Equal(480, shared.MaxPowerW);
        Assert.Equal(240, shared.NormalizedPowerW);
        Assert.Equal(1.2, shared.IntensityFactor);
        Assert.Equal(95.5, shared.Tss);
        Assert.Equal(64.0, shared.HrTss);
        Assert.Equal(151, shared.AvgHeartRate);
        Assert.Equal(178, shared.MaxHeartRate);
        Assert.Equal(42.5, shared.Trimp);
        Assert.Equal(88, shared.AvgCadence);
        Assert.Equal(6.8, shared.AvgSpeedMs);
        Assert.Equal(11.2, shared.MaxSpeedMs);
        Assert.Equal(120, shared.ElevationGainM);
        Assert.Equal(40, shared.ElevationLossM);
        Assert.Equal(180, shared.EstimatedAvgPowerW);
        Assert.Equal(2.1, shared.EfficiencyFactor);
        Assert.Equal(4.2, shared.DecouplingPct);
        Assert.True(shared.Steady);
        Assert.Equal(22_000, shared.WPrimeJ);
        Assert.Equal(8000, shared.MinWPrimeBalanceJ);
        Assert.NotNull(shared.HeartRateZones);
        Assert.NotNull(shared.PowerZones);
        Assert.Equal(HeartRateZoneModels.Threshold, shared.HeartRateZoneModel);
        Assert.Equal(160, shared.HeartRateZoneReferenceBpm);
    }

    [Fact]
    public void ForViewer_ShouldClearTheRidersOwnAnswers_WhenTheRideIsShared()
    {
        // What the ride did to the rider's numbers, and their own question about it, are never a viewer's to read.
        var ride = Ride(Guid.NewGuid()) with
        {
            HeartRateNote = HeartRateNotes.MaxMeasured,
            HeartRateMaxNote = HeartRateNotes.MaxMeasured,
            HeartRateThresholdNote = HeartRateNotes.ThresholdMeasured,
            FtpSuggestionId = Guid.NewGuid(),
            FtpSuggestionW = 266,
            FtpSuggestionEffortW = 280,
            FtpSuggestionMethod = "20min",
        };

        var hidden = PrivacyRules.ForViewer(ride);

        Assert.Null(hidden.HeartRateNote);
        Assert.Null(hidden.HeartRateMaxNote);
        Assert.Null(hidden.HeartRateThresholdNote);
        Assert.Null(hidden.FtpSuggestionId);
        Assert.Null(hidden.FtpSuggestionW);
        Assert.Null(hidden.FtpSuggestionEffortW);
        Assert.Null(hidden.FtpSuggestionMethod);
    }

    [Fact]
    public void ForViewer_ShouldKeepTheTitleAndDescription_WhenTheRideIsShared()
    {
        // The member's own words about the ride are meant to pass; the per-ride wellbeing note is a different field
        // that never reaches a viewer at all.
        var hidden = PrivacyRules.ForViewer(Ride(Guid.NewGuid()));

        Assert.Equal("Morning", hidden.Title);
        Assert.Equal("Steady", hidden.Description);
        Assert.Equal("ride.fit", hidden.FileName);
    }

    [Fact]
    public void ForViewer_ShouldChangeNothing_WhenTheMemberSharesEverything()
    {
        var ride = Ride(Guid.NewGuid());
        var streams = Line();
        var none = new PrivacyProfile(PrivacyDefaults.None, []);

        Assert.Equal(ride, PrivacyRules.ForViewer(ride));
        Assert.Equal(streams.Latitude, PrivacyRules.ForViewer(streams, none, showRoute: true).Latitude);
    }
}
